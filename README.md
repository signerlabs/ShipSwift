# ShipSwift

> AI-native iOS component library — production-ready SwiftUI code that LLMs can use to build real apps.

## Quick Start

Connect ShipSwift via MCP so your AI assistant can access components and best practices:

```bash
claude mcp add --transport http shipswift https://api.shipswift.app/mcp
```

## Open-Source Components

### SWAnimation — 9 Animation Components

BeforeAfterSlider, TypewriterText, ShakingIcon, Shimmer, GlowSweep, LightSweep, ScanningOverlay, AnimatedMeshGradient, OrbitingLogos

### SWChart — 8 Chart Components

LineChart, BarChart, AreaChart, DonutChart, RingChart, RadarChart, ScatterChart, ActivityHeatmap

### SWComponent — 14 UI Components

**Display:** FloatingLabels, ScrollingFAQ, RotatingQuote, BulletPointText, GradientDivider, Label, OnboardingView, OrderView, RootTabView
**Feedback:** Alert, Loading, ThinkingIndicator
**Input:** TabButton, Stepper, AgreementChecker, AddSheet

### SWModule — 6 Multi-File Frameworks

- **SWAuth** — User authentication (Amplify/Cognito, social login, email/password)
- **SWCamera** — Camera capture with viewfinder, zoom, and photo picker
- **SWPaywall** — Subscription paywall using StoreKit 2
- **SWChat** — Chat input, message list, and voice recognition (VolcEngine ASR)
- **SWFaceCamera** — Face detection camera with Vision landmark tracking
- **SWSetting** — Settings page template with language switch, share, legal links, recommended apps

### SWUtil — 5 Shared Utilities

DebugLog, String/Date/View extensions, LocationManager

## Directory Structure

```
ShipSwift/
├── SWPackage/
│   ├── SWAnimation/          # Animation components (9 files)
│   ├── SWChart/              # Chart components (8 files)
│   ├── SWComponent/          # UI components (14 files)
│   │   ├── Display/          #   Display components
│   │   ├── Feedback/         #   Feedback components
│   │   └── Input/            #   Input components
│   ├── SWModule/             # Multi-file frameworks (6 modules)
│   │   ├── SWAuth/           #   Authentication (3 files)
│   │   ├── SWCamera/         #   Camera capture (2 files)
│   │   ├── SWPaywall/        #   Subscription paywall (2 files)
│   │   ├── SWChat/           #   Chat + voice input (3 files)
│   │   ├── SWFaceCamera/     #   Face detection camera (3 files)
│   │   └── SWSetting/        #   Settings page (1 file)
│   └── SWUtil/               # Shared utilities (5 files)
├── View/                     # Showcase app views (4-tab layout)
│   ├── RootTabView.swift     #   Tab container
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
