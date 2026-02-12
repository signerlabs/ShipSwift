# ShipSwift

> 面向 AI 的 iOS 开发参考库 — 让大模型基于实战验证的 Recipe 写出生产级代码。

## 愿景

ShipSwift 不是让你复制粘贴的模板项目。它是一个**为大模型设计的结构化知识库**（Claude、GPT 等），当独立开发者说"帮我加订阅功能"时，AI 能拿到生产级的上下文 — 架构决策、完整实现、已知陷阱 — 而不是从通用训练数据里生成不完整的代码。

### 核心洞察

代码编写的范式正在转变：

- **过去**：人类开发者下载模板 → 读文档 → 手动修改代码
- **现在**：开发者指挥 AI（Claude Code / Cursor / Windsurf）→ AI 写代码
- **未来**：AI 是主要的"代码消费者"，谁把 AI 服务好，谁就赢了

传统 Starter Kit 的文档和模板是为人类设计的，AI 大模型在生成 iOS 代码时只能依赖训练数据中可能过时的知识。ShipSwift 通过 MCP（Model Context Protocol）直接为 AI 提供高质量的组件和文档，让 AI 写出**生产级 iOS 代码**。

### 竞争格局对比

| 维度 | 传统 Starter Kit | ShipSwift MCP |
|------|-----------------|---------------|
| 服务对象 | 人类开发者 | AI 大模型 |
| 交付方式 | 下载 Xcode 项目 | MCP 协议实时调用 |
| 消费场景 | 人读文档 → 复制粘贴 | AI 查询 → 直接生成代码 |
| 商业模式 | 一次性 $199 | 开放核心 + 一次性买断 $79 |
| 护城河 | 容易被复制 | 组件质量 + 文档深度 + 上下文工程 |
| 市场规模 | 几千个独立开发者 | 所有用 AI 写 iOS 代码的人 |
| 竞争对手 | 8+ 同类产品 | **零竞争（全新品类）** |

### 设计原则

1. **AI 优先** — 内容为大模型消费而结构化，不仅仅是给人看的
2. **实战验证** — 每个 Recipe 来自生产应用（Fullpack、Truvet 等）
3. **自包含** — 一个 Recipe = 完整上下文，无跨文件依赖
4. **始终最新** — 远程分发意味着用户永远拿到最新版本
5. **全栈** — 每个 Recipe 包含 iOS + 后端，因为独立开发者两端都要做

---

## 目录结构

- `ShipSwift/slPackage/` — 可复用 SwiftUI 组件
  - 动画组件（扫描动画、渐变、Rive 加载器等）
  - UI 组件（图表、Onboarding、步进器、Loading 等）
  - 聊天组件（语音识别、消息列表等）
  - 管理类和工具类
- `ShipSwift/Docs/` — 后端开发文档（CDK、Auth、Database、Lambda 等）
- `ShipSwift/View/` — 示例视图

---

## 产品：基于 Recipe 的 MCP Server

每个功能以独立的 **Recipe** 组织 — 为 AI 消费优化的完整实现方案。

MCP Server 部署为 AWS 上的**远程 HTTP 服务**，所有 Recipe（免费和付费）从服务端返回，用户无需本地安装。

```
架构：

┌──────────────┐   HTTP (Streamable)   ┌──────────────────────────────┐
│  AI 客户端    │ ◄──────────────────► │  AWS (CDK)                    │
│  Claude Code │                       │                                │
│  Cursor      │                       │  App Runner (Hono)            │
│  Windsurf    │                       │  ├── MCP transport layer      │
│  ...         │                       │  ├── listRecipes              │
└──────────────┘                       │  ├── getRecipe (free/pro)     │
                                       │  └── searchRecipes            │
                                       │                                │
                                       │  Aurora Serverless v2         │
                                       │  ├── recipes (内容)           │
                                       │  └── licenses (密钥校验)      │
                                       └──────────────────────────────┘
```

### 用户安装

```bash
# 免费用户 — 一条命令，无需安装运行时
claude mcp add --transport http shipswift https://api.shipswift.dev/mcp

# 付费用户 — 带上 license key
claude mcp add --transport http shipswift https://api.shipswift.dev/mcp \
  --header "Authorization: Bearer sk-xxxxx"
```

### 为什么选择远程 HTTP

