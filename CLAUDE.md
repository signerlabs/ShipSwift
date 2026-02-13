# CLAUDE.md

## Project Overview
- ShipSwift iOS component template library (public repo)

## Directory Structure
- Reusable components live under `ShipSwift/SWPackage/` in five directories:
  - `SWAnimation/` — Self-contained animation components (9 files, each works independently, may depend on SWUtil only)
  - `SWChart/` — Self-contained chart components (8 files, each works independently, may depend on SWUtil only)
  - `SWComponent/` — Self-contained UI components organized by category:
    - `Display/` — Display components (FloatingLabels, ScrollingFAQ, RotatingQuote, Labels, Dividers, OnboardingView, OrderView, RootTabView, etc.)
    - `Feedback/` — Feedback components (Alert, Loading, ThinkingIndicator)
    - `Input/` — Input components (TabButton, Stepper, AgreementChecker, AddSheet)
  - `SWModule/` — Multi-file frameworks (SWAuth, SWCamera, SWPaywall, SWChat, SWFaceCamera, SWSetting)
  - `SWUtil/` — Shared utilities (no dependencies on other SWPackage directories)
- Showcase app views live under `ShipSwift/View/` (AnimationView, ChartView, ComponentView, ModuleView, RootTabView, SettingView)
- Shared app components live under `ShipSwift/Component/` (ListItem)

## Naming Conventions
- All type names use the `SW` prefix: `SWAlertManager`, `SWStoreManager`, `SWCameraView`
- View modifier methods use `.sw` lowercase prefix: `.swAlert()`, `.swPageLoading()`, `.swPrimary`
- File names match their primary type: `SWAlert.swift` contains `SWAlertManager`

## Dependency Rules
- `SWUtil` has zero dependencies on other SWPackage directories
- `SWAnimation`, `SWChart`, and `SWComponent` may only depend on `SWUtil`
- `SWModule` may depend on `SWUtil`, `SWComponent`, and other files within the same module

## Self-Containment Principle
- Every file in `SWAnimation/`, `SWChart/`, and `SWComponent/` must work without importing other SWPackage files (except `SWUtil`)
- Alert and Loading merge their managers into the same file for self-containment
- CameraManager uses an `onError` closure instead of directly referencing `SWAlertManager`

## Code Style
- All comments and documentation in English
- No external constants file — product IDs, URLs, and config values are inlined or configurable via struct properties
