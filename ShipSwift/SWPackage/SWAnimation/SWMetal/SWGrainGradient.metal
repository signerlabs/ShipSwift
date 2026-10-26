//
//  SWGrainGradient.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — soft tri-color gradient with film grain.
//
//  Two low-frequency value-noise samples drive the blend between three
//  user colors, producing a slow, premium-feeling color field. A per-frame
//  high-frequency hash adds film grain so the surface always reads as
//  "designed" rather than flat — the staple of 2025-era hero backgrounds
//  (Apple Music posters, Spotify hero cards, Linear gradients).
//
//  Paired with: SWGrainGradient.swift
//  Entry point: `swGrainGradient` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float swGrainGradientHash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Bilinear value noise with smoothstep interpolation.
static float swGrainGradientVNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = swGrainGradientHash21(i);
    float b = swGrainGradientHash21(i + float2(1.0, 0.0));
    float c = swGrainGradientHash21(i + float2(0.0, 1.0));
    float d = swGrainGradientHash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

[[ stitchable ]] half4 swGrainGradient(float2 position,
                                       half4  color,
                                       float4 boundingRect,
                                       float  time,
                                       float  speed,
                                       float  scale,
                                       float  grain,
                                       float  contrast,
                                       half4  color1,
                                       half4  color2,
                                       half4  color3) {
    float2 size = boundingRect.zw;
    // Normalized coords (0..1), then scaled for the noise sampler.
    float2 uv = position / max(min(size.x, size.y), 1.0);
    float2 ap = uv * max(scale, 0.0001);

    // Time is slowed by 0.15 — grain gradients are meant to drift, not flow.
    float t = time * speed * 0.15;

    // Two low-frequency samples drive the two blend weights between the
    // three colors. Different offsets / scales decouple them so the field
    // doesn't collapse into a single direction of motion.
    float n1 = swGrainGradientVNoise(ap         + float2( t,         t * 0.6));
    float n2 = swGrainGradientVNoise(ap * 0.7   + float2(-t * 0.4,   t * 0.3) + 17.0);

    // Contrast-shape each weight before blending so the user can compress
    // colors toward one dominant tone or open them up.
    float w1 = clamp(pow(n1, max(contrast, 0.001)), 0.0, 1.0);
    float w2 = clamp(pow(n2, max(contrast, 0.001)), 0.0, 1.0);

    float3 c1 = float3(color1.rgb);
    float3 c2 = float3(color2.rgb);
    float3 c3 = float3(color3.rgb);

    float3 col = mix(c1, c2, w1);
    col        = mix(col, c3, w2);

    // Film grain — high-frequency hash on raw pixel position (independent
    // of `scale`) shifted per-frame so the grain shimmers like actual film.
    // Centered around 0 so it adds equally to highlights and shadows.
    float g = swGrainGradientHash21(position * 0.5 + time * 60.0) - 0.5;
    col    += g * grain;

    return half4(half3(col), 1.0);
}
