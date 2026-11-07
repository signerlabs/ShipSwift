//
//  SWLiquidMetal.metal
//  ShipSwift
//
//  Stitchable SwiftUI layerEffect — a flowing liquid-metal effect.
//  Wraps any view (typically an SF Symbol) in animated metal: big
//  low-frequency simplex-noise light/dark blocks drift one way across
//  the silhouette, lit from above, with a cool ambient bounce, a warm
//  accent, a fresnel rim along the contour and a slow brightness breath.
//  Layer size is sourced from the `boundingRect` parameter for
//  portability across SwiftUI shader APIs.
//
//  Paired with: SWLiquidMetal.swift
//  Entry point: `swLiquidMetal` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 18+ / macOS 15+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - Constants & shared helpers
// =============================================================================

constant float4 SWLM_C = float4(0.211324865405187,
                                 0.366025403784439,
                                -0.577350269189626,
                                 0.024390243902439);

// =============================================================================
// MARK: - Tunable Parameters  (edit values here, recompile, observe)
// =============================================================================
// All the visual magic numbers that were repeatedly hand-tuned live here in one
// place. Each is the CURRENT shipping value; the shader body below only
// references these names. Edit a value, recompile, and look — no hunting inside
// the algorithm. Each comment says what it controls and which way to nudge it.

// --- Endpoint colors ---------------------------------------------------------
// The two ends of the metal ramp. color1 = cool specular white, color2 = the
// near-black shadow. Push color1 toward 1.0 for a brighter sheen; lower color2
// (toward 0) for a darker, higher-contrast body.
constant float3 SWLM_COLOR1     = float3(0.97, 0.98, 1.0);   // cool highlight white
constant float3 SWLM_COLOR2     = float3(0.035, 0.035, 0.045);// near-black shadow base
constant float  SWLM_COLOR2_BLUE_BOOST = 0.05;  // extra blue added to shadow toward bottom-right (bigger = bluer shadow)

// --- Cool ambient bounce -----------------------------------------------------
// The blue/cyan tint mixed into the mid-tones. More blue / less red+green =
// cooler. Multiplied at runtime by the `coolTint` slider.
constant float3 SWLM_COOL_COLOR = float3(0.55, 0.72, 1.0);   // ambient cool-blue bounce

// --- Fresnel rim -------------------------------------------------------------
// Color and internal strength of the contour rim. RIM_GAIN scales how wide the
// rim ring reads before the `fresnel` slider applies (bigger = fatter rim).
constant float3 SWLM_RIM_COLOR  = float3(0.60, 0.80, 1.0);   // cool-BLUE grazing rim (WWDC blue edge)
constant float  SWLM_RIM_GAIN   = 4.0;   // rim ring width gain (bigger = wider rim band)
constant float  SWLM_RIM_GLOW   = 0.7;   // additive cool-blue edge glow — keeps the rim bright even on dark frames (bigger = brighter blue edge)

// --- Low-frequency block field (the big bright body) -------------------------
// FLOW_AXIS = the tilted direction the big blocks drift along. Rotate it to
//   change which way the light streaks.
// FIELD_SCALE = scale of the blocks — SMALLER = BIGGER blocks.
// FLOW_DRIFT = one-way drift speed (bigger = faster).
// BRIGHT_LO/BRIGHT_HI = how much of the value range counts as "lit silver".
//   Lower both to make the bright body claim MORE of the logo (less shadow);
//   bring them closer together for a harder light/dark edge.
// OUT_BASE = output floor of the field (bigger = shadows never as deep).
constant float2 SWLM_FLOW_AXIS   = float2(0.62, 0.78);  // direction the bright bar sweeps along (rotate to re-aim)
constant float  SWLM_FIELD_SCALE = 1.1;   // scale of the big light/dark blocks — SMALLER = BIGGER blocks (~1 = one big bright block + one big shadow across the logo)
constant float  SWLM_FLOW_DRIFT  = 0.6;   // one-way flow speed of the big blocks (bigger = faster continuous drift)
constant float  SWLM_BRIGHT_LO   = 0.34;   // bright-zone threshold low  (lower = more of logo is lit)
constant float  SWLM_BRIGHT_HI   = 0.66;   // bright-zone threshold high (closer to LO = harder edge)
constant float  SWLM_OUT_BASE    = 0.05;   // lowField output floor (bigger = shadows never as deep)

// --- Global brightness breath ------------------------------------------------
// Whole-logo luminance slowly pulses dark -> bright -> dark, matching the WWDC
// clip's overall rise & fall (runs on an independent slow clock).
constant float  SWLM_BREATH_MIN   = 0.82;  // dimmest point of the breath (smaller = deeper dips)
constant float  SWLM_BREATH_SPEED = 1.0;   // breath rate rad/s (~6.3s per cycle at 1.0)

