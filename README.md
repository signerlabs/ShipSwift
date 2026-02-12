# ShipSwift

> 面向 AI 的 iOS 开发组件库 — 让大模型基于实战验证的代码写出生产级 iOS 应用。

## 快速开始

通过 MCP 连接 ShipSwift，AI 自动获取组件和最佳实践：

```bash
claude mcp add --transport http shipswift https://api.shipswift.app/mcp
```

## 开源组件

### slComponent — 20+ SwiftUI UI 组件

Heatmap, RadarChart, DonutChart, RingChart, ScatterChart, BeforeAfter, GlowScan, ThinkingIndicator 等

### slAnimation — 9 个即用动画

Shimmer, MeshGradient, Typewriter, FloatingLabels, BeforeAfter 等

### slView — 7 个完整页面

Onboarding, Paywall, Camera, Settings, Order, RootTab, Auth

### slManager — 6 个管理器

User, Store, Camera, Alert, Loading, Location

### slChat — 聊天组件

聊天输入 + 消息列表 + 语音识别

### slUtil — 工具扩展

Date/String/View 扩展 + DebugLog

### slConfig — 全局配置

Constants 配置项

## 目录结构

```
ShipSwift/
├── slPackage/
│   ├── slComponent/    # UI 组件
│   ├── slAnimation/    # 动画组件
│   ├── slView/         # 完整页面
│   ├── slManager/      # 管理器
│   ├── slChat/         # 聊天组件
│   ├── slUtil/         # 工具扩展
│   └── slConfig/       # 全局配置
└── View/               # 示例视图
```

## 技术栈

- SwiftUI + Swift
- StoreKit 2
- Amplify SDK
- SpriteKit
- 火山引擎 ASR

## Pro Recipe

开源组件之外，ShipSwift 还提供付费 Recipe — 包含架构决策、完整实现、集成清单和已知陷阱的全栈解决方案：

- 认证系统（Cognito + Amplify）
- 订阅系统（StoreKit 2 + 服务端验证）
- AI 流式对话（Lambda Streaming + SSE）
- 语音输入（火山引擎 ASR）
- 基础设施（AWS CDK 全栈）
- 数据库（Aurora Serverless + Drizzle ORM）
- 消息服务（SES/SNS）

详情访问 [shipswift.app](https://shipswift.app)

## License

MIT
