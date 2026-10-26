//
//  SWGlitter.metal
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI layerEffect that scatters animated glitter points
//  over any source layer. A hashed grid seeds per-cell sparkles whose
//  phase is nudged by the `tilt` vector, so glints twinkle as the card
//  is rotated.
//
//  Paired with: SWGlitter.swift
//  Entry point: `swGlitter` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - helpers
// =============================================================================

// Rainbow color generation — phase-shifted sines on the three channels.
static half3 swGlitter_generateRainbow(float angle, float intensity) {
    half3 color;
    color.r = sin(angle) * 0.5h + 0.5h;
    color.g = sin(angle + 2.094h) * 0.5h + 0.5h;
    color.b = sin(angle + 4.189h) * 0.5h + 0.5h;
    return color * half(intensity);
}

// =============================================================================
// MARK: - swGlitter
// =============================================================================

[[stitchable]] half4 swGlitter(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float2 tilt,
    float time,
    float density
) {
    float2 size = boundingRect.zw;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    float2 uv = position / size;

    // Grid for glitter points
    float gridSize = density;
    float2 gridUV = fract(uv * gridSize);
    float2 gridID = floor(uv * gridSize);

    // Pseudo-random per grid cell
    float random = fract(sin(dot(gridID, float2(12.9898, 78.233))) * 43758.5453);

    // Sparkle visibility
    float sparklePhase = random * 6.28318 + time * (2.0 + random * 3.0);
    float tiltInfluence = dot(normalize(tilt + 0.001), float2(cos(random * 6.28), sin(random * 6.28)));
    float sparkleIntensity = pow(max(0.0, sin(sparklePhase + tiltInfluence * 3.0)), 8.0);

    // Distance from center of grid cell
    float2 cellCenter = float2(0.5, 0.5);
    float dist = length(gridUV - cellCenter);
    float pointSize = 0.1 + random * 0.1;
    float point = smoothstep(pointSize, 0.0, dist);

    // Sparkle color
    half3 sparkleColor = half3(1.0h, 1.0h, 1.0h);
    float rainbowAngle = random * 6.28 + tilt.x * 2.0 + tilt.y * 2.0;
    sparkleColor += swGlitter_generateRainbow(rainbowAngle, 0.3) * 0.5h;

    half3 finalColor = originalColor.rgb + sparkleColor * half(point * sparkleIntensity * 0.55);

    return half4(finalColor, originalColor.a);
}
