# ShipSwift Recipe Catalog

All source files are under `ShipSwift/SWPackage/`. Each component is self-contained — copy the file(s) plus `SWUtil/` into your project.

## Animation (`SWAnimation/`)

| Component | File | Description |
|-----------|------|-------------|
| AnimatedMeshGradient | `SWAnimatedMeshGradient.swift` | Animated mesh gradient background |
| BeforeAfterSlider | `SWBeforeAfterSlider.swift` | Drag-to-compare before/after image slider |
| GlowSweep | `SWGlowSweep.swift` | Glowing sweep animation overlay |
| LightSweep | `SWLightSweep.swift` | Light sweep / skeleton loading effect |
| OrbitingLogos | `SWOrbitingLogos.swift` | Logos orbiting around a center point |
| ScanningOverlay | `SWScanningOverlay.swift` | Scanning line animation overlay |
| ShakingIcon | `SWShakingIcon.swift` | Icon with shake animation on trigger |
| Shimmer | `SWShimmer.swift` | Shimmer / skeleton loading placeholder |
| TypewriterText | `SWTypewriterText.swift` | Character-by-character typing animation |

## Chart (`SWChart/`)

| Component | File | Description |
|-----------|------|-------------|
| ActivityHeatmap | `SWActivityHeatmap.swift` | GitHub-style contribution heatmap |
| AreaChart | `SWAreaChart.swift` | Filled area chart with gradient |
| BarChart | `SWBarChart.swift` | Vertical bar chart |
| DonutChart | `SWDonutChart.swift` | Donut / pie chart with center label |
| LineChart | `SWLineChart.swift` | Line chart with markers |
| RadarChart | `SWRadarChart.swift` | Spider / radar chart |
| RingChart | `SWRingChart.swift` | Circular progress ring chart |
| ScatterChart | `SWScatterChart.swift` | Scatter plot chart |

## Component — Display (`SWComponent/Display/`)

| Component | File | Description |
|-----------|------|-------------|
| BulletPointText | `SWBulletPointText.swift` | Styled bullet point list |
| FloatingLabels | `SWFloatingLabels.swift` | Floating animated labels |
| GradientDivider | `SWGradientDivider.swift` | Gradient-styled divider line |
| Label | `SWLabel.swift` | Styled label with icon support |
| MarkdownText | `SWMarkdownText.swift` | Markdown-rendered text view |
| OnboardingView | `SWOnboardingView.swift` | Multi-page onboarding flow |
| OrderView | `SWOrderView.swift` | Order / receipt summary view |
| RootTabView | `SWRootTabView.swift` | Tab bar navigation root view |
| RotatingQuote | `SWRotatingQuote.swift` | Auto-rotating quote display |
| ScrollingFAQ | `SWScrollingFAQ+iOS.swift` | Expandable FAQ list (iOS) |

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
| `SWViewExtension.swift` | View modifier extensions (`.swAlert()`, `.swPageLoading()`, `.swPrimary`) |

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
