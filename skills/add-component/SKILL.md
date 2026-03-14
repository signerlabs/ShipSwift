---
name: add-component
description: >
  Add a SwiftUI component from ShipSwift. Use when the user says "add component",
  "add a view", "add X view", "I need a chart", "add animation", or wants a specific UI element.
---

# Add Component from ShipSwift

Add production-ready SwiftUI components to your project from ShipSwift's local source library.

## Workflow

1. **Identify the component**: Read `skills/catalog.md` to find the right component. Common mappings:
   - "shimmer" / "loading skeleton" → `SWAnimation/SWShimmer.swift`
   - "donut chart" / "pie chart" → `SWChart/SWDonutChart.swift`
   - "alert" / "popup" → `SWComponent/Feedback/SWAlert.swift`
   - "auth" / "login" → `SWModule/SWAuth/` (all files)
   - "camera" → `SWModule/SWCamera/` (all files)

2. **Read the source file**: Read the Swift file from `ShipSwift/SWPackage/<path>`. The file contains the complete implementation.

3. **Integrate into the project**:
   - Copy the file(s) into the user's project
   - Also copy `SWUtil/` if not already present
   - Adapt naming, colors, and data models to match the project
   - For `+iOS`/`+macOS` files, set the platform filter in Xcode Build Phases

4. **Verify**: Walk through any dependencies or setup steps needed.

## Guidelines

- Types use `SW` prefix (`SWDonutChart`, `SWTypewriter`).
- View modifiers use `.sw` prefix (`.swShimmer()`, `.swGlowScan()`).
- Chart components use a generic `CategoryType` pattern with `String` convenience initializer.
- Internal helper types should be `private` with `SW` prefix.
- Components in `SWAnimation/`, `SWChart/`, and `SWComponent/` are each self-contained (single file + SWUtil).
- Modules in `SWModule/` are multi-file — copy the entire folder.
