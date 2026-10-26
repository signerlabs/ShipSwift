//
//  SWLiquidChrome.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — animated liquid chrome surface.
//
//  Three sequential value-noise samples are domain-warped against each
//  other to produce a fluid metallic flow. The third sample drives a
//  chrome curve (gamma-corrected, smoothstep-cut for highlights) and a
//  power-curve specular glint. A subtle tint is layered in via the first
//  sample for color depth.
//
//  Paired with: SWLiquidChrome.swift
//  Entry point: `swLiquidChrome` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Cheap 2D scalar hash. Standard fract/dot trick — biased but visually
// fine for value-noise interpolation.
static float swLiquidChromeHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Bilinear value noise with smoothstep interpolation.
static float swLiquidChromeNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = swLiquidChromeHash(i);
    float b = swLiquidChromeHash(i + float2(1.0, 0.0));
    float c = swLiquidChromeHash(i + float2(0.0, 1.0));
    float d = swLiquidChromeHash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

[[ stitchable ]] half4 swLiquidChrome(float2 position,
                                      half4  color,
                                      float4 boundingRect,
                                      float  time,
                                      float  speed,
                                      float  scale,
                                      float  warp,
                                      float  contrast,
                                      float  specPower,
                                      float  specStrength,
                                      float  tintStrength,
                                      half4  shadow,
                                      half4  silver,
                                      half4  highlight,
                                      half4  tint) {
    float2 size = boundingRect.zw;
    // Centered, aspect-corrected coords (-1..1 along the short axis).
    float2 uv = (position * 2.0 - size) / max(min(size.x, size.y), 1.0);

    float t = time * speed;

    // Domain warping: each sample displaces the next by a scaled previous
    // noise value plus a per-axis time shift.
    float2 p  = uv * max(scale, 0.0001);
    float  n1 = swLiquidChromeNoise(p + float2(t, t * 0.6));
    float  n2 = swLiquidChromeNoise(p + n1 * warp + float2(-t * 0.4, t * 0.3));
    float  n3 = swLiquidChromeNoise(p * 1.5 + n2 * warp + float2(t * 0.2, -t * 0.5));

    // Chrome curve: remap to 0..1, then gamma-shape it. Higher contrast
    // exponent → steeper falloff into shadows; lower → flatter mid-tones.
    float chrome = clamp(n3 * 0.5 + 0.5, 0.0, 1.0);
    chrome = pow(chrome, max(contrast, 0.001));

    float3 sh = float3(shadow.rgb);
    float3 sv = float3(silver.rgb);
    float3 hl = float3(highlight.rgb);
    float3 tn = float3(tint.rgb);

    float3 col = mix(sh, sv, chrome);
    col = mix(col, hl, smoothstep(0.8, 0.98, chrome));
    col += tn * smoothstep(0.3, 0.6, n1) * tintStrength;

    // Specular glint — high-power curve on the chrome value picks out crests.
    // The baked-in cool tint (0.6, 0.6, 0.8) is intentional and part of the
    // chrome style identity; it gives glints a slightly blue cast that reads
    // as polished metal even when the four user colors are warm.
    float spec = pow(max(chrome, 0.0), max(specPower, 0.001));
    col += float3(0.6, 0.6, 0.8) * spec * specStrength;

    return half4(half3(col), 1.0);
}
