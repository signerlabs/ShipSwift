//
//  SWGlassOrb.metal
//  ShipSwift
//
//  Adapted from Inferno's "Warping Loupe" by Paul Hudson
//  https://github.com/twostraws/Inferno
//  Licensed under the MIT License. Copyright (c) 2023 Paul Hudson and other authors.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI `layerEffect` that renders a glass orb by magnifying and
//  refracting the layer it is applied to — in SWGlassOrb that layer is the
//  orb's own color gradient. Inferno's Warping Loupe contributes the core
//  refraction maths: inside a circular region the underlying layer is
//  magnified, and the magnification eases off with distance from the centre
//  to give a spherical (barrel) warp rather than a flat zoom. On top of that
//  base this shader adds the cues that make it read as a *sphere* and not a
//  magnifier: a cool Fresnel rim that brightens toward the silhouette, a
//  soft upper-left specular hot-spot, and an optional faint RGB dispersion
//  at the rim. Outside the orb the layer passes through untouched.
//
//  Paired with: SWGlassOrb.swift
//  Entry point: `swGlassOrb` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - swGlassOrb
// =============================================================================

/// A glass-orb refraction `layerEffect`.
///
/// - Parameter position: User-space coordinate of the current pixel (auto-injected).
/// - Parameter layer: The SwiftUI layer being sampled (auto-injected).
/// - Parameter boundingRect: The view's bounding rect; `.zw` is its size.
/// - Parameter center: Orb centre in user-space pixels (drag-driven from Swift).
/// - Parameter radius: Orb radius in user-space pixels.
/// - Parameter magnification: Peak zoom at the orb centre (e.g. 1.6 = 1.6x).
/// - Parameter refraction: Strength of the spherical (barrel) warp, 0...1.
/// - Parameter edgeHighlight: Strength of the Fresnel rim + specular, 0...1.
/// - Parameter dispersion: Strength of the rim RGB split, 0...1 (0 disables).
/// - Returns: The new pixel color.
[[stitchable]] half4 swGlassOrb(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float2 center,
    float radius,
    float magnification,
    float refraction,
    float edgeHighlight,
    float dispersion
) {
    // Vector from the orb centre to this pixel, in pixels.
    float2 delta = position - center;
    float dist = length(delta);

    // Outside the orb: pass the underlying pixel straight through.
    if (dist >= radius) {
        return layer.sample(position);
    }

    // Normalised radial position, 0 at centre → 1 at the rim.
    float r = dist / max(radius, 1.0);

    // --- Spherical refraction (Inferno Warping Loupe core) -------------------
    // Warping Loupe magnifies most at the centre and eases the zoom back as a
    // function of distance, which bends straight lines into a barrel/fisheye
    // curve. We reproduce that easing here: start fully zoomed (1/magnification
    // shrinks the sampled delta → things look bigger), then add back a portion
    // of the distance so the effect relaxes toward the rim. `refraction`
    // scales how much of that spherical relaxation we apply — at 0 it is a flat
    // loupe zoom, at 1 it is a strong glass-ball bulge.
    float invMag = 1.0 / max(magnification, 1.0);
    // smoothstep gives the eased falloff Warping Loupe applies via distance.
    float ease = smoothstep(0.0, 1.0, r);
    float zoom = invMag + ease * (1.0 - invMag) * refraction;

    // The sampled point: shrink the delta by `zoom` and offset back to centre.
    // (zoom < 1 magnifies; as r → 1, zoom → 1 so the rim lines up with the
    // surrounding, un-zoomed content for a seamless join.)
    float2 sampleDelta = delta * zoom;

    // --- Edge RGB dispersion (optional glass chroma) -------------------------
    // Split the channels along the radial direction, ramped up only near the
    // rim where real glass disperses most. Cheap: three samples at the rim,
    // collapses to one in the interior when dispersion is 0.
    half4 src;
    if (dispersion > 0.0001) {
        float2 dir = (dist > 0.0001) ? (delta / dist) : float2(0.0);
        // Rim-weighted spread, in pixels.
        float spread = dispersion * pow(r, 3.0) * radius * 0.04;
        half r_s = layer.sample(center + sampleDelta + dir * spread).r;
        half4 g_s = layer.sample(center + sampleDelta);
        half b_s = layer.sample(center + sampleDelta - dir * spread).b;
        src = half4(r_s, g_s.g, b_s, g_s.a);
    } else {
        src = layer.sample(center + sampleDelta);
    }

    half3 color = src.rgb;

    // --- Fresnel rim highlight ----------------------------------------------
    // Real spheres brighten sharply at the silhouette (grazing angle). Model
    // that with a steep ramp that is ~0 across the body and spikes near r = 1.
    // A cool tint sells "glass" over "lens".
    float fresnel = pow(r, 6.0);
    half3 rimTint = half3(0.72h, 0.85h, 1.0h); // cool blue-white
    color += rimTint * half(fresnel * edgeHighlight * 0.9);

    // --- Specular hot-spot ---------------------------------------------------
    // A single soft highlight toward the upper-left, the classic studio
    // reflection that makes a circle read as a 3D ball. Positioned at ~35% of
    // the radius up-and-left of centre.
    float2 specCenter = center + float2(-0.35, -0.35) * radius;
    float specDist = length(position - specCenter) / max(radius, 1.0);
    float spec = smoothstep(0.42, 0.0, specDist);   // tight, soft-edged blob
    color += half3(spec * spec) * half(edgeHighlight * 0.55);

    // --- Inner contact shadow -----------------------------------------------
    // A faint darkening just inside the rim grounds the highlight and adds
    // volume (the far side of the glass picks up less light).
    float innerShade = smoothstep(0.55, 1.0, r) * (1.0 - fresnel);
    color *= (1.0h - half(innerShade * edgeHighlight * 0.18));

    // Anti-alias the orb silhouette over ~1px so the rim is crisp, not jagged.
    float aa = 1.0 - smoothstep(radius - 1.0, radius, dist);
    half4 passthrough = layer.sample(position);
    half4 orb = half4(color, src.a);
    return mix(passthrough, orb, half(aa));
}
