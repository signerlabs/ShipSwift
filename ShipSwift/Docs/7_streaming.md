# 7. 流式传输 (Lambda Response Streaming)

AWS Lambda Response Streaming API 实现真正的 SSE 流式传输，适用于 AI 聊天、实时日志等场景。

## 为什么使用 Lambda Response Streaming？

### App Runner vs Lambda Function URL 对比

| 对比项 | App Runner | Lambda Function URL (Response Streaming) |
|--------|-----------|------------------------------------------|
| **流式响应** | ❌ 缓冲 6-7 秒后一次性返回 | ✅ 每个 token 立即传输 (~1.6s 首次响应) |
| **缓冲控制** | ❌ 无法禁用内部缓冲机制 | ✅ `streamifyResponse()` 原生支持零缓冲 |
| **用户体验** | ❌ 等待卡顿，突然出现完整内容 | ✅ 流畅的打字机效果，实时反馈 |
| **成本模型** | 持续运行（即使空闲） | 按调用计费（冷启动 ~500ms） |
| **适用场景** | REST API、CRUD 操作 | AI 聊天、实时流、日志输出 |

### 性能指标对比（实测数据）

**App Runner 问题：**
- OpenAI 开始响应后，需要等待 6-7 秒
- 完整内容突然出现，用户体验差

**Lambda Function URL：**
- OpenAI 首次响应：~1.6 秒
- SSE 转发延迟：0ms（立即转发，零缓冲）
- 用户首次看到内容：~2-4 秒（含网络 + Lambda 冷启动）

**改进效果：**
- 首次响应时间从 6-7 秒降低到 2-4 秒
- 用户体验从"卡顿等待"变为"流畅打字"

---

## 架构设计

### 混合架构：Lambda + App Runner

```
┌─────────────────────────────────────────────────────────────────────┐
│                          iOS Client                                 │
└───────────┬────────────────────────────┬────────────────────────────┘
            │                            │
            │ SSE Stream                 │ REST API
            ▼                            ▼
┌────────────────────────────┐  ┌────────────────────────────┐
│  Lambda Function URL       │  │    App Runner              │
│  (Response Streaming)      │  │    (CRUD APIs)             │
│  ──────────────────────    │  │    ──────────────────────  │
│  • POST /chat (流式)       │  │  • GET /conversations      │
│  • JWT 本地解析            │  │  • GET /messages           │
│  • VPC 访问 RDS Proxy      │  │  • DELETE /conversation    │
└────────────┬───────────────┘  └────────────┬───────────────┘
             │                               │
             └───────────┬───────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │   RDS   │    │   S3    │    │ OpenAI  │
    │  Proxy  │    │ Bucket  │    │   API   │
    └─────────┘    └─────────┘    └─────────┘
```

**设计原则：**
- **流式响应** → Lambda Function URL
- **其他 API** → App Runner（更简单，无需考虑冷启动）

---

## 实现步骤

### 1. CDK 配置：启用 Response Streaming

```typescript
// cdk/constructs/chat-lambda-construct.ts
import * as cdk from "aws-cdk-lib";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import { Construct } from "constructs";

export interface ChatLambdaConstructProps {
  vpc: ec2.IVpc;
  dbSecretArn: string;
  dbHost: string;
  dbPort: string;
  dbName: string;
  appSecretArn: string;
}

export class ChatLambdaConstruct extends Construct {
  public readonly lambda: lambda.Function;
  public readonly functionUrl: lambda.FunctionUrl;

  constructor(scope: Construct, id: string, props: ChatLambdaConstructProps) {
    super(scope, id);

    // 创建 Lambda 函数
    this.lambda = new lambda.Function(this, "ChatProcessor", {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: "index.handler",
      code: lambda.Code.fromAsset("cdk/lambda/chat-processor", {
        bundling: {
          image: lambda.Runtime.NODEJS_22_X.bundlingImage,
          command: [
            "bash",
            "-c",
            "npm install && cp -r /asset-input/* /asset-output/",
          ],
        },
      }),
      timeout: cdk.Duration.seconds(120),
      memorySize: 1024,
      vpc: props.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      environment: {
        DB_SECRET_ARN: props.dbSecretArn,
        DB_HOST: props.dbHost,
        DB_PORT: props.dbPort,
        DB_NAME: props.dbName,
        APP_SECRET_ARN: props.appSecretArn,
        NODE_ENV: "production",
      },
    });

    // 🔑 关键：创建 Function URL 并启用 Response Streaming
    this.functionUrl = this.lambda.addFunctionUrl({
      authType: lambda.FunctionUrlAuthType.NONE,
      invokeMode: lambda.InvokeMode.RESPONSE_STREAM,  // 启用流式响应
      cors: {
        allowedOrigins: ["*"],
        allowedMethods: [lambda.HttpMethod.POST],
        allowedHeaders: ["*"],
        maxAge: cdk.Duration.hours(1),
      },
    });

    // 输出 Function URL
    new cdk.CfnOutput(this, "ChatLambdaFunctionUrl", {
      value: this.functionUrl.url,
      description: "Chat Lambda Function URL (Response Streaming)",
    });
  }
}
```

