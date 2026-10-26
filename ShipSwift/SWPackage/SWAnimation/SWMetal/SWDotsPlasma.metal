//
//  SWDotsPlasma.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — `plasma` style of the SWDots family.
//  Plasma-style sin-stack lighting a flat (non-perspective) dot grid. Each
//  dot reads the plasma intensity at its cell center and tones up accordingly.
//
//  Paired with: SWDots.swift (style = .plasma)
//  Entry point: `swDotsPlasma` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Trailing `horizon` / `amplitude` / `depthFade` belong to the unified
// SWDots parameter set; not used by this flat-grid style.
[[ stitchable ]] half4 swDotsPlasma(float2 position,
                                    half4  color,
                                    float4 boundingRect,
                                    float  time,
                                    float  speed,
                                    float  brightness,
                                    half4  tint,
                                    half4  background,
                                    float  dotSize,
                                    float  gridDensity,
                                    float  patternScale,
                                    float  vignette,
                                    float  horizon,
                                    float  amplitude,
                                    float  depthFade) {
    (void)horizon;
    (void)amplitude;
    (void)depthFade;

    float2 size = boundingRect.zw;
    float2 uv   = (position - 0.5 * size) / size.y;
    float  t    = time * speed;

    float  grid      = 0.018 / max(gridDensity, 0.01);
    float2 cell      = round(uv / grid) * grid;
    float  distToDot = length(uv - cell);
    float  pxR       = (1.6 / size.y) * dotSize;
    float  mask      = smoothstep(pxR * 1.4, pxR * 0.6, distToDot);

    float v = sin(cell.x * 8.0 * patternScale + t * 1.3) +
              sin(cell.y * 8.0 * patternScale + t * 1.1) +
              sin((cell.x + cell.y) * 6.0 * patternScale + t * 1.5) +
              sin(length(cell) * 10.0 * patternScale - t * 1.8);
    v = v * 0.25;
    float bright = clamp(0.5 + 0.5 * v, 0.0, 1.0);
    bright = pow(bright, 2.5);

    float2 vUV  = (position - 0.5 * size) / size;
    float  vig  = clamp(1.0 - dot(vUV, vUV) * 0.9 * vignette, 0.0, 1.0);
    float  intensity = mask * bright * vig;

    float3 bg  = float3(background.rgb);
    float3 fg  = float3(tint.rgb) * brightness;
    float3 col = mix(bg, fg, intensity);
    return half4(half3(col), 1.0h);
}
