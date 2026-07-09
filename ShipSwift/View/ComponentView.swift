//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab — showcases all component categories:
//  Module, Animation, Chart, Display, Feedback, and Input.
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI
import Charts

/// Sidebar categories for the macOS NavigationSplitView layout.
enum ComponentSection: String, CaseIterable, Identifiable {
    case module = "Module"
    case animation = "Animation"
    case chart = "Chart"
    case display = "Display"
    case feedback = "Feedback"
    case input = "Input"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .module: "square.3.layers.3d"
        case .animation: "sparkles"
        case .chart: "chart.bar"
        case .display: "rectangle.on.rectangle"
        case .feedback: "bell"
        case .input: "keyboard"
        }
    }
}

struct ComponentView: View {
    @Binding var scrollTarget: String?

    // Input section state
    @State private var selectedInputTab = 0
    @State private var stepperValue = 1
    @State private var searchBarText = ""

    // Display section state
    @State private var showAddSheet = false


    // Chart section state
    @State private var donutSelectedCategory: String? = nil

    // macOS sidebar selection
    #if os(macOS)
    private enum MacSidebarItem: Hashable {
        case home
        case section(ComponentSection)
    }

    @State private var selectedMacItem: MacSidebarItem? = .home

    /// Maps HomeView's tab-string binding to the macOS sidebar selection,
    /// using scrollTarget to determine the correct component section.
    private var homeTabBinding: Binding<String> {
        Binding(
            get: { "home" },
            set: { newValue in
                guard newValue == "component" else { return }
                switch scrollTarget {
                case "animation": selectedMacItem = .section(.animation)
                case "chart":     selectedMacItem = .section(.chart)
                case "display":   selectedMacItem = .section(.display)
                case "feedback":  selectedMacItem = .section(.feedback)
                case "input":     selectedMacItem = .section(.input)
                default:          selectedMacItem = .section(.module)
                }
            }
        )
    }
    #endif

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    // MARK: - iOS Body

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    moduleSection
                    animationSection
                    chartSection
                    displaySection
                    feedbackSection
                    inputSection
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    // Reset after scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        scrollTarget = nil
                    }
                }
            }
            .navigationTitle("Components")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ComponentNavigationLink {
                        SettingView()
                            .hideTabBar()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
    #endif

    // MARK: - macOS Body

    #if os(macOS)
    private var macOSBody: some View {
        NavigationSplitView {
            List(selection: $selectedMacItem) {
                Label("ShipSwift", systemImage: "house.fill")
                    .tag(MacSidebarItem.home)

                Section("Components") {
                    ForEach(ComponentSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(MacSidebarItem.section(section))
                    }
                }
            }
            .navigationTitle("ShipSwift")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selectedMacItem {
            case .home, nil:
                HomeView(selectedTab: homeTabBinding, scrollTarget: $scrollTarget)
            case .section(let section):
                NavigationStack {
                    Group {
                        switch section {
                        case .module: List { moduleSection }
                        case .animation: List { animationSection }
                        case .chart: List { chartSection }
                        case .display: List { displaySection }
                        case .feedback: List { feedbackSection }
                        case .input: List { inputSection }
                        }
                    }
                    .navigationTitle(section.rawValue)
                    .toolbarBackground(.hidden, for: .windowToolbar)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            ComponentNavigationLink {
                                SettingView()
                            } label: {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
    #endif

    // MARK: - Module Section

    private var moduleSection: some View {
        Section {
            // Auth demo — renders SWAuthView (iOS or macOS version automatically)
            ComponentNavigationLink {
                SWAuthView(isDemo: true)
                    .environment(SWUserManager(skipAuthCheck: true))
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Auth",
                    icon: "person.badge.key.fill",
                    description: "Complete auth flow: email sign-in/up, phone sign-in with country code picker, verification code, forgot/reset password, Apple & Google social sign-in."
                )
            }

            // Camera demo — iOS only
            #if os(iOS)
            ComponentNavigationLink {
                ComponentViewCameraDemo()
                    .swAlert()
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Camera",
                    icon: "camera.fill",
                    description: "Full camera capture view with viewfinder overlay, pinch-to-zoom, zoom slider, photo library picker, and permission handling."
                )
            }

            // Face Camera demo — iOS only
            ComponentNavigationLink {
                ComponentViewFaceCameraDemo()
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Face Camera",
                    icon: "face.smiling.inverse",
                    description: "Camera with real-time Vision face landmark detection, front/back switching, landmark overlay toggle, and configurable color schemes."
                )
            }
            #endif

            // Paywall — Pro paywall with lifetime purchase
            ComponentNavigationLink {
                SWPaywallView(isDemo: true)
                    .environment(SWStoreManager.shared)
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Paywall",
                    icon: "creditcard.fill",
                    description: "Pro paywall with lifetime purchase, feature list, restore purchases, and sign-in for API key management."
                )
            }

            // Chat demo — iOS only
            #if os(iOS)
            ComponentNavigationLink {
                ComponentViewChatDemo()
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Chat",
                    icon: "bubble.left.and.bubble.right.fill",
                    description: "Chat interface with message bubbles, text input, voice recording waveform, and simple echo response simulation."
                )
            }
            #endif

            // TikTok Tracking demo — iOS only
            #if os(iOS)
            ComponentNavigationLink {
                SWTikTokTrackingView()
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "TikTok Tracking",
                    icon: "chart.bar.xaxis.ascending",
                    description: "TikTok App Events SDK with ATT permission flow and event tracking for ad attribution."
                )
            }
            #endif

            // Subject Lifting demo — iOS only
            #if os(iOS)
            ComponentNavigationLink {
                SWSubjectLiftingView()
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Subject Lifting",
                    icon: "person.and.background.dotted",
                    description: "Background removal using VisionKit ImageAnalyzer. Capture or pick a photo to extract the primary subject."
                )
            }
            #endif

            // Settings module
            ComponentNavigationLink {
                SWSettingView(isDemo: true)
                    .hideTabBar()
            } label: {
                ListItem(
                    title: "Setting",
                    icon: "gearshape.fill",
                    description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                )
            }
        } header: {
            #if os(iOS)
            Text("Module")
                .font(.title3.bold())
                .textCase(nil)
                .id("module")
            #endif
        }
    }

    // MARK: - Animation Section

    private var animationSection: some View {
        Section {
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
        } header: {
            #if os(iOS)
            Text("Animation")
                .font(.title3.bold())
                .textCase(nil)
                .id("animation")
            #endif
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        Section {
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let salesData: [SWLineChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWLineChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 40...90), category: "Revenue"),
                                    .init(date: date, value: Double.random(in: 20...60), category: "Cost"),
                                ]
                            }

                            SWLineChart(
                                dataPoints: salesData,
                                colorMapping: ["Revenue": .blue, "Cost": .red],
                                title: "Revenue vs Cost"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let tempData: [SWLineChart<String>.DataPoint] = (0..<10).map { dayOffset in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return .init(date: date, value: Double.random(in: 35.5...38.5), category: "Temperature")
                            }

                            SWLineChart(
                                dataPoints: tempData,
                                colorMapping: ["Temperature": .orange],
                                referenceLines: [
                                    .init(value: 37.0, label: "Normal", color: .green),
                                    .init(value: 38.0, label: "Fever", color: .red),
                                ],
                                interpolationMethod: .catmullRom,
                                showPointMarkers: true,
                                yDomain: 35...40,
                                visibleDays: 10,
                                chartHeight: 220,
                                title: "Body Temperature"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Line Chart",
                    icon: "chart.xyaxis.line",
                    description: "Multi-series line chart with horizontal scrolling, reference lines, point markers, and configurable interpolation methods."
                )
            }

            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let salesData: [SWBarChart<String>.DataPoint] = (0..<10).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 50...150), category: "Online"),
                                    .init(date: date, value: Double.random(in: 30...100), category: "Offline"),
                                ]
                            }

                            SWBarChart(
                                dataPoints: salesData,
                                colorMapping: ["Online": .blue, "Offline": .orange],
                                title: "Sales by Channel (Grouped)"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let stackedData: [SWBarChart<String>.DataPoint] = (0..<7).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 30...80), category: "Food"),
                                    .init(date: date, value: Double.random(in: 20...50), category: "Transport"),
                                    .init(date: date, value: Double.random(in: 10...40), category: "Entertainment"),
                                ]
                            }

                            SWBarChart(
                                dataPoints: stackedData,
                                colorMapping: ["Food": .green, "Transport": .blue, "Entertainment": .purple],
                                stackMode: .stacked,
                                yDomain: 0...200,
                                visibleDays: 7,
                                chartHeight: 250,
                                title: "Daily Expenses (Stacked)"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Bar Chart",
                    icon: "chart.bar.fill",
                    description: "Grouped or stacked bar chart with horizontal scrolling, optional value labels, and configurable bar corner radius."
                )
            }

            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let trafficData: [SWAreaChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 100...300), category: "Organic"),
                                    .init(date: date, value: Double.random(in: 50...200), category: "Paid"),
                                ]
                            }

                            SWAreaChart(
                                dataPoints: trafficData,
                                colorMapping: ["Organic": .green, "Paid": .blue],
                                gradientOpacity: 0.25,
                                title: "Website Traffic"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let revenueData: [SWAreaChart<String>.DataPoint] = (0..<10).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 40...120), category: "Product A"),
                                    .init(date: date, value: Double.random(in: 30...80), category: "Product B"),
                                    .init(date: date, value: Double.random(in: 20...60), category: "Product C"),
                                ]
                            }

                            SWAreaChart(
                                dataPoints: revenueData,
                                colorMapping: ["Product A": .purple, "Product B": .orange, "Product C": .cyan],
                                stackMode: .stacked,
                                gradientOpacity: 0.4,
                                yDomain: 0...300,
                                visibleDays: 10,
                                chartHeight: 240,
                                title: "Revenue by Product (Stacked)"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Area Chart",
                    icon: "chart.line.uptrend.xyaxis",
                    description: "Standard or stacked area chart with smooth interpolation, optional line overlay, and configurable area opacity."
                )
            }

            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let sampleData: [SWScatterChart<String>.DataPoint] = [
                                .init(date: calendar.date(byAdding: .hour, value: 8, to: today)!, value: 85, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 52, category: "Food"),
                                .init(date: calendar.date(byAdding: .hour, value: 18, to: today)!, value: 78, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 72, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .hour, value: -18, to: today)!, value: 65, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 90, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 45, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 88, category: "Teeth"),
                            ]

                            SWScatterChart(
                                dataPoints: sampleData,
                                colorMapping: ["Teeth": .blue, "Food": .orange],
                                title: "Scan Trends"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let temperatureData: [SWScatterChart<String>.DataPoint] = [
                                .init(date: calendar.date(byAdding: .hour, value: 6, to: today)!, value: 36.2, category: "Morning"),
                                .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 36.8, category: "Noon"),
                                .init(date: calendar.date(byAdding: .hour, value: 20, to: today)!, value: 37.1, category: "Evening"),
                                .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 36.5, category: "Morning"),
                            ]

                            SWScatterChart(
                                dataPoints: temperatureData,
                                colorMapping: ["Morning": .cyan, "Noon": .yellow, "Evening": .purple],
                                yDomain: 35...40,
                                visibleDays: 5,
                                chartHeight: 200,
                                title: "Body Temperature"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Scatter Chart",
                    icon: "chart.dots.scatter",
                    description: "Horizontally scrollable scatter chart with generic category types, color mapping, and configurable axis ranges."
                )
            }

            ComponentNavigationLink {
                SWDonutChart(
                    subjects: {
                        let work = SWDonutChart.Category(name: "Work")
                        let personal = SWDonutChart.Category(name: "Personal")
                        let health = SWDonutChart.Category(name: "Health")
                        return [
                            .init(name: "Meeting", category: work),
                            .init(name: "Report", category: work),
                            .init(name: "Email", category: work),
                            .init(name: "Shopping", category: personal),
                            .init(name: "Reading", category: personal),
                            .init(name: "Exercise", category: health),
                            .init(name: "Meditation", category: health),
                            .init(name: "Running", category: health),
                            .init(name: "Uncategorized Task", category: nil),
                        ]
                    }(),
                    selectedCategory: $donutSelectedCategory
                )
                .padding()
            } label: {
                ListItem(
                    title: "Donut Chart",
                    icon: "chart.pie.fill",
                    description: "Interactive donut chart with tap-to-select categories. Selected segment expands with center overlay showing count and name."
                )
            }

            ComponentNavigationLink {
                SWRadarChart(data: [
                    .init(label: "Tolerance", value: 75),
                    .init(label: "Ambition", value: 50),
                    .init(label: "Acuity", value: 50),
                    .init(label: "Creativity", value: 85),
                    .init(label: "Stability", value: 85)
                ])
                .padding(100)
            } label: {
                ListItem(
                    title: "Radar Chart",
                    icon: "pentagon",
                    description: "Animated radar (spider) chart with axis labels, grid rings, and radial lines. Supports 3+ axes with customizable max value."
                )
            }

            ComponentNavigationLink {
                VStack(spacing: 40) {
                    SWRingChart(data: [
                        .init(label: "Move", value: 75, color: .red),
                        .init(label: "Exercise", value: 50, color: .green),
                        .init(label: "Stand", value: 90, color: .cyan)
                    ]) {
                        VStack {
                            Image(systemName: "flame.fill")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text("Activity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    SWRingChart(
                        data: [
                            .init(label: "Partner", value: 80, color: .accentColor),
                            .init(label: "Family", value: 91, color: .green),
                            .init(label: "Social", value: 63, color: .orange)
                        ],
                        size: 200,
                        ringWidth: 20,
                        spacing: 8
                    )
                }
                .padding()
            } label: {
                ListItem(
                    title: "Ring Chart",
                    icon: "circle.circle",
                    description: "Apple Watch Activity Rings style concentric ring progress chart. Supports custom center content, dimensions, and animated appear."
                )
            }

            ComponentNavigationLink {
                let timestamps: [Date] = {
                    var dates: [Date] = []
                    let calendar = Calendar.current
                    let today = Date()
                    for i in 0..<60 {
                        if Int.random(in: 0...100) < 70 {
                            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                                let count = Int.random(in: 1...3)
                                for _ in 0..<count {
                                    dates.append(date)
                                }
                            }
                        }
                    }
                    return dates
                }()

                NavigationStack {
                    Form {
                        Section {
                            SWActivityHeatmap.StreakCard(
                                streaks: timestamps,
                                colors: [.blue, .purple]
                            )
                        }
                        .listRowInsets(EdgeInsets())

                        Section {
                            SWActivityHeatmap.HeatmapGrid(
                                timestamps: timestamps,
                                days: 60,
                                baseColor: .green
                            )
                        } header: {
                            Text("Past 60 days")
                        } footer: {
                            SWActivityHeatmap.HeatmapLegend(
                                baseColor: .green
                            )
                        }
                    }
                    .navigationTitle("Activity")
                }
            } label: {
                ListItem(
                    title: "Activity Heatmap",
                    icon: "square.grid.3x3.fill",
                    description: "GitHub-style activity heatmap with streak tracking. Includes StreakCard, HeatmapGrid, HeatmapLegend sub-components."
                )
            }

            ComponentNavigationLink {
                SWNetworkGraph(
                    nodes: SWNetworkGraphData.nodes,
                    edges: SWNetworkGraphData.edges
                )
                .ignoresSafeArea()
            } label: {
                ListItem(
                    title: "Network Graph",
                    icon: "point.3.connected.trianglepath.dotted",
                    description: "Interactive 3D dependency graph on a single Canvas — drag to orbit, pinch to zoom, tap a dot to highlight its full prerequisite lineage with camera focus, plus a group-filter sheet and a native detail sheet. Ships with the open Marble curriculum dataset (1,590 topics)."
                )
            }
        } header: {
            #if os(iOS)
            Text("Chart")
                .font(.title3.bold())
                .textCase(nil)
                .id("chart")
            #endif
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        Section {
            // Floating labels — animated capsule labels hovering over an image
            ComponentNavigationLink {
                SWFloatingLabels(
                    image: Image(.facePicture),
                    labels: [
                        .init(text: "Teeth mapping",    position: CGPoint(x: 0.3, y: 0.5)),
                        .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
                        .init(text: "Shape & balance",  position: CGPoint(x: 0.5, y: 0.8))
                    ]
                )
            } label: {
                ListItem(
                    title: "Floating Labels",
                    icon: "tag.fill",
                    description: "Animated floating capsule labels over an image. Labels fade in/out at specified positions, ideal for feature callouts."
                )
            }

            // Scrolling FAQ — iOS only (UIScrollView + CADisplayLink)
            #if os(iOS)
            ComponentNavigationLink {
                SWScrollingFAQ(
                    rows: [
                        ["How does AI work?", "What can I ask?", "How accurate?", "Help with coding?",
                         "Remember chat?", "Languages supported?", "Get started?", "Explain topics?"],
                        ["Write an email", "Summarize article", "Translate text", "Creative ideas",
                         "Debug code", "Explain concept", "Meal plan", "Brainstorm"],
                        ["Best approach?", "How to improve?", "Give examples", "Compare options",
                         "Suggest alternatives", "Pros and cons?", "Help understand", "Walk through"]
                    ],
                    title: "Let's talk about new topics"
                ) { _ in }
            } label: {
                ListItem(
                    title: "Scrolling FAQ",
                    icon: "bubble.left.and.text.bubble.right",
                    description: "Auto-scrolling horizontal FAQ carousel with alternating row directions. Tapping a pill triggers a callback."
                )
            }
            #endif

            // Rotating quote — auto-cycling famous quotes display
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        // Multiple quotes rotation
                        SWRotatingQuote(
                            quotes: [
                                "Those times when you get up early, and you work hard, those times when you stay up late, and you work hard.",
                                "Those times when you don't feel like working, you're too tired, you don't want to push yourself, but you do it anyway.",
                                "That is actually the dream. It's not the destination, it's the journey."
                            ],
                            author: "Kobe Bryant"
                        )
                        .frame(height: 140)

                        Divider()

                        // Single quote (no rotation)
                        SWRotatingQuote(
                            quotes: [
                                "Stay hungry, stay foolish."
                            ],
                            author: "Steve Jobs",
                            quoteFont: .title3,
                            authorFont: .title2
                        )
                        .frame(height: 100)

                        Divider()

                        // Custom style (serif, faster rotation)
                        SWRotatingQuote(
                            quotes: [
                                "The only way to do great work is to love what you do.",
                                "Innovation distinguishes between a leader and a follower.",
                                "Your time is limited, don't waste it living someone else's life."
                            ],
                            author: "Steve Jobs",
                            interval: 3.0,
                            quoteFont: .body,
                            authorFont: .callout,
                            fontDesign: .serif,
                            foregroundStyle: .primary
                        )
                        .frame(height: 120)
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Rotating Quote",
                    icon: "text.quote",
                    description: "Auto-rotating quote display that cycles through texts with animated transitions and author attribution."
                )
            }

            // Basic display elements — BulletPointText + GradientDivider + Label
            ComponentNavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Section 1: SWBulletPointText demo
                        Text("Bullet Point Text")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 10) {
                            SWBulletPointText(bulletColor: .blue) {
                                Text("Wealth")
                            }
                            SWBulletPointText(bulletColor: .green) {
                                HStack {
                                    Text("Health")
                                    Image(systemName: "heart.fill")
                                }
                            }
                            SWBulletPointText(bulletColor: .orange) {
                                Text("Happiness")
                            }
                            SWBulletPointText(bulletColor: .purple) {
                                Text("Wisdom")
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Section 2: SWGradientDivider demo
                        Text("Gradient Divider")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 20) {
                            SWGradientDivider()
                            SWGradientDivider(color: .purple, opacity: 0.5)
                            SWGradientDivider(color: .mint, height: 2)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Section 3: SWLabelWithIcon demo
                        Text("Label with Icon")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            SWLabelWithIcon()
                            SWLabelWithIcon(
                                icon: "gearshape",
                                bg: .orange,
                                name: "Settings"
                            )
                            SWLabelWithIcon(
                                icon: "bell.badge",
                                bg: .red,
                                name: "Notifications"
                            )
                            SWLabelWithIcon(
                                icon: "lock.shield",
                                bg: .green,
                                name: "Privacy"
                            )
                            SWLabelWithIcon(
                                icon: "creditcard",
                                bg: .purple,
                                name: "Subscription"
                            )

                            Divider()

                            SWLabelWithImage(
                                image: .fullpackLogo,
                                name: "FullPack"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } label: {
                ListItem(
                    title: "Basic Display Elements",
                    icon: "rectangle.3.group",
                    description: "BulletPointText, GradientDivider, and LabelWithIcon — simple building blocks for lists, settings, and content sections."
                )
            }
            // Onboarding — multi-page welcome flow with swipe navigation and skip
            ComponentNavigationLink {
                SWOnboardingView(onComplete: {})
            } label: {
                ListItem(
                    title: "Onboarding",
                    icon: "hand.wave.fill",
                    description: "Multi-page welcome flow with swipe navigation and skip support."
                )
            }

            // Order — animated drink customization demo
            ComponentNavigationLink {
                SWOrderView()
            } label: {
                ListItem(
                    title: "Order",
                    icon: "cup.and.saucer.fill",
                    description: "Animated drink customization demo with flavor/size selectors and cup animations."
                )
            }

            // Tab — TabView template
            ComponentNavigationLink {
                SWRootTabView()
            } label: {
                ListItem(
                    title: "Tab",
                    icon: "rectangle.split.3x1.fill",
                    description: "TabView template with selected/unselected icons and haptic feedback."
                )
            }

            // Markdown Text — renders common LLM Markdown output
            ComponentNavigationLink {
                ScrollView {
                    SWMarkdownText("""
                    # Heading 1
                    ## Heading 2
                    ### Heading 3

                    This is a paragraph with **bold** and *italic* text.

                    Here is `inline code` in a sentence.

                    ```swift
                    func greet() {
                        print("Hello, world!")
                    }
                    ```

                    - First item
                    - Second item with **bold**
                    - Third item

                    1. Ordered item one
                    2. Ordered item two

                    ---

                    Another paragraph after the divider.
                    """)
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Markdown Text",
                    icon: "text.badge.checkmark",
                    description: "Custom Markdown renderer supporting headings, bold/italic, code blocks, lists, and dividers — ideal for LLM output."
                )
            }

            // Status Badge — capsule status indicator with five semantic styles
            ComponentNavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All styles")
                                .font(.headline)
                            HStack(spacing: 8) {
                                SWStatusBadge(text: "Info", style: .info)
                                SWStatusBadge(text: "Success", style: .success)
                                SWStatusBadge(text: "Warning", style: .warning)
                                SWStatusBadge(text: "Error", style: .error)
                                SWStatusBadge(text: "Neutral", style: .neutral)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Order list example")
                                .font(.headline)
                            HStack {
                                Text("Order #1024")
                                Spacer()
                                SWStatusBadge(text: "Pending", style: .warning)
                            }
                            HStack {
                                Text("Order #1025")
                                Spacer()
                                SWStatusBadge(text: "Making", style: .info)
                            }
                            HStack {
                                Text("Order #1026")
                                Spacer()
                                SWStatusBadge(text: "Ready", style: .success)
                            }
                            HStack {
                                Text("Order #1027")
                                Spacer()
                                SWStatusBadge(text: "Cancelled", style: .error)
                            }
                            HStack {
                                Text("Order #1028")
                                Spacer()
                                SWStatusBadge(text: "Completed", style: .neutral)
                            }
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Status Badge",
                    icon: "circle.dotted",
                    description: "Capsule status badge with five semantic styles (info, success, warning, error, neutral). LocalizedStringKey and String overloads."
                )
            }

            // Image Thumbnail — square image tile with same-named ColorSet fallback
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset", size: 200, cornerRadius: 24)
                            Text("200 × 200, radius 24")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset")
                            Text("Default 120 × 120, radius 18")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset", size: 60, cornerRadius: 12)
                            Text("60 × 60, radius 12 (cart row)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Tip: register a same-named ColorSet alongside the image set to get a brand-appropriate tint before the image decodes — or as a permanent fallback for empty states.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Image Thumbnail",
                    icon: "photo.fill",
                    description: "Square image tile with same-named ColorSet fallback. Renders the tint while the image decodes or when the asset is missing."
                )
            }

            // KPI Card — dashboard metric card with icon, animated value, and trailing slot
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 20) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            SWKPICard(
                                title: "Today's Revenue",
                                value: "$1,234",
                                icon: "dollarsign.circle.fill",
                                tint: .brown
                            ) {
                                SWKPIDeltaTag(delta: 12.5)
                            }
                            SWKPICard(
                                title: "Cups Sold",
                                value: "128",
                                icon: "cup.and.saucer.fill",
                                tint: .orange
                            ) {
                                Text("Unit: cups")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            SWKPICard(
                                title: "Monthly Revenue",
                                value: "$24,560",
                                icon: "calendar",
                                tint: .green
                            ) {
                                SWKPIDeltaTag(delta: -3.2)
                            }
                            SWKPICard(
                                title: "New Members",
                                value: "42",
                                icon: "person.2.fill",
                                tint: .pink
                            ) {
                                SWKPIDeltaTag(delta: nil)
                            }
                        }

                        Divider()

                        SWKPICard(
                            title: "Total Members",
                            value: "1,024",
                            icon: "person.3.fill",
                            tint: .blue
                        )
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "KPI Card",
                    icon: "rectangle.stack.badge.plus",
                    description: "Dashboard KPI card with icon, animated numeric value, and customizable trailing slot. Pairs with SWKPIDeltaTag for period-over-period."
                )
            }

            // Wallet — pouch holding a stack of payment cards with a reveal toggle
            ComponentNavigationLink {
                SWWallet()
            } label: {
                ListItem(
                    title: "Wallet",
                    icon: "wallet.bifold.fill",
                    description: "Olive-green wallet pouch holding a stack of payment cards. Tap the eye to spring the cards out into a ladder and reveal the total balance."
                )
            }
        } header: {
            #if os(iOS)
            Text("Display")
                .font(.title3.bold())
                .textCase(nil)
                .id("display")
            #endif
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section {
            // Global toast alert — supports info/success/warning/error presets and custom styles
            ComponentNavigationLink {
                VStack(spacing: 12) {
                    Spacer()

                    Text("Tap to trigger alerts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        Button {
                            SWAlertManager.shared.show(.info, message: "This is an info message")
                        } label: {
                            Label("Info", systemImage: "info.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.primary)

                        Button {
                            SWAlertManager.shared.show(.success, message: "Saved successfully")
                        } label: {
                            Label("Success", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.green)

                        Button {
                            SWAlertManager.shared.show(.warning, message: "Slow connection")
                        } label: {
                            Label("Warning", systemImage: "exclamationmark.triangle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.orange)

                        Button {
                            SWAlertManager.shared.show(.error, message: "Operation failed, please retry")
                        } label: {
                            Label("Error", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.red)

                        Button {
                            SWAlertManager.shared.show(
                                icon: "star.fill",
                                message: "Custom alert style",
                                textColor: .yellow,
                                backgroundStyle: AnyShapeStyle(.black),
                                borderColor: .yellow
                            )
                        } label: {
                            Label("Custom", systemImage: "star.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.yellow)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()
                }
                .padding(.horizontal, 24)
            } label: {
                ListItem(
                    title: "SWAlert",
                    icon: "bell.badge",
                    description: "Toast-style alert overlay with four preset styles (info, success, warning, error) and custom styling. Auto-dismisses after configurable duration."
                )
            }

            // Fullscreen loading overlay — blur material background + optional icon pulse animation
            ComponentNavigationLink {
                ZStack {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("Page Content")
                            .font(.largeTitle)
                            .foregroundStyle(.white)

                        Button("Show Default Loading") {
                            SWLoadingManager.shared.show(page: .home, message: "Loading data...")
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                SWLoadingManager.shared.hide(page: .home)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Show Loading with Icon") {
                            SWLoadingManager.shared.show(
                                page: .home,
                                message: "Syncing data...",
                                systemImage: "arrow.triangle.2.circlepath"
                            )
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                SWLoadingManager.shared.hide(page: .home)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .swPageLoading(.home)
            } label: {
                ListItem(
                    title: "SWLoading",
                    icon: "hourglass",
                    description: "Fullscreen loading overlay with blur material background, customizable message, optional SF Symbol icon with pulse animation."
                )
            }

            // Thinking indicator — three-dot bouncing animation for chat typing state
            ComponentNavigationLink {
                VStack(spacing: 40) {
                    // Default style
                    VStack(spacing: 8) {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SWThinkingIndicator()
                    }

                    // Inside a chat bubble
                    VStack(spacing: 8) {
                        Text("Chat Bubble")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            HStack(spacing: 4) {
                                Text("Thinking")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                SWThinkingIndicator()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    // Custom color and size
                    VStack(spacing: 8) {
                        Text("Custom (blue, large)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SWThinkingIndicator(dotSize: 10, dotColor: .blue, spacing: 6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWThinkingIndicator",
                    icon: "ellipsis.bubble",
                    description: "Animated three-dot bouncing indicator for chat typing states. Configurable dot size, color, and spacing."
                )
            }
        } header: {
            #if os(iOS)
            Text("Feedback")
                .font(.title3.bold())
                .textCase(nil)
                .id("feedback")
            #endif
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        Section {
            // Capsule tab button — for custom segmented controls and filter bars
            ComponentNavigationLink {
                List {
                    HStack {
                        SWTabButton(title: "All", isSelected: selectedInputTab == 0) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 0 }
                        }
                        SWTabButton(title: "Favorites", isSelected: selectedInputTab == 1) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 1 }
                        }
                        SWTabButton(title: "Recent", isSelected: selectedInputTab == 2) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 2 }
                        }
                        SWTabButton(title: "Trending", isSelected: selectedInputTab == 3) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 3 }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section {
                        if selectedInputTab == 0 {
                            ForEach(["Meeting notes", "Grocery list", "Workout plan", "Travel ideas", "Book wishlist"], id: \.self) { item in
                                Label(item, systemImage: "doc.text")
                            }
                        } else if selectedInputTab == 1 {
                            ForEach(["Workout plan", "Travel ideas"], id: \.self) { item in
                                Label(item, systemImage: "star.fill")
                                    .foregroundStyle(.orange)
                            }
                        } else if selectedInputTab == 2 {
                            ForEach(["Grocery list", "Meeting notes"], id: \.self) { item in
                                Label(item, systemImage: "clock")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(["AI prompts", "Fitness trends", "Recipe hacks"], id: \.self) { item in
                                Label(item, systemImage: "flame.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            } label: {
                ListItem(
                    title: "SWTabButton",
                    icon: "rectangle.compress.vertical",
                    description: "Capsule-shaped tab button for custom segmented controls and filter bars. Toggles between selected and unselected states."
                )
            }

            // Numeric stepper — compact control with animated transitions and haptic feedback
            ComponentNavigationLink {
                VStack(spacing: 30) {
                    SWStepper(quantity: $stepperValue)

                    Divider()

                    HStack {
                        Text("Quantity")
                        Spacer()
                        SWStepper(quantity: $stepperValue)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWStepper",
                    icon: "minus.forwardslash.plus",
                    description: "Compact numeric stepper with animated transitions and haptic feedback. Chevron-style increment/decrement buttons."
                )
            }

            // Add sheet — bottom sheet with text input
            ComponentNavigationLink {
                VStack {
                    Spacer()

                    Button("Show Add Sheet") {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showAddSheet) {
                    SWAddSheet(isPresented: $showAddSheet) { _ in }
                }
            } label: {
                ListItem(
                    title: "SWAddSheet",
                    icon: "plus.rectangle.on.rectangle",
                    description: "Bottom sheet with text input, cancel and confirm buttons. Presented as medium detent for collecting user input."
                )
            }

            // Search bar — capsule-shaped with magnifying glass, clear button, ultra-thin material
            ComponentNavigationLink {
                VStack(spacing: 24) {
                    SWSearchBar(text: $searchBarText)
                        .padding(.horizontal)

                    SWSearchBar(text: $searchBarText, placeholder: "Search contacts")
                        .padding(.horizontal)

                    Text(searchBarText.isEmpty ? "Start typing to see the bound value..." : "Query: \(searchBarText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWSearchBar",
                    icon: "magnifyingglass",
                    description: "Capsule-shaped search bar with magnifying glass, clear button and ultra-thin material background. Binds to a text string."
                )
            }
        } header: {
            #if os(iOS)
            Text("Input")
                .font(.title3.bold())
                .textCase(nil)
                .id("input")
            #endif
        }
    }
}
// MARK: - Face Camera Demo View (Real Camera with Face Tracking)

#if os(iOS)
/// SWFaceCameraView includes its own close button — present it directly.
struct ComponentViewFaceCameraDemo: View {
    var body: some View {
        SWFaceCameraView()
    }
}

// MARK: - Camera Demo View (Real Camera, No Processing)

/// Demo using real SWCameraView — captured or selected photos are not processed or saved.
struct ComponentViewCameraDemo: View {
    @State private var capturedImage: UIImage?

    var body: some View {
        SWCameraView(image: $capturedImage)
            .swAlert()
    }
}
#endif

// MARK: - Chat Demo View (SWChatView with Simulated Response)

#if os(iOS)
/// Demo showcasing SWChatView with a simulated echo-style AI response.
/// No ASR config is provided so the microphone button is hidden in demo mode.
struct ComponentViewChatDemo: View {
    @State private var messages: [SWChatMessage] = [
        SWChatMessage(
            content: "Welcome! Send a message to see the demo response.",
            isUser: false
        ),
    ]
    @State private var isWaiting = false

    var body: some View {
        SWChatView(
            messages: $messages,
            isDisabled: isWaiting
        ) { text in
            // Simulate AI response with a 1-second delay
            isWaiting = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                messages.append(
                    SWChatMessage(
                        content: "This is a demo response. Connect ShipSwift MCP to enable full AI chat functionality.",
                        isUser: false
                    )
                )
                isWaiting = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif

// MARK: - Helpers

/// Hides the tab bar when a view is pushed via NavigationLink on iOS.
/// No-op on macOS where tab bars don't exist.
private extension View {
    @ViewBuilder func hideTabBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }
}

/// Drop-in replacement for `NavigationLink { destination } label: { … }` that
/// automatically hides the floating tab bar when the destination is pushed.
///
/// Convention for this showcase: every component preview is a subpage of the
/// root tab — the tab bar should only be visible on top-level tabs, never on
/// pushed component previews. Using this wrapper instead of `NavigationLink`
/// makes that the default; no per-call `.hideTabBar()` needed.
private struct ComponentNavigationLink<Label: View, Destination: View>: View {
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink {
            destination()
                .hideTabBar()
        } label: {
            label()
        }
    }
}

#Preview {
    ComponentView(scrollTarget: .constant(nil))
        .environment(SWStoreManager.shared)
}