**关键配置：**
- `invokeMode: InvokeMode.RESPONSE_STREAM` - 必须设置，否则无法使用流式 API
- `authType: NONE` - Lambda 内部处理 JWT 验证
- `cors` - iOS 客户端跨域配置

---

### 2. Lambda Handler：streamifyResponse

```typescript
// cdk/lambda/chat-processor/index.ts
import { streamText } from "ai";
import { createOpenAI } from "@ai-sdk/openai";
import type { Context as LambdaContext } from "aws-lambda";
import type { Writable } from "stream";

// 🔑 声明全局 awslambda 对象（Lambda Runtime 提供）
declare const awslambda: {
  streamifyResponse(
    handler: (
      event: any,
      responseStream: Writable,
      context: LambdaContext
    ) => Promise<void>
  ): (event: any, context: LambdaContext) => Promise<void>;

  HttpResponseStream: {
    from(
      responseStream: Writable,
      metadata: { statusCode: number; headers: Record<string, string> }
    ): Writable;
  };
};

// Handler 实现
async function handleChatStream(
  event: any,
  responseStream: Writable,
  context: LambdaContext
): Promise<void> {
  // 🔑 使用 HttpResponseStream.from 设置响应头
  const stream = awslambda.HttpResponseStream.from(responseStream, {
    statusCode: 200,
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
    },
  });

  try {
    // 1. JWT 验证
    const token = event.headers?.authorization?.replace(/^Bearer\s+/i, "");
    const cognitoSub = validateToken(token);

    // 2. 查询用户、构建上下文
    const userId = await getUserId(cognitoSub);
    const conversationId = await getOrCreateConversation(userId, message);
    const [historyMessages, context] = await Promise.all([
      getConversationMessages(conversationId),
      getChatContext(userId),
    ]);

    // 3. 构建 System Prompt
    const systemPrompt = buildSystemPrompt(context);
    const apiKey = await getOpenAIApiKey();
    const openai = createOpenAI({ apiKey });

    // 4. 🔑 流式生成（Vercel AI SDK）
    const result = streamText({
      model: openai("gpt-5.2-chat-latest"),
      system: systemPrompt,
      messages: historyMessages,
    });

    // 5. 🔑 直接迭代 textStream - 每个 token 立即传输（零缓冲）
    let fullResponse = "";
    for await (const chunk of result.textStream) {
      fullResponse += chunk;

      // 立即写入流，不等待下一个 chunk
      stream.write(formatSSE({ type: "text-delta", content: chunk }));
    }

    // 6. 保存对话到数据库
    await saveMessage(conversationId, "assistant", fullResponse);
    await touchConversation(conversationId);

    // 7. 发送完成事件
    stream.write(formatSSE({ type: "finish", conversationId }));
  } catch (error) {
    stream.write(formatSSE({ type: "error", message: "Internal error" }));
  } finally {
    stream.end();
  }
}

// 🔑 导出包装后的 handler
export const handler = awslambda.streamifyResponse(handleChatStream);

// SSE 格式化工具
function formatSSE(data: object): string {
  return `data: ${JSON.stringify(data)}\n\n`;
}
```

**关键点：**

