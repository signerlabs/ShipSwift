# AWS Lambda 开发指南

Lambda handler 代码写法、性能优化、错误处理。CDK 配置详见 [0_cdk.md](0_cdk.md#5-lambda)。

## Handler 类型

### 1. CDK Custom Resource Handler

部署时执行，如数据库迁移：

```typescript
// lib/lambda/db-migrate/index.ts
interface CloudFormationRequest {
  RequestType: 'Create' | 'Update' | 'Delete';
  PhysicalResourceId?: string;
}

export async function handler(event: CloudFormationRequest) {
  const physicalResourceId = event.PhysicalResourceId || `db-migrate-${Date.now()}`;

  // Delete 时跳过，避免 RDS Proxy 已删除导致超时
  if (event.RequestType === 'Delete') {
    return { PhysicalResourceId: physicalResourceId };
  }

  await runMigrations();

  return {
    PhysicalResourceId: physicalResourceId,
    Data: { Message: 'Migration completed' },
  };
}
```

### 2. 定时任务 Handler

EventBridge 触发：

```typescript
// lib/lambda/daily-scheduler/index.ts
interface ScheduledEvent {
  'detail-type': string;
  source: string;
  time: string;
}

export async function handler(event: ScheduledEvent) {
  console.log('Scheduled task triggered', { time: event.time });

  await processTask();

  return { statusCode: 200, body: JSON.stringify({ message: 'Done' }) };
}
```

### 3. Lambda 调用 Lambda

```typescript
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

// 初始化放在 handler 外部（重要！）
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });

export async function handler(event: any) {
  const response = await lambdaClient.send(
    new InvokeCommand({
      FunctionName: process.env.TARGET_LAMBDA_ARN,
      InvocationType: 'RequestResponse',
      Payload: JSON.stringify({ key: 'value' }),
    })
  );

  const result = JSON.parse(new TextDecoder().decode(response.Payload));
  return result;
}
```

## 性能优化

### 初始化放在 handler 外部

Lambda 会复用执行环境，外部初始化的对象可被后续调用复用：

```typescript
// 好：复用连接
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });
const db = await getDb();

export async function handler(event: any) {
  await lambdaClient.send(...);
  await db.select(...);
}
```

```typescript
// 差：每次调用都初始化
export async function handler(event: any) {
  const lambdaClient = new LambdaClient(...);  // 浪费时间
  const db = await getDb();  // 浪费时间
}
```

### 内存配置

内存增加会同比增加 CPU：

| 场景 | 推荐内存 |
|------|----------|
| 简单任务 | 512 MB |
| 数据处理 | 1024-2048 MB |
| 计算密集 | 3008+ MB |

## 错误处理

### 幂等性

写入前检查是否已存在：

```typescript
const [existing] = await db
  .select()
  .from(records)
  .where(eq(records.id, recordId))
  .limit(1);

if (existing) {
  return { success: true, skipped: true };
}

await db.insert(records).values({ ... });
```

### Custom Resource 错误

失败会触发 CDK 回滚：

```typescript
export async function handler(event: CloudFormationRequest) {
  try {
    await doWork();
    return { PhysicalResourceId: '...' };
  } catch (error) {
    console.error('Error:', error);
    throw error;  // 触发回滚
  }
}
```

## 日志

结构化日志便于 CloudWatch 查询：

```typescript
console.log(JSON.stringify({
  level: 'info',
  message: 'Processing started',
  userId,
  timestamp: new Date().toISOString(),
}));
```

## 常见问题

### 1. 超时

**症状**：Task timed out after X seconds

**检查**：
- VPC Lambda 是否能访问目标（安全组、NAT）
- 数据库连接是否正常
- 增加 timeout 配置

### 2. 无法访问 Secrets Manager

**症状**：`getaddrinfo ENOTFOUND secretsmanager.*.amazonaws.com`

**原因**：VPC Lambda 无法访问公网

**解决**：确保有 NAT Gateway 或添加 VPC 端点

### 3. ESM 模块问题

**症状**：`require is not defined`

**解决**：CDK bundling 添加 banner：

```typescript
bundling: {
  format: OutputFormat.ESM,
  banner: {
    js: `import { createRequire } from 'module'; const require = createRequire(import.meta.url);`,
  },
}
```

### 4. 依赖找不到

**症状**：`Cannot find module 'xxx'`

**解决**：CDK bundling 添加到 nodeModules：

```typescript
bundling: {
  nodeModules: ['drizzle-orm', 'postgres'],
}
```
