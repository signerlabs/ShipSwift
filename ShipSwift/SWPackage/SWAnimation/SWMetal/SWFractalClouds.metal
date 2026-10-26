//
//  SWFractalClouds.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — drifting fractal clouds.
//
//  Two-pass FBM (5-octave value noise): the first pass perturbs the sample
//  position for the second, producing soft cumulus-like swirls. Sky and
//  cloud colors are mixed by the warped FBM, then a warm tint is added on
//  top of the unwarped FBM for ambient lift.
//
//  Paired with: SWFractalClouds.swift
//  Entry point: `swFractalClouds` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float swFractalCloudsHash(float2 p) {
    p = fract(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

static float swFractalCloudsNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = swFractalCloudsHash(i);
    float b = swFractalCloudsHash(i + float2(1.0, 0.0));
    float c = swFractalCloudsHash(i + float2(0.0, 1.0));
    float d = swFractalCloudsHash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 5-octave fractional Brownian motion. Loop bound is static so the compiler
// can fully unroll; do not turn the octave count into a uniform.
static float swFractalCloudsFBM(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * swFractalCloudsNoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

[[ stitchable ]] half4 swFractalClouds(float2 position,
                                       half4  color,
                                       float4 boundingRect,
                                       float  time,
                                       float  speed,
                                       float  zoom,
                                       float  driftX,
                                       float  driftY,
                                       float  warp,
                                       float  coverage,
                                       half4  skyColor,
                                       half4  cloudColor,
                                       half4  warmTint,
                                       float  warmth) {
    float2 size = boundingRect.zw;
    float2 uv   = position / size;

    float t = time * speed;

    uv *= max(zoom, 0.0001);
    uv += float2(t * driftX, t * driftY);

    float f1 = swFractalCloudsFBM(uv);
    float f2 = swFractalCloudsFBM(uv + f1 * warp + float2(t * 0.02, t * 0.03));

    float3 sky   = float3(skyColor.rgb);
    float3 cloud = float3(cloudColor.rgb);
    float3 tint  = float3(warmTint.rgb);

    float3 col = mix(sky, cloud, clamp(f2 + coverage, 0.0, 1.0));
    col += tint * f1 * warmth;

    return half4(half3(col), 1.0);
}
