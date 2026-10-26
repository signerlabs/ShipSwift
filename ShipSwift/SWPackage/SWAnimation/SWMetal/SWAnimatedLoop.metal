//
//  SWAnimatedLoop.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effects — `SWAnimatedLoop` family.
//
//  Four hand-tuned styles bundled in one file because they share the same
//  per-line phase ramp / RGB-channel split / additive composite logic;
//  they only differ in the distance metric `d` and the pattern term `m`.
//
//  Entry points:
//    - `swAnimatedLoopShape`   — user-pickable shape (circle / square /
//                                 diamond pip / hexagon / star)
//    - `swAnimatedLoopDiamond` — L1 distance rings + multiplicative pattern
//    - `swAnimatedLoopNeon`    — circle rings + per-channel angular wobble
//    - `swAnimatedLoopWarp`    — stretched-ellipse rings + 1D pattern
//
//  All four take the same 18-parameter signature so the Swift renderer can
//  use a single argument list and dispatch by name. Parameters that don't
//  apply to a given style are touched with `(void)x;` to make the "unused
//  on purpose" decision explicit.
//
//  Paired with: SWAnimatedLoop.swift
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Shape

[[ stitchable ]] half4 swAnimatedLoopShape(float2 position,
                                           half4  color,
                                           float4 boundingRect,
                                           float  time,
                                           float  speed,
                                           float  lineWidth,
                                           float  lines,
                                           float  spacing,
                                           float  channelOffset,
                                           float  patternMod,
                                           float  rotation,
                                           float  scale,
                                           float2 center,
                                           float  shape,
                                           float  petals,
                                           float  angularLobes,
                                           float  angularAmount,
                                           float  angularSpeed,
                                           half4  color1,
                                           half4  color2,
                                           half4  color3,
                                           half4  background) {
    // Angular params unused by this style — see file header.
    (void)angularLobes;
    (void)angularAmount;
    (void)angularSpeed;

    float2 size = boundingRect.zw;
    float2 uv   = (position * 2.0 - size) / min(size.x, size.y);

    uv = uv / max(scale, 0.0001);
    uv -= center;
    float c = cos(rotation);
    float s = sin(rotation);
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float t     = time * speed;
    int   count = max(1, int(lines));

    int   shapeIdx = int(shape);
    float d;
    if (shapeIdx == 1) {
        d = max(abs(uv.x), abs(uv.y));                      // square
    } else if (shapeIdx == 2) {
        d = abs(uv.x) * 1.6 + abs(uv.y) * 0.85;             // diamond pip
    } else if (shapeIdx == 3) {
        float2 q = abs(uv);
        d = max(q.x * 0.866025 + q.y * 0.5, q.y);           // hexagon
    } else if (shapeIdx == 4) {
        float ang = atan2(uv.y, uv.x);
        float r   = length(uv);
        d = r * (1.0 + 0.35 * cos(petals * ang));           // star
    } else {
        d = length(uv);                                     // circle
    }

    float pmm = max(patternMod, 0.0001);
    float m   = fmod(uv.x + uv.y, pmm);

    float3 ch[3] = { float3(color1.rgb), float3(color2.rgb), float3(color3.rgb) };

    float3 col = float3(0.0);
    for (int j = 0; j < 3; j++) {
        float acc = 0.0;
        for (int i = 0; i < count; i++) {
            float f = fract(t - channelOffset * float(j) + 0.01 * float(i)) * spacing - d + m;
            acc += lineWidth * float(i * i) / max(abs(f), 0.00001);
        }
        col += ch[j] * acc;
    }

    float3 bg = float3(background.rgb);
    return half4(half3(bg + col), 1.0);
}

// MARK: - Diamond

[[ stitchable ]] half4 swAnimatedLoopDiamond(float2 position,
                                             half4  color,
                                             float4 boundingRect,
                                             float  time,
                                             float  speed,
                                             float  lineWidth,
                                             float  lines,
                                             float  spacing,
                                             float  channelOffset,
                                             float  patternMod,
                                             float  rotation,
                                             float  scale,
                                             float2 center,
                                             float  shape,
                                             float  petals,
                                             float  angularLobes,
                                             float  angularAmount,
                                             float  angularSpeed,
                                             half4  color1,
                                             half4  color2,
                                             half4  color3,
                                             half4  background) {
    (void)shape;
    (void)petals;
    (void)angularLobes;
    (void)angularAmount;
    (void)angularSpeed;

    float2 size = boundingRect.zw;
    float2 uv   = (position * 2.0 - size) / min(size.x, size.y);

    uv = uv / max(scale, 0.0001);
    uv -= center;
    float c = cos(rotation);
    float s = sin(rotation);
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float t     = time * speed;
    int   count = max(1, int(lines));

    float d   = abs(uv.x) + abs(uv.y);
    float pmm = max(patternMod, 0.0001);
    float m   = fmod(uv.x * uv.y, pmm);

    float3 ch[3] = { float3(color1.rgb), float3(color2.rgb), float3(color3.rgb) };

    float3 col = float3(0.0);
    for (int j = 0; j < 3; j++) {
        float acc = 0.0;
        for (int i = 0; i < count; i++) {
            float f = fract(t - channelOffset * float(j) + 0.012 * float(i)) * spacing - d + m;
            acc += lineWidth * float(i * i) / max(abs(f), 0.00001);
        }
        col += ch[j] * acc;
    }

    float3 bg = float3(background.rgb);
    return half4(half3(bg + col), 1.0);
}

