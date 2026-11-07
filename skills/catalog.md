# ShipSwift Skill Catalog

All source files are under `ShipSwift/SWPackage/`. Each component is self-contained — copy the file(s) plus `SWUtil/` into your project.

## Animation (`SWAnimation/`)

| Component | File | Description |
|-----------|------|-------------|
| AnimatedMeshGradient | `SWAnimatedMeshGradient.swift` | Animated mesh gradient background |
| BeforeAfterSlider | `SWBeforeAfterSlider.swift` | Drag-to-compare before/after image slider |
| ChangeEffect | `SWChangeEffect.swift` | Micro-interaction effects fired on value changes (shake, jump, spin, ping…) |
| CharSphere | `SWCharSphere.swift` | Rotating 3D sphere of characters / emoji |
| Confetti | `SWConfetti.swift` | Canvas-rendered celebration confetti burst |
| DotSphere | `SWDotSphere.swift` | Rotating 3D dot sphere with optional morphing |
| FullScreenButton | `SWFullScreenButton+iOS.swift` | Card that zooms into a full-screen view (iOS) |
| GlowSweep | `SWGlowSweep.swift` | Glowing sweep animation overlay |
| LightSweep | `SWLightSweep.swift` | Light sweep / skeleton loading effect |
| OrbitingLogos | `SWOrbitingLogos.swift` | Logos orbiting around a center point |
| ParticleTransition | `SWParticleTransition.swift` | Particle-burst view transitions (poof, pop…) |
| ScanningOverlay | `SWScanningOverlay.swift` | Scanning line animation overlay |
| ShakingIcon | `SWShakingIcon.swift` | Icon with shake animation on trigger |
| Shimmer | `SWShimmer.swift` | Shimmer / skeleton loading placeholder |
| Transition | `SWTransition.swift` | Custom view transitions on SwiftUI's `Transition` protocol |
| TypewriterText | `SWTypewriterText.swift` | Character-by-character typing animation |

### Metal shader effects (`SWAnimation/SWMetal/`)

Each effect is a `.swift` view plus a `.metal` shader with the same name — copy both.

| Component | Files | Description |
|-----------|-------|-------------|
| AnimatedLoop | `SWAnimatedLoop.swift` + `.metal` | Pulsing concentric rings background |
| ChromaticGlass | `SWChromaticGlass.swift` + `.metal` | Chromatic-aberration glass effect over any view |
| ColorPanels | `SWColorPanels.swift` + `.metal` | Rotating translucent color panels background |
| DotOrbit | `SWDotOrbit.swift` + `.metal` | Dots orbiting Voronoi cell centers |
| Dots | `SWDots.swift` + `SWDots*.metal` (7) | Perspective dot-grid backgrounds in seven styles |
| Foil | `SWFoil.swift` + `.metal` | Holographic rainbow foil effect over any view |
| FractalClouds | `SWFractalClouds.swift` + `.metal` | Drifting fractal clouds background |
| Glass | `SWGlass.swift` + `.metal` | Magnifying / refracting glass lens effect |
| GlassLogo | `SWGlassLogo.swift` + `.metal` | Glass logo refracting a flowing gradient |
| GlassOrb | `SWGlassOrb.swift` + `.metal` | Draggable glass orb |
| Glitter | `SWGlitter.swift` + `.metal` | Twinkling glitter effect over any view |
| GrainGradient | `SWGrainGradient.swift` + `.metal` | Tri-color noise gradient with film grain |
| Halftone | `SWHalftone.swift` + `.metal` | Halftone image filter |
| InkSmoke | `SWInkSmoke.swift` + `.metal` | "Ink in water" smoke background |
| IntenseBling | `SWIntenseBling.swift` + `.metal` | High-intensity holographic shimmer effect |
| LiquidChrome | `SWLiquidChrome.swift` + `.metal` | Animated liquid chrome surface |
| LiquidMetal | `SWLiquidMetal.swift` + `.metal` | Liquid-metal image filter |
| Metaballs | `SWMetaballs.swift` + `.metal` | Gooey metaball blobs background |
| NeuroNoise | `SWNeuroNoise.swift` + `.metal` | Glowing neural-web background |
| Plasma | `SWPlasma.swift` + `.metal` | Full-color plasma backgrounds |
| PolishedAluminum | `SWPolishedAluminum.swift` + `.metal` | Polished-aluminum finish effect over any view |
| SimplexNoise | `SWSimplexNoise.swift` + `.metal` | Multi-color simplex-noise gradient background |
| SmokeRing | `SWSmokeRing.swift` + `.metal` | Smoke ring background |
| StarNest | `SWStarNest.swift` + `.metal` | Volumetric star-nebula background |
| Starfield | `SWStarfield.swift` + `.metal` | Parallax twinkling starfield |
| Swirl | `SWSwirl.swift` + `.metal` | Twisted spiral bands background |
| Voronoi | `SWVoronoi.swift` + `.metal` | Animated Voronoi cell background |
| Water | `SWWater.swift` + `.metal` | Rippling water-caustic image filter |

## Chart (`SWChart/`)

