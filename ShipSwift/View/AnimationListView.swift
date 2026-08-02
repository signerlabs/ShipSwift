//
//  AnimationListView.swift
//  ShipSwift
//
//  Animation tab — showcases all animation components: transitions,
//  change effects, holographic cards, text effects, sweeps, and the
//  full Metal-shader background collection.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

struct AnimationListView: View {
    var body: some View {
        NavigationStack {
            List {
                ComponentNavigationLink {
                    SWTransitionShowcase()
                } label: {
                    ListItem(
                        title: "Transitions",
                        icon: "square.stack.3d.forward.dottedline",
                        description: "16 modern view transitions on the iOS 17 Transition protocol: boing, skid, swoosh, flip, iris, wipe, blinds, clock, glare, dissolve, flicker, film exposure and more."
                    )
                }

                ComponentNavigationLink {
                    SWParticleTransitionShowcase()
                } label: {
                    ListItem(
                        title: "Particle Transitions",
                        icon: "burst",
                        description: "Particle-powered transitions with a self-contained Canvas burst engine: poof smoke cloud, pop ripple with particle flurry, and anvil slam with dust impact."
                    )
                }

                ComponentNavigationLink {
                    SWChangeEffectShowcase()
                } label: {
                    ListItem(
                        title: "Change Effects",
                        icon: "wand.and.rays",
                        description: "Micro-interactions that fire on value changes via KeyframeAnimator: shake, jump, spin, ping rings, heart spray, +1 rise, one-shot shine, and haptics."
                    )
                }

                ComponentNavigationLink {
                    SWHolographicCardShowcase()
                } label: {
                    ListItem(
                        title: "Holographic Cards",
                        icon: "rectangle.portrait.on.rectangle.portrait.angled",
                        description: "Holographic trading-card showcase. Drag a card to tilt its finish across five Metal foil effects: foil, glitter, intense bling, chromatic glass, and polished aluminum."
                    )
                }

                ComponentNavigationLink {
                    SWBeforeAfterSlider(
                        before: Image(.smileBefore),
                        after: Image(.smileAfter)
                    )
                    .padding()
                } label: {
                    ListItem(
                        title: "Before / After Slider",
                        icon: "slider.horizontal.below.rectangle",
                        description: "Draggable image comparison slider with auto-oscillating animation. Supports custom labels, speed, and aspect ratio."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 26) {
                        SWTypewriterText(
                            texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                            animationStyle: .spring
                        )
                        .font(.title3.weight(.semibold))

                        SWTypewriterText(
                            texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                            animationStyle: .blur
                        )
                        .font(.title3.weight(.semibold))

                        SWTypewriterText(
                            texts: ["Hello World", "Welcome Back", "Let's Go"],
                            animationStyle: .spring,
                            gradient: LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .font(.title.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } label: {
                    ListItem(
                        title: "Typewriter Text",
                        icon: "character.cursor.ibeam",
                        description: "Typing and deleting text animation that cycles through strings. Six animation styles: spring, blur, fade, scale, wave, none."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 40) {
                        SWShakingIcon(image: Image(systemName: "apple.logo"), height: 20)
                        SWShakingIcon(image: Image(.smileAfter), height: 100, cornerRadius: 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    ListItem(
                        title: "Shaking Icon",
                        icon: "iphone.radiowaves.left.and.right",
                        description: "Periodically zooms in and shakes side-to-side, mimicking the iOS home-screen jiggle effect. Supports SF Symbols and asset images."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 30) {
                        SWShimmer {
                            Button {} label: {
                                Text("Hello World")
                                    .font(.largeTitle)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        SWShimmer {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.3))
                                .frame(width: 280, height: 120)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    ListItem(
                        title: "Shimmer",
                        icon: "light.max",
                        description: "Translucent light band sweep across any view. Commonly used on buttons, skeleton loaders, or cards to draw attention."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 26) {
                        SWGlowSweep {
                            Text("Start Scan Today")
                                .font(.largeTitle.bold())
                        }

                        SWGlowSweep(baseColor: .accentColor, glowColor: .white, duration: 1.5) {
                            Text("Analyzing...")
                                .font(.title2.bold())
                        }

                        SWGlowSweep(baseColor: .green.opacity(0.7), glowColor: .black) {
                            Text("Processing")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    ListItem(
                        title: "Glow Sweep",
                        icon: "wand.and.rays",
                        description: "Sweeps a glowing highlight band using the original content shape as mask. Ideal for text, icons, and SF Symbols."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 26) {
                        SWLightSweep {
                            Image(.smileAfter)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                        }

                        SWLightSweep(lineWidth: 120, duration: 0.5, cornerRadius: 20) {
                            Image(.smileAfter)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    ListItem(
                        title: "Light Sweep",
                        icon: "light.beacon.max",
                        description: "Gradient light band that sweeps across content in a rounded rectangle. Great for image cards and thumbnails."
                    )
                }

                ComponentNavigationLink {
                    VStack(spacing: 20) {
                        SWScanningOverlay {
                            Image(.facePicture)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        SWScanningOverlay(gridOpacity: 0.1, bandOpacity: 0.1, speed: 3.0) {
                            Image(.facePicture)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    ListItem(
                        title: "Scanning Overlay",
                        icon: "barcode.viewfinder",
                        description: "Grid lines, sweeping scan band, and noise layer overlay. Conveys an analyzing / processing visual effect."
                    )
                }

                ComponentNavigationLink {
                    SWAnimatedMeshGradient()
                        .ignoresSafeArea()
                } label: {
                    ListItem(
                        title: "Animated Mesh Gradient",
                        icon: "circle.hexagongrid.fill",
                        description: "3x3 mesh gradient background that transitions between two color palettes. Designed as a full-screen or section background."
                    )
                }

                ComponentNavigationLink {
                    SWDots(showsControls: true)
                } label: {
                    ListItem(
                        title: "Dots",
                        icon: "circle.grid.3x3.fill",
                        description: "Metal-shader 3D dot-grid backgrounds — switch between styles (wavy, mountains, …) via a single enum. Perspective projection with soft halos, crest highlighting, vignette, and a tunable horizon. Tap the gear in this preview to live-tune every parameter."
                    )
                }

                ComponentNavigationLink {
                    SWStarfield(showsControls: true)
                } label: {
                    ListItem(
                        title: "Starfield",
                        icon: "sparkles",
                        description: "Multi-layer twinkling starfield rendered via a Metal stitchable shader. Per-cell hash places stars, parallax layers drift downward at different speeds, and a sin-driven term twinkles each star. Tap the gear in this preview to live-tune layers, density, star size, twinkle, and colors."
                    )
                }

                ComponentNavigationLink {
                    SWStarNest(showsControls: true)
                } label: {
                    ListItem(
                        title: "Star Nest",
                        icon: "sparkles.rectangle.stack.fill",
                        description: "Volumetric procedural space nebula — a fixed camera flies through a 3D space-folded fractal field, accumulating drifting stars and dark-matter voids per pixel with no texture sampling. Adapted from Pablo Roman Andrioli's classic Star Nest shader (MIT). Heaviest background in the library; use one full-screen instance. Tap the gear to live-tune zoom, speed, nebula color, and quality."
                    )
                }

                ComponentNavigationLink {
                    SWGlassOrb(showsControls: true)
                } label: {
                    ListItem(
                        title: "Glass Orb",
                        icon: "circle.circle",
                        description: "Drag a glass orb filled with its own flowing color gradient — the sphere magnifies and bends its gradient with a spherical barrel warp, ringed by a cool Fresnel rim, an upper-left specular hot-spot, and faint edge RGB dispersion so it reads as a solid glass ball. Adapted from Inferno's Warping Loupe by Paul Hudson (MIT). Tap the gear to live-tune radius, magnification, refraction, edge highlight, dispersion, and color flow."
                    )
                }

                ComponentNavigationLink {
                    SWGlassLogo(showsControls: true)
                } label: {
                    ListItem(
                        title: "Glass Logo",
                        icon: "apple.logo",
                        description: "A frosted-glass SF Symbol (apple.logo by default) glowing on a near-black canvas with flowing cool/warm light trapped inside it. Four composited passes: black canvas, a slowly rotating tri-color MeshGradient with drifting diagonal stripes, the light masked to the symbol and run through a Metal layerEffect (alpha-gradient surface normal → subtle refraction + frosted blur + cool Fresnel rim, clipped to the shape), and a breathing two-layer bloom. Tap the gear to live-tune refraction, frost, thickness, edge softness, Fresnel rim, and flow speed."
                    )
                }

                ComponentNavigationLink {
                    SWGlass(showsControls: true)
                } label: {
                    ListItem(
                        title: "Glass",
                        icon: "drop.halffull",
                        description: "Lay a sheet of refractive glass over any content inside an analytic SDF region (circle or rounded rectangle). The rim bends the background hardest while the centre stays calm, a golden-angle disk frosts the content, the same taps split chromatically for dispersion, and tint, directional edge light, a 3D specular glint and a Fresnel rim finish it off. Tap the gear to live-tune Shape / Glass / Highlight / Fresnel / Tint."
                    )
                }

                ComponentNavigationLink {
                    SWFractalClouds(showsControls: true)
                } label: {
                    ListItem(
                        title: "Fractal Clouds",
                        icon: "cloud.fill",
                        description: "Drifting cumulus-like clouds built from a two-pass 5-octave FBM noise — the first pass warps the second's sample position for soft swirls. Sky / cloud / warm-tint colors, drift velocity, coverage, and warp depth are all tunable. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWInkSmoke(showsControls: true)
                } label: {
                    ListItem(
                        title: "Ink Smoke",
                        icon: "drop.fill",
                        description: "Domain-warped FBM smoke field — drops of ink diffusing through water. Two-stage warp on 5-octave value noise blends four ink colors plus a wispy glow highlight. Heavier per-pixel cost than Fractal Clouds. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWLiquidChrome(showsControls: true)
                } label: {
                    ListItem(
                        title: "Liquid Chrome",
                        icon: "circle.lefthalf.filled",
                        description: "Animated liquid chrome surface — three sequential value-noise samples domain-warp into a fluid metallic flow lit with a gamma curve and a high-power specular glint. Shadow / silver / highlight / tint colors are tunable; the cool spec bias is baked in for true chrome feel. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWPlasma(showsControls: true)
                } label: {
                    ListItem(
                        title: "Plasma",
                        icon: "flame.fill",
                        description: "Full-color plasma backgrounds with five hand-tuned styles — Solar (warm), Prism (chromatic split), Spectrum (vertical split), Ember (glowing coals), Lilac (soft pulsing pastel). Switch styles in the sheet to load each style's signature 5-stop palette."
                    )
                }

                ComponentNavigationLink {
                    SWAnimatedLoop(showsControls: true)
                } label: {
                    ListItem(
                        title: "Animated Loop",
                        icon: "circle.dashed",
                        description: "Pulsing concentric rings in four hand-tuned styles — Shape (5 geometric shapes: circle/square/diamond/hexagon/star), Diamond (L1 distance), Neon (circle + angular wobble), Warp (stretched ellipse). Three RGB channels phase-offset for chromatic-aberration sweep. Tap the gear to switch style and live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWMetaballs(showsControls: true)
                } label: {
                    ListItem(
                        title: "Metaballs",
                        icon: "circle.hexagonpath.fill",
                        description: "Metal-shader metaballs in two styles — Cluster (gooey blobs drifting on randomized radii/speeds/phases, colors blended where they overlap) and Fountain (a big central ball with up to 99 small balls streaming up: about half rise from the bottom and dissolve into it, half leave upward, their colors blending into the big ball like two liquids mixing). Tap the gear to switch style and tune count, ball/big-ball size, speed, and colors."
                    )
                }

                ComponentNavigationLink {
                    SWGrainGradient(showsControls: true)
                } label: {
                    ListItem(
                        title: "Grain Gradient",
                        icon: "circle.grid.cross.fill",
                        description: "Soft tri-color noise gradient with film grain — the 2025-era staple hero background (Apple Music posters, Spotify cards, Linear gradients). Two low-frequency noise samples blend three colors; a per-frame high-frequency hash adds the film grain. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWHalftone(showsControls: true) {
                        Image(.facePicture)
                            .resizable()
                            .scaledToFill()
                    }
                } label: {
                    ListItem(
                        title: "Halftone",
                        icon: "circle.grid.3x3",
                        description: "Halftone image filter — wraps any source view in 4 dot styles (classic / gooey / holes / soft) × 2 grids (square / hex), plus a 4-channel CMYK plate mode. Toggle inverted, original colors, and procedural grain. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWWater(showsControls: true) {
                        Image(.facePicture)
                            .resizable()
                            .scaledToFill()
                    }
                } label: {
                    ListItem(
                        title: "Water",
                        icon: "drop.fill",
                        description: "Water ripple image filter — simplex-noise wave drift + 6-octave rotated caustic distortion warps the source UVs and adds a sunlight-on-pool highlight tint. Tap the gear to live-tune size, caustic, waves, layering, edges, highlights, and colors."
                    )
                }

                ComponentNavigationLink {
                    SWLiquidMetal(showsControls: true) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 300))
                    }
                } label: {
                    ListItem(
                        title: "Liquid Metal",
                        icon: "drop.triangle.fill",
                        description: "Liquid-metal image filter — simplex-noise driven stripe pattern with per-channel chromatic refraction, edge-aware bulge, and flowing chrome over any opaque source view (SF Symbols, logos). Tap the gear to tune refraction, edge, liquid, pattern blur / scale, time scale."
                    )
                }

                ComponentNavigationLink {
                    SWNeuroNoise(showsControls: true)
                } label: {
                    ListItem(
                        title: "Neuro Noise",
                        icon: "waveform.path",
                        description: "Neuro-noise procedural background — 15-layer sine/cosine accumulation with rotated UV creates a glowing organic web of fluid lines. Front / mid / back 3-color palette. Tap the gear to tune palette, brightness, contrast, and speed."
                    )
                }

                ComponentNavigationLink {
                    SWDotOrbit(showsControls: true)
                } label: {
                    ListItem(
                        title: "Dot Orbit",
                        icon: "circle.hexagongrid.fill",
                        description: "Dot-orbit procedural background — Voronoi-cell dots orbiting around their cell centers + rotating individually, mapped onto a 1–10 step-discretized color ramp. Tap the gear to tune palette, dot size / range, orbit spreading, palette steps, and motion."
                    )
                }

                ComponentNavigationLink {
                    SWVoronoi(showsControls: true)
                } label: {
                    ListItem(
                        title: "Voronoi",
                        icon: "hexagon.fill",
                        description: "Voronoi procedural background — animated double-pass Voronoi with anti-aliased edges, 1–5 color cell ramp, optional gap border between cells, and radial inner glow shadow. Tap the gear to tune palette, density, distortion, gap, glow, and motion."
                    )
                }

                ComponentNavigationLink {
                    SWSimplexNoise(showsControls: true)
                } label: {
                    ListItem(
                        title: "Simplex Noise",
                        icon: "swirl.circle.righthalf.filled",
                        description: "Simplex-noise procedural background — two layered 2D simplex noises drive a 1–10 color gradient with stepped smooth transitions and wrap-around seam blending. Tap the gear to tune palette (add/remove colors), scale, steps per color, softness, and motion."
                    )
                }

                ComponentNavigationLink {
                    SWColorPanels(showsControls: true)
                } label: {
                    ListItem(
                        title: "Color Panels",
                        icon: "fan.fill",
                        description: "Color-panels procedural background — pseudo-3D semi-transparent panels rotating around a central vertical axis. 1–7 color palette + edge highlight, skew, side blur, fade-in/out, per-panel gradient mixing. Tap the gear to live-tune all parameters."
                    )
                }

                ComponentNavigationLink {
                    SWSmokeRing(showsControls: true)
                } label: {
                    ListItem(
                        title: "Smoke Ring",
                        icon: "circle.dashed",
                        description: "Smoke-ring procedural background — polar-coordinate ring distorted by two phase-shifted FBM noise layers that cross-fade so the smoke never visibly loops. 1–10 color gradient + tunable radius / thickness / inner fill / noise iterations. Tap the gear to live-tune."
                    )
                }

                ComponentNavigationLink {
                    SWSwirl(showsControls: true)
                } label: {
                    ListItem(
                        title: "Swirl",
                        icon: "hurricane",
                        description: "Swirl procedural background — polar-coordinate angle bands twisted into spirals via `pow(length, -twist)`, folded to a triangular wave, mapped onto a 1–10 color anti-aliased gradient with optional simplex-noise distortion. Tap the gear to tune bands / twist / center / proportion / softness / noise / motion."
                    )
                }

                ComponentNavigationLink {
                    SWDotSphere(showsControls: true)
                } label: {
                    ListItem(
                        title: "Dot Sphere",
                        icon: "globe.americas.fill",
                        description: "Canvas-rendered rotating 3D dot sphere — N dots distributed via spherical Fibonacci / Vogel spiral, optional morph between random 3D cloud and even sphere, one-axis perspective projection, palette cross-fade waves up the sphere. Tap the gear to tune palette, dot count / size, morph, rotation, and fade timing."
                    )
                }

                ComponentNavigationLink {
                    SWCharSphere(showsControls: true)
                } label: {
                    ListItem(
                        title: "Char Sphere",
                        icon: "character.bubble.fill",
                        description: "Canvas-rendered rotating 3D glyph sphere — any text (1 char tiles, multi-char rotates) drawn at each spherical Fibonacci point with perspective-scaled font, back-face culling, palette cross-fade waves up the sphere. Tap the gear to edit text, weight, glyph count, font size, palette, morph, rotation, and fade."
                    )
                }

                ComponentNavigationLink {
                    SWConfettiShowcase()
                } label: {
                    ListItem(
                        title: "Confetti",
                        icon: "party.popper",
                        description: "Celebration confetti burst overlay with Canvas-rendered particles at 60fps. Toggle between classic confetti and a Marina Bay Sands fireworks show with launch trails, blur glow, and water reflections."
                    )
                }

                ComponentNavigationLink {
                    VStack {
                        SWOrbitingLogos(
                            images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                        ) {
                            Image(.fullpackLogo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .offset(y: -5)
                        }

                        SWOrbitingLogos(
                            images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                        ) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 50, height: 50)
                        }
                        .frame(width: 150)
                    }
                } label: {
                    ListItem(
                        title: "Orbiting Logos",
                        icon: "atom",
                        description: "SpriteKit-powered concentric rings of colored dots with icons on the outermost ring. Custom center view via SwiftUI."
                    )
                }

                // Full-Screen Button — iOS 18 zoom transition; unavailable on macOS.
                #if os(iOS)
                ComponentNavigationLink {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Default — reproduces the original showcase look
                            SWFullScreenButton()

                            Divider()

                            // Custom copy and palette — pink / purple gradient
                            SWFullScreenButton(
                                title: "SmileMax",
                                subtitle: "Daily smile analytics",
                                footer: "Open",
                                gradientColors: [.pink, .purple]
                            )

                            Divider()

                            // Warm gradient + tighter corner radius
                            SWFullScreenButton(
                                title: "FullPack",
                                subtitle: "Pack smart, travel light",
                                footer: "Launch",
                                gradientColors: [.orange, .yellow],
                                cornerRadius: 24
                            )
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                } label: {
                    ListItem(
                        title: "Full-Screen Button",
                        icon: "rectangle.expand.vertical",
                        description: "Tappable card with App Store / Photos style zoom transition — the card geometry-matches into a true full-screen view via iOS 18 `.navigationTransition(.zoom)`. Configurable title, subtitle, footer, gradient, and corner radius."
                    )
                }
                #endif
            }
            .navigationTitle("tab.animation")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

// MARK: - Preview

#Preview {
    AnimationListView()
}
