//
//  SWDotsSnake.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — `snake` style of the SWDots family.
//  Snake-like dot trails on a flat (non-perspective) dot grid. A flow
//  field defines an angle per dot; brightness peaks where the dot's
//  position aligns with the flow's phase wavefront.
//
//  Paired with: SWDots.swift (style = .snake)
//  Entry point: `swDotsSnake` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Trailing `horizon` / `amplitude` / `depthFade` belong to the unified
// SWDots parameter set; not used by this flat-grid style.
[[ stitchable ]] half4 swDotsSnake(float2 position,
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
    float  pxR       = (1.5 / size.y) * dotSize;
    float  mask      = smoothstep(pxR * 1.4, pxR * 0.6, distToDot);

    float angle = sin(cell.x * 4.0 * patternScale + t * 0.6) * 1.2 +
                  cos(cell.y * 4.0 * patternScale - t * 0.5) * 1.2 +
                  sin((cell.x + cell.y) * 3.0 * patternScale + t * 0.9);
    float2 flow = float2(cos(angle), sin(angle));

    float phase  = dot(cell, flow) * 12.0 * patternScale - t * 4.0;
    float bright = 0.5 + 0.5 * sin(phase);
    bright = pow(bright, 4.0);

    float2 vUV   = (position - 0.5 * size) / size;
    float  vig   = clamp(1.0 - dot(vUV, vUV) * 0.7 * vignette, 0.0, 1.0);
    float  intensity = mask * (0.10 + 1.1 * bright) * vig;

    float3 bg  = float3(background.rgb);
    float3 fg  = float3(tint.rgb) * brightness;
    float3 col = mix(bg, fg, intensity);
    return half4(half3(col), 1.0h);
}
