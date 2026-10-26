//
//  SWStarNest.metal
//  ShipSwift
//
//  Adapted from "Star Nest" by Pablo Roman Andrioli (Kali)
//  https://www.shadertoy.com/view/XlfGRj
//  Licensed under the MIT License. Copyright (c) Pablo Roman Andrioli.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Stitchable SwiftUI color effect — volumetric procedural star nebula.
//
//  A fully procedural deep-space nebula: a fixed camera flies through a
//  3D space-folded fractal field. For each pixel a ray is marched in
//  `volsteps` slices; at every slice the sample point is folded into a
//  repeating tile, then run through `iterations` of the Star Nest "magic
//  formula" `p = abs(p)/dot(p,p) - formuparam`, which accumulates fractal
//  detail. The accumulated value is colored, faded with distance, and
//  dark-matter is subtracted to carve voids. No view sampling — this is a
//  pure generative background.
//
//  Paired with: SWStarNest.swift
//  Entry point: `swStarNest` — invoked via SwiftUI `.colorEffect(...)`.
//
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// GLSL `mod(x, y) = x - y * floor(x / y)`. Result takes the SIGN OF Y, so
// for a positive y it is always non-negative — unlike Metal's `fmod`, which
// truncates toward zero and returns a NEGATIVE result for negative inputs.
// Star Nest's camera origin (`from`) has negative components, so the tiling
// fold MUST use this GLSL-semantics version or the nebula tears apart on the
// negative side of space. Do not replace this with `fmod`.
static float3 swStarNestMod(float3 x, float3 y) {
    return x - y * floor(x / y);
}

[[ stitchable ]] half4 swStarNest(float2 position,
                                  half4  color,
                                  float4 boundingRect,
                                  float  time,
                                  float  speed,
                                  float  zoom,
                                  float  brightness,
                                  float  saturation,
                                  float  darkmatter,
                                  float  distfading,
                                  float  angleX,
                                  float  angleY,
                                  float  volsteps,
                                  float  iterations) {
    // Star Nest fixed tuning constants (the #defines that are not exposed as
    // adjustable parameters). Kept at their original values.
    const float formuparam = 0.53;   // fractal fold offset — the "magic" knob
    const float stepsize   = 0.1;    // distance advanced per volume slice
    const float tile       = 0.850;  // half-period of the space-folding tile

    float2 size = boundingRect.zw;

    // iResolution-equivalent UV: 0..1 then recentred to -0.5..0.5, with the
    // vertical axis aspect-corrected exactly as the original shader does.
    float2 uv = position / size - 0.5;
    uv.y *= size.y / size.x;

    // Ray direction for this pixel, scaled by the zoom (field of view).
    float3 dir = float3(uv * zoom, 1.0);

    float t = time * speed + 0.25;

    // Camera orientation. The original drives a1/a2 from the mouse; here they
    // are the caller-supplied `angleX` / `angleY` so the look is reproducible
    // and tunable. The +0.5 / +0.8 base matches Star Nest's neutral framing.
    float a1 = angleX;
    float a2 = angleY;

    // GLSL `mat2(cos,sin,-sin,cos)` is column-major: first column (cos, sin),
    // second column (-sin, cos). Metal's float2x2(col0, col1) matches that, so
    // float2x2(float2(c, s), float2(-s, c)) is the identical rotation matrix.
    float2x2 rot1 = float2x2(float2(cos(a1), sin(a1)), float2(-sin(a1), cos(a1)));
    float2x2 rot2 = float2x2(float2(cos(a2), sin(a2)), float2(-sin(a2), cos(a2)));

    // `dir.xz *= rot1; dir.xy *= rot2;` — rotate the swizzled pair, write back.
    float2 dxz = rot1 * float2(dir.x, dir.z);
    dir.x = dxz.x; dir.z = dxz.y;
    float2 dxy = rot2 * float2(dir.x, dir.y);
    dir.x = dxy.x; dir.y = dxy.y;

    // Camera origin, drifting through space over time, then rotated the same
    // way as the ray so the whole frame turns coherently.
    float3 from = float3(1.0, 0.5, 0.5);
    from += float3(t * 2.0, t, -2.0);
    float2 fxz = rot1 * float2(from.x, from.z);
    from.x = fxz.x; from.z = fxz.y;
    float2 fxy = rot2 * float2(from.x, from.y);
    from.x = fxy.x; from.y = fxy.y;

    // Volumetric march.
    float s = 0.1;
    float fade = 1.0;
    float3 v = float3(0.0);

    // Loop bounds are taken from the float parameters; cast to int and clamp so
    // a stray value can never spin the GPU. Upper caps match the original look.
    int vsteps = clamp(int(volsteps), 1, 24);
    int iters  = clamp(int(iterations), 1, 24);

    for (int r = 0; r < vsteps; r++) {
        float3 p = from + s * dir * 0.5;
        // Tiling fold — GLSL mod semantics are mandatory here (see helper).
        p = abs(float3(tile) - swStarNestMod(p, float3(tile * 2.0)));

        float pa = 0.0;
        float a  = 0.0;
        for (int i = 0; i < iters; i++) {
            // The Star Nest "magic formula": fold + inverse-square scale.
            p = abs(p) / dot(p, p) - formuparam;
            a += abs(length(p) - pa);   // accumulate inter-iteration change
            pa = length(p);
        }

        // Dark matter carves voids where the field is dense.
        float dm = max(0.0, darkmatter - a * a * 0.001);
        a *= a * a;                 // emphasise the brightest streaks
        if (r > 6) { fade *= 1.0 - dm; }

        v += fade;
        // Per-slice color: the (s, s^2, s^4) ramp tints near→far slices, so
        // depth reads as a hue shift across the nebula.
        v += float3(s, s * s, s * s * s * s) * a * brightness * fade;
        fade *= distfading;         // distant slices contribute less
        s += stepsize;
    }

    // Desaturate toward luminance by `saturation` (1 = full color, 0 = grey).
    v = mix(float3(length(v)), v, saturation);

    // Original scales the accumulated radiance by 0.01 into display range.
    return half4(half3(v * 0.01), 1.0);
}
