# CLAUDE.md

## Project Overview
- ShipSwift iOS component template library (public repo)

## Directory Structure
- Reusable components live under `ShipSwift/slPackage/` in four directories:
  - `SWComponent/` — Self-contained UI components (each file works independently, may depend on SWUtil only)
  - `SWModule/` — Multi-file frameworks (SWAuth, SWCamera, SWPaywall, SWChat, SWFaceCamera)
  - `SWView/` — Complete page views (may depend on SWUtil only)
  - `SWUtil/` — Shared utilities (no dependencies on other slPackage directories)

## Naming Conventions
- All type names use the `SW` prefix: `SWAlertManager`, `SWStoreManager`, `SWCameraView`
- View modifier methods use `.sw` lowercase prefix: `.swAlert()`, `.swPageLoading()`, `.swPrimary`
- File names match their primary type: `SWAlert.swift` contains `SWAlertManager`

## Dependency Rules
- `SWUtil` has zero dependencies on other slPackage directories
- `SWComponent` and `SWView` may only depend on `SWUtil`
- `SWModule` may depend on `SWUtil`, `SWComponent`, and other files within the same module

## Self-Containment Principle
- Every file in `SWComponent/` and `SWView/` must work without importing other slPackage files (except `SWUtil`)
- Alert and Loading merge their managers into the same file for self-containment
- CameraManager uses an `onError` closure instead of directly referencing `SWAlertManager`

## Code Style
- All comments and documentation in English
- No external constants file — product IDs, URLs, and config values are inlined or configurable via struct properties