- **零安装** — 不需要 Node.js、Python、不需要下载任何东西，一条命令指向 URL 即可
- **即时更新** — 修改 Recipe 后所有用户立即生效
- **内容保护** — Pro Recipe 不经过有效 license 不会离开服务器
- **统一服务** — 一个 App Runner 服务对接所有客户端（Claude Code、Cursor、Windsurf 等）
- **低成本** — App Runner + Aurora Serverless 闲时自动缩容，早期成本极低

### 工具发现机制

AI 客户端通过 MCP 协议的两层机制发现和使用 Recipe：

**第一层：工具发现（连接时自动完成）**

客户端连接 MCP Server 时，协议自动调用 `tools/list`，AI 获取所有可用工具：

```json
{
  "tools": [
    {
      "name": "listRecipes",
      "description": "列出所有可用的 ShipSwift iOS 开发 Recipe。当用户需要实现以下功能时调用：认证、订阅、AI 对话、语音输入、UI 组件、动画、Onboarding、付费墙、基础设施部署、数据库配置。返回每个 Recipe 的 id、标题、tier(free/pro) 和简介。"
    },
    {
      "name": "getRecipe",
      "description": "获取指定 Recipe 的完整内容，包含架构决策、完整代码实现、集成清单和已知陷阱。",
      "inputSchema": { "recipeId": "string" }
    },
    {
      "name": "searchRecipes",
      "description": "按关键词搜索 Recipe。当用户需求不能直接匹配到具体 Recipe 时使用。",
      "inputSchema": { "query": "string" }
    }
  ]
}
```

**第二层：Recipe 发现（AI 按需调用）**

```
用户："帮我加订阅功能"

1. AI 看到自己有 listRecipes 工具
2. AI 调用 listRecipes() → 服务端返回 Recipe 列表
3. AI 匹配到 subscription-storekit 与用户需求相关
4. AI 调用 getRecipe("subscription-storekit")
5. 服务端校验 license → 返回完整内容（或购买提示）
6. AI 基于 Recipe 内容生成生产级代码
```

**关键：tool description 决定 AI 是否主动调用。** description 需要明确列出覆盖的功能场景，AI 才能在正确的时机自动调用，让用户体验无缝。

**description 动态生成：** `listRecipes` 的 description 从数据库实时拼接，新增 Recipe 后自动包含，无需改代码或重新部署：

```typescript
async function buildListRecipesDescription(): Promise<string> {
  const recipes = await db.query.recipes.findMany({
    columns: { id: true, title: true }
  })

  const keywords = recipes.map(r => r.title).join('、')

  return (
    `列出所有可用的 ShipSwift iOS 开发 Recipe。` +
    `当用户需要实现以下功能时调用：${keywords}。` +
    `返回每个 Recipe 的 id、标题、tier(free/pro) 和简介。`
  )
}
```

---

## Recipe 格式规范

每个 Recipe 遵循固定结构，确保 AI 解析一致：

```markdown
---
id: auth-cognito
requires: []
pairs_with: [subscription-storekit, ai-chat-streaming]
platform: ios + aws
complexity: medium
---

# Recipe 标题

## 解决什么问题
[一句话说明]

## 架构决策
[为什么选这个方案，与替代方案的 trade-off]

## 依赖
[精确到版本的依赖列表]

## 实现
### iOS
[完整 Swift 代码，关键决策点有内联注释]

### 后端
[CDK 定义 + Lambda handler]

## 集成清单
- [ ] 步骤 1: ...
- [ ] 步骤 2: ...

## 常见定制
- 想加 Google 登录？→ 修改这里
- 想改为验证码登录？→ 参考 variants/otp.md

## 已知陷阱
[来自生产环境的真实 bug 和边界情况]
```

关键设计：
- AI 读一个 `recipe.md` 就有完整上下文，不需要跨文件查找
- `pairs_with` 告诉 AI 模块间的搭配关系
- `常见定制` 让 AI 能应对用户的个性化需求
- `已知陷阱` 是核心壁垒 — 实战经验，Stack Overflow 上找不到

---

## 商业模式：开放核心 + 一次性买断

### 定价

| 层级 | 价格 | 内容 |
|------|------|------|
| **Free** | $0 | MCP Server + 3-4 个免费 Recipe |
| **Pro** | $79 一次性 | 全部 Recipe（当前版本 + 后续更新） |
| **升级** | $29 / 大版本 | 未来的新 Recipe 包 |

