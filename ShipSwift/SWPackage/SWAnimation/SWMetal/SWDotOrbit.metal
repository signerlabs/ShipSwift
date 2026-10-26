//
//  SWDotOrbit.metal
//  ShipSwift
//
//  Stitchable SwiftUI colorEffect that renders animated multi-color dots,
//  each orbiting around its own Voronoi-cell center, mapped onto a 1–10
//  color step-discretized gradient.
//
//  The per-cell randomizers (`randomR` / `randomGB`) use pure hash
//  functions so no auxiliary texture has to be bound through SwiftUI's
//  `ShaderLibrary`.
//
//  Paired with: SWDotOrbit.swift
//  Entry point: `swDotOrbit` — invoked via SwiftUI `.colorEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - hash helpers (avoid binding an auxiliary noise texture)
// =============================================================================

// Single-channel hash for the orbit-rotation seed (`randomR`).
static float swDO_hash11(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2-channel hash for the orbit-phase + palette mixer (`randomGB`).
static float2 swDO_hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// 2D rotation by `theta` radians.
static float2 swDO_rotate(float2 uv, float th) {
    float c = cos(th), s = sin(th);
    return float2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
}

// voronoiShape — 3×3 neighbour scan to find the closest orbiting
// cell-center. Returns `(minDist, randomizer.x, randomizer.y)`.
static float3 swDO_voronoi(float2 uv, float time, float spreading) {
    const float TWO_PI = 6.28318530718;
    float2 iuv = floor(uv);
    float2 fuv = fract(uv);

    float s = 0.25 * saturate(spreading);

    float minDist = 1.0;
    float2 randomizer = float2(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 tileOffset = float2(float(x), float(y));
            float2 rnd = swDO_hash22(iuv + tileOffset);
            float2 center = float2(0.5 + 1e-4);
            center += s * cos(time + TWO_PI * rnd);
            center -= 0.5;
            center = swDO_rotate(center,
                                 swDO_hash11(float2(rnd.x, rnd.y)) + 0.1 * time);
            center += 0.5;
            float d = length(tileOffset + center - fuv);
            if (d < minDist) {
                minDist = d;
                randomizer = rnd;
            }
        }
    }
    return float3(minDist, randomizer);
}

// =============================================================================
// MARK: - swDotOrbit
// =============================================================================

[[ stitchable ]] half4 swDotOrbit(float2 position,
                                  half4  inColor,
                                  float4 boundingRect,
                                  float  time,
                                  float  speed,
                                  float  scale,         // 0.1..5, default 1.5
                                  float  size,          // 0..1 dot radius
                                  float  sizeRange,     // 0..1 random size variation
                                  float  spreading,     // 0..1 orbit radius
                                  float  stepsPerColor, // 1..4 palette quantization
                                  float  colorsCount,
                                  half4  c1, half4 c2, half4 c3, half4 c4, half4 c5,
                                  half4  c6, half4 c7, half4 c8, half4 c9, half4 c10,
                                  half4  colorBack) {
    float2 sz = boundingRect.zw;
    float minDim = max(min(sz.x, sz.y), 1.0);
    float2 uv = (position - 0.5 * sz) / minDim;
    uv *= max(scale, 1e-4);

    const float firstFrameOffset = -10.0;
    float t = time * speed + firstFrameOffset;

    float3 voro = swDO_voronoi(uv, t, spreading) + 1e-4;

    float radius = 0.25 * saturate(size) - 0.5 * saturate(sizeRange) * voro.z;
    float dist = voro.x;
    float edgeWidth = fwidth(dist);
    float dots = 1.0 - smoothstep(radius - edgeWidth, radius + edgeWidth, dist);

    float shape = voro.y;
    int countI = clamp(int(colorsCount + 0.5), 1, 10);
    float countF = float(countI);
    float steps = max(1.0, stepsPerColor);

    // Two-step mixer — the second assignment is the one that actually
    // drives the gradient (the first is unused; kept for clarity).
    float mixerA = shape * (countF - 1.0);
    (void)mixerA;
    float mixer = (shape - 0.5 / countF) * countF;

    half4 colors[10] = { c1, c2, c3, c4, c5, c6, c7, c8, c9, c10 };

    half4 gradient = colors[0];
    half3 g_rgb = half3(gradient.rgb) * gradient.a;
    gradient = half4(g_rgb, gradient.a);

    for (int i = 1; i < 10; i++) {
        if (i >= countI) break;
        float localT = clamp(mixer - float(i - 1), 0.0, 1.0);
        localT = round(localT * steps) / steps;
        half4 cc = colors[i];
        cc = half4(half3(cc.rgb) * cc.a, cc.a);
        gradient = mix(gradient, cc, half(localT));
    }

    // Wrap-around mix — handle the edge case where mixer is outside
    // [0, count-1] by interpolating between last and first.
    if (mixer < 0.0 || mixer > (countF - 1.0)) {
        float localT = mixer + 1.0;
        if (mixer > (countF - 1.0)) {
            localT = mixer - (countF - 1.0);
        }
        localT = round(localT * steps) / steps;
        half4 cFst = colors[0];
        cFst = half4(half3(cFst.rgb) * cFst.a, cFst.a);
        half4 cLast = colors[countI - 1];
        cLast = half4(half3(cLast.rgb) * cLast.a, cLast.a);
        gradient = mix(cLast, cFst, half(localT));
    }

    float3 col = float3(gradient.rgb) * dots;
    float opacity = float(gradient.a) * dots;

    float3 bgRGB = float3(colorBack.rgb) * float(colorBack.a);
    col = col + bgRGB * (1.0 - opacity);

    return half4(half3(col), 1.0);
}
