//
//  SWChromaticGlass.metal
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI layerEffect — a subtle chromatic-aberration "glass"
//  pass. The red and blue channels are sampled at opposing offsets that
//  grow toward the edges and follow the `tilt` vector, plus a soft centre
//  glow, for a premium glass-over-card feel.
//
//  Extracted from ShaderKit's GlassShaders.metal `chromaticGlass` function.
//
//  Paired with: SWChromaticGlass.swift
//  Entry point: `swChromaticGlass` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - swChromaticGlass
// =============================================================================

[[stitchable]] half4 swChromaticGlass(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float2 tilt,
    float time,
    float intensity,
    float separation   // How much RGB channels separate (0.0 - 1.0)
) {
    float2 size = boundingRect.zw;
    float2 uv = position / size;

    // Chromatic offset based on tilt and position
    // Stronger at edges, follows tilt direction
    float2 center = float2(0.5, 0.5);
    float2 fromCenter = uv - center;
    float edgeFactor = length(fromCenter) * 2.0; // 0 at center, 1 at corners
    edgeFactor = pow(edgeFactor, 1.5); // Non-linear falloff

    // Offset direction influenced by tilt
    float2 offsetDir = normalize(fromCenter + tilt * 0.3 + 0.001);
    // Keep a baseline split even at the centre (the 0.15 floor) so the RGB
    // fringing reads clearly across the whole photo, then ramp up at edges.
    float offsetAmount = separation * (edgeFactor * 0.85 + 0.15) * 14.0; // pixels

    // Sample each channel at slightly different positions
    float2 redOffset = offsetDir * offsetAmount;
    float2 blueOffset = -offsetDir * offsetAmount;

    half4 redSample = layer.sample(position + redOffset);
    half4 greenSample = layer.sample(position);
    half4 blueSample = layer.sample(position + blueOffset);

    half4 result;
    half h_intensity = half(intensity);
    result.r = mix(greenSample.r, redSample.r, h_intensity);
    result.g = greenSample.g;
    result.b = mix(greenSample.b, blueSample.b, h_intensity);
    result.a = greenSample.a;

    // Add subtle brightness boost at center
    float centerGlow = smoothstep(0.7, 0.0, length(fromCenter)) * 0.03 * intensity;
    result.rgb += centerGlow;

    return result;
}
