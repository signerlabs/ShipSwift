//
//  SWMetaballs.metal
//  ShipSwift
//
//  Stitchable SwiftUI color effect that renders a cluster of metaballs.
//  Each blob is a radial power-of-distance shape; per-ball shapes are
//  summed and a smoothstep threshold carves the final silhouette. Color
//  is the shape-weighted average of the per-ball colors, composited over
//  `background`.
//
//  Paired with: SWMetaballs.swift
//  Entry point: `swMetaballs` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// 1D hash + smoothstep noise — avoids binding an auxiliary noise texture.
// Produces a smooth pseudo-random scalar in [0, 1] so the per-ball drift
// is continuous in time.
static float swMetaballsHash1(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

static float swMetaballsNoise1(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(swMetaballsHash1(i), swMetaballsHash1(i + 1.0), u);
}

// Radial power-of-distance shape, 0..1.
// `aspectScale` rescales the (uv - c) difference so 1 unit on each axis
// corresponds to the same on-screen distance: keeps the blob round on
// portrait / landscape viewports instead of stretching with the frame.
static float swMetaballsBallShape(float2 uv, float2 c, float p, float2 aspectScale) {
    float2 diff = (uv - c) * aspectScale;
    float s = 0.5 * length(diff);
    s = 1.0 - saturate(s);
    return pow(s, p);
}

[[ stitchable ]] half4 swMetaballs(float2 position,
                                   half4  inColor,
                                   float4 boundingRect,
                                   float  time,
                                   float  speed,
                                   float  count,
                                   float  size,
                                   float  colorsCount,
                                   half4  color1,
                                   half4  color2,
                                   half4  color3,
                                   half4  color4,
                                   half4  color5,
                                   half4  color6,
                                   half4  color7,
                                   half4  color8,
                                   half4  background) {
    float2 sz = boundingRect.zw;
    // Map the bounding rect to 0..1 in pixel space — divide the position
    // by the bounding rect.
    float2 shape_uv = position / max(sz, float2(1.0));
    // `aspectScale` lets `length()` measure visually equal distances on
    // both axes — divide pixels by the short side, so the short axis
    // scales to 1 and the long axis scales above 1.
    float minDim = max(min(sz.x, sz.y), 1.0);
    float2 aspectScale = sz / minDim;

    // Offset time by 2503.4 in the first frame so the cluster doesn't
    // start in a "uniform initial state". `speed` is exposed here as a
    // wrapper-side multiplier on top of the internal 0.2 factor.
    const float firstFrameOffset = 2503.4;
    float t = 0.2 * (time * speed + firstFrameOffset);

    // Pack the 8 color slots so the loop can index by ball.
    half4 colors[8] = { color1, color2, color3, color4,
                        color5, color6, color7, color8 };
    int colorsCountInt = max(int(colorsCount + 0.5), 1);

    // Unrolled to 8 iterations to fit SwiftUI's stitchable color shaders'
    // instruction budget. `count` is exposed as a float so the wrapper can
    // fractional-fade the last ball in / out via `fract(count)`.
    float countClamped = min(max(count, 1.0), 8.0);
    int countCeil = int(ceil(countClamped));

    float3 totalColor = float3(0.0);
    float  totalShape = 0.0;

    for (int i = 0; i < 8; i++) {
        if (i >= countCeil) break;

        // Per-ball drift — two 1D noise samples placed on a circle so
        // each ball gets an independent, slowly meandering position.
        float idxFract = float(i) / 20.0;
        float angle = 6.2831853 * idxFract;
        float spd = 1.0 - 0.2 * idxFract;
        float noiseX = swMetaballsNoise1(angle * 10.0 + float(i) + t * spd);
        float noiseY = swMetaballsNoise1(angle * 20.0 + float(i) - t * spd);
        float2 pos = float2(0.5) + 1e-4 + 0.9 * (float2(noiseX, noiseY) - 0.5);

        // Pick color by `i % colorsCount` so adding balls beyond the
        // color count cycles through the palette.
        int safeIdx = i % colorsCountInt;
        half4 ballColor = colors[safeIdx];
        // Premultiply alpha — the summation assumes premultiplied color
        // contributions.
        float3 rgb = float3(ballColor.rgb) * float(ballColor.a);

        // Fractional last-ball fade: when `count` isn't a whole number,
        // shrink the last ball by `fract(count)` so it grows in.
        float sizeFrac = 1.0;
        if (float(i) > floor(countClamped - 1.0)) {
            sizeFrac *= fract(countClamped);
        }

        float p = 45.0 - 30.0 * size * sizeFrac;
        float shape = swMetaballsBallShape(shape_uv, pos, p, aspectScale);
        shape *= pow(size, 0.2);
        shape = smoothstep(0.0, 1.0, shape);

        totalColor += rgb * shape;
        totalShape += shape;
    }

    // Shape-weighted average — gives each blob its own hue while the
    // overlaps blend smoothly.
    totalColor /= max(totalShape, 1e-4);

    // Use `fwidth(totalShape)` for an anti-aliased edge. Metal's `fwidth`
    // works inside fragment-shader-style stitchables — fall back to a
    // small constant if the compile target rejects it.
    float edge_width = fwidth(totalShape);
    float finalShape = smoothstep(0.4, 0.4 + edge_width, totalShape);

    float3 color = totalColor * finalShape +
                   float3(background.rgb) * (1.0 - finalShape);

    return half4(half3(color), 1.0);
}

// MARK: - Fountain

// A large central ball with small balls streaming vertically: roughly half
// rise from the bottom and converge into the big ball, the other half leave
// the big ball and spread upward out of frame. Because all shapes are summed
// before the threshold, a small ball melts into a teardrop bridge as it nears
// the big ball (the metaball "merge"), then separates again as it travels.
// Reuses the same parameter signature as `swMetaballs`:
//   count = number of small balls (1...7, big ball is always present)
//   size  = ball fatness, speed = stream speed, colors = palette
//           (colors[0] paints the big ball, the rest cycle over small balls).
[[ stitchable ]] half4 swMetaballsFountain(float2 position,
                                           half4  inColor,
                                           float4 boundingRect,
                                           float  time,
                                           float  speed,
                                           float  count,
                                           float  size,
                                           float  colorsCount,
                                           half4  color1,
                                           half4  color2,
                                           half4  color3,
                                           half4  color4,
                                           half4  color5,
                                           half4  color6,
                                           half4  color7,
                                           half4  color8,
                                           half4  background,
                                           float  bigSize) {
    float2 sz = boundingRect.zw;
    float2 shape_uv = position / max(sz, float2(1.0));
    float minDim = max(min(sz.x, sz.y), 1.0);
    float2 aspectScale = sz / minDim;

    float t = time * speed;

    half4 colors[8] = { color1, color2, color3, color4,
                        color5, color6, color7, color8 };
    int colorsCountInt = max(int(colorsCount + 0.5), 1);

    float3 totalColor = float3(0.0);
    float  totalShape = 0.0;

    // --- Big central ball (always present, painted with colors[0]) ---
    // Small power = large, soft ball. `bigSize` is independent of `size`.
    // Wide range so `bigSize` can grow the big ball much larger.
    float bigP = 18.0 - 15.0 * bigSize;
    float bigShape = swMetaballsBallShape(shape_uv, float2(0.5, 0.5), bigP, aspectScale);
    bigShape = smoothstep(0.0, 1.0, bigShape);
    half4  bigColor = colors[0];
    float3 bigRGB   = float3(bigColor.rgb) * float(bigColor.a);
    totalColor += bigRGB * bigShape;
    totalShape += bigShape;

    // --- Small balls streaming in / out ---
    // Large power = small, crisp balls. Wide range so `size` can go very tiny.
    float smallP = 100.0 - 70.0 * size;
    int n = max(min(int(count + 0.5), 99), 1);
    for (int i = 0; i < 99; i++) {
        if (i >= n) break;
        float fi = float(i);

        float h1 = swMetaballsHash1(fi + 1.0);    // per-ball phase offset
        float h2 = swMetaballsHash1(fi + 7.3);    // horizontal spread
        bool  rising = (int(h1 * 17.0) % 2 == 0); // ~half rise, half leave
        float xj = (h2 - 0.5) * 0.55;             // lateral offset at the far end

        float phase = fract(t * 0.22 + h1);       // 0..1 travel loop

        float2 pos;
        float fade;
        if (rising) {
            // bottom (y = 1.12) -> centre (y = 0.5), x converges to centre.
            float y = mix(1.12, 0.5, phase);
            float x = 0.5 + xj * (1.0 - phase);
            pos = float2(x, y);
            fade = smoothstep(0.0, 0.18, phase);  // fade in from bottom, stay as it merges
        } else {
            // centre (y = 0.5) -> top (y = -0.12), x spreads outward.
            float y = mix(0.5, -0.12, phase);
            float x = 0.5 + xj * phase;
            pos = float2(x, y);
            fade = smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.72, 1.0, phase));
        }

        float shape = swMetaballsBallShape(shape_uv, pos, smallP, aspectScale);
        shape = smoothstep(0.0, 1.0, shape) * fade;

        int safeIdx = (i + 1) % colorsCountInt;
        half4 bc = colors[safeIdx];
        float3 rgb = float3(bc.rgb) * float(bc.a);
        // Dissolve into the big ball: the nearer a small ball is to the centre,
        // the more its color is blended toward the big ball's, so it mixes in
        // like two liquids instead of staying a distinct dot.
        float distToBig = length((pos - float2(0.5)) * aspectScale);
        float blend = 1.0 - smoothstep(0.0, 0.6, distToBig);
        rgb = mix(rgb, bigRGB, blend);
        totalColor += rgb * shape;
        totalShape += shape;
    }

    totalColor /= max(totalShape, 1e-4);

    float edge_width = fwidth(totalShape);
    float finalShape = smoothstep(0.4, 0.4 + edge_width, totalShape);

    float3 color = totalColor * finalShape +
                   float3(background.rgb) * (1.0 - finalShape);

    return half4(half3(color), 1.0);
}
