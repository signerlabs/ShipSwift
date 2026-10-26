//
//  SWGlassLogo.metal
//  ShipSwift
//
//  A stitchable SwiftUI `layerEffect` that turns an opaque silhouette (an SF
//  Symbol such as `apple.logo`) into a sheet of frosted, refractive glass that
//  exists ONLY inside the symbol's shape. Everything outside the silhouette is
//  cut away to full transparency, so the effect drops cleanly onto any dark
//  canvas as a glass-shaped logo.
//
//  Unlike the SDF-based glass in the library, this kernel has no analytic shape
//  to differentiate. The "shape" is whatever silhouette the source layer draws,
//  so the surface normal is recovered directly from the layer's ALPHA channel:
//  a finite-difference gradient of alpha points outward across the antialiased
//  contour and acts as the 2D surface normal. That single idea drives the whole
//  look:
//    - alpha gradient            -> 2D surface normal (refraction direction)
//    - distance-into-the-shape   -> edge-weighted refraction + frost falloff
//    - a small golden-angle disk -> frosted blur of the refracted content
//    - alpha-contour band        -> a cool Fresnel rim hugging the silhouette
//
//  The layer being sampled is the flowing color content placed BEHIND the
//  silhouette mask in Swift, so the glass refracts and frosts that moving light.
//
//  Paired with: SWGlassLogo.swift
//  Entry point: `swGlassLogo` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - Local helpers
// =============================================================================

namespace sw_glass_logo {

    // Rec. 601 luminance weights, used by the luminosity-preserving tint.
    constant float3 kLumWeights = float3(0.299, 0.587, 0.114);

    /// Read the silhouette coverage at a pixel. The Swift side renders the mask
    /// shape into the alpha channel, so alpha is the cleanest coverage signal;
    /// we fall back to red only if a source happens to be fully opaque.
    inline float coverageAt(SwiftUI::Layer layer, float2 pos) {
        half4 s = layer.sample(pos);
        return float(s.a);
    }
}

// =============================================================================
// MARK: - swGlassLogo
// =============================================================================

