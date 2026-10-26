//
//  SWIntenseBling.metal
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI layerEffect — maximum-intensity holographic shader
//  with a dense vertical diamond grid, multi-hue rainbow, three moving
//  light hotspots and layered sparkles. All highlights track the `tilt`
//  vector for an aggressive "secret-rare card" shimmer.
//
//  The two utility helpers below (hash + HSV->RGB) are vendored verbatim
//  from ShaderKit's ShaderUtilities.metal and namespaced with a `swBling_`
//  prefix so every SW Metal file stays self-contained and free of
//  duplicate-symbol collisions across the app's single shader library.
//
//  Paired with: SWIntenseBling.swift
//  Entry point: `swIntenseBling` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - helpers (vendored from ShaderKit ShaderUtilities.metal)
// =============================================================================

/// 2D hash for pseudo-random values.
static float swBling_hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/// Convert HSV to RGB color space.
static half3 swBling_hsv2rgb(half3 c) {
    half4 K = half4(1.0h, 2.0h / 3.0h, 1.0h / 3.0h, 3.0h);
    half3 p = abs(fract(c.xxx + K.xyz) * 6.0h - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0h, 1.0h), c.y);
}

// =============================================================================
// MARK: - swIntenseBling
// =============================================================================

[[stitchable]] half4 swIntenseBling(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float2 tilt,
    float time,
    float intensity
) {
    float2 size = boundingRect.zw;
    float2 uv = position / size;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    // Dense vertical diamond grid
    float diamondWidth = 28.0;
    float diamondHeight = 48.0;

    float2 diamondUV = float2(
        uv.x * diamondWidth,
        uv.y * diamondHeight
    );

    float row = floor(diamondUV.y);
    if (fmod(row, 2.0) == 1.0) {
        diamondUV.x += 0.5;
    }

    float2 diamondCell = floor(diamondUV);
    float2 diamondLocal = fract(diamondUV) - 0.5;
    float diamondDist = abs(diamondLocal.x) * 2.0 + abs(diamondLocal.y);

    float diamondEdge = smoothstep(0.5, 0.25, diamondDist);
    float diamondRim = smoothstep(0.5, 0.4, diamondDist) - smoothstep(0.4, 0.3, diamondDist);

    // Multi-hue rainbow
    float2 tiltOffset = tilt * 4.0;
    float hue1 = fract((diamondCell.x + diamondCell.y) * 0.06 + tiltOffset.x * 0.12);
    float hue2 = fract((diamondCell.x - diamondCell.y) * 0.04 + tiltOffset.y * 0.1);
    float hue = fract((hue1 + hue2) * 0.5 + time * 0.01);

    half3 diamondColor = swBling_hsv2rgb(half3(hue, 0.9h, 1.0h));

    // Secondary color layer
    float hue3 = fract(hue + 0.33);
    half3 diamondColor2 = swBling_hsv2rgb(half3(hue3, 0.7h, 0.9h));

    // Multiple light sources
    float2 light1 = float2(0.5 + tilt.y * 0.9, 0.5 + tilt.x * 0.9);
    float2 light2 = float2(0.5 - tilt.y * 0.6, 0.5 - tilt.x * 0.6);
    float2 light3 = float2(0.5 + tilt.x * 0.5, 0.5 - tilt.y * 0.5);

    float hot1 = pow(smoothstep(0.5, 0.0, length(uv - light1)), 1.8);
    float hot2 = pow(smoothstep(0.4, 0.0, length(uv - light2)), 2.0) * 0.6;
    float hot3 = pow(smoothstep(0.35, 0.0, length(uv - light3)), 2.0) * 0.4;
    float totalHot = hot1 + hot2 + hot3;

    // Intense sparkles
    float sparkleRand = swBling_hash21(diamondCell);
    float sparklePhase = sparkleRand * 6.28 + (tilt.x + tilt.y) * 12.0 + time * 3.0;
    float sparkle = pow(max(0.0, sin(sparklePhase)), 6.0);
    sparkle *= step(0.5, sparkleRand);
    sparkle *= diamondEdge;

    // Extra bright sparkles
    float megaSparkle = pow(max(0.0, sin(sparklePhase * 0.5)), 12.0);
    megaSparkle *= step(0.85, sparkleRand);
    megaSparkle *= diamondEdge;

    // Combine all effects. `hi` scales every holographic overlay so the
    // shader can act as a light surface finish (intensity 0 ≈ source image)
    // up to the full secret-rare blast (intensity 1).
    half hi = half(intensity);

    half holoStrength = half(diamondEdge * (0.7 + totalHot * 0.3)) * hi;
    half3 result = mix(originalColor.rgb, diamondColor, holoStrength);

    result = mix(result, diamondColor2, half(totalHot * diamondEdge * 0.3) * hi);
    result += half(totalHot * diamondEdge * 0.5) * diamondColor * hi;
    result += half(diamondRim * 0.5 * (totalHot + 0.3)) * half3(1.0h, 1.0h, 1.0h) * hi;
    result += half(sparkle * 1.5) * half3(1.0h, 1.0h, 1.0h) * hi;
    result += half(megaSparkle * 2.5) * half3(1.0h, 0.95h, 0.9h) * hi;
    result *= half(1.0 + totalHot * 0.25 * intensity);

    return half4(result, originalColor.a);
}