### 为什么选这个模式

1. **免费层是增长引擎** — 无需注册，一条命令即可使用免费 Recipe；MCP 生态先发优势
2. **免费 Recipe 建立信任** — 用户体验到质量差异后自然转化
3. **一次性买断符合目标用户** — 独立开发者讨厌为不是每天都用的工具付订阅
4. **升级价带来持续收入** — 新 Recipe 包老用户 $29 升级，新用户仍然 $79 全包

### License 访问控制

所有 Recipe 通过远程 HTTP 提供。付费内容通过简单的 License Key 机制控制。

```sql
-- recipes 表
recipes
├── id            -- 例如 "auth-cognito", "subscription-storekit"
├── tier          -- "free" | "pro"
├── content       -- recipe markdown 内容
└── updated_at

-- licenses 表
licenses
├── key           -- 例如 "sk-a1b2c3d4e5f6..."
├── email
├── tier          -- "pro"
├── created_at
└── expires_at    -- null = 终身有效
```

```typescript
// 服务端门控逻辑（Hono）
app.tool("getRecipe", { recipeId: z.string() }, async ({ recipeId }, c) => {
  const recipe = await db.query.recipes.findFirst({
    where: eq(recipes.id, recipeId)
  })

  if (recipe.tier === "pro") {
    const key = getAuthKey(c)
    const license = await db.query.licenses.findFirst({
      where: eq(licenses.key, key)
    })

    if (!license) {
      return { content: [{ type: "text", text:
        "🔒 这是付费 Recipe。请在 https://shipswift.dev 获取 License"
      }]}
    }
  }

  return { content: [{ type: "text", text: recipe.content }] }
})
```

没有 OAuth，没有 token 刷新，没有复杂认证流程。Header 里一个 key，数据库查一次，完事。

---

## 分发渠道

| 渠道 | 形式 | 使用场景 |
|------|------|---------|
| **MCP Server (HTTP)** | 按需获取 | 主要渠道 — 所有 AI 客户端连接同一个端点 |
| **文档网站** | 面向人类阅读 | 开发者浏览、学习、发现 |
| **Claude Project** | 上传到 Project Knowledge | 偏好离线使用的用户 |

---

## 用户旅程

```
发现 → 试用 → 转化 → 留存

1. 发现：通过 GitHub / Twitter / MCP 目录
2. 安装：一条命令
   claude mcp add --transport http shipswift https://api.shipswift.dev/mcp
3. 试用：使用免费 Recipe
   "帮我做一个引导页" → AI 调用 ShipSwift → 完美输出
4. 转化：遇到付费 Recipe
   "加订阅功能" → MCP 返回："付费 Recipe，请在 shipswift.dev 获取 License"
5. 付费：$79，配置 license key，解锁全部付费 Recipe
6. 留存：后续新 Recipe 包升级（$29）
```

---

## 现有资源盘点

### 代码资源（ShipSwift/slPackage/）

| 模块 | 内容 |
|------|------|
| slComponent | 20+ UI 组件（Heatmap, RadarChart, DonutChart, RingChart, ScatterChart, BeforeAfter, GlowScan, ThinkingIndicator 等） |
| slAnimation | 9 个动画（Shimmer, MeshGradient, Typewriter, FloatingLabels, BeforeAfter 等） |
| slView | 7 个完整页面（Auth, Paywall, Onboarding, Camera, Settings, Order, RootTab） |
| slManager | 6 个管理器（User 644行, Store 107行, Camera 249行, Alert, Loading, Location） |
| slChat | 聊天输入 + 消息列表 + 火山引擎 ASR |
| slUtil | Date/String/View 扩展 + DebugLog |
| slConfig | Constants 全局配置 |

### 文档资源（ShipSwift/Docs/）— 共 6,724 行

| 文件 | 行数 | 内容 |
|------|------|------|
| 0_cdk.md | 1,041 | CDK 架构 |
| 1_auth.md | 1,737 | Cognito 认证 |
| 2_database.md | 367 | Aurora + Drizzle ORM |
| 3_subscription.md | 841 | StoreKit 2 |
| 4_lambda.md | 356 | Lambda |
| 5_messaging.md | 215 | SES/SNS |
| 6_asr.md | 362 | 语音识别 |
| 7_streaming.md | 901 | Lambda Streaming |
| 8_export.md | 696 | 数据导出 |
| 9_ios_issue.md | 61 | iOS 问题 |