1. **`awslambda.streamifyResponse()`** - 包装 handler，启用流式响应
2. **`HttpResponseStream.from()`** - 创建响应流，设置 SSE 响应头
3. **`for await (const chunk of result.textStream)`** - 直接迭代，无缓冲
4. **`stream.write()` + `stream.end()`** - 写入数据并关闭流

---

### 3. JWT 本地解析（避免 Cognito API）

**为什么不用 `GetUserCommand`？**

```typescript
// ❌ 错误方式：调用 Cognito API
import { CognitoIdentityProviderClient, GetUserCommand } from "@aws-sdk/client-cognito-identity-provider";

const cognitoClient = new CognitoIdentityProviderClient({});

async function validateToken(token: string): Promise<string> {
  // 问题 1：GetUserCommand 需要 Access Token，但 iOS 发送的是 ID Token
  // 问题 2：每次调用都有网络延迟（~100ms）
  // 问题 3：Lambda 冷启动需要初始化 Cognito Client
  const response = await cognitoClient.send(
    new GetUserCommand({ AccessToken: token })
  );
  return response.UserAttributes?.find(attr => attr.Name === "sub")?.Value!;
}
```

**✅ 正确方式：本地解析 JWT**

```typescript
// ✅ 正确方式：本地解析 ID Token
function parseJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    // JWT payload 是 base64url 编码
    const payload = parts[1]!;

    // base64url -> base64
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");

    // 解码
    const decoded = Buffer.from(base64, "base64").toString("utf-8");
    return JSON.parse(decoded);
  } catch (error) {
    console.error("JWT parse error:", error);
    return null;
  }
}

function validateToken(token: string): string {
  const payload = parseJwtPayload(token);

  if (!payload?.sub || typeof payload.sub !== "string") {
    throw new Error("UNAUTHORIZED");
  }

  // 检查过期时间
  if (payload.exp && typeof payload.exp === "number") {
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      throw new Error("TOKEN_EXPIRED");
    }
  }

  return payload.sub;
}
```

**优势：**
- ✅ 无网络调用，零延迟
- ✅ 无需初始化 AWS SDK Client
- ✅ 支持 ID Token（iOS 发送的 token 类型）
- ✅ 可选验证过期时间

**安全性说明：**
- 在生产环境中，应该验证 JWT 签名（使用 Cognito 公钥）
- 对于受信任的客户端（iOS App），简化验证可以接受
- 如果需要更严格的安全性，可以添加签名验证逻辑

---

## iOS 客户端集成

### EventSource / SSE 解析

```swift
// Services/ChatService.swift
import Foundation

actor ChatService {
    func sendMessage(
        _ message: String,
        conversationId: String? = nil,
        onDelta: @escaping (String) -> Void,
        onFinish: @escaping (String, String, String) -> Void
    ) async throws {
        guard let url = URL(string: "https://xxx.lambda-url.us-east-1.on.aws/") else {
            throw ChatError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "message": message,
            "conversationId": conversationId as Any
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // URLSession 支持 SSE 流式解析
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.requestFailed
        }

        var buffer = ""
        for try await byte in bytes {
            let char = String(UnicodeScalar(byte))
            buffer.append(char)

            // SSE 格式：data: {...}\n\n
            if buffer.hasSuffix("\n\n") {
                let lines = buffer.components(separatedBy: "\n")
                for line in lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = line.dropFirst(6)  // 去掉 "data: "
                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let type = json["type"] as? String {

                            switch type {
                            case "text-delta":
                                if let content = json["content"] as? String {
                                    onDelta(content)
                                }
                            case "finish":
                                if let convId = json["conversationId"] as? String,
                                   let userMsgId = json["userMessageId"] as? String,
                                   let assistantMsgId = json["assistantMessageId"] as? String {
                                    onFinish(convId, userMsgId, assistantMsgId)
                                }
                            case "error":
                                throw ChatError.streamError
                            default:
                                break
                            }
                        }
                    }
                }
                buffer = ""
            }
        }
    }
}
```

---

## 性能优化建议

### 1. 减少冷启动

**问题：** Lambda 冷启动 ~500ms

