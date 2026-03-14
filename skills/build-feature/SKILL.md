---
name: build-feature
description: >
  Build an iOS feature using ShipSwift components. Use when the user says
  "build", "create", "add a feature", or describes an iOS feature they want to implement.
---

# Build Feature with ShipSwift

Build production-ready iOS features by combining ShipSwift components — copy-paste-ready SwiftUI implementations covering animations, charts, UI components, and full-stack modules.

## Workflow

1. **Browse the catalog**: Read `skills/catalog.md` to see all available components organized by category.

2. **Read the source**: For each relevant component, read the Swift file directly from `ShipSwift/SWPackage/`. For example:
   - Shimmer animation → read `ShipSwift/SWPackage/SWAnimation/SWShimmer.swift`
   - Donut chart → read `ShipSwift/SWPackage/SWChart/SWDonutChart.swift`
   - Auth module → read all files in `ShipSwift/SWPackage/SWModule/SWAuth/`

3. **Present an integration plan**: Before writing code, show the user:
   - Which components will be used
   - How they connect together
   - What customizations are needed

4. **Generate code**: Adapt the component patterns to the user's project. Combine multiple components when the feature spans several areas (e.g., a chart view with shimmer loading).

5. **Integration checklist**: List required dependencies, Info.plist entries, or Xcode build phase settings (especially for `+iOS`/`+macOS` platform-filtered files).

## Guidelines

- Always check the catalog before writing code from scratch — ShipSwift likely has a ready-made solution.
- Use `SW`-prefixed naming (`SWShimmer`, `SWDonutChart`).
- View modifiers use `.sw` lowercase prefix (`.swShimmer()`, `.swGlowScan()`).
- Copy `SWUtil/` alongside any component — it provides shared extensions.
- For modules (`SWModule/`), copy the entire module folder.
- Support Dark Mode and Dynamic Type by default.

## Pro Recipes (MCP)

Some full-stack recipes (backend + compliance + pitfall guides) are available via the MCP server at `https://api.shipswift.app/mcp`. If MCP tools (`listRecipes`, `searchRecipes`, `getRecipe`) are available, use them for extended content. The local source code works independently.
