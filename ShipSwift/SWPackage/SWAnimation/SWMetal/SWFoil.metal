//
//  SWFoil.metal
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI layerEffect that paints a holographic rainbow foil
//  over any source layer. Three crossing sine waves drive a rainbow ramp,
//  a high-power sparkle term adds glints, and a tilt-driven fresnel rim
//  makes the foil flare as the card is rotated.
//
//  Paired with: SWFoil.swift
//  Entry point: `swFoil` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - helpers
// =============================================================================

// Rainbow color generation — phase-shifted sines on the three channels.
static half3 swFoil_generateRainbow(float angle, float intensity) {
    half3 color;
    color.r = sin(angle) * 0.5h + 0.5h;
    color.g = sin(angle + 2.094h) * 0.5h + 0.5h;
    color.b = sin(angle + 4.189h) * 0.5h + 0.5h;
    return color * half(intensity);
}

// =============================================================================
// MARK: - swFoil
// =============================================================================

[[stitchable]] half4 swFoil(
    float2 position,
    SwiftUI::Layer layer,
    float4 boundingRect,
    float2 tilt,
    float time,
    float intensity
) {
    float2 size = boundingRect.zw;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    float2 uv = position / size;

    // Holographic angle based on position and tilt
    float angle = (uv.x + uv.y) * 6.0 + tilt.x * 3.0 + tilt.y * 2.0 + time * 0.5;

    // Wave patterns
    float wave1 = sin(uv.x * 20.0 + time * 2.0 + tilt.x * 5.0) * 0.5 + 0.5;
    float wave2 = sin(uv.y * 15.0 + time * 1.5 + tilt.y * 4.0) * 0.5 + 0.5;
    float wave3 = sin((uv.x + uv.y) * 25.0 + time * 3.0) * 0.5 + 0.5;

    float pattern = (wave1 + wave2 + wave3) / 3.0;

    half3 rainbow = swFoil_generateRainbow(angle + pattern * 2.0, 1.0);

    // Sparkle effect
    float sparkleAngle = (uv.x * 50.0 + uv.y * 50.0 + time * 10.0);
    float sparkle = pow(max(0.0, sin(sparkleAngle)), 20.0) * 0.5;

    // Fresnel-like effect
    float2 center = float2(0.5, 0.5);
    float2 toCenter = uv - center;
    float tiltDot = dot(normalize(toCenter + 0.001), normalize(tilt + 0.001));
    float fresnel = pow(1.0 - abs(tiltDot), 2.0) * 0.3 + 0.7;

    // Combine effects
    half3 holoColor = rainbow * half(pattern * fresnel + sparkle);
    half3 finalColor = mix(originalColor.rgb, originalColor.rgb + holoColor * 0.6h, half(intensity));
    finalColor += rainbow * 0.15h * half(intensity);

    return half4(finalColor, originalColor.a);
}
