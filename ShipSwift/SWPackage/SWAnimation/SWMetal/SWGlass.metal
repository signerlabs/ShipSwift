//
//  SWGlass.metal
//  ShipSwift
//
//  A stitchable SwiftUI `layerEffect` that turns any content into a sheet of
//  refractive glass laid over a region defined by an analytic signed-distance
//  field (SDF). The layer the effect is applied to is the *background* being
//  refracted; inside the SDF shape the background is bent, frosted, tinted and
//  lit, while outside the shape it passes through untouched (or is cut away
//  when `cutout` is on).
//
//  The glass is built entirely from the SDF and its gradient:
//    - The surface normal comes from a finite-difference gradient of the SDF.
//    - Thickness near the edge drives a squared refraction falloff so the rim
//      bends hard and the centre stays calm.
//    - A single in-shader golden-angle disk does the frosted blur, and the
//      same taps are reused with a chromatic split for dispersion.
//    - Tint, directional edge light, a 3D specular glint and a Fresnel rim are
//      layered on top, then cross-faded into the background by an edge mask.
//
//  This is a from-scratch Metal implementation of a well-known glass-refraction
//  technique, reorganised into a single linear kernel with local helpers.
//
//  Paired with: SWGlass.swift
//  Entry point: `swGlass` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - Local helpers
// =============================================================================

namespace sw_glass {

    // Luminance weights (Rec. 601) used by the luminosity-preserving tint.
    constant float3 kLumWeights = float3(0.299, 0.587, 0.114);

    /// Signed distance to a circle of radius `r` centred at the origin.
    /// Negative inside, positive outside.
    inline float sdfCircle(float2 p, float r) {
        return length(p) - r;
    }

    /// Signed distance to a rounded box with half-extents `b` and corner
    /// radius `r`, centred at the origin. Negative inside, positive outside.
    inline float sdfRoundedBox(float2 p, float2 b, float r) {
        float2 q = abs(p) - b + r;
        return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    }

    /// Evaluate the active shape's SDF at a *centred, aspect-corrected* point.
    /// `shape` 0 = circle, 1 = rounded rectangle (passed as a float since
    /// SwiftUI's `Shader.Argument` has no integer case). The shape is
    /// normalised to a nominal half-size of ~0.4 so the default 1.0 `scale`
    /// fills the view comfortably with margin for the rim.
    inline float sdfShape(float2 p, float shape, float cornerRadius) {
        if (shape > 0.5) {
            // Rounded rectangle: slightly landscape half-extents read as a
            // "card / pill" of glass.
            return sdfRoundedBox(p, float2(0.34, 0.26), cornerRadius);
        }
        // Default: circle.
        return sdfCircle(p, 0.4);
    }

    /// Map view UV (0...1) into the centred, aspect-corrected, scaled space the
    /// SDF lives in. Matches the inverse used when undoing the offset later.
    inline float2 toShapeSpace(float2 uv, float2 center, float2 aspect, float scale) {
        return (uv - center) * aspect / scale;
    }

    /// Sample the SDF for a given view UV, returning the distance already
    /// divided by `scale` so thresholds stay scale-independent.
    inline float sampleSDF(float2 uv, float2 center, float2 aspect, float scale,
                           float shape, float cornerRadius) {
        float2 p = toShapeSpace(uv, center, aspect, scale);
        return sdfShape(p, shape, cornerRadius) / scale;
    }
}

// =============================================================================
// MARK: - swGlass
// =============================================================================

