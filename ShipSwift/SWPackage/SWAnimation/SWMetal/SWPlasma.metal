//
//  SWPlasma.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effects — `SWPlasma` family.
//
//  Five plasma styles bundled in one file because they share the same
//  hash / value-noise / FBM / 5-stop palette helpers (with only minor
//  octave-count differences). Unlike `SWDots`, where each style's shader
//  body diverges substantially and warrants its own file, the plasma
//  shaders only differ in their final color mixing step — keeping them
//  in one TU lets the helpers be defined exactly once.
//
//  Entry points:
//    - `swPlasmaSolar`     — stacked sins + 3-octave fbm, warm 5-stop palette
//    - `swPlasmaPrism`     — rotating-direction sin field, RGB split on X
//    - `swPlasmaSpectrum`  — like Prism but vertical bias, RGB split on Y
//    - `swPlasmaEmber`     — radial term + gamma boost + high-power hotspots
//    - `swPlasmaLilac`     — slow phase + global breath envelope
//
//  Paired with: SWPlasma.swift
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Shared helpers

static float swPlasmaHash(float2 p) {
    p = float2(dot(p, float2(91.31, 47.79)),
               dot(p, float2(31.07, 73.13)));
    return fract(sin(p.x + p.y) * 19357.713);
}

static float swPlasmaVNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = swPlasmaHash(i);
    float b = swPlasmaHash(i + float2(1.0, 0.0));
    float c = swPlasmaHash(i + float2(0.0, 1.0));
    float d = swPlasmaHash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 2-octave FBM (Prism only).
static float swPlasmaFBM2(float2 p) {
    float v = swPlasmaVNoise(p) * 0.6;
    v += swPlasmaVNoise(p * 2.0) * 0.4;
    return v - 0.5;
}

// 3-octave FBM (everyone else).
static float swPlasmaFBM3(float2 p) {
    float v = swPlasmaVNoise(p) * 0.5;
    v += swPlasmaVNoise(p * 2.0) * 0.3;
    v += swPlasmaVNoise(p * 4.0) * 0.2;
    return v - 0.5;
}

// 5-stop palette mixer, smoothstep-interpolated between each adjacent pair.
static float3 swPlasmaPal5(float t,
                           float3 c1, float3 c2, float3 c3, float3 c4, float3 c5) {
    t = clamp(t, 0.0, 1.0);
    if (t < 0.25) return mix(c1, c2, smoothstep(0.0,  0.25, t));
    if (t < 0.5)  return mix(c2, c3, smoothstep(0.25, 0.5,  t));
    if (t < 0.75) return mix(c3, c4, smoothstep(0.5,  0.75, t));
    return mix(c4, c5, smoothstep(0.75, 1.0, t));
}

// MARK: - Solar

[[ stitchable ]] half4 swPlasmaSolar(float2 position,
                                     half4  color,
                                     float4 boundingRect,
                                     float  time,
                                     half4  c1,
                                     half4  c2,
                                     half4  c3,
                                     half4  c4,
                                     half4  c5,
                                     float  scale,
                                     float  intensity,
                                     float  distortion) {
    float2 size   = boundingRect.zw;
    float2 uv     = position / size;
    float  aspect = size.x / size.y;
    float2 p      = uv - 0.5;
    p.x *= aspect;
    p   *= scale;

    float v = 0.0;
    v += sin(p.x * 2.1 + time * 0.7);
    v += sin(p.y * 2.5 + time * 0.9);
    v += sin((p.x + p.y) * 1.4 + time * 0.5);
    v += swPlasmaFBM3(p * 2.0 + time * 0.18) * distortion * 2.0;
    v  = (v + 4.0) * 0.125;
    v  = clamp(v * intensity, 0.0, 1.0);

    float3 col = swPlasmaPal5(v,
                              float3(c1.rgb), float3(c2.rgb),
                              float3(c3.rgb), float3(c4.rgb), float3(c5.rgb));
    col += pow(v, 4.0) * 0.4;
    return half4(half3(col), 1.0h);
}

// MARK: - Prism

