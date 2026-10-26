//
//  SWDotsFlow.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — `flow` style of the SWDots family.
//  Curl-like flow field on a flat (non-perspective) dot grid. Each dot's
//  brightness pulses along wavefronts orthogonal to the flow direction.
//
//  Paired with: SWDots.swift (style = .flow)
//  Entry point: `swDotsFlow` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Signature mirrors SWDotsWavy.metal so that `SWDotsRenderer` can call every
// style with the same argument list. The trailing `horizon` / `amplitude` /
// `depthFade` belong to the unified parameter set but are not consumed by
// this flat-grid style; they are touched with `(void)x;` to make the
// "unused on purpose" decision explicit.
[[ stitchable ]] half4 swDotsFlow(float2 position,
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

    float  grid       = 0.020 / max(gridDensity, 0.01);
    float2 cell       = round(uv / grid) * grid;
    float  distToDot  = length(uv - cell);
    float  pxR        = (1.4 / size.y) * dotSize;
    float  mask       = smoothstep(pxR * 1.4, pxR * 0.6, distToDot);

    float n = sin(cell.x * 3.0 * patternScale + t * 0.4) *
              cos(cell.y * 3.0 * patternScale - t * 0.35) +
              0.5 * sin(cell.x * 7.0 * patternScale - t * 0.6) *
                    sin(cell.y * 7.0 * patternScale + t * 0.55);

    float fronts = sin(n * 6.0 + length(cell) * 8.0 * patternScale - t * 1.8);
    float bright = pow(max(fronts, 0.0), 1.8);

    float2 vUV   = (position - 0.5 * size) / size;
    float  vig   = clamp(1.0 - dot(vUV, vUV) * 0.85 * vignette, 0.0, 1.0);
    float  intensity = mask * (0.10 + 1.0 * bright) * vig;

    float3 bg  = float3(background.rgb);
    float3 fg  = float3(tint.rgb) * brightness;
    float3 col = mix(bg, fg, intensity);
    return half4(half3(col), 1.0h);
}
