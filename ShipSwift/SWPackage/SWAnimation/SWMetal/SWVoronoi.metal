//
//  SWVoronoi.metal
//  ShipSwift
//
//  Stitchable SwiftUI colorEffect — voronoi. Anti-aliased animated
//  Voronoi pattern with smooth, customizable edges; up to 5 cell colors
//  in a step-discretized ramp, plus radial inner glow and explicit gap
//  border between cells.
//
//  The per-cell randomizer (`randomGB`) uses a pure 2-channel hash
//  function so no auxiliary texture binding is needed.
//
//  Paired with: SWVoronoi.swift
//  Entry point: `swVoronoi` — invoked via SwiftUI `.colorEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - helpers
// =============================================================================

// 2-channel hash for the per-cell offset randomizer.
static float2 swV_hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Double-pass Voronoi. First pass finds the closest
// cell center; second pass scans a 5×5 neighbourhood to compute the
// minimum half-plane distance to all neighbour cells — that's the cell
// edge distance.
//
// Returns `(edgeDist, mr.x, mr.y, randomHash)`.
//   - `edgeDist`     : signed-distance to the nearest cell border
//   - `mr.xy`        : vector from current point to closest center
//   - `randomHash`   : the raw 0..1 hash of the closest cell (palette mixer)
static float4 swV_voronoi(float2 x, float time, float distortion) {
    const float TWO_PI = 6.28318530718;

    float2 ip = floor(x);
    float2 fp = fract(x);

    float2 mg = float2(0.0);
    float2 mr = float2(0.0);
    float  md = 8.0;
    float  rndHash = 0.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 g = float2(float(i), float(j));
            float2 o = swV_hash22(ip + g);
            float rawHash = o.x;
            o = 0.5 + distortion * sin(time + TWO_PI * o);
            float2 r = g + o - fp;
            float d = dot(r, r);

            if (d < md) {
                md = d;
                mr = r;
                mg = g;
                rndHash = rawHash;
            }
        }
    }

    md = 8.0;
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            float2 g = mg + float2(float(i), float(j));
            float2 o = swV_hash22(ip + g);
            o = 0.5 + distortion * sin(time + TWO_PI * o);
            float2 r = g + o - fp;
            if (dot(mr - r, mr - r) > 0.00001) {
                md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
            }
        }
    }

    return float4(md, mr, rndHash);
}

// =============================================================================
// MARK: - swVoronoi
// =============================================================================

[[ stitchable ]] half4 swVoronoi(float2 position,
                                 half4  inColor,
                                 float4 boundingRect,
                                 float  time,
                                 float  speed,
                                 float  scale,         // 0.3..5  pattern zoom + AA
                                 float  distortion,    // 0..0.5  cell-center sin distortion
                                 float  gap,           // 0..0.1  border width
                                 float  glow,          // 0..1    radial inner shadow strength
                                 float  stepsPerColor, // 1..3    palette quantization
                                 float  colorsCount,
                                 half4  c1, half4 c2, half4 c3, half4 c4, half4 c5,
                                 half4  colorGap,
                                 half4  colorGlow,
                                 half4  colorBack) {
    float2 sz = boundingRect.zw;
    float  minDim = max(min(sz.x, sz.y), 1.0);
    float2 uv = (position - 0.5 * sz) / minDim;
    uv *= max(scale, 1e-4);

    float t = time * speed;
    float4 v = swV_voronoi(uv, t, saturate(distortion));

    // Palette mixer — two-line idiom where the first assignment
    // is overwritten; preserved for parity.
    float shape = saturate(v.w);
    int countI = clamp(int(colorsCount + 0.5), 1, 5);
    float countF = float(countI);

    float mixerA = shape * (countF - 1.0);
    (void)mixerA;
    float mixer = (shape - 0.5 / countF) * countF;
    float steps = max(1.0, stepsPerColor);

    half4 colors[5] = { c1, c2, c3, c4, c5 };

    half4 gradient = colors[0];
    gradient = half4(half3(gradient.rgb) * gradient.a, gradient.a);
    for (int i = 1; i < 5; i++) {
        if (i >= countI) break;
        float localT = clamp(mixer - float(i - 1), 0.0, 1.0);
        localT = round(localT * steps) / steps;
        half4 cc = colors[i];
        cc = half4(half3(cc.rgb) * cc.a, cc.a);
        gradient = mix(gradient, cc, half(localT));
    }

    // Wrap-around mix for mixer outside [0, count-1].
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

    float3 cellColor = float3(gradient.rgb);
    float cellOpacity = float(gradient.a);

    // Radial inner glow shadow — uses `mr` (vector to cell center).
    float glows = length(v.yz * saturate(glow));
    glows = pow(glows, 1.5);
    float3 glowRGB = float3(colorGlow.rgb) * float(colorGlow.a);
    float3 col = mix(cellColor, glowRGB, float(colorGlow.a) * glows);
    float opacity = cellOpacity + float(colorGlow.a) * glows;

    // Cell border (gap) — AA width scales with viewport scale.
    float edge = v.x;
    float smoothEdge = 0.02 / (2.0 * max(scale, 1e-4)) * (1.0 + 0.5 * saturate(gap));
    edge = smoothstep(saturate(gap) - smoothEdge, saturate(gap) + smoothEdge, edge);

    float3 gapRGB = float3(colorGap.rgb) * float(colorGap.a);
    col = mix(gapRGB, col, edge);
    opacity = mix(float(colorGap.a), opacity, edge);

    // Composite over background.
    float3 backRGB = float3(colorBack.rgb) * float(colorBack.a);
    col = col + backRGB * (1.0 - saturate(opacity));

    return half4(half3(col), 1.0);
}
