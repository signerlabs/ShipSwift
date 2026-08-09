# AGENTS.md

## Project Overview
- ShipSwift iOS component template library (public repo)

## Directory Structure
- Reusable components live under `ShipSwift/SWPackage/` in five directories:
  - `SWAnimation/` — Self-contained animation components (each works independently, may depend on SWUtil only)
  - `SWChart/` — Self-contained chart components (each works independently, may depend on SWUtil only)
  - `SWComponent/` — Self-contained UI components organized by category:
    - `Display/` — Display components (FloatingLabels, MarkdownText, ScrollingFAQ, RotatingQuote, BulletPointText, GradientDivider, Label, OnboardingView, OrderView, RootTabView)
    - `Feedback/` — Feedback components (Alert, Loading, ThinkingIndicator)
    - `Input/` — Input components (TabButton, Stepper, AddSheet, SearchBar)
  - `SWModule/` — Multi-file frameworks (SWAuth, SWCamera, SWPaywall, SWChat, SWSetting, SWSubjectLifting, SWTikTokTracking)
  - `SWUtil/` — Shared utilities (no dependencies on other SWPackage directories)
- Showcase app views live under `ShipSwift/View/` (HomeView, ModuleListView, AnimationListView, ChartListView, UIListView, ComponentListShared, ProPaywallView, RootTabView, SettingView, ShipSwiftAuthView, SWHolographicCardShowcase)
- App services live under `ShipSwift/Service/` (ShipSwiftAPIService)
- Shared app components live under `ShipSwift/Component/` (ListItem)

## Naming Conventions
- All type names use the `SW` prefix: `SWAlertManager`, `SWStoreManager`, `SWCameraView`
- View modifier methods use `.sw` lowercase prefix: `.swAlert()`, `.swPageLoading()`, `.swPrimary`
- File names match their primary type: `SWAlert.swift` contains `SWAlertManager`
- **Platform suffix rule**: iOS-only files use `+iOS` suffix (e.g. `SWCameraManager+iOS.swift`), macOS-only files use `+macOS` suffix. Cross-platform files have no suffix
- **Xcode Build Phases reminder**: This project supports both iOS and macOS. When adding a `+iOS` or `+macOS` file, remind the user to set the platform filter in Xcode → Build Phases → Compile Sources (change "Always Used" to "iOS" or "macOS"). Do NOT use `#if os(iOS)` / `#if os(macOS)` as a substitute

## Dependency Rules
- `SWUtil` has zero dependencies on other SWPackage directories
- `SWAnimation`, `SWChart`, and `SWComponent` may only depend on `SWUtil`
- `SWModule` may depend on `SWUtil`, `SWComponent`, and other files within the same module

## Self-Containment Principle
- Every file in `SWAnimation/`, `SWChart/`, and `SWComponent/` must work without importing other SWPackage files (except `SWUtil`)
- Alert and Loading merge their managers into the same file for self-containment
- CameraManager uses an `onError` closure instead of directly referencing `SWAlertManager`

## Code Style
- All comments and documentation in English (this is a public repo; overrides the global Chinese rule)
- No external constants file — product IDs, URLs, and config values are inlined or configurable via struct properties

## ShipSwift 产品标识

| 标识 | 值 |
|------|-----|
| Bundle ID | `com.signerlabs.ship-swift-ios` |
| Apple ID | `6759209764` |
| App Store Product ID | `com.signerlabs.shipswift.lifetime` |
| TikTok App ID | `7613007501285818376` |
| SKAdNetwork ID | `mj797d8u6f.skadnetwork` |

- TikTok 凭证存放在 `ShipSwift/SWSecrets.swift`（.gitignore，不提交）；模板文件 `SWSecrets.swift.example`（提交到 repo）

## 核心库变更审查规则
本库（前端组件模板库）是项目核心资产，**任何修改都必须经评审后才可提交**。

## 组件变更同步规则
当 `ShipSwift/SWPackage/` 中的组件有任何变更（新增/修改/删除），必须同步更新对应分类的展示页：

| 组件目录 | 展示页文件 |
|---------|-----------|
| `SWModule/` | `ModuleListView.swift` |
| `SWAnimation/` | `AnimationListView.swift` |
| `SWChart/` | `ChartListView.swift` |
| `SWComponent/`（Display / Feedback / Input） | `UIListView.swift` |

- 展示页更新后统一评审
- 组件变更后，ShipSwift 服务端的 Recipe 定义也需一并同步（由维护者处理，不在本 repo）

## 关联项目

- **Skills & Plugin 分发**：https://github.com/signerlabs/shipswift-skills