### 后端基础（07-smile-max-server/）

- Hono 4.11.7 + TypeScript 5.9.3
- CDK 2.237.1（已有 VPC, Cognito, App Runner, Aurora Serverless v2, S3）
- 当前 server.ts 仅有 health/info 端点

---

## Recipe 清单

### 免费 Recipe（展示价值）

| Recipe ID | 标题 | 来源 | 完整度 |
|-----------|------|------|--------|
| `ui-components` | SwiftUI 组件集 | slComponent 系列 20+ 个文件 | 中 |
| `animations` | 动画组件集 | slAnimation 系列 9 个文件 | 中 |
| `onboarding` | Onboarding 引导流程 | slOnboardingView | 中 |

### 付费 Recipe（解决每个 App 都需要的痛点）

| Recipe ID | 标题 | 来源 | iOS | 后端 | 完整度 |
|-----------|------|------|-----|------|--------|
| `auth-cognito` | 认证系统（Cognito + Amplify） | slUserManager + 1_auth.md | ✅ | ✅ | 高 |
| `subscription-storekit` | 订阅系统（StoreKit 2 + 服务端验证） | slStoreManager + 3_subscription.md | ✅ | ✅ | 高 |
| `ai-chat-streaming` | AI 流式对话（Lambda Streaming + SSE） | slChat + 7_streaming.md | ✅ | 部分 | 中 |
| `voice-asr` | 语音输入（火山引擎 ASR） | slChat/ASR + 6_asr.md | ✅ | ✅ | 高 |
| `infra-cdk` | 基础设施（AWS CDK 全栈） | 0_cdk.md | — | ✅ | 高 |
| `database-aurora` | 数据库（Aurora Serverless + Drizzle ORM） | 2_database.md | — | ✅ | 高 |
| `messaging` | 消息服务（SES/SNS + 阿里云短信） | 5_messaging.md | — | ✅ | 高 |
| `paywall-ui` | 付费墙 UI | slPaywallView | ✅ | — | 中 |
| `lambda` | Lambda 函数 | 4_lambda.md | — | ✅ | 高 |

**MVP 范围：3 个免费 + 6-7 个付费 Recipe，足够验证完整链路。**

---

## 分阶段实施计划

### 阶段一：MCP Server 骨架

**目标**：跑通 MCP 协议，本地 Claude Code 可连接并调用工具

**项目结构**（在 07-smile-max-server 中扩展）：

```
07-smile-max-server/src/
├── server.ts              # 现有 Hono 服务（挂载 /mcp 路由）
├── mcp/
│   ├── index.ts           # MCP Server 入口
│   ├── tools.ts           # listRecipes / getRecipe / searchRecipes
│   └── auth.ts            # License Key 校验（阶段四实现）
└── recipes/               # Recipe markdown（先用文件系统）
    ├── free/
    │   ├── ui-components.md
    │   ├── animations.md
    │   └── onboarding.md
    └── pro/
        ├── auth-cognito.md
        ├── subscription-storekit.md
        └── infra-cdk.md
```

**关键依赖**：`@modelcontextprotocol/sdk`、`zod`

**Transport**：StreamableHTTPServerTransport（远程 HTTP 模式），集成到 Hono 的 `/mcp` 路径

**MVP 简化**：Recipe 用本地 markdown 文件存储，License 校验跳过，全部免费开放

**本地验证**：
```bash
npm start
claude mcp add --transport http shipswift http://localhost:3000/mcp
# 测试："帮我做一个引导页" → AI 应调用 listRecipes → getRecipe("onboarding")
```

### 阶段二：Recipe 内容编写

**目标**：将现有代码和文档转化为 3 免费 + 3 付费 Recipe

**免费 Recipe**：ui-components、animations、onboarding

**付费 Recipe（MVP 首批）**：auth-cognito、subscription-storekit、infra-cdk

**Recipe 格式**：遵循 frontmatter + 固定章节（解决什么问题 → 架构决策 → 依赖 → 实现 → 集成清单 → 常见定制 → 已知陷阱）

### 阶段三：部署上线

