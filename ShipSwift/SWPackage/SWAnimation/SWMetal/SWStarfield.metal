//
//  SWStarfield.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — multi-layer twinkling starfield.
//
//  Each layer is a hashed grid: a per-cell scalar hash decides which cells
//  "light up" (`h > 1 - density`), a per-cell 2D hash places the star
//  inside the cell, and a sin-driven term twinkles its brightness. Layers
//  shift downward at different speeds for a parallax effect — back layers
//  are dimmer and finer-grained.
//
//  Paired with: SWStarfield.swift
//  Entry point: `swStarfield` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Cheap per-cell scalar hash. Standard "sin(dot) * 43758" trick — not great
// statistically but cheap and visually fine for a starfield.
static float swStarfieldHash1(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Two independent hashes packed into a vec2 — used to place the star inside
// the cell. Different magic numbers per channel so x and y aren't correlated.
static float2 swStarfieldHash2(float2 p) {
    float a = fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(p, float2(269.5, 183.3))) * 43758.5453);
    return float2(a, b);
}

[[ stitchable ]] half4 swStarfield(float2 position,
                                   half4  color,
                                   float4 boundingRect,
                                   float  time,
                                   float  speed,
                                   float  layers,
                                   float  baseScale,
                                   float  scaleStep,
                                   float  density,
                                   float  starSize,
                                   float  twinkleSpeed,
                                   float  twinkleAmount,
                                   half4  starColor,
                                   half4  background) {
    float2 size = boundingRect.zw;
    float2 uv   = position / max(size, float2(1.0));

    // Cap the layer count so the loop bound is bounded for the compiler.
    int   count  = max(1, min(int(layers), 8));
    float thresh = clamp(1.0 - density, 0.0, 1.0);
    float ssz    = max(starSize, 0.001);
    float amt    = clamp(twinkleAmount, 0.0, 1.0);

    float3 starRGB = float3(starColor.rgb);
    float3 col     = float3(0.0);

    for (int layer = 0; layer < count; layer++) {
        float fl    = float(layer);
        float scale = max(baseScale + fl * scaleStep, 1.0);
        float lspd  = (0.03 + fl * 0.02) * speed;
        float bri   = max(0.0, 1.0 - fl * 0.25);

        float2 st   = uv * scale;
        st.y       += time * lspd * scale;
        float2 cell = floor(st);
        float2 f    = fract(st);

        float h = swStarfieldHash1(cell);
        if (h > thresh) {
            float2 center = swStarfieldHash2(cell);
            float  d      = length(f - center);
            // Re-expressed as (mean = 1 - amt, amplitude = amt) so amt=0
            // gives steady stars and amt=0.3 reproduces the original look.
            float twink = sin(time * twinkleSpeed + h * 100.0) * amt + (1.0 - amt);
            // Inverse smoothstep — bright at d=0, fades to 0 at d=ssz. Using
            // (1 - smoothstep) instead of edge-flipped smoothstep so behavior
            // matches the WGSL preview, where edge0 > edge1 is undefined.
            float falloff = 1.0 - smoothstep(0.0, ssz, d);
            col += starRGB * (falloff * twink * bri);
        }
    }

    float3 bg = float3(background.rgb);
    return half4(half3(bg + col), 1.0);
}
