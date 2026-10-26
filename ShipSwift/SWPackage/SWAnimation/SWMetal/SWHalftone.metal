//
//  SWHalftone.metal
//  ShipSwift
//
//  Stitchable SwiftUI layerEffect rendering a halftone print family.
//  Two entry points:
//
//    • `swHalftoneDots` — 4 dot styles
//      (classic / gooey / holes / soft) × 2 grids (square / hex), with
//      optional originalColors mode and procedural grain.
//
//    • `swHalftoneCmyk` — simplified ink-only CMYK
//      variant. 4 channel plates (C / M / Y / K) at the classic 15° /
//      75° / 0° / 45° rotations, multiplicatively layered on a paper
//      background to produce a four-color printing look.
//
//  Both shaders treat the source layer as an image, quantize it into
//  rotated cell grids, and render dots whose size tracks the locally-
//  sampled luminance (or CMYK channel coverage). Anti-aliasing is via
//  `fwidth`-based smoothstep across cell edges.
//
//  Paired with: SWHalftone.swift
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - Shared helpers
// =============================================================================

// Linear smoothstep.
static float swHt_lst(float a, float b, float x) {
    return clamp((x - a) / max(b - a, 1e-6), 0.0, 1.0);
}

// 2D rotation by precomputed cos/sin.
static float2 swHt_rot(float2 p, float c, float s) {
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Sigmoid — applied per-RGB-channel before luminance to give
// a smoother contrast curve than a hard linear stretch.
static float swHt_sigmoid(float x, float k) {
    return 1.0 / (1.0 + exp(-k * (x - 0.5)));
}

// Apply sigmoid contrast to an RGB triple.
static float3 swHt_contrastRGB(float3 c, float k) {
    return float3(
        swHt_sigmoid(c.r, k),
        swHt_sigmoid(c.g, k),
        swHt_sigmoid(c.b, k)
    );
}

// Linear contrast — used in originalColors mode where keeping
// natural saturation matters more than a smooth midtone curve.
static float3 swHt_contrastLinear(float3 c, float k) {
    return clamp((c - 0.5) * k + 0.5, 0.0, 1.0);
}

// Cheap 2D hash for procedural noise — approximated with a hash so we
// don't have to bind a noise texture through SwiftUI.
static float swHt_hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float swHt_valueNoise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);
    float a = swHt_hash21(i);
    float b = swHt_hash21(i + float2(1.0, 0.0));
    float c = swHt_hash21(i + float2(0.0, 1.0));
    float d = swHt_hash21(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Smooth box that fades a `uv ∈ [0, 1]` rectangle's edges over `pad`.
// Crops dots that try to reach beyond the source image rectangle.
static float swHt_uvFrame(float2 uv, float2 pad) {
    const float aa = 0.0001;
    float left   = smoothstep(-pad.x, -pad.x + aa, uv.x);
    float right  = smoothstep(1.0 + pad.x, 1.0 + pad.x - aa, uv.x);
    float bottom = smoothstep(-pad.y, -pad.y + aa, uv.y);
    float top    = smoothstep(1.0 + pad.y, 1.0 + pad.y - aa, uv.y);
    return left * right * bottom * top;
}

// =============================================================================
// MARK: - Dot shape functions (classic / gooey / holes / soft)
// =============================================================================

// Classic crisp circle. `lum=0` → big dot, `lum=1` → none.
static float swHt_getClassic(float2 uv, float lum, float baseR) {
    float r = mix(0.25 * baseR, 0.0, lum);
    float d = length(uv - 0.5);
    float aa = fwidth(d);
    return 1.0 - smoothstep(r - aa, r + aa, d);
}

// Gooey soft falloff blob. Hex grid uses 0.42 base radius vs 0.3 for
// square.
static float swHt_getGooey(float2 uv, float lum, float baseR, bool hex) {
    float d = length(uv - 0.5);
    float sizeR = hex ? (0.42 * baseR) : (0.3 * baseR);
    sizeR = mix(sizeR, 0.0, lum);
    d = 1.0 - smoothstep(0.0, sizeR, d);
    d = pow(d, 2.0 + baseR);
    return d;
}

// Circle with optional hole. Big `lum` produces a ring (cell minus inner
// circle).
static float swHt_getHoles(float2 uv, float lum, float baseR) {
    float insideX = step(0.0, uv.x) * (1.0 - step(1.0, uv.x));
    float insideY = step(0.0, uv.y) * (1.0 - step(1.0, uv.y));
    float cell = insideX * insideY;

    float r = mix(0.75 * baseR, 0.0, lum);
    float rMod = fmod(r, 0.5);
    float d = length(uv - 0.5);
    float aa = fwidth(d);
    float circle = 1.0 - smoothstep(rMod - aa, rMod + aa, d);
    return (r < 0.5) ? circle : (cell - circle);
}

// Soft fuzzy falloff.
static float swHt_getSoft(float2 uv, float lum, float baseR) {
    float d = length(uv - 0.5);
    float sizeR = clamp(baseR, 0.0, 1.0);
    sizeR = mix(0.5 * sizeR, 0.0, lum);
    d = 1.0 - swHt_lst(0.0, sizeR, d);
    float powR = 1.0 - swHt_lst(0.0, 2.0, baseR);
    d = pow(d, 4.0 + 3.0 * powR);
    return d;
}

// =============================================================================
// MARK: - Luminance ball (combines sample + dot)
// =============================================================================

// Evaluates one dot at a sub-cell offset, writing the sampled ball color
// (used by originalColors mode) to `outBallColor`.
static float swHt_getLumBall(float2 uv,
                             float2 pad,
                             float2 offset,
                             SwiftUI::Layer layer,
                             float2 layerSize,
                             int typeI,
                             bool hexGrid,
                             bool originalColors,
                             float contrastK_sigmoid,
                             float contrastK_linear,
                             float baseRadius,
                             bool inverted,
                             float stepSize,
                             thread float4 &outBallColor) {
    float2 p = uv + offset;
    float2 uv_i = floor(p);
    float2 uv_f = fract(p);
    float2 samplingUV = (uv_i + 0.5 - offset) * pad + 0.5;
    float outOfFrame = swHt_uvFrame(samplingUV, pad * stepSize);

    float2 samplingPos = samplingUV * layerSize;
    half4 tex = layer.sample(samplingPos);

    // Two contrast paths so we don't double-apply contrast when the
    // caller wants original colors retained.
    float3 c = originalColors
        ? swHt_contrastLinear(float3(tex.rgb), contrastK_linear)
        : swHt_contrastRGB(float3(tex.rgb), contrastK_sigmoid);

    float lum = dot(float3(0.2126, 0.7152, 0.0722), c);
    lum = mix(1.0, lum, float(tex.a));
    if (inverted) lum = 1.0 - lum;

    outBallColor = float4(c * float(tex.a), float(tex.a)) * outOfFrame;

    float ball = 0.0;
    if      (typeI == 0) ball = swHt_getClassic(uv_f, lum, baseRadius);
    else if (typeI == 1) ball = swHt_getGooey  (uv_f, lum, baseRadius, hexGrid);
    else if (typeI == 2) ball = swHt_getHoles  (uv_f, lum, baseRadius);
    else                 ball = swHt_getSoft   (uv_f, lum, baseRadius);

    return ball * outOfFrame;
}

// Picks the right sub-sampling density per dot type.
// classic = 2× (4 samples), gooey/soft = 6× (36 samples), holes = 1× (1 sample).
static float swHt_stepMultiplierFor(int typeI) {
    if (typeI == 0) return 2.0;
    if (typeI == 2) return 1.0;
    return 6.0;
}

// =============================================================================
// MARK: - swHalftoneDots (4 styles × 2 grids × originalColors + grain)
// =============================================================================

[[ stitchable ]] half4 swHalftoneDots(float2 position,
                                      SwiftUI::Layer layer,
                                      float4 boundingRect,
                                      float  type,            // 0=classic 1=gooey 2=holes 3=soft
                                      float  grid,            // 0=square 1=hex
                                      float  size,            // 0..1
                                      float  radius,          // 0..2
                                      float  contrast,        // 0..1
                                      float  inverted,        // 0 / 1
                                      float  originalColors,  // 0 / 1
                                      float  grainMixer,      // 0..1
                                      float  grainOverlay,    // 0..1
                                      float  grainSize,       // 0..1
                                      half4  colorFront,
                                      half4  colorBack) {
    float2 sz = boundingRect.zw;
    float aspect = sz.x / max(sz.y, 1.0);

    int typeI = clamp(int(type + 0.5), 0, 3);
    bool hexGrid = (grid > 0.5);
    bool inv     = (inverted > 0.5);
    bool useOrig = (originalColors > 0.5);

    float stepMultiplier = swHt_stepMultiplierFor(typeI);
    float stepSize = 1.0 / stepMultiplier;

    // Grid in normalized image UV (0..1 across the layer).
    float cellsPerSide = mix(300.0, 7.0, pow(saturate(size), 0.7));
    cellsPerSide /= stepMultiplier;
    float cellSizeY = 1.0 / cellsPerSide;
    float2 pad = cellSizeY * float2(1.0 / max(aspect, 1e-4), 1.0);
    if (typeI == 1 && hexGrid) {
        // gooey + hex: shrink pad to keep cells overlapping properly.
        pad *= 0.7;
    }

    // uvImage in [0, 1]; uv in cell-grid coords centered at 0.
    float2 uvImage = position / max(sz, float2(1.0));
    float2 uv = (uvImage - 0.5) / pad;

    // Two contrast curves so originalColors mode keeps natural midtones
    // while two-tone mode aggressively shapes the histogram.
    float contrastK_sigmoid = mix(0.0, 15.0, pow(saturate(contrast), 1.5));
    float contrastK_linear  = mix(0.1, 4.0,  pow(saturate(contrast), 2.0));
    float baseRadius = useOrig
        ? (2.0 * pow(0.5 * saturate(radius), 0.3))
        : saturate(radius);

    // Sub-cell scan — nested loop, capped at 6×6 = 36 samples.
    float  totalShape   = 0.0;
    float3 totalColor   = float3(0.0);
    float  totalOpacity = 0.0;

    int steps = int(stepMultiplier);
    for (int ix = 0; ix < 6; ix++) {
        if (ix >= steps) break;
        float ox = -0.5 + (float(ix) + 0.5) * stepSize;
        for (int iy = 0; iy < 6; iy++) {
            if (iy >= steps) break;
            float oy = -0.5 + (float(iy) + 0.5) * stepSize;
            float2 offset = float2(ox, oy);

            // Hex grid alternates row/col parity differently per type.
            if (hexGrid) {
                float rowIndex = floor((oy + 0.5) / stepSize);
                float colIndex = floor((ox + 0.5) / stepSize);
                if (stepSize >= 0.999) {
                    rowIndex = floor(uv.y + oy + 1.0);
                    if (typeI == 1) colIndex = floor(uv.x + ox + 1.0);
                }
                if (typeI == 1) {
                    // gooey hex: skip checker-pattern cells.
                    if (fmod(rowIndex + colIndex, 2.0) >= 0.5) continue;
                } else {
                    // others: offset every other row by half a cell.
                    if (fmod(rowIndex, 2.0) >= 0.5) offset.x += 0.5 * stepSize;
                }
            }

            float4 ballColor;
            float shape = swHt_getLumBall(
                uv, pad, offset, layer, sz,
                typeI, hexGrid, useOrig,
                contrastK_sigmoid, contrastK_linear,
                baseRadius, inv, stepSize,
                ballColor
            );

            totalColor   += ballColor.rgb * shape;
            totalShape   += shape;
            totalOpacity += shape;
        }
    }

    const float eps = 1e-4;
    totalColor   /= max(totalShape, eps);
    totalOpacity /= max(totalShape, eps);

    // Per-type threshold.
    float finalShape;
    if (typeI == 0)      finalShape = min(1.0, totalShape);
    else if (typeI == 1) { float aa = fwidth(totalShape);
                           finalShape = smoothstep(0.5 - aa, 0.5 + aa, totalShape); }
    else if (typeI == 2) finalShape = min(1.0, totalShape);
    else                 finalShape = totalShape;

    // Grain mixer — perturbs the dot mask with a noise field.
    float2 grainScale = mix(2000.0, 200.0, saturate(grainSize))
                       * float2(1.0, 1.0 / max(aspect, 1e-4));
    float2 grainUV    = (uvImage - 0.5) * grainScale + 0.5;
    float  grainN     = swHt_valueNoise(grainUV);
    grainN = smoothstep(0.55, 0.7 + 0.2 * saturate(grainMixer), grainN);
    grainN *= saturate(grainMixer);
    finalShape = mix(finalShape, 0.0, grainN);

    // Composite — either keep sampled colors or replace with ink/paper.
    float3 col;
    if (useOrig) {
        float opacity = totalOpacity * finalShape;
        col = totalColor * finalShape
            + float3(colorBack.rgb) * float(colorBack.a) * (1.0 - opacity);
    } else {
        float fgA = float(colorFront.a);
        float bgA = float(colorBack.a);
        col = float3(colorFront.rgb) * fgA * finalShape
            + float3(colorBack.rgb)  * bgA * (1.0 - fgA * finalShape);
    }

    // Grain overlay — black/white speckle added on top, slightly rotated
    // for variety so it doesn't look like a regular pattern.
    float2 grainUVA = swHt_rot(grainUV, cos(1.0), sin(1.0)) + 3.0;
    float2 grainUVB = swHt_rot(grainUV, cos(2.0), sin(2.0)) + float2(-1.0);
    float grainOver = mix(swHt_valueNoise(grainUVA), swHt_valueNoise(grainUVB), 0.5);
    grainOver = pow(grainOver, 1.3);
    float grainOverV = grainOver * 2.0 - 1.0;
    float grainStr = saturate(grainOverlay) * abs(grainOverV);
    grainStr = pow(grainStr, 0.8);
    float3 grainColor = float3(step(0.0, grainOverV));
    col = mix(col, grainColor, 0.5 * grainStr);

    return half4(half3(col), 1.0);
}

// =============================================================================
// MARK: - swHalftoneCmyk (4-channel CMYK ink-only simplified port)
// =============================================================================
//
// Simplified CMYK variant:
//   • Only the `ink` dot style — `dots` (separate) and `sharp` (per-pixel)
//     styles need extra branching and are left for a follow-up.
//   • No flood / gain / softness sliders — uses fixed defaults.
//   • No grain mixer / overlay.
//   • CMYK plate rotation angles, paper feed shifts, and a 3×3
//     neighbour scan drive the four-color reconstruction.

// Extract one CMYK channel from a contrast-shaped RGB triple.
static float swHt_cyan(float3 c)    { float m = max(max(c.r, c.g), c.b); return m > 1e-5 ? (m - c.r) / m : 0.0; }
static float swHt_magenta(float3 c) { float m = max(max(c.r, c.g), c.b); return m > 1e-5 ? (m - c.g) / m : 0.0; }
static float swHt_yellow(float3 c)  { float m = max(max(c.r, c.g), c.b); return m > 1e-5 ? (m - c.b) / m : 0.0; }
static float swHt_black(float3 c)   { return 1.0 - max(max(c.r, c.g), c.b); }

// One CMYK dot in ink mode — joined coverage mask.
static float swHt_cmykDot(float2 uvLocal, float2 cellCenter, float coverage, float alpha) {
    float radius = coverage * 1.1;
    radius += 0.15;
    radius = max(0.0, radius);
    radius = mix(0.0, radius, alpha);
    float dist = length(uvLocal - cellCenter);
    float m = 1.0 - smoothstep(0.0, radius, dist);
    return pow(m, 1.2);
}

// Image normalized UV for a CMYK cell center in plate-local grid space.
static float2 swHt_gridToImageUV(float2 cellCenter, float c, float s, float shift, float2 pad) {
    float2 uvGrid = swHt_rot(cellCenter - shift, c, -s);
    return uvGrid * pad + 0.5;
}

[[ stitchable ]] half4 swHalftoneCmyk(float2 position,
                                      SwiftUI::Layer layer,
                                      float4 boundingRect,
                                      float  size,
                                      float  contrast,
                                      half4  colorBack,
                                      half4  colorC,
                                      half4  colorM,
                                      half4  colorY,
                                      half4  colorK) {
    float2 sz = boundingRect.zw;
    float aspect = sz.x / max(sz.y, 1.0);

    // CMYK plate rotations: 15° (C), 75° (M), 0° (Y), 45° (K).
    const float cosC = 0.9659258, sinC = 0.2588190;
    const float cosM = 0.2588190, sinM = 0.9659258;
    const float cosY = 1.0,       sinY = 0.0;
    const float cosK = 0.7071068, sinK = 0.7071068;
    const float shiftC = -0.5, shiftM = -0.25, shiftY = 0.2, shiftK = 0.0;

    float cellsPerSide = mix(400.0, 7.0, pow(saturate(size), 0.7));
    float cellSizeY = 1.0 / cellsPerSide;
    float2 pad = cellSizeY * float2(1.0 / max(aspect, 1e-4), 1.0);

    float2 uvImage = position / max(sz, float2(1.0));
    float2 uvGrid = (uvImage - 0.5) / pad;
    float insideImageBox = swHt_uvFrame(uvImage, pad);

    // Per-plate grid coordinates — rotate the world into each plate's
    // local frame, then shift so the dots don't overlap exactly.
    float2 uvC = swHt_rot(uvGrid, cosC, sinC) + shiftC;
    float2 uvM = swHt_rot(uvGrid, cosM, sinM) + shiftM;
    float2 uvY = swHt_rot(uvGrid, cosY, sinY) + shiftY;
    float2 uvK = swHt_rot(uvGrid, cosK, sinK) + shiftK;

    float contrastK = mix(0.1, 4.0, pow(saturate(contrast), 2.0));

    float4 outMask = float4(0.0);

    // 3×3 neighbour scan per plate so dots near cell boundaries still
    // light up correctly.
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            float2 cellOffset = float2(float(dx), float(dy));

            // CYAN
            float2 cellC = floor(uvC) + 0.5 + cellOffset;
            float2 imgUVc = swHt_gridToImageUV(cellC, cosC, sinC, shiftC, pad);
            half4 texC = layer.sample(imgUVc * sz);
            float3 cC = swHt_contrastLinear(float3(texC.rgb), contrastK);
            outMask[0] += swHt_cmykDot(uvC, cellC, swHt_cyan(cC), insideImageBox * float(texC.a));

            // MAGENTA
            float2 cellM = floor(uvM) + 0.5 + cellOffset;
            float2 imgUVm = swHt_gridToImageUV(cellM, cosM, sinM, shiftM, pad);
            half4 texM = layer.sample(imgUVm * sz);
            float3 cM = swHt_contrastLinear(float3(texM.rgb), contrastK);
            outMask[1] += swHt_cmykDot(uvM, cellM, swHt_magenta(cM), insideImageBox * float(texM.a));

            // YELLOW
            float2 cellY = floor(uvY) + 0.5 + cellOffset;
            float2 imgUVy = swHt_gridToImageUV(cellY, cosY, sinY, shiftY, pad);
            half4 texY = layer.sample(imgUVy * sz);
            float3 cY = swHt_contrastLinear(float3(texY.rgb), contrastK);
            outMask[2] += swHt_cmykDot(uvY, cellY, swHt_yellow(cY), insideImageBox * float(texY.a));

            // BLACK
            float2 cellK = floor(uvK) + 0.5 + cellOffset;
            float2 imgUVk = swHt_gridToImageUV(cellK, cosK, sinK, shiftK, pad);
            half4 texK = layer.sample(imgUVk * sz);
            float3 cK = swHt_contrastLinear(float3(texK.rgb), contrastK);
            outMask[3] += swHt_cmykDot(uvK, cellK, swHt_black(cK), insideImageBox * float(texK.a));
        }
    }

    // Ink threshold — join overlapping dots into a continuous ink
    // body via smoothstep with a fixed softness.
    const float th = 0.5;
    const float soft = 0.2;
    outMask = float4(
        smoothstep(th - soft - fwidth(outMask[0]), th + soft, outMask[0]),
        smoothstep(th - soft - fwidth(outMask[1]), th + soft, outMask[1]),
        smoothstep(th - soft - fwidth(outMask[2]), th + soft, outMask[2]),
        smoothstep(th - soft - fwidth(outMask[3]), th + soft, outMask[3])
    );

    float C = outMask[0] * float(colorC.a);
    float M = outMask[1] * float(colorM.a);
    float Y = outMask[2] * float(colorY.a);
    float K = outMask[3] * float(colorK.a);

    // Multiplicative ink layering on the paper background.
    float3 ink = float3(1.0);
    ink = mix(float3(1.0), float3(colorK.rgb), clamp(K, 0.0, 1.0)) * ink;
    ink = mix(float3(1.0), float3(colorC.rgb), clamp(C, 0.0, 1.0)) * ink;
    ink = mix(float3(1.0), float3(colorM.rgb), clamp(M, 0.0, 1.0)) * ink;
    ink = mix(float3(1.0), float3(colorY.rgb), clamp(Y, 0.0, 1.0)) * ink;

    float shape = clamp(max(max(C, M), max(Y, K)), 0.0, 1.0);
    float3 paper = float3(colorBack.rgb) * float(colorBack.a);
    float3 col = mix(paper, ink, shape);

    return half4(half3(col), 1.0);
}
