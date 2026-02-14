# ShipSwift

> AI-native iOS component library — production-ready SwiftUI code that LLMs can use to build real apps.

## Requirements

- iOS 18.0+
- Swift 5.0+
- Xcode 16.0+

## Quick Start

### Option 1: MCP Integration (Recommended)

Connect ShipSwift via MCP so your AI assistant can access components and best practices:

```bash
claude mcp add --transport http shipswift https://api.shipswift.app/mcp
```

### Option 2: File Copy

1. Clone this repository
2. Copy the files you need from `ShipSwift/SWPackage/` into your Xcode project
3. Each component in `SWAnimation/`, `SWChart/`, and `SWComponent/` is self-contained — just copy the file and `SWUtil/` if needed

### Run the Showcase App

```
git clone https://github.com/signerlabs/ShipSwift.git
cd ShipSwift
open ShipSwift.xcodeproj
```

Select a simulator or device, then press **Cmd+R** to build and run.

## Open-Source Components

### SWAnimation — 9 Animation Components

BeforeAfterSlider, TypewriterText, ShakingIcon, Shimmer, GlowSweep, LightSweep, ScanningOverlay, AnimatedMeshGradient, OrbitingLogos

### SWChart — 8 Chart Components

LineChart, BarChart, AreaChart, DonutChart, RingChart, RadarChart, ScatterChart, ActivityHeatmap

### SWComponent — 15 UI Components

**Display:** FloatingLabels, ScrollingFAQ, RotatingQuote, BulletPointText, GradientDivider, Label, OnboardingView, OrderView, RootTabView
**Feedback:** Alert, Loading, ThinkingIndicator
**Input:** TabButton, Stepper, AddSheet

### SWModule — 5 Multi-File Frameworks

- **SWAuth** — User authentication (Amplify/Cognito, social login, email/password, phone sign-in with country code picker)
- **SWCamera** — Camera capture with viewfinder, zoom, photo picker, and face detection with Vision landmark tracking
- **SWPaywall** — Subscription paywall using StoreKit 2
- **SWChat** — All-in-one chat view with message list, text input, and optional voice recognition (VolcEngine ASR)
- **SWSetting** — Settings page template with language switch, share, legal links, recommended apps

### SWUtil — 5 Shared Utilities

DebugLog, String/Date/View extensions, LocationManager

## Directory Structure

```
ShipSwift/
├── SWPackage/
│   ├── SWAnimation/          # Animation components (9 files)
│   ├── SWChart/              # Chart components (8 files)
│   ├── SWComponent/          # UI components (15 files)
│   │   ├── Display/          #   Display components (9)
│   │   ├── Feedback/         #   Feedback components (3)
│   │   └── Input/            #   Input components (3)
│   ├── SWModule/             # Multi-file frameworks (5 modules)
│   │   ├── SWAuth/           #   Authentication (4 files)
│   │   ├── SWCamera/         #   Camera + face detection (4 files)
│   │   ├── SWPaywall/        #   Subscription paywall (2 files)
│   │   ├── SWChat/           #   Chat + voice input (4 files)
│   │   └── SWSetting/        #   Settings page (1 file)
│   └── SWUtil/               # Shared utilities (5 files)
├── View/                     # Showcase app views
│   ├── RootTabView.swift     #   Tab container
│   ├── HomeView.swift        #   Home page
│   ├── AnimationView.swift   #   Animation showcase
│   ├── ChartView.swift       #   Chart showcase
│   ├── ComponentView.swift   #   Component showcase
│   ├── ModuleView.swift      #   Module showcase
│   └── SettingView.swift     #   App settings
└── Component/                # Shared app components
    └── ListItem.swift        #   Reusable list row
```

## Naming Convention

All types use the `SW` prefix (e.g., `SWAlertManager`, `SWStoreManager`).
View modifiers use `.sw` lowercase prefix (e.g., `.swAlert()`, `.swPageLoading()`, `.swPrimary`).

## Dependency Rules

```
SWUtil        ← no dependencies on other SWPackage directories
SWAnimation   ← may depend on SWUtil only
SWChart       ← may depend on SWUtil only
SWComponent   ← may depend on SWUtil only
SWModule      ← may depend on SWUtil and SWComponent; internal files may depend on each other
```

## Tech Stack

- SwiftUI + Swift
- StoreKit 2
- Amplify SDK (Cognito)
- AVFoundation + Vision
- SpriteKit
- VolcEngine ASR

## Pro Recipes

Beyond open-source components, ShipSwift offers paid Recipes — full-stack solutions with architecture decisions, complete implementations, integration checklists, and known pitfalls:

- Authentication (Cognito + Amplify)
- Subscriptions (StoreKit 2 + server-side validation)
- AI Streaming Chat (Lambda Streaming + SSE)
- Voice Input (VolcEngine ASR)
- Infrastructure (AWS CDK full-stack)
- Database (Aurora Serverless + Drizzle ORM)
- Messaging (SES/SNS)

Learn more at [shipswift.app](https://shipswift.app)

## License

MIT