**优化：**
```typescript
// 在 handler 外部初始化连接（复用）
let db: ReturnType<typeof drizzle> | null = null;
let openaiApiKey: string | null = null;

async function initDb() {
  if (db) return db;  // 复用已有连接

  const credentials = await getDbCredentials();
  const connectionString = `postgres://...`;

  const dbClient = postgres(connectionString, {
    max: 1,                // Lambda 单并发，只需 1 个连接
    idle_timeout: 20,
    connect_timeout: 30,
  });

  db = drizzle(dbClient);
  return db;
}

async function getOpenAIApiKey(): Promise<string> {
  if (openaiApiKey) return openaiApiKey;  // 复用
  const secrets = await getAppSecrets();
  openaiApiKey = secrets.OPENAI_API_KEY;
  return openaiApiKey;
}
```

### 2. 并行加载上下文

```typescript
// ✅ 好：并行获取
const [historyMessages, context] = await Promise.all([
  getConversationMessages(conversationId),
  getChatContext(userId),
]);

// ❌ 差：串行等待
const historyMessages = await getConversationMessages(conversationId);
const context = await getChatContext(userId);
```

### 3. 最小化数据库查询

```typescript
// ✅ 好：只查询需要的字段
const [user] = await db
  .select({ id: users.id })
  .from(users)
  .where(eq(users.cognitoSub, cognitoSub))
  .limit(1);

// ❌ 差：查询所有字段
const [user] = await db
  .select()
  .from(users)
  .where(eq(users.cognitoSub, cognitoSub))
  .limit(1);
```

---

## 常见问题

### Q1: Lambda Function URL 支持 VPC 吗？

**A:** 支持。Lambda 函数本身可以配置 VPC，Function URL 是公网入口：

```typescript
const chatLambda = new lambda.Function(this, "ChatProcessor", {
  vpc: props.vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
  // ... 其他配置
});
```

客户端 → Function URL (公网) → Lambda (VPC) → RDS Proxy (VPC)

### Q2: Response Streaming 有大小限制吗？

**A:** 有限制：
- **响应体大小**：最多 20MB
- **超时时间**：最多 15 分钟
- **适用场景**：AI 聊天、实时日志等中等数据量场景

### Q3: 如何调试 Lambda Response Streaming？

**A:** 使用 CloudWatch Logs：

```bash
# 查看最近 10 分钟的日志
aws logs tail /aws/lambda/brushmo-chat-processor --since 10m --follow

# 查看特定 request
aws logs tail /aws/lambda/brushmo-chat-processor --since 1h --filter-pattern "RequestId: xxx"
```

### Q4: 为什么不直接用 App Runner？

**A:** App Runner 无法禁用内部缓冲机制，SSE 流会被缓冲 6-7 秒后一次性返回。Lambda Response Streaming 提供原生流式 API，零缓冲。

### Q5: Lambda + App Runner 混合架构的成本如何？

**A:**
- **Lambda**：按调用计费，空闲时零成本，适合低频流式请求
- **App Runner**：持续运行，适合高频 REST API

对于聊天场景（低频但需要流式），Lambda 更划算。

---

## 参考资料

- [AWS Lambda Response Streaming 官方文档](https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html)
- [Vercel AI SDK - streamText](https://sdk.vercel.ai/docs/ai-sdk-core/generating-text#streaming)
- [Server-Sent Events (SSE) 规范](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [JWT 解析实践](https://jwt.io/)

---

## 总结

**Lambda Response Streaming 最佳实践：**

✅ **使用场景**：需要实时流式响应（AI 聊天、日志流、实时数据）
✅ **核心 API**：`awslambda.streamifyResponse()` + `HttpResponseStream.from()`
✅ **CDK 配置**：`invokeMode: InvokeMode.RESPONSE_STREAM`
✅ **JWT 验证**：本地解析 ID Token（避免 Cognito API 调用）
✅ **性能**：零缓冲，每个 token 立即传输
✅ **兼容性**：与 Vercel AI SDK 完美集成

❌ **不适用**：简单 REST API（直接用 App Runner 更简单）
❌ **限制**：响应体不能超过 20MB，超时时间最多 15 分钟

**架构建议：**
- **流式响应** → Lambda Function URL
- **CRUD API** → App Runner
- **混合使用** → 最优成本和性能
