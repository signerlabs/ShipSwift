# iOS 客户端数据缓存指南

iOS 客户端的内存缓存策略，用于减少重复网络请求、提升用户体验。

## 核心原则

1. **内存缓存优先** - 数据存储在 Manager 的属性中，App 生命周期内有效
2. **智能加载检查** - 请求前检查缓存是否存在，避免重复请求
3. **强制刷新分离** - `load` 方法检查缓存，`refresh` 方法强制重新获取
4. **登出时清理** - 用户登出时清空所有缓存数据

## 最佳实践

### 1. Manager 结构

```swift
@MainActor
@Observable
class DataManager {
    // MARK: - State
    var cachedData: SomeModel?
    var isLoading = false
    var error: String?

    private let service = SomeService()

    // MARK: - 加载数据（有缓存则跳过）
    func loadData(idToken: String) async {
        // 1. 如果已有数据，不重复请求
        guard cachedData == nil else {
            debugLog("Data already cached, skipping load")
            return
        }

        // 2. 如果正在加载中，不重复请求
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            cachedData = try await service.fetchData(idToken: idToken)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 强制刷新（清空缓存后重新获取）
    func refreshData(idToken: String) async {
        cachedData = nil  // 清空缓存
        await loadData(idToken: idToken)
    }

    // MARK: - 重置状态（登出时调用）
    func reset() {
        cachedData = nil
        isLoading = false
        error = nil
    }
}
```

### 2. 日期缓存验证

对于每日更新的数据（如每日运势、每日报告），需要检查数据日期：

```swift
func loadDailyData(idToken: String) async {
    // 如果已有今天的数据，不重复请求
    if let data = dailyData, data.date == todayDateString() {
        return
    }

    // ... 执行请求
}

private func todayDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    return formatter.string(from: Date())
}
```

### 3. View 中的使用

```swift
struct ContentView: View {
    @Environment(DataManager.self) private var manager

    var body: some View {
        ScrollView {
            // 显示数据
        }
        .task {
            // 进入页面时加载（有缓存则跳过）
            if let idToken = userManager.sessionState.tokens?.idToken {
                await manager.loadData(idToken: idToken)
            }
        }
        .refreshable {
            // 下拉刷新时强制重新获取
            if let idToken = userManager.sessionState.tokens?.idToken {
                await manager.refreshData(idToken: idToken)
            }
        }
    }
}
```

### 4. 数据更新后刷新

当用户修改数据后（如编辑问卷、更新资料），需要强制刷新：

```swift
func onDataUpdated(idToken: String) async {
    // 用户修改数据后，清空缓存并重新获取
    cachedData = nil
    isLoading = true

    do {
        cachedData = try await service.fetchData(idToken: idToken)
    } catch {
        self.error = error.localizedDescription
    }

    isLoading = false
}
```

## 缓存策略对比

| 场景 | 方法 | 行为 |
|------|------|------|
| 进入页面 | `loadData` | 有缓存则跳过 |
| 下拉刷新 | `refreshData` | 强制重新获取 |
| 用户修改数据后 | `onDataUpdated` | 强制重新获取 |
| 用户登出 | `reset` | 清空所有缓存 |

## 注意事项

1. **不使用本地持久化** - 当前策略仅使用内存缓存，App 重启后数据会重新获取
2. **避免并发请求** - 使用 `isLoading` 标志防止同时发起多个相同请求
3. **错误处理** - 请求失败时保留旧缓存，让用户可以继续使用
4. **登出清理** - 必须在用户登出时调用 `reset()` 清空缓存，避免数据泄露
