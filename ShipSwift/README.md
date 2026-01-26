# ShipSwift

快速构建 iOS 应用的代码模板库和开发指南。

## 核心内容

ShipSwift 包含两个核心部分：

### 1. 代码模板 (`slPackage/`)

可直接复制使用的 SwiftUI/Swift 代码组件，所有组件以 `sl` 前缀命名：

| 目录 | 说明 |
|------|------|
| `slAnimation/` | 动画组件（扫描动画、渐变、Rive加载器、摇晃效果等） |
| `slComponent/` | UI组件（活动热力图、旋转引用、图表、Loading等） |
| `slChat/` | 聊天组件（语音识别、消息列表等） |
| `slManager/` | 管理类（状态管理、数据管理等） |
| `slConfig/` | 配置相关 |
| `slUtil/` | 工具类 |
| `slView/` | 视图组件（Auth、Onboarding、Setting等） |

### 常用组件

- **slImageScanOverlay** - 图片扫描动画，AI 处理、图片分析场景
- **slRotatingQuote** - 旋转引用文本，设置页底部展示名人名言
- **slActivityHeatmap** - 活动热力图，展示连续打卡和活动记录

### 2. 开发文档 (`docs/`)

新项目快速开发指南，涵盖后端服务搭建和功能集成：

| 文档 | 说明 |
|------|------|
| [0_cdk.md](docs/0_cdk.md) | AWS CDK 基础设施配置 (VPC, Aurora, App Runner, Lambda, Cognito, SES/SNS) |
| [1_auth.md](docs/1_auth.md) | 认证系统 (iOS Amplify SDK 集成、登录/登出/删除账户流程) |
| [2_database.md](docs/2_database.md) | 数据库 (Drizzle ORM 配置、本地开发、迁移管理) |
| [3_subscription.md](docs/3_subscription.md) | iOS 订阅系统 (StoreKit 2 客户端 + 后端验证实现) |
| [4_lambda.md](docs/4_lambda.md) | Lambda 开发 (handler 代码写法、性能优化、错误处理) |
| [5_messaging.md](docs/5_messaging.md) | 消息服务 (AWS SES/SNS + 阿里云短信/邮件，工厂模式切换) |
| [6_asr.md](docs/6_asr.md) | 语音识别 (火山引擎流式ASR、聊天输入框集成) |
| [7_streaming.md](docs/7_streaming.md) | 流式传输 (Lambda Response Streaming、AI 聊天、SSE 最佳实践) |

---

## 快速开始

### 使用代码模板

1. 浏览 `slPackage/` 找到需要的组件
2. 将整个目录或单个文件复制到你的项目中
3. 根据需要修改配置和样式

示例：集成语音识别聊天输入框

```swift
// 复制 slASR/ 目录到项目后

import SwiftUI

struct ChatView: View {
    @State private var text = ""

    let asrConfig = SLASRConfig(
        appId: "你的AppID",
        accessToken: "你的AccessToken"
    )

    var body: some View {
        VStack {
            // 消息列表...

            SLChatInputView(text: $text, asrConfig: asrConfig) {
                sendMessage()
            }
        }
    }
}
```

### 使用开发文档

1. 阅读 `docs/` 下的文档了解最佳实践
2. 按照文档步骤搭建后端服务
3. 参考代码示例进行集成

---

## 目录结构

```
ShipSwift/
├── README.md                   # 本文件
├── docs/                       # 开发文档
│   ├── 0_cdk.md               # AWS CDK
│   ├── 1_auth.md              # 认证
│   ├── 2_database.md          # 数据库
│   ├── 3_subscription.md      # 订阅
│   ├── 4_lambda.md            # Lambda
│   ├── 5_messaging.md         # 消息
│   ├── 6_asr.md               # 语音识别
│   └── 7_streaming.md         # 流式传输
├── slPackage/                  # 代码模板
│   ├── slAnimation/           # 动画
│   ├── slASR/                 # 语音识别
│   ├── slComponent/           # UI组件
│   ├── slConfig/              # 配置
│   ├── slManager/             # 管理类
│   ├── slUtil/                # 工具
│   └── slView/                # 视图
└── ...
```

---

## 设计原则

1. **即插即用**：组件独立，复制即可使用
2. **最小依赖**：尽量使用系统框架，减少第三方依赖
3. **文档驱动**：每个功能模块都有详细的集成文档
4. **实战验证**：所有代码来自真实项目，经过验证

## 文档维护

- 在任意项目中发现新的最佳实践，及时更新并 push
- 使用前先 pull 获取最新内容
- Claude Code 工作时可直接参考 workspace 内的文档