/// A glass-logo refraction `layerEffect`.
///
/// - Parameter position: User-space pixel coordinate (auto-injected).
/// - Parameter layer: The SwiftUI layer being sampled — the flowing light
///   content, masked to the silhouette shape on the Swift side.
/// - Parameter boundingRect: The view's bounding rect; `.zw` is its size.
/// - Parameter refraction: Master strength of the refractive bend (subtle by
///   default — the look leans on frost + rim rather than heavy warp).
/// - Parameter frost: Frosted-blur disk radius in pixels-ish (0 = sharp).
/// - Parameter thickness: Apparent glass thickness; widens the band over which
///   the rim bends hardest before the centre goes calm.
/// - Parameter edgeSoftness: Width of the soft alpha-contour band the rim and
///   the composite cross-fade ride on.
/// - Parameter fresnel: Strength of the cool Fresnel rim hugging the contour.
/// - Parameter fresnelSoftness: How far in from the contour the rim reaches.
/// - Parameter fresnelColor: RGB of the cool rim light.
/// - Parameter tintColor: RGB the glass tints the refracted light toward.
/// - Parameter tintIntensity: How strongly the tint is mixed in (0 = none).
/// - Returns: The new pixel color, transparent outside the silhouette.
[[stitchable]] half4 swGlassLogo(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float refraction,
    float frost,
    float thickness,
    float edgeSoftness,
    float fresnel,
    float fresnelSoftness,
    float3 fresnelColor,
    float3 tintColor,
    float tintIntensity
) {
    using namespace sw_glass_logo;

    float2 size = boundingRect.zw;

    // Coverage (silhouette alpha) at this pixel. Zero coverage = fully outside
    // the logo shape, so we cut straight to transparent and do no work.
    float cov = coverageAt(layer, position);
    if (cov <= 0.001) {
        return half4(0.0h);
    }

    // --- Surface normal from the ALPHA gradient -------------------------------
    // Sampling coverage one step away on each axis approximates ∂alpha/∂pos.
    // Across the antialiased silhouette edge alpha climbs from 0 (outside) to 1
    // (inside), so the gradient points INWARD; negating it gives an outward
    // surface normal just like an SDF gradient would, but recovered from the
    // rendered shape instead of an analytic formula.
    const float EPS = 1.5; // pixels — wide enough to span the AA edge
    float covX = coverageAt(layer, position + float2(EPS, 0.0));
    float covY = coverageAt(layer, position + float2(0.0, EPS));
    float2 alphaGrad = float2(covX - cov, covY - cov);
    float  gradLen   = length(alphaGrad);
    // Outward normal in screen space (zero in the flat interior where alpha is
    // constant, strong across the contour).
    float2 normal = (gradLen > 1e-4) ? (-alphaGrad / gradLen) : float2(0.0);

    // --- Edge band + thickness falloff ----------------------------------------
    // `edgeBand` is ~1 right on the antialiased contour and ~0 in the solid
    // interior — it is exactly where alpha is transitioning. We build it from
    // the gradient magnitude so it needs no distance field. The rim and the
    // refraction concentrate here; the calm interior is left mostly unbent,
    // matching how real glass bends light hardest at its curved edge.
    float band = saturate(gradLen * (32.0 / max(edgeSoftness, 0.001)));
    // Thickness widens the bend band a touch so thicker glass bends over a
    // broader lip; squared so the bend stays concentrated at the very edge.
    float thick = saturate(band * (0.5 + thickness));
    float bendStrength = thick * thick;

    // --- Refraction offset ----------------------------------------------------
    // Bend the sampled position along the outward normal, strongest at the edge.
    // Kept deliberately small: the brief calls for a subtle warp carried mostly
    // by frost and the cool rim, not a fisheye.
    float2 refrOffset = normal * (refraction * 14.0) * bendStrength;
    float2 lensPos = position + refrOffset;

    // --- Frosted blur (single golden-angle disk) ------------------------------
    // One small disk of taps frosts the refracted light. The disk grows a touch
    // toward the edge (more frost where the glass is "thicker" at the lip) and
    // stays calmer in the centre. All taps are weighted by their own coverage so
    // the blur never drags transparent exterior pixels into the silhouette.
    float diskRadius = frost * (0.6 + 0.8 * band);
    float3 acc = float3(0.0);
    float  wsum = 0.0;

    if (diskRadius > 0.25) {
        const int   TAPS = 9;
        const float GOLD = 2.39996323; // golden angle (radians)
        for (int i = 0; i < TAPS; i++) {
            float ang = float(i) * GOLD;
            float rad = sqrt(float(i) / float(TAPS));
            float2 d  = float2(cos(ang), sin(ang)) * rad * diskRadius;
            half4  s  = layer.sample(lensPos + d);
            float  wc = float(s.a);              // coverage weight: ignore exterior
            acc  += float3(s.rgb) * wc;
            wsum += wc;
        }
    }
    float3 refracted;
    if (wsum > 1e-4) {
        refracted = acc / wsum;
    } else {
        // No frost (or the disk fell entirely outside): single sharp tap.
        refracted = float3(layer.sample(lensPos).rgb);
    }

    // --- Tint -----------------------------------------------------------------
    // Nudge the refracted light toward the glass tint while preserving its
    // luminance, so the tint shifts hue/chroma without dimming the flow.
    float3 tinted = mix(refracted, tintColor, tintIntensity);
    float origLum   = dot(refracted, kLumWeights);
    float tintedLum = dot(tinted,    kLumWeights);
    tinted *= origLum / max(tintedLum, 0.0001);

    // --- Cool Fresnel rim -----------------------------------------------------
    // A thin cool-blue lip riding the alpha contour. `rim` peaks on the edge
    // band and fades into the interior over `fresnelSoftness`, gated by coverage
    // so it never leaks past the silhouette. Squared for a crisp grazing falloff.
    float rimReach = max(fresnelSoftness, 0.05);
    float rim = band * smoothstep(0.0, rimReach, band);
    rim = rim * rim * fresnel;
    float3 lit = tinted + fresnelColor * rim;

    // --- Composite ------------------------------------------------------------
    // Output alpha is the silhouette coverage, so the glass keeps the symbol's
    // exact shape with a soft antialiased edge and a fully transparent exterior.
    return half4(half3(lit * cov), half(cov));
}