| Component | File | Description |
|-----------|------|-------------|
| ActivityHeatmap | `SWActivityHeatmap.swift` | GitHub-style contribution heatmap |
| AreaChart | `SWAreaChart.swift` | Filled area chart with gradient |
| BarChart | `SWBarChart.swift` | Vertical bar chart |
| DonutChart | `SWDonutChart.swift` | Donut / pie chart with center label |
| LineChart | `SWLineChart.swift` | Line chart with markers |
| NetworkGraph | `SWNetworkGraph.swift`, `SWNetworkGraphData.swift` | Interactive 3D dependency graph (sample data in the second file) |
| RadarChart | `SWRadarChart.swift` | Spider / radar chart |
| RingChart | `SWRingChart.swift` | Circular progress ring chart |
| ScatterChart | `SWScatterChart.swift` | Scatter plot chart |

## Component — Display (`SWComponent/Display/`)

| Component | File | Description |
|-----------|------|-------------|
| BulletPointText | `SWBulletPointText.swift` | Styled bullet point list |
| CachedImage | `SWCachedImage.swift` | `AsyncImage` replacement with memory + disk cache |
| FloatingLabels | `SWFloatingLabels.swift` | Floating animated labels |
| GradientDivider | `SWGradientDivider.swift` | Gradient-styled divider line |
| ImageThumbnail | `SWImageThumbnail.swift` | Rounded image thumbnail with color fallback |
| KPICard | `SWKPICard.swift` | Dashboard metric card |
| Label | `SWLabel.swift` | Styled label with icon support |
| MarkdownText | `SWMarkdownText.swift` | Markdown-rendered text view |
| OnboardingView | `SWOnboardingView.swift` | Multi-page onboarding flow |
| OrderView | `SWOrderView.swift` | Order / receipt summary view |
| RootTabView | `SWRootTabView.swift` | Tab bar navigation root view |
| RotatingQuote | `SWRotatingQuote.swift` | Auto-rotating quote display |
| ScrollingFAQ | `SWScrollingFAQ+iOS.swift` | Auto-scrolling FAQ carousel (iOS) |
| StatusBadge | `SWStatusBadge.swift` | Colored status capsule badge |
| VideoPlayer | `SWVideoPlayer+iOS.swift` | Video thumbnail with full-screen playback (iOS) |
| Wallet | `SWWallet.swift` | Wallet pocket holding a stack of cards |

## Component — Feedback (`SWComponent/Feedback/`)

| Component | File | Description |
|-----------|------|-------------|
| Alert | `SWAlert.swift` | Custom alert with SWAlertManager |
| Loading | `SWLoading.swift` | Page loading overlay |
| ThinkingIndicator | `SWThinkingIndicator.swift` | AI thinking / typing indicator |

## Component — Input (`SWComponent/Input/`)

| Component | File | Description |
|-----------|------|-------------|
| AddSheet | `SWAddSheet.swift` | Bottom sheet for adding items |
| SearchBar | `SWSearchBar.swift` | Capsule search bar with clear button |
| Stepper | `SWStepper.swift` | Custom stepper control |
| TabButton | `SWTabButton.swift` | Styled tab bar button |

## Module (`SWModule/`)

Multi-file modules. Copy the entire module folder plus `SWUtil/`.

| Module | Files | Description |
|--------|-------|-------------|
| **SWAuth** | `SWAuthView+iOS.swift`, `SWAuthView+macOS.swift`, `SWUserManager.swift`, `SWCountryData.swift`, `SWAgreementChecker.swift` | Authentication with Amplify/Cognito — social login, email/password, phone sign-in with country code picker |
| **SWCamera** | `SWCameraManager+iOS.swift`, `SWCameraView+iOS.swift`, `SWFaceCameraView+iOS.swift`, `SWFaceLandmark+iOS.swift` | Camera capture with viewfinder, zoom, photo picker, face detection with Vision landmarks |
| **SWChat** | `SWChatView+iOS.swift`, `SWChatInputView+iOS.swift`, `SWMessageList+iOS.swift`, `SWVolcEngineASRService+iOS.swift` | Chat view with message list, text input, optional voice recognition (VolcEngine ASR) |
| **SWPaywall** | `SWPaywallView.swift`, `SWStoreManager.swift` | StoreKit 2 subscription paywall |
| **SWSetting** | `SWSettingView+iOS.swift`, `SWSettingView+macOS.swift` | Settings page with language switch, share, legal links |
| **SWSubjectLifting** | `SWSubjectLiftingManager+iOS.swift`, `SWSubjectLiftingView+iOS.swift` | Background removal using VisionKit |
| **SWTikTokTracking** | `SWTikTokTrackingManager+iOS.swift`, `SWTikTokTrackingView+iOS.swift` | TikTok Events API attribution tracking |

## Utilities (`SWUtil/`)

| File | Description |
|------|-------------|
| `SWDateExtension.swift` | Date formatting extensions |
| `SWDebugLog.swift` | Debug logging utility |
| `SWLocationManager.swift` | Location manager wrapper |
| `SWStringExtension.swift` | String utility extensions |
| `SWViewExtension.swift` | Button styles (`.swPrimary`, `.swSecondary`) and the `.swCardStyle()` modifier |

## Dependency Rules

```
SWUtil         ← no dependencies
SWAnimation    ← SWUtil only
SWChart        ← SWUtil only
SWComponent    ← SWUtil only
SWModule       ← SWUtil + SWComponent + same-module files
```

## Naming Conventions

- Types: `SW` prefix (`SWAlertManager`, `SWStoreManager`)
- View modifiers: `.sw` prefix (`.swAlert()`, `.swPageLoading()`)
- iOS-only files: `+iOS` suffix
- macOS-only files: `+macOS` suffix
