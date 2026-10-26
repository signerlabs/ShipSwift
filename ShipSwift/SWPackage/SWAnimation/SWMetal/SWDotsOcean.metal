//
//  SWDotsOcean.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect — `ocean` style of the SWDots family.
//  Big rolling ocean swells with longer wavelengths than `wavy`. The dots
//  themselves are biased with a baked-in cool-water tint so the field
//  reads as "sea" even with neutral user tints.
//
//  Paired with: SWDots.swift (style = .ocean)
//  Entry point: `swDotsOcean` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float swDotsOceanHeight(float x, float z, float t,
                               float amplitude, float patternScale) {
    float base = sin(x * 1.2 * patternScale + t * 0.55) * 0.55 +
                 sin(z * 0.9 * patternScale + t * 0.45) * 0.50 +
                 sin((x * 0.5 + z * 0.7) * patternScale + t * 0.70) * 0.40 +
                 sin((x * 1.5 - z * 0.6) * patternScale + t * 0.35) * 0.20;
    base *= 0.20;
    float damp = 1.0 - smoothstep(3.5, 9.0, z) * 0.85;
    return base * damp * amplitude;
}

[[ stitchable ]] half4 swDotsOcean(float2 position,
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
    float2 size = boundingRect.zw;
    float2 uv   = (position - 0.5 * size) / size.y;
    float  t    = time * speed;

    float yFromHorizon = uv.y - horizon;
    if (yFromHorizon < 0.002) {
        return half4(half3(background.rgb), 1.0h);
    }

    // Wave-aware Z sweep: a cell at depth Z with displacement Y projects to
    // screen-Y = (1 - Y) / Z, so for the current pixel the contributing cells
    // span Z in [(1 - yampBound), (1 + yampBound)] / yFromHorizon. yampBound
    // tracks the peak |Y| at the current amplitude (0.33 = ocean's worst-case
    // displacement at amplitude=1). Replaces a fixed ±dj window that dropped
    // cells (black holes) once gridDensity or amplitude pushed displacement
    // past the hardcoded search radius.
    float gridSize = 0.034 / max(gridDensity, 0.01);
    const float cellZmax = 9.1;
    float jMaxAbsolute = cellZmax / gridSize;

    float Z0        = 1.0 / yFromHorizon;
    float dampEst   = 1.0 - smoothstep(3.5, 9.0, Z0 * 0.85) * 0.85;
    float yampBound = max(0.33 * dampEst * amplitude, 0.03);
    float Zlo = max(0.05, (1.0 - yampBound) / yFromHorizon);
    float Zhi = (1.0 + yampBound) / yFromHorizon;
    int jMin = max(1, int(floor(Zlo / gridSize)));
    int jMax = min(int(jMaxAbsolute), int(ceil(Zhi / gridSize)));

    half3 accum = half3(0.0);
    float halfSizeX = 0.5 * size.x;
    float halfSizeY = 0.5 * size.y;
    for (int j = jMin; j <= jMax; j++) {
        float jf    = float(j);
        float cellZ = jf * gridSize;

        float rawR             = 4.4 / (1.0 + cellZ * 1.10);
        float pxR              = max(rawR, 0.85) * dotSize;
        float horizCullThresh  = pxR * 4.0 + 2.0;
        float haloScale        = max(pxR * 1.7, 1.2);
        float subPxFade        = smoothstep(0.4, 1.0, rawR);
        float depth            = 1.0 / (1.0 + cellZ * 0.35 * depthFade);
        float invCellZ         = 1.0 / cellZ;
        float pitchScreenX     = gridSize * invCellZ * size.y;
        float iCenter          = round(uv.x * jf);
        float iCenterScreenX   = iCenter * pitchScreenX + halfSizeX;
        float iCenterCellX     = iCenter * gridSize;

        for (int di = -1; di <= 1; di++) {
            float dotScreenX = iCenterScreenX + float(di) * pitchScreenX;
            if (abs(position.x - dotScreenX) > horizCullThresh) continue;

            float cellX = iCenterCellX + float(di) * gridSize;
            float Y     = swDotsOceanHeight(cellX, cellZ, t, amplitude, patternScale);
            float dotYFromH = (1.0 - Y) * invCellZ;
            if (dotYFromH < 0.01) continue;
            float dotScreenY = (horizon + dotYFromH) * size.y + halfSizeY;

            float horizonFade = smoothstep(0.0, 0.05, dotYFromH);
            float d           = length(position - float2(dotScreenX, dotScreenY));
            float mask        = smoothstep(pxR + 1.0, pxR - 1.0, d);
            float halo        = exp(-d / haloScale) * 0.25;
            float crest       = clamp(Y / (0.28 * max(amplitude, 0.01)) * 0.5 + 0.5, 0.0, 1.0);
            float highlight   = 0.45 + 1.0 * crest;
            float intensity   = (mask + halo) * depth * highlight * horizonFade * subPxFade;
            accum = max(accum, half3(intensity));
        }
    }
    accum = min(accum * 1.25, half3(1.0));

    float2 vUV  = (position - 0.5 * size) / size;
    float  vig  = clamp(1.0 - dot(vUV, vUV) * 0.6 * vignette, 0.0, 1.0);
    accum *= half(vig);

    // Slight cool-water tint baked into the dots — combines with user `tint`
    // to keep the field reading as "sea" even when the caller picks neutral
    // colors. This is intentional and part of the ocean style's identity.
    float3 waterTint = float3(0.92, 0.97, 1.0);
    float3 fg  = float3(tint.rgb) * brightness * waterTint;
    float3 bg  = float3(background.rgb);
    float3 col = mix(bg, fg, float3(accum));
    return half4(half3(col), 1.0h);
}