/// A glass-refraction `layerEffect` over an analytic SDF region.
///
/// All geometry is computed in a normalised UV space (the view's bounding rect
/// maps to 0...1), aspect-corrected so circles stay round. The layer is the
/// background being refracted.
///
/// - Parameter position: User-space pixel coordinate (auto-injected).
/// - Parameter layer: The SwiftUI layer being sampled — the background.
/// - Parameter boundingRect: The view's bounding rect; `.zw` is its size.
/// - Parameter shape: 0 = circle, 1 = rounded rectangle.
/// - Parameter center: Shape centre in UV space (default 0.5, 0.5).
/// - Parameter scale: Shape scale; >1 shrinks the glass, <1 grows it.
/// - Parameter cornerRadius: Corner radius for the rounded-rectangle shape.
/// - Parameter cutout: When > 0.5, output alpha = the edge mask (glass is
///   isolated on transparency rather than composited over the background).
/// - Parameter refraction: Master strength of the refractive bend.
/// - Parameter edgeSoftness: Width of the soft edge fill band.
/// - Parameter blur: Frosted-glass disk radius in pixels-ish (0 = sharp).
/// - Parameter thickness: Apparent glass thickness; widens the refractive band.
/// - Parameter aberration: Chromatic split strength along the refraction vector.
/// - Parameter innerZoom: Magnifies the refracted content (>1 zooms in).
/// - Parameter lightDir: Pre-computed (cos, sin) of the light angle.
/// - Parameter highlight: Master strength of edge light + specular glint.
/// - Parameter highlightColor: RGB of the highlight / specular.
/// - Parameter highlightSoftness: Specular tightness (higher = broader glint).
/// - Parameter fresnel: Strength of the Fresnel rim.
/// - Parameter fresnelSoftness: Width of the Fresnel rim band.
/// - Parameter fresnelColor: RGB of the Fresnel rim.
/// - Parameter tintColor: RGB the glass tints the refracted content toward.
/// - Parameter tintIntensity: How strongly the tint is mixed in (0 = none).
/// - Parameter tintPreserveLuminosity: When > 0.5, the tint keeps original luma.
/// - Returns: The new pixel color.
[[stitchable]] half4 swGlass(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float shape,
    float2 center,
    float scale,
    float cornerRadius,
    float cutout,
    float refraction,
    float edgeSoftness,
    float blur,
    float thickness,
    float aberration,
    float innerZoom,
    float2 lightDir,
    float highlight,
    float3 highlightColor,
    float highlightSoftness,
    float fresnel,
    float fresnelSoftness,
    float3 fresnelColor,
    float3 tintColor,
    float tintIntensity,
    float tintPreserveLuminosity
) {
    using namespace sw_glass;

    float2 size = boundingRect.zw;
    float2 uv   = position / size;

    // Aspect correction: stretch the shorter axis so the SDF stays isotropic
    // (a circle reads as a circle on any view shape).
    float  ar     = size.x / max(size.y, 1.0);
    float2 aspect = float2(max(ar, 1.0), max(1.0 / ar, 1.0));

    // --- SDF at this pixel ----------------------------------------------------
    float sdf = sampleSDF(uv, center, aspect, scale, shape, cornerRadius);

    // Outside the shape: background passes straight through. With `cutout` the
    // exterior is fully transparent so only the glass remains.
    half4 background = layer.sample(position);
    if (sdf > 0.0) {
        if (cutout > 0.5) return half4(0.0h);
        return background;
    }

    // --- Surface normal via finite-difference SDF gradient --------------------
    // Sampling the SDF a small step away on each axis approximates ∂sdf/∂uv,
    // which points "outward" from the shape — our 2D surface normal.
    const float EPS = 0.01;
    float sdfX = sampleSDF(uv + float2(EPS, 0.0), center, aspect, scale, shape, cornerRadius);
    float sdfY = sampleSDF(uv + float2(0.0, EPS), center, aspect, scale, shape, cornerRadius);
    float gradX = (sdfX - sdf) / EPS;
    float gradY = (sdfY - sdf) / EPS;
    float2 grad = float2(gradX, gradY);

    // --- Edge fill mask (rb1) -------------------------------------------------
    // A 0...1 band that fills in from the silhouette over `sharp` units, used
    // both as the composite cross-fade and to gate the Fresnel rim.
    float sharp = max(edgeSoftness * 0.5, 0.001);
    float rb1   = clamp(-sdf / sharp * 32.0, 0.0, 1.0);

    // --- Thickness → refraction falloff --------------------------------------
    // Near the rim the glass is "thin" and bends hard; toward the centre it is
    // "thick" and calm. depthNorm is 0 at the rim → 1 once we pass the band,
    // and the squared inverse makes the bend concentrate at the edge.
    float thicknessRange = max(thickness * 0.3, 0.001);
    float depthNorm      = clamp(-sdf / thicknessRange, 0.0, 1.0);
    float refrStrength   = (1.0 - depthNorm) * (1.0 - depthNorm);

    // --- Refraction offset ----------------------------------------------------
    // Bend along the (negated) gradient, scaled by master refraction and the
    // edge-weighted strength. The x component is divided by aspect so the bend
    // is symmetric in screen space after the aspect stretch.
    float2 offset = -grad * (refraction * 0.15) * refrStrength;
    offset.x /= aspect.x;

    // Magnify the refracted content about the centre, then add the bend.
    float2 lensUV = center + (uv - center) / max(innerZoom, 0.0001) + offset;

    // --- Frosted blur + chromatic dispersion (single in-shader disk) ----------
    // One golden-angle disk does the frosting; the same disk is reused at three
    // chromatically-shifted centres for dispersion, so heavy taps only happen
    // when actually needed.
    float2 pixelSize = 1.0 / size;
    float  diskRadius = blur * 2.0;                 // in pixels-ish
    bool   doBlur     = diskRadius > 0.001;
    float2 chrOff     = offset * (aberration * 0.06);
    bool   doChroma   = aberration > 0.0001;

    const int   TAPS  = 9;
    const float GOLD  = 2.39996323; // golden angle (radians)

    float3 rgb;
    if (!doBlur && !doChroma) {
        // Cheapest path: a single sharp tap at the bent UV.
        rgb = float3(layer.sample(lensUV * size).rgb);
    } else {
        // Accumulate r / g / b separately so we can offset the red and blue
        // sample centres for chromatic aberration while green stays put.
        float accR = 0.0, accG = 0.0, accB = 0.0;
        float wsum = 0.0;

        // When blur is off we still want a single tap per channel, so collapse
        // the disk to its centre by zeroing the radius.
        float effRadius = doBlur ? diskRadius : 0.0;
        int   effTaps   = doBlur ? TAPS : 1;

        float2 cR = doChroma ? (lensUV + chrOff) : lensUV;
        float2 cG = lensUV;
        float2 cB = doChroma ? (lensUV - chrOff) : lensUV;

        for (int i = 0; i < effTaps; i++) {
            // Golden-angle spiral: uniform-ish disk coverage with few taps.
            float ang = float(i) * GOLD;
            float rad = sqrt(float(i) / float(TAPS));
            float2 diskPt = float2(cos(ang), sin(ang)) * rad;
            float2 d = diskPt * pixelSize * effRadius;

            accR += layer.sample((cR + d) * size).r;
            accG += layer.sample((cG + d) * size).g;
            accB += layer.sample((cB + d) * size).b;
            wsum += 1.0;
        }
        rgb = float3(accR, accG, accB) / max(wsum, 1.0);
    }

    // --- Tint -----------------------------------------------------------------
    // Mix the refracted color toward the tint, optionally rescaling so the
    // tinted result keeps the original luminance (tint only shifts hue/chroma).
    float3 tinted = mix(rgb, tintColor, tintIntensity);
    if (tintPreserveLuminosity > 0.5) {
        float origLum   = dot(rgb,    kLumWeights);
        float tintedLum = dot(tinted, kLumWeights);
        tinted *= origLum / max(tintedLum, 0.0001);
    }
    float3 tintedGlass = tinted;

    // --- Directional edge light (rb2) ----------------------------------------
    // A bright ring just inside the silhouette, modulated by how much the
    // surface faces the light. `lightFacing` is the gradient dotted with the
    // light direction (the rim that points at the light glows).
    float rb2base    = clamp(-sdf / sharp, 0.0, 1.0);
    rb2base          = rb2base * (1.0 - rb2base) * 4.0; // ring: peaks mid-band
    float lightFacing = clamp(dot(normalize(grad + 1e-5), lightDir) * 0.5 + 0.5, 0.0, 1.0);
    float rb2          = rb2base * lightFacing * highlight;

    // --- Specular glint (3D half-vector) -------------------------------------
    // Treat the surface as a 3D normal tilted by the gradient, with the eye
    // straight on. The half-vector between light and eye drives a Blinn-Phong
    // lobe; the exponent comes from highlightSoftness (softer = lower power).
    float3 N      = normalize(float3(gradX, gradY, 2.0));
    float3 L      = normalize(float3(lightDir, 1.0));
    float3 V      = float3(0.0, 0.0, 1.0);
    float3 H      = normalize(L + V);
    float  nDotH  = clamp(dot(N, H), 0.0, 1.0);
    float  specExp = exp2(8.0 - highlightSoftness * 7.0);
    float  specGlint = pow(nDotH, specExp) * highlight * refrStrength;

    // --- Fresnel rim ----------------------------------------------------------
    // A thin bright lip exactly at the silhouette, squared for a fast falloff
    // and gated by the edge fill mask so it never bleeds outside the glass.
    float fw         = max(fresnelSoftness * 0.06, 0.0001);
    float fEdge      = 1.0 - clamp(-sdf / fw, 0.0, 1.0);
    float fresnelRim = fEdge * fEdge * fresnel * rb1;

    // --- Composite ------------------------------------------------------------
    float3 lighting = tintedGlass
                    + highlightColor * rb2
                    + highlightColor * specGlint
                    + fresnelColor   * fresnelRim;

    float transition = smoothstep(0.0, 1.0, rb1);
    float3 outRGB    = mix(float3(background.rgb), lighting, transition);

    half outA = (cutout > 0.5) ? half(transition) : background.a;
    return half4(half3(outRGB), outA);
}
