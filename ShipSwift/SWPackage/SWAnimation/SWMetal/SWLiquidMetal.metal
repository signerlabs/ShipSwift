//
//  SWLiquidMetal.metal
//  ShipSwift
//
//  Stitchable SwiftUI layerEffect — a flowing chromatic liquid-metal
//  effect. Wraps any view (typically an SF Symbol) in animated metal:
//  simplex noise drives a stripe-pattern color split with refraction,
//  edge-aware bulge, and per-channel chromatic shift. Layer size is
//  sourced from the `boundingRect` parameter for portability across
//  SwiftUI shader APIs.
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

constant float SWLM_PI = 3.14159265358979323846;
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

// --- Top-down lighting -------------------------------------------------------
// Light comes from above. TOPDOWN_FLOOR is how dark the very bottom gets in the
// low-frequency field (smaller = darker bottom); TOPDOWN_LIFT lifts it back up
// a touch so it never dies to pure black.
constant float  SWLM_TOPDOWN_FLOOR = 0.55;  // bottom darkening factor in lowField (smaller = darker bottom)
constant float  SWLM_TOPDOWN_LIFT  = 0.05;  // floor lift so bottom never goes pure black (bigger = brighter bottom)

// --- Low-frequency block field (the big bright body) -------------------------
// FLOW_AXIS = the tilted direction the big highlight sweeps along (the diagonal
//   of the reflection). Rotate it to change which way the light streaks.
// RAMP_LO/RAMP_HI = the monotonic bright ramp span along that axis. Widen the
//   gap (lower LO / raise HI) for a softer, longer gradient; narrow it for a
//   harder light/dark split. LO more negative = bigger bright body.
// BRIGHT_LO/BRIGHT_HI = how much of the value range counts as "lit silver".
//   Lower both to make the bright body claim MORE of the logo (less shadow).
// CORE_LO/CORE_HI = the hottest specular core window.
// FLOW_SPEED = how fast the big reflection slides diagonally (bigger = faster).
// NOISE_WOBBLE = how much noise bends the otherwise-straight light edge.
constant float2 SWLM_FLOW_AXIS   = float2(0.62, 0.78);  // direction the bright bar sweeps along (rotate to re-aim)

// --- Rectangular sweep bar (THE bright block) — minimal: one bar, back & forth
constant float  SWLM_FIELD_SCALE = 1.1;   // scale of the big light/dark blocks — SMALLER = BIGGER blocks (~1 = one big bright block + one big shadow across the logo)
constant float  SWLM_FLOW_DRIFT  = 0.6;   // one-way flow speed of the big blocks (bigger = faster continuous drift)
// (block contrast = SWLM_BRIGHT_LO / SWLM_BRIGHT_HI below; flow direction = SWLM_FLOW_AXIS above)

// (Legacy organic-field params below are now UNUSED — kept until the look is locked, then cleaned.)
constant float  SWLM_RAMP_LO     = -0.15;  // ramp start (more negative = larger bright body)
constant float  SWLM_RAMP_HI     = 0.95;   // ramp end   (closer to LO = harder light/dark edge)
constant float  SWLM_BRIGHT_LO   = 0.34;   // bright-zone threshold low  (lower = more of logo is lit)
constant float  SWLM_BRIGHT_HI   = 0.66;   // bright-zone threshold high (closer to LO = harder edge)
constant float  SWLM_CORE_LO     = 0.66;   // specular core threshold low
constant float  SWLM_CORE_HI     = 0.95;   // specular core threshold high
constant float  SWLM_FIELD_BASE  = 0.30;   // baseline brightness of the field (bigger = brighter overall)
constant float  SWLM_FIELD_RAMP_W= 0.58;   // weight of the bright ramp (bigger = stronger body/shadow split)
constant float  SWLM_FIELD_N1_W  = 0.16;   // weight of coarse noise blob (bigger = more organic variation)
constant float  SWLM_FIELD_N2_W  = 0.08;   // weight of finer noise blob
constant float  SWLM_OUT_BASE    = 0.05;   // lowField output floor (bigger = shadows never as deep)
constant float  SWLM_OUT_BRIGHT_W= 0.82;   // bright body contribution to output
constant float  SWLM_OUT_CORE_W  = 0.28;   // specular core contribution to output
constant float  SWLM_FLOW_SPEED  = 0.26;   // diagonal slide speed of the big reflection (bigger = faster)
constant float  SWLM_NOISE_WOBBLE= 0.16;   // how much noise bends the light edge (bigger = wavier)
constant float  SWLM_FIELD_N1_FREQ = 1.15; // coarse blob frequency (bigger = smaller blobs)
constant float  SWLM_FIELD_N2_FREQ = 2.30; // finer blob frequency

