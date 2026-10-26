//
//  SWInkSmoke.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — domain-warped fbm "ink in water"
//  smoke field.
//
//  Three layers of value-noise fbm form the smoke body: `q` warps `p`,
//  `r2` warps it again with `q` as the offset, and `f` is a final fbm
//  sampled at the double-warped point. Four ink colors are mixed by
//  `f`, `q.x`, and `r2.y`, then a wispy highlight is added where `f`
//  is brightest.
//
//  Paired with: SWInkSmoke.swift
//  Entry point: `swInkSmoke` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float swInkSmokeHash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float swInkSmokeVNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = swInkSmokeHash21(i);
    float b = swInkSmokeHash21(i + float2(1.0, 0.0));
    float c = swInkSmokeHash21(i + float2(0.0, 1.0));
    float d = swInkSmokeHash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 5-octave fractional Brownian motion. Loop bound is static so the compiler
// can fully unroll; do not turn the octave count into a uniform.
static float swInkSmokeFBM(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * swInkSmokeVNoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

[[ stitchable ]] half4 swInkSmoke(float2 position,
                                  half4  color,
                                  float4 boundingRect,
                                  float  time,
                                  float  speed,
                                  float  scale,
                                  float  warp,
                                  float  highlight,
                                  half4  ink1,
                                  half4  ink2,
                                  half4  ink3,
                                  half4  ink4,
                                  half4  glow) {
    float2 size = boundingRect.zw;
    float2 uv   = (position * 2.0 - size) / min(size.x, size.y);

    float  t = time * speed * 0.2;
    float2 p = uv * max(scale, 0.0001);

    // Two-stage domain warp — q warps p, then r2 warps it again with q as
    // the offset. f is the final fbm sampled at the double-warped point.
    float2 q  = float2(swInkSmokeFBM(p + float2(t * 0.4, t * 0.3)),
                       swInkSmokeFBM(p + float2(t * 0.2, -t * 0.4)));
    float2 r2 = float2(swInkSmokeFBM(p + q * warp + float2(1.7, 9.2) + t * 0.15),
                       swInkSmokeFBM(p + q * warp + float2(8.3, 2.8) - t * 0.1));
    float  f  = swInkSmokeFBM(p + r2 * 2.0);

    float3 c1 = float3(ink1.rgb);
    float3 c2 = float3(ink2.rgb);
    float3 c3 = float3(ink3.rgb);
    float3 c4 = float3(ink4.rgb);
    float3 g  = float3(glow.rgb);

    float3 col = mix(c1, c2, clamp(f * 2.0, 0.0, 1.0));
    col        = mix(col, c3, clamp(q.x * 1.5, 0.0, 1.0));
    col        = mix(col, c4, clamp(r2.y * 0.8, 0.0, 1.0));

    // Wispy highlights where the double-warped field peaks.
    float wisp = pow(clamp(f * 1.5, 0.0, 1.0), 3.0);
    col       += g * wisp * highlight;

    return half4(half3(col), 1.0);
}