// MARK: - Neon

[[ stitchable ]] half4 swAnimatedLoopNeon(float2 position,
                                          half4  color,
                                          float4 boundingRect,
                                          float  time,
                                          float  speed,
                                          float  lineWidth,
                                          float  lines,
                                          float  spacing,
                                          float  channelOffset,
                                          float  patternMod,
                                          float  rotation,
                                          float  scale,
                                          float2 center,
                                          float  shape,
                                          float  petals,
                                          float  angularLobes,
                                          float  angularAmount,
                                          float  angularSpeed,
                                          half4  color1,
                                          half4  color2,
                                          half4  color3,
                                          half4  background) {
    (void)shape;
    (void)petals;

    float2 size = boundingRect.zw;
    float2 uv   = (position * 2.0 - size) / min(size.x, size.y);

    uv = uv / max(scale, 0.0001);
    uv -= center;
    float c = cos(rotation);
    float s = sin(rotation);
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float t     = time * speed;
    int   count = max(1, int(lines));

    float d   = length(uv);
    float pmm = max(patternMod, 0.0001);
    float m   = fmod(uv.x + uv.y, pmm);
    float ang = atan2(uv.y, uv.x);

    float3 ch[3] = { float3(color1.rgb), float3(color2.rgb), float3(color3.rgb) };

    float3 col = float3(0.0);
    for (int j = 0; j < 3; j++) {
        float angularShift = sin(ang * angularLobes + time * angularSpeed + float(j)) * angularAmount;
        float acc = 0.0;
        for (int i = 0; i < count; i++) {
            float f = fract(t - channelOffset * float(j) + 0.01 * float(i)) * spacing - d + angularShift + m;
            acc += lineWidth * float(i * i) / max(abs(f), 0.00001);
        }
        col += ch[j] * acc;
    }
    // Baked-in cool/warm RGB boost — part of the Neon style identity.
    col *= float3(1.1, 0.8, 1.2);

    float3 bg = float3(background.rgb);
    return half4(half3(bg + col), 1.0);
}

// MARK: - Warp

[[ stitchable ]] half4 swAnimatedLoopWarp(float2 position,
                                          half4  color,
                                          float4 boundingRect,
                                          float  time,
                                          float  speed,
                                          float  lineWidth,
                                          float  lines,
                                          float  spacing,
                                          float  channelOffset,
                                          float  patternMod,
                                          float  rotation,
                                          float  scale,
                                          float2 center,
                                          float  shape,
                                          float  petals,
                                          float  angularLobes,
                                          float  angularAmount,
                                          float  angularSpeed,
                                          half4  color1,
                                          half4  color2,
                                          half4  color3,
                                          half4  background) {
    (void)shape;
    (void)petals;
    (void)angularLobes;
    (void)angularAmount;
    (void)angularSpeed;

    float2 size = boundingRect.zw;
    float2 uv   = (position * 2.0 - size) / min(size.x, size.y);

    uv = uv / max(scale, 0.0001);
    uv -= center;
    float c = cos(rotation);
    float s = sin(rotation);
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float t     = time * speed;
    int   count = max(1, int(lines));

    float d   = length(uv * float2(0.4, 1.0));
    float pmm = max(patternMod, 0.0001);
    float m   = fmod(uv.x, pmm);

    float3 ch[3] = { float3(color1.rgb), float3(color2.rgb), float3(color3.rgb) };

    float3 col = float3(0.0);
    for (int j = 0; j < 3; j++) {
        float acc = 0.0;
        for (int i = 0; i < count; i++) {
            float f = fract(t - channelOffset * float(j) + 0.015 * float(i)) * spacing - d + m;
            acc += lineWidth * float(i * i) / max(abs(f), 0.00001);
        }
        col += ch[j] * acc;
    }

    float3 bg = float3(background.rgb);
    return half4(half3(bg + col), 1.0);
}
