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

### 3. Lambda 调用 Lambda（同步）

```typescript
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

// 初始化放在 handler 外部（重要！）
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });

export async function handler(event: any) {
  const response = await lambdaClient.send(
    new InvokeCommand({
      FunctionName: process.env.TARGET_LAMBDA_ARN,
      InvocationType: 'RequestResponse',  // 同步调用，等待结果
      Payload: JSON.stringify({ key: 'value' }),
    })
  );

  const result = JSON.parse(new TextDecoder().decode(response.Payload));
  return result;
}
```

### 4. 异步任务处理 Handler (Fire-and-Forget)

App Runner 触发 Lambda 后立即返回，Lambda 在后台处理并更新数据库状态。适用于 AI 生成、图像处理等耗时任务。

#### 架构

```
┌─────────────────┐    POST /api/tasks     ┌─────────────────┐
│   iOS Client    │ ───────────────────────▶│   App Runner    │
└────────┬────────┘                         └────────┬────────┘
         │                                           │
         │ GET /api/tasks/:id (轮询)                 │ Lambda.invoke(Event)
         │                                           ▼
         │                                  ┌─────────────────┐
         │                                  │  Task Processor │
         │                                  │     Lambda      │
         │                                  └────────┬────────┘
         │                                           │
         │                                           ▼ 更新状态
         │                                  ┌─────────────────┐
         └─────────────────────────────────▶│    Database     │
                    读取结果                 └─────────────────┘
```

#### App Runner 端（触发 Lambda）

```typescript
// src/services/task-processor.service.ts
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });

export async function triggerTask(taskId: string, type: string, input: any): Promise<boolean> {
  try {
    await lambdaClient.send(
      new InvokeCommand({
        FunctionName: process.env.TASK_PROCESSOR_LAMBDA_ARN,
        InvocationType: 'Event',  // 异步调用，不等待结果
        Payload: JSON.stringify({ taskId, type, input }),
      })
    );
    return true;
  } catch (error) {
    console.error('Failed to trigger task', error);
    return false;
  }
}
```

#### Route Handler

```typescript
// src/routes/tasks.ts
app.post('/api/tasks', async (c) => {
  const { type, input } = await c.req.json();
  const userId = c.get('userId');

  // 1. 创建任务记录
  const [task] = await db.insert(tasks).values({
    userId,
    type,
    status: 'pending',
  }).returning();

  // 2. 异步触发 Lambda（fire-and-forget）
  await triggerTask(task.id, type, input);

  // 3. 立即返回 taskId
  return c.json({ taskId: task.id });
});

app.get('/api/tasks/:id', async (c) => {
  const taskId = c.req.param('id');
  const [task] = await db.select().from(tasks).where(eq(tasks.id, taskId));
  return c.json(task);
});
```

#### Lambda Handler

```typescript
// lib/lambda/task-processor/index.ts
interface TaskPayload {
  taskId: string;
  type: string;
  input: Record<string, unknown>;
}

export async function handler(event: TaskPayload) {
  const { taskId, type, input } = event;
  const db = await getDb();

  // 更新状态为 processing
  await db.update(tasks)
    .set({ status: 'processing', updatedAt: new Date() })
    .where(eq(tasks.id, taskId));

  try {
    // 根据类型路由到对应处理器
    const result = await processTask(type, input);

    // 更新为 completed
    await db.update(tasks)
      .set({ status: 'completed', result, updatedAt: new Date() })
      .where(eq(tasks.id, taskId));

    return { statusCode: 200 };
  } catch (error) {
    // 更新为 failed
    await db.update(tasks)
      .set({ status: 'failed', error: error.message, updatedAt: new Date() })
      .where(eq(tasks.id, taskId));

    return { statusCode: 500 };
  }
}
```

#### 任务状态

| 状态 | 说明 |
|------|------|
| `pending` | 任务已创建，等待 Lambda 处理 |
| `processing` | Lambda 正在处理 |
| `completed` | 处理完成，result 字段包含结果 |
| `failed` | 处理失败，error 字段包含错误信息 |

#### 数据库 Schema

```typescript
export const tasks = pgTable('tasks', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  type: varchar('type', { length: 50 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('pending'),
  input: jsonb('input'),
  result: jsonb('result'),
  error: text('error'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});
```

#### 注意事项

1. **幂等性**：Lambda 可能重试，处理器需要幂等
2. **超时**：Lambda 默认 3 秒，AI 任务需要设置更长（如 5 分钟）
3. **VPC 访问**：Lambda 需要访问 RDS Proxy，需配置 VPC 和安全组
4. **状态更新失败**：使用重试机制确保状态更新成功

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
