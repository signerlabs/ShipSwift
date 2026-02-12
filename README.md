# ShipSwift

> AI-native iOS component library — production-ready SwiftUI code that LLMs can use to build real apps.

## Quick Start

Connect ShipSwift via MCP so your AI assistant can access components and best practices:

```bash
claude mcp add --transport http shipswift https://api.shipswift.app/mcp
```

## Open-Source Components

### SWComponent — 28 Self-Contained UI Components

Charts: DonutChart, RingChart, RadarChart, ScatterChart, ActivityHeatmap
Animations: Typewriter, BeforeAfter, Shimmer, FloatingLabels, ShakingIcon, MeshGradient, ImageScanOverlay, ScrollingFAQ
UI Elements: Alert, Loading, Label, TabButton, Stepper, GradientDivider, BulletPointText, ThinkingIndicator, AddSheet, ViewfinderOverlay, ScanImage, GlowScan, RotatingQuote, LogoOrbit, AgreementChecker

### SWModule — 5 Multi-File Frameworks

- **SWAuth** — User authentication (Amplify/Cognito, social login, email/password)
- **SWCamera** — Camera capture with viewfinder, zoom, and photo picker
- **SWPaywall** — Subscription paywall using StoreKit 2
- **SWChat** — Chat input, message list, and voice recognition (VolcEngine ASR)
- **SWFaceCamera** — Face detection camera with Vision landmark tracking

### SWView — 4 Complete Page Views

Onboarding, Settings, Order, RootTab

### SWUtil — 5 Shared Utilities

DebugLog, String/Date/View extensions, LocationManager

## Directory Structure

```
ShipSwift/
├── slPackage/
│   ├── SWComponent/         # Self-contained UI components (28 files)
│   ├── SWModule/            # Multi-file frameworks (5 modules)
│   │   ├── SWAuth/          #   Authentication (3 files)
│   │   ├── SWCamera/        #   Camera capture (2 files)
│   │   ├── SWPaywall/       #   Subscription paywall (2 files)
│   │   ├── SWChat/          #   Chat + voice input (3 files)
│   │   └── SWFaceCamera/    #   Face detection camera (3 files)
│   ├── SWView/              # Complete page views (4 files)
│   └── SWUtil/              # Shared utilities (5 files)
└── View/                    # Demo views
```

## Naming Convention

All types use the `SW` prefix (e.g., `SWAlertManager`, `SWStoreManager`).
View modifiers use `.sw` lowercase prefix (e.g., `.swAlert()`, `.swPageLoading()`, `.swPrimary`).

## Dependency Rules

```
SWUtil        ← no dependencies on other slPackage directories
SWComponent   ← may depend on SWUtil only
SWView        ← may depend on SWUtil only
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