// --- Non-radial bulge modulator ----------------------------------------------
// Soft directional quantity used by the stripe path. BULGE_BASE/BULGE_AMP build
// it from one big noise blob (NOT a radial distance, so no concentric ring).
// Bigger AMP = more contrast in the stripe modulation.
constant float  SWLM_BULGE_BASE  = 0.5;    // bulge midpoint
constant float  SWLM_BULGE_AMP   = 0.45;   // bulge swing from noise (bigger = stronger stripe modulation)
constant float  SWLM_BULGE_FREQ  = 1.3;    // bulge blob frequency
constant float  SWLM_BULGE_FLOW  = 0.11;   // bulge blob drift speed

// --- Stripe vs. block blend --------------------------------------------------
// blockMix = saturate(1 - FADE * (patternScale - PIVOT)). At/below PIVOT the
// output is the pure non-radial block field (no stripe residue, no arcs); above
// it the periodic stripes fade back in. Raise FADE to kill stripes sooner.
constant float  SWLM_BLOCK_FADE  = 0.80;   // how fast stripes fade out as scale drops (bigger = block wins sooner)
constant float  SWLM_BLOCK_PIVOT = 0.55;   // patternScale at/below which it's pure block field

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

static float2 swLM_rotate(float2 uv, float th) {
    float2x2 m = float2x2(cos(th), sin(th), -sin(th), cos(th));
    return m * uv;
}

// Soft alpha falloff at the layer's outer 10%.
static float swLM_imgFrameAlpha(float2 uv, float frameWidth) {
    float f = smoothstep(0.0, frameWidth, uv.x)
            * smoothstep(1.0, 1.0 - frameWidth, uv.x);
    f *= smoothstep(0.0, frameWidth, uv.y)
       * smoothstep(1.0, 1.0 - frameWidth, uv.y);
    return f;
}

// Per-channel color resolver. Threads the
// stripe pattern through 5 alternating smoothstep bands plus a trailing
// gradient. `c1` / `c2` are the two endpoint colors (light vs. dark),
// `stripePos` is the wrapped UV along the stripe direction, `w` packs
// the stripe widths, `extraBlur` lets the caller widen the per-channel
// band edge for chromatic split, and `bulge` modulates which bands the
// stripe enters.
//
// `bandSoftness` (>= 1.0) scales the per-edge blur on top of `patternBlur`,
// pushing the look away from crisp stripes toward the broad, smooth
// reflection bands of polished metal: at high softness adjacent bands melt
// into one another, leaving a few wide highlight/shadow sweeps instead of
// many thin lines.
static float swLM_getColorChannel(float c1, float c2,
                                  float stripePos,
                                  float3 w,
                                  float extraBlur,
                                  float bulge,
                                  float patternBlur,
                                  float bandSoftness) {
    float ch = c2;
    float blur = (patternBlur + extraBlur) * bandSoftness;

    // As bandSoftness rises the two interior alternation segments collapse:
    // their target colors are pulled toward the mid-tone so they no longer
    // form their own crisp light/dark stripes. At softness 1.0 this is a no-op
    // (`merge` == 0) and the original 5-band stripe behavior is preserved; at
    // high softness the cycle melts into a single broad highlight sweep that
    // fades smoothly back to shadow — large polished-mercury blobs instead of
    // thin lines.
    float merge = smoothstep(1.0, 5.0, bandSoftness);
    float mid   = mix(c1, c2, 0.5);
    float c1m   = mix(c1, mid, merge);   // softened "light" interior segment
    float c2m   = mix(c2, mid, merge);   // softened "dark"  interior segment

    ch = mix(ch, c1, smoothstep(0.0, blur, stripePos));

    float border = w[0];
    ch = mix(ch, c2m, smoothstep(border - blur, border + blur, stripePos));

    float b = smoothstep(0.2, 0.8, bulge);
    border = w[0] + 0.4 * (1.0 - b) * w[1];
    ch = mix(ch, c1m, smoothstep(border - blur, border + blur, stripePos));

    border = w[0] + 0.5 * (1.0 - b) * w[1];
    ch = mix(ch, c2m, smoothstep(border - blur, border + blur, stripePos));

    border = w[0] + w[1];
    ch = mix(ch, c1, smoothstep(border - blur, border + blur, stripePos));

    float gradientT = (stripePos - w[0] - w[1]) / w[2];
    float gradient  = mix(c1, c2, smoothstep(0.0, 1.0, gradientT));
    ch = mix(ch, gradient, smoothstep(border - blur, border + blur, stripePos));
    return ch;
}