- 现有 App Runner + Hono 架构直接复用（MCP 是 Hono 的一个路由）
- 配置域名 `api.shipswift.dev` 指向 App Runner
- 部署：`git push origin main`（App Runner 自动部署）

### 阶段四：数据库 + License 校验

- Drizzle ORM schema：`recipes` 表 + `licenses` 表
- License Key 校验中间件（Authorization header → 查表）
- Recipe 导入脚本（markdown → Aurora）
- 接入支付（LemonSqueezy），付款后自动生成 License Key

### 阶段五：扩展

- 更多 Recipe：AI 流式对话、语音输入 ASR、数据库、Lambda、消息服务、数据导出
- Landing Page / 文档网站（面向人类浏览）
- 提交到 MCP 目录（Anthropic 官方）
- Twitter / 独立开发者社区推广
- `listRecipes` 的 tool description 动态生成

**建议执行顺序：阶段一 → 阶段二 → 本地验证 → 阶段三 → 阶段四 → 阶段五**

---

## 技术栈

### 现有（iOS 应用模板）

- SwiftUI + Swift
- StoreKit 2（App 内购买）
- Amplify SDK（AWS 集成）
- SpriteKit（动画）
- 火山引擎（ASR）

### 后端（文档覆盖）

- AWS CDK（基础设施即代码）
- AWS Cognito（认证）
- Aurora Serverless v2（数据库）
- Lambda（无服务器函数）
- App Runner + Hono（API 服务）
- Drizzle ORM（数据库操作）

### MCP Server（待开发）

- TypeScript + Hono（App Runner）
- MCP SDK（@modelcontextprotocol/sdk）
- AWS App Runner（HTTP 服务）
- AWS Aurora Serverless v2（Recipe 内容 + License 密钥）
- AWS CDK（基础设施即代码，复用现有 CDK 经验）
- Drizzle ORM（数据库操作，复用现有模式）

---

## 路线图

### 第一阶段：MVP
- [ ] 将现有内容重组为 Recipe 格式
- [ ] 在 AWS 上构建 MCP Server（App Runner + Aurora Serverless + CDK）
- [ ] 实现 License Key 校验
- [ ] 上线 3 个免费 + 6 个付费 Recipe
- [ ] 部署到 api.shipswift.dev

### 第二阶段：发布
- [ ] Landing Page / 文档网站
- [ ] 接入支付（Gumroad / LemonSqueezy）
- [ ] 提交到 MCP 目录
- [ ] Twitter / 独立开发者社区推广

### 第三阶段：扩展
- [ ] 新 Recipe 包（CloudKit、Push Notifications、Widgets、SwiftData）
- [ ] Claude Project 预配置模板
- [ ] 面向人类的视频教程
- [ ] 社区 Recipe 贡献

---

## 附录：市场调研

> 调研时间：2026-02-09

### 市场排名（按用户/下载规模排序）

| 排名 | 产品 | 用户/下载规模 | 价格 | 定位 |
|:---:|------|-------------|------|------|
| 1 | **iOS App Templates** | 50万+ 下载, 15万+ 开发者, 5500+ 付费客户 | $99-$249/模板 | 单功能模板市场 |
| 2 | **SwiftyLaunch** | 3000+ 开发者, 200+ 已发布 App | $179-$229 | Xcode 项目生成器 |
| 3 | **WrapFast** | 34+ App 上架 App Store | $299 | AI Wrapper 专用 |
| 4 | **Swift Starter Kits** | 74 开发者 | $199 | 100+ SwiftUI 组件 |
| 5 | **ShipThatApp** | 未公开 | $269 | SwiftUI + Supabase |
| 6 | **SwiftShip** | 未公开 | 未公开 | RevenueCat + 推送 |
| 7 | **ShipiOS** | 未公开 | $79-$999 | SwiftUI 模板 |
| 8 | **The Swift Kit** | 未公开 | 未公开 | Supabase + RevenueCat |

### 市场空白

1. **同质化严重**：几乎所有产品都提供 Auth + IAP + Onboarding 三件套
2. **后端弱**：大多依赖 Firebase/Supabase，缺少自有后端方案
3. **缺乏垂直领域模板**：没有产品专注健康/美容/Fitness 细分
4. **AI 成为新卖点**：WrapFast 靠 AI Wrapper 差异化
5. **所有竞品都服务人类开发者，没有任何产品针对 AI 大模型优化**
