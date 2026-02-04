# iOS 导航栏半卡死/鬼影问题 (Navigation Bar State Corruption)

## 问题现象

在 iOS SwiftUI 开发中（特别是 iOS 16/17），可能会遇到以下情况：

1.  **鬼影重叠**：页面顶部出现两个导航栏标题重叠，通常是一个“从上一页残留的大标题”覆盖在“当前页的标题”上。
2.  **交互锁死**：页面 UI 失去响应，特别是在尝试使用系统侧划返回（Interactive Pop Gesture）之后。
3.  **触发场景**：
    - 主列表页使用 **Large Title** (默认)。
    - 详情页强制指定 **Inline Title** (`.navigationBarTitleDisplayMode(.inline)`).
    - 在详情页打开一个模态视图 (Sheet) 并关闭。
    - 关闭 Sheet 后立即尝试侧划返回上一页。

## 问题原因

这是一个 iOS 导航控制器 (UINavigationController) 的状态管理 Bug。

当 `NavigationController` 需要同时处理以下两个状态变更时，容易发生状态竞争（Race Condition）：

1.  **视图层级变化**：模态视图 (Sheet) 的 Dismiss 动画引起的父视图重绘。
2.  **导航栏模式切换**：侧划手势触发的从 `Inline` 模式平滑过渡到 `Large` 模式的动画。

当这两个过程在极短时间内发生冲突时，导航栏的内部状态机可能会损坏，导致渲染层停留在“半 Inline 半 Large”的中间态，并阻塞主线程的交互事件分发。

## 解决方案

**核心思路**：减少或消除导航栏模式在页面跳转时的剧烈切换。

### 方案一：统一导航栏模式（推荐）

最稳健的修复方式是确保详情页与父级页面的导航栏模式保持一致。

如果父级页面是 `Large` 模式，建议详情页也使用 `Large` 模式，或者移除 `.navigationBarTitleDisplayMode(.inline)` 修饰符（默认继承父级）。

```swift
// ❌ 容易出问题的写法
.navigationTitle("详情页")
.navigationBarTitleDisplayMode(.inline) // 强行切换模式

// ✅ 稳健的写法
.navigationTitle("详情页")
.navigationBarTitleDisplayMode(.large) // 保持一致
// 或者直接删除该修饰符，让系统自动处理
```

### 方案二：延迟修正（如必须使用 Inline）

如果 UI 设计强制要求详情页必须是 Inline 模式（例如标题很长），可以尝试以下变通方法：

1.  **父级妥协**：将父级也改为 Inline 模式。
2.  **禁用侧划**：在特定场景下禁用侧划返回（不推荐，影响体验）。
3.  **自定义导航栏**：完全隐藏系统导航栏，使用自定义 Toolbar（工作量大，但彻底规避系统 Bug）。

## 最佳实践建议

在 SwiftUI 项目中：

- 尽量保持整个 NavigationStack 中的 `navigationBarTitleDisplayMode` 一致性。
- **主列表**与**详情页**最好都使用默认配置（Large），仅在确实需要腾出空间时才谨慎使用 Inline。
- 遇到莫名其妙的 UI 卡死或重影问题，优先检查是否涉及 `Large <-> Inline` 的混合使用。