// Large-scale, NON-periodic, DIRECTIONAL light/dark field. This is the
// antidote to the repeating diagonal stripes — and, critically, it contains
// NO radial term: an earlier version fed the radial `bulge` (a function of the
// distance to center) into this field, which printed an obvious concentric
// dark ring/ellipse right through the middle of the logo. That radial input is
// gone. Instead the field is built purely from big simplex blobs plus one wide
// highlight sweep that travels along a tilted axis, like the polished metal
// reflecting one bright window drifting across a dark room. Returns a 0..1
// brightness with no repetition and no concentric structure whatsoever.
//
// `flow` (the animation time) slowly drifts the blobs and slides the highlight
// sweep so the big reflections creep diagonally like mercury.
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
                                     float  refraction,    // 0..0.06 reasonable
                                     float  edge,          // 0..1 edge sharpness
                                     float  liquid,        // 0..1 noise strength
                                     float  patternBlur,   // 0..0.05 band softness
                                     float  patternScale,  // 1..10 stripe density
                                     float  timeScale,     // 0..2 animation rate
                                     float  coolTint,      // 0..1 cool blue ambient bounce
                                     float  fresnel,       // 0..1 rim highlight strength
                                     float  bandSoftness) {// 1..8 broad-band reflection blur
    float2 sz = boundingRect.zw;
    float2 uvRaw = position / max(sz, float2(1.0));
    float2 uv = uvRaw;

    half4 img = layer.sample(position);
    if (img.a == 0.0) {
        return img;
    }

    // Core shader.
    float diagonal = uv.x - uv.y;
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

    // NON-radial "bulge" modulator. The old version derived this from
    // `length(uv - center)` rotated by `swLM_rotate`, i.e. a tilted concentric
    // ellipse — that is exactly what printed the regular C-shaped crescent of
    // shadow down the left side of the logo. There is now NO distance-to-center
    // and NO rotation: `bulge` is a smooth low-frequency directional quantity
    // built from a big simplex blob plus a top-down ramp, so every downstream
    // `* bulge` term modulates softly along a flowing diagonal instead of along
    // a symmetric ring. `gradUV` keeps a plain (un-rotated) centered coordinate
    // only as a directional axis for the stripe `dir`.
    float2 gradUV = uv - 0.5;
    float blobLow = swLM_snoise(uv * SWLM_BULGE_FREQ + float2(SWLM_BULGE_FLOW * t, -0.08 * t));
    float bulge = SWLM_BULGE_BASE + SWLM_BULGE_AMP * blobLow;  // ~0..1, organic, non-radial
    bulge = mix(bulge, bulge * pow(uv.y, 0.3), 0.6);  // gently lit-from-above

    // Band layout. Widened from the original thin-stripe ratios so that each
    // cycle is dominated by one broad highlight sweep with a softer, wider
    // secondary band — the look of a few large curved reflections rather than
    // many crisp lines. The remaining `wideRatio` carries the long smooth
    // gradient back down into shadow.
    float cycleWidth = max(patternScale, 1e-4);
    float thin1Ratio = 0.30 / cycleWidth * (1.0 - 0.4 * bulge);
    float thin2Ratio = 0.22 / cycleWidth * (1.0 + 0.4 * bulge);
    float wideRatio  = 1.0 - thin1Ratio - thin2Ratio;
    float thin1Width = cycleWidth * thin1Ratio;
    float thin2Width = cycleWidth * thin2Ratio;

    float opacity = 1.0 - smoothstep(0.9 - 0.5 * saturate(edge),
                                     1.0 - 0.5 * saturate(edge), pixelEdge);
    opacity *= swLM_imgFrameAlpha(uvRaw, 0.1);

    float noise = swLM_snoise(uv - float2(t, t));
    // liquid edge-noise distortion REMOVED — it animated the silhouette mask as
    // a second moving layer on top of the blob. Edge mask is now static so only
    // the blob animates. (`noise` is still used by the legacy stripe path below.)

    float refr = clamp(1.0 - bulge, 0.0, 1.0);
    float dir = gradUV.x + diagonal;
    dir -= 2.0 * noise * diagonal *
           (smoothstep(0.0, 1.0, pixelEdge) * smoothstep(1.0, 0.0, pixelEdge));
    bulge *= clamp(pow(uv.y, 0.1), 0.3, 1.0);
    dir *= (0.1 + (1.1 - pixelEdge) * bulge);
    dir *= smoothstep(1.0, 0.7, pixelEdge);
    dir += 0.18 * (smoothstep(0.1, 0.2, uv.y) * smoothstep(0.4, 0.2, uv.y));
    dir += 0.03 * (smoothstep(0.1, 0.2, 1.0 - uv.y) *
                   smoothstep(0.4, 0.2, 1.0 - uv.y));
    dir *= (0.5 + 0.5 * pow(uv.y, 2.0));
    dir *= cycleWidth;
    dir -= t;

    // Per-channel chromatic split. WWDC-style liquid metal is a near-neutral
    // cool silver with almost no rainbow dispersion, so the old strong local
    // amplifiers (the `5.0 *` red kick in particular) that fanned the R/B
    // channels apart into visible red/green/blue stripes have been tamed to a
    // tiny fraction. With the default `refraction` near zero the three channels
    // sample the band table at essentially the same position, collapsing the
    // colored fringes into a single neutral metal tone.
    float refr_r = refr + 0.03 * bulge * noise;
    float refr_b = 1.3 * refr;
    refr_r += 0.4 *
              (smoothstep(-0.1, 0.2, uv.y) * smoothstep(0.5, 0.1, uv.y)) *
              (smoothstep( 0.4, 0.6, bulge) * smoothstep(1.0, 0.4, bulge));
    refr_r -= diagonal;
    refr_b += (smoothstep(0.0, 0.4, uv.y) * smoothstep(0.8, 0.1, uv.y)) *
              (smoothstep(0.4, 0.6, bulge) * smoothstep(0.8, 0.4, bulge));
    refr_b -= 0.2 * pixelEdge;
    refr_r *= saturate(refraction);
    refr_b *= saturate(refraction);

    float3 w = float3(thin1Width, thin2Width, wideRatio);
    w[1] -= 0.02 * smoothstep(0.0, 1.0, pixelEdge + bulge);

    float softness = max(bandSoftness, 1.0);
    float stripe_r = fract(dir + refr_r);
    float r = swLM_getColorChannel(color1.r, color2.r, stripe_r, w,
                                   0.02 + 0.03 * saturate(refraction) * bulge,
                                   bulge, patternBlur, softness);
    float stripe_g = fract(dir);
    float g = swLM_getColorChannel(color1.g, color2.g, stripe_g, w,
                                   0.01 / max(1.0 - diagonal, 1e-4),
                                   bulge, patternBlur, softness);
    float stripe_b = fract(dir - refr_b);
    float b = swLM_getColorChannel(color1.b, color2.b, stripe_b, w,
                                   0.01, bulge, patternBlur, softness);

    float3 metal = float3(r, g, b);

    // --- Large-scale block reflection ---------------------------------------
    // Blend the periodic stripe result toward the non-periodic low-frequency
    // field. The smaller `patternScale` is, the more the look is governed by
    // the big block field rather than the wrapping stripes — at the default
    // sub-1.0 scale the logo reads as 2-3 large smooth reflection blobs (bright
    // body + dark zone + cool shoulder) with the stripes contributing only a
    // faint moving texture, killing the diagonal "brushed metal" repetition.
    float lowF = swLM_lowField(uv, topDown, t);
    float3 blockColor = mix(color2, color1, lowF);
    // At/near the default sub-1.0 scale this is essentially 1.0, i.e. the
    // output is the pure non-radial block field with no stripe residue — so the
    // remaining stripe path (which still carries `bulge`) cannot bleed any
    // ellipse/arc through. Raising patternScale fades the stripes back in.
    // Pure block field. The periodic stripe path is fully replaced here — it was
    // the source of the thin "strand" structures. Only the big flowing blocks.
    metal = blockColor;

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