// --- Local warm accent -------------------------------------------------------
// A drifting touch of warm gold in the hottest reflections — cool-silver
// dominant with a hint of warmth, not pure greyscale.
constant float3 SWLM_WARM_COLOR = float3(1.0, 0.66, 0.42);  // warm orange-gold accent
constant float  SWLM_WARM_AMT   = 0.18;   // warmth in hot reflections (0 = pure cool)

// --- Dither ------------------------------------------------------------------
// Tiny per-pixel noise added at the very end to break up 8-bit banding and the
// visible "block edges" where the smooth field crosses a smoothstep threshold.
constant float  SWLM_DITHER     = 2.2;   // dither strength in 1/255 units (bigger = noisier but smoother gradients)

// =============================================================================

static float3 swLM_mod289v3(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float2 swLM_mod289v2(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float3 swLM_permute(float3 x)  { return swLM_mod289v3(((x * 34.0) + 1.0) * x); }

// 2D simplex noise (Ashima Arts / Stefan Gustavson, public domain).
static float swLM_snoise(float2 v) {
    float2 i = floor(v + dot(v, SWLM_C.yy));
    float2 x0 = v - i + dot(i, SWLM_C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + SWLM_C.xxzz;
    x12.xy -= i1;
    i = swLM_mod289v2(i);
    float3 p = swLM_permute(swLM_permute(i.y + float3(0.0, i1.y, 1.0))
                                       + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0),
                                 dot(x12.xy, x12.xy),
                                 dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    float3 x = 2.0 * fract(p * SWLM_C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x  = a0.x  * x0.x   + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// Soft alpha falloff at the layer's outer 10%.
static float swLM_imgFrameAlpha(float2 uv, float frameWidth) {
    float f = smoothstep(0.0, frameWidth, uv.x)
            * smoothstep(1.0, 1.0 - frameWidth, uv.x);
    f *= smoothstep(0.0, frameWidth, uv.y)
       * smoothstep(1.0, 1.0 - frameWidth, uv.y);
    return f;
}

// Large-scale, NON-periodic, DIRECTIONAL light/dark field — the metal's body.
// Built purely from big simplex blobs that slide along a tilted axis, like
// polished metal reflecting one bright window drifting across a dark room.
// Returns a 0..1 brightness with no repetition and no concentric structure.
//
// `flow` (the animation time) slowly drifts the blobs so the big reflections
// creep diagonally like mercury.
static float swLM_lowField(float2 uv, float topDown, float flow) {
    // BIG soft light/dark blocks that FLOW one way, like WWDC's molten metal.
    // Sample LOW-frequency noise whose position slides continuously in a single
    // direction: low frequency => only a couple of LARGE soft regions span the
    // whole logo (one big bright block + one big shadow), never small dots or
    // thin strands; the continuous slide (no fract/wrap) flows endlessly one way
    // with NO jump; two octaves let the big shape morph slowly like liquid metal.
    float2 dir   = normalize(SWLM_FLOW_AXIS);
    float2 fuv   = uv - dir * (flow * SWLM_FLOW_DRIFT);            // one-way continuous flow, no seam
    float  n1    = swLM_snoise(fuv * SWLM_FIELD_SCALE);
    float  n2    = swLM_snoise(fuv * SWLM_FIELD_SCALE * 1.7 + float2(4.0, 9.0));
    float  field = 0.5 + 0.55 * n1 + 0.22 * n2;                   // big soft light/dark field
    float  s     = smoothstep(SWLM_BRIGHT_LO, SWLM_BRIGHT_HI, field);
    s = s * s * (3.0 - 2.0 * s);                                  // smootherstep: wide soft boundary, no line
    return saturate(SWLM_OUT_BASE + (1.0 - SWLM_OUT_BASE) * s);
}

// =============================================================================
// MARK: - swLiquidMetal
// =============================================================================

[[ stitchable ]] half4 swLiquidMetal(float2 position,
                                     SwiftUI::Layer layer,
                                     float4 boundingRect,
                                     float  time,
                                     float  speed,
                                     float  edge,          // 0..1 edge sharpness
                                     float  timeScale,     // 0..2 animation rate
                                     float  coolTint,      // 0..1 cool blue ambient bounce
                                     float  fresnel) {     // 0..1 rim highlight strength
    float2 sz = boundingRect.zw;
    float2 uvRaw = position / max(sz, float2(1.0));
    float2 uv = uvRaw;

    half4 img = layer.sample(position);
    if (img.a == 0.0) {
        return img;
    }

    float t = timeScale * speed * time;

    // High-contrast endpoints: a cool near-white specular highlight against a
    // near-black shadow. color2 is pushed much darker than before so the
    // light/dark split reads like polished metal rather than grey plastic.
    // A faint top-down luminance ramp keeps the top brighter and the bottom
    // darker (light comes from above) while never letting the bottom die to
    // pure black.
    float topDown = mix(0.06, 1.0, smoothstep(1.0, 0.0, uv.y));
    float3 color1 = SWLM_COLOR1 * mix(0.85, 1.0, topDown);
    float3 color2 = float3(SWLM_COLOR2.r, SWLM_COLOR2.g,
                           SWLM_COLOR2.b + SWLM_COLOR2_BLUE_BOOST * smoothstep(0.7, 1.3, uv.x + uv.y))
                    * mix(0.7, 1.0, topDown);

    // Cool ambient bounce injected into the highlight->shadow transition:
    // a soft blue/cyan tint that keeps the metal from looking like a flat
    // greyscale ramp. Sampled by how close a channel sits to the mid-tone.
    float3 coolColor = SWLM_COOL_COLOR;

    float pixelEdge = float(img.r);   // use red channel of the source as the edge mask

    float opacity = 1.0 - smoothstep(0.9 - 0.5 * saturate(edge),
                                     1.0 - 0.5 * saturate(edge), pixelEdge);
    opacity *= swLM_imgFrameAlpha(uvRaw, 0.1);

    // --- Large-scale block reflection ---------------------------------------
    // The metal body: a couple of big, smooth, non-periodic light/dark blocks
    // (bright body + dark zone) that drift one way across the logo.
    float lowF = swLM_lowField(uv, topDown, t);
    float3 metal = mix(color2, color1, lowF);

    // --- Global brightness breath -------------------------------------------
    // Whole-logo luminance pulse (dark -> bright -> dark) on a slow independent
    // clock, matching the WWDC clip's overall rise & fall.
    float breath = mix(SWLM_BREATH_MIN, 1.0, 0.5 + 0.5 * sin(time * SWLM_BREATH_SPEED));
    metal *= breath;

    // --- Cool ambient bounce -------------------------------------------------
    // Inject the blue/cyan tint strongest in the mid-tones (the highlight->
    // shadow transition), tapering off in both the brightest specular and the
    // deepest shadow so the rim stays clean white and the core stays dark.
    float luma = dot(metal, float3(0.299, 0.587, 0.114));
    float midBand = smoothstep(0.12, 0.45, luma) * smoothstep(0.95, 0.5, luma);
    metal = mix(metal, metal * coolColor, saturate(coolTint) * midBand);

    // --- Local warm accent --------------------------------------------------
    // A drifting hint of warm gold in the hottest reflections, so the metal is
    // cool-dominant with a touch of warmth rather than pure greyscale.
    float warmGate = smoothstep(0.6, 0.95, lowF) *
                     (0.5 + 0.5 * swLM_snoise(uv * 0.8 - float2(0.12 * t, 0.05 * t)));
    metal = mix(metal, metal * SWLM_WARM_COLOR, saturate(warmGate) * SWLM_WARM_AMT);

    // --- Fresnel rim highlight ----------------------------------------------
    // Grazing-angle reflection along the silhouette contour, computed WITHOUT
    // sampling neighbouring pixels so the shader honours `maxSampleOffset:
    // .zero`. The source red channel `pixelEdge` ramps 0 -> 1 across the soft
    // antialiased outline of the silhouette; the product `e * (1 - e)` peaks
    // exactly on that transition band (the contour) and is ~0 in both the
    // solid interior and the empty exterior. That gives a clean rim ring that
    // we brighten toward a cool white.
    float e = saturate(pixelEdge);
    float rim = saturate(SWLM_RIM_GAIN * e * (1.0 - e)) * saturate(fresnel);
    rim *= rim;   // tighten the ring so the rim hugs the very edge
    float3 rimColor = SWLM_RIM_COLOR;   // cool-blue grazing reflection
    metal = mix(metal, rimColor, rim);
    metal += rimColor * rim * SWLM_RIM_GLOW;   // additive glow keeps the blue edge bright on dark frames

    // Dither: break up 8-bit banding / visible block edges on the big smooth gradients.
    float dither = (fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453) - 0.5) * (SWLM_DITHER / 255.0);
    metal += dither;

    return half4(half(metal.r * opacity),
                 half(metal.g * opacity),
                 half(metal.b * opacity),
                 half(opacity));
}