[[ stitchable ]] half4 swPlasmaPrism(float2 position,
                                     half4  color,
                                     float4 boundingRect,
                                     float  time,
                                     half4  c1,
                                     half4  c2,
                                     half4  c3,
                                     half4  c4,
                                     half4  c5,
                                     float  scale,
                                     float  intensity,
                                     float  distortion) {
    float2 size   = boundingRect.zw;
    float2 uv     = position / size;
    float  aspect = size.x / size.y;
    float2 p      = uv - 0.5;
    p.x *= aspect;
    p   *= scale;

    float a  = time * 0.3;
    float2 d = float2(cos(a), sin(a));

    // Inlined field — Prism-specific factor (3.0) and FBM2.
    float v1 = sin(dot(p + float2( 0.025, 0.0), d) * 3.0 + swPlasmaFBM2((p + float2( 0.025, 0.0)) * 1.5) * distortion * 3.0 + time * 0.4);
    float v2 = sin(dot(p,                       d) * 3.0 + swPlasmaFBM2( p                       * 1.5) * distortion * 3.0 + time * 0.4);
    float v3 = sin(dot(p + float2(-0.025, 0.0), d) * 3.0 + swPlasmaFBM2((p + float2(-0.025, 0.0)) * 1.5) * distortion * 3.0 + time * 0.4);

    float3 cc1 = float3(c1.rgb), cc2 = float3(c2.rgb), cc3 = float3(c3.rgb),
           cc4 = float3(c4.rgb), cc5 = float3(c5.rgb);
    float3 ca = swPlasmaPal5(v1 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 cb = swPlasmaPal5(v2 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 cc = swPlasmaPal5(v3 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 col = float3(ca.r, cb.g, cc.b) * intensity;
    return half4(half3(clamp(col, 0.0, 1.5)), 1.0h);
}

// MARK: - Spectrum

[[ stitchable ]] half4 swPlasmaSpectrum(float2 position,
                                        half4  color,
                                        float4 boundingRect,
                                        float  time,
                                        half4  c1,
                                        half4  c2,
                                        half4  c3,
                                        half4  c4,
                                        half4  c5,
                                        float  scale,
                                        float  intensity,
                                        float  distortion) {
    float2 size   = boundingRect.zw;
    float2 uv     = position / size;
    float  aspect = size.x / size.y;
    float2 p      = uv - 0.5;
    p.x *= aspect;
    p   *= scale;

    float a  = time * 0.22 + 1.57;          // ~90° biases d toward vertical
    float2 d = float2(cos(a), sin(a));

    // Inlined field — Spectrum-specific factor (2.4) and FBM3 with time-shift.
    float v1 = sin(dot(p + float2(0.0,  0.045), d) * 2.4 + swPlasmaFBM3((p + float2(0.0,  0.045)) * 1.3 + time * 0.07) * distortion * 4.0 + time * 0.45);
    float v2 = sin(dot(p,                       d) * 2.4 + swPlasmaFBM3( p                       * 1.3 + time * 0.07) * distortion * 4.0 + time * 0.45);
    float v3 = sin(dot(p + float2(0.0, -0.045), d) * 2.4 + swPlasmaFBM3((p + float2(0.0, -0.045)) * 1.3 + time * 0.07) * distortion * 4.0 + time * 0.45);

    float3 cc1 = float3(c1.rgb), cc2 = float3(c2.rgb), cc3 = float3(c3.rgb),
           cc4 = float3(c4.rgb), cc5 = float3(c5.rgb);
    float3 ca = swPlasmaPal5(v1 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 cb = swPlasmaPal5(v2 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 cc = swPlasmaPal5(v3 * 0.5 + 0.5, cc1, cc2, cc3, cc4, cc5);
    float3 col = float3(ca.r, cb.g, cc.b) * intensity * 1.15;
    return half4(half3(clamp(col, 0.0, 1.6)), 1.0h);
}

// MARK: - Ember

[[ stitchable ]] half4 swPlasmaEmber(float2 position,
                                     half4  color,
                                     float4 boundingRect,
                                     float  time,
                                     half4  c1,
                                     half4  c2,
                                     half4  c3,
                                     half4  c4,
                                     half4  c5,
                                     float  scale,
                                     float  intensity,
                                     float  distortion) {
    float2 size   = boundingRect.zw;
    float2 uv     = position / size;
    float  aspect = size.x / size.y;
    float2 p      = uv - 0.5;
    p.x *= aspect;
    p   *= scale * 1.3;                     // tighter pre-scale for ember detail

    float v = 0.0;
    v += sin(p.x * 2.5 + time * 0.6);
    v += sin(p.y * 3.0 + time * 0.8);
    v += sin(length(p) * 2.0 - time * 0.5);
    v += swPlasmaFBM3(p * 2.0 + time * 0.18) * distortion * 3.0;
    v  = (v + 4.0) * 0.125;
    v  = pow(clamp(v, 0.0, 1.0), 1.6) * intensity;

    float3 col = swPlasmaPal5(v,
                              float3(c1.rgb), float3(c2.rgb),
                              float3(c3.rgb), float3(c4.rgb), float3(c5.rgb));
    col += pow(v, 6.0) * 0.55;
    return half4(half3(col), 1.0h);
}

// MARK: - Lilac

[[ stitchable ]] half4 swPlasmaLilac(float2 position,
                                     half4  color,
                                     float4 boundingRect,
                                     float  time,
                                     half4  c1,
                                     half4  c2,
                                     half4  c3,
                                     half4  c4,
                                     half4  c5,
                                     float  scale,
                                     float  intensity,
                                     float  distortion) {
    float2 size   = boundingRect.zw;
    float2 uv     = position / size;
    float  aspect = size.x / size.y;
    float2 p      = uv - 0.5;
    p.x *= aspect;
    p   *= scale;

    float t      = time * 0.7;
    float breath = 0.5 + 0.5 * sin(time * 0.5);

    float v = 0.0;
    v += sin(p.x * 1.8 + t);
    v += sin(p.y * 2.2 + t * 1.1);
    v += sin((p.x + p.y) * 1.0 + t * 0.8);
    v += swPlasmaFBM3(p * 1.5 + t * 0.15) * distortion * 2.0;
    v  = (v + 3.5) * 0.143;
    v  = clamp(v * intensity * (0.7 + 0.6 * breath), 0.0, 1.0);

    float3 col = swPlasmaPal5(v,
                              float3(c1.rgb), float3(c2.rgb),
                              float3(c3.rgb), float3(c4.rgb), float3(c5.rgb));
    col += pow(v, 4.0) * 0.35 * breath;
    return half4(half3(col), 1.0h);
}
