# 数据库架构最佳实践

## 技术栈

- **数据库引擎**: Amazon Aurora Serverless v2 (PostgreSQL 15)
- **连接池**: Amazon RDS Proxy
- **ORM**: Drizzle ORM
- **运行时**: App Runner (生产) / Docker PostgreSQL (本地开发)

## 架构

```
App Runner (VPC)
    │
    ▼
RDS Proxy (VPC Private Subnet)
    │
    ▼
Aurora Cluster (VPC Isolated Subnet)
```

### 架构优势

1. **RDS Proxy**: 连接池管理，避免 Serverless 连接风暴
2. **Aurora Serverless v2**: 自动扩缩容，按需计费
3. **VPC 隔离**: 数据库在 Isolated Subnet，仅通过 Proxy 访问

## 连接配置

### 生产环境

通过 Secrets Manager 获取凭证：

```typescript
// lib/db/client.ts
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

async function loadDbCredentials(secretArn: string) {
  const client = new SecretsManagerClient({});
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: secretArn })
  );
  return JSON.parse(response.SecretString!);
}

// 初始化时加载
if (process.env.DB_SECRET_ARN) {
  const credentials = await loadDbCredentials(process.env.DB_SECRET_ARN);
  username = credentials.username;
  password = credentials.password;
}
```

环境变量：
- `DB_HOST`: RDS Proxy 端点
- `DB_NAME`: 数据库名称
- `DB_SECRET_ARN`: Secrets Manager ARN

### 本地开发

直接使用环境变量：

```bash
# .env.local
DB_HOST=localhost
DB_NAME=my_database
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

## 本地开发命令

```json
// package.json scripts
{
  "db:start": "docker run --name my-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=my_database -p 5432:5432 -d postgres:15",
  "db:stop": "docker rm -f my-postgres",
  "db:migrate": "drizzle-kit migrate",
  "db:reset": "npm run db:stop && npm run db:start && sleep 2 && npm run db:migrate"
}
```

```bash
# 启动 PostgreSQL 容器
npm run db:start

# 运行迁移
npm run db:migrate

# 停止并删除容器
npm run db:stop

# 重置数据库（停止→启动→迁移）
npm run db:reset
```

## 查看数据

```bash
# 查看所有表
docker exec my-postgres psql -U postgres -d my_database -c "\dt"

# 查看表数据
docker exec my-postgres psql -U postgres -d my_database -c "SELECT * FROM users;"

# 进入交互模式
docker exec -it my-postgres psql -U postgres -d my_database
```

## Drizzle ORM 配置

### drizzle.config.ts

```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './lib/db/schema.ts',
  out: './drizzle/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 5432,
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'my_database',
  },
});
```

### Schema 示例

```typescript
// lib/db/schema.ts
import { pgTable, uuid, varchar, timestamp, text } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  cognitoSub: varchar('cognito_sub', { length: 255 }).notNull().unique(),
  email: varchar('email', { length: 255 }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

// 类型导出
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

### 数据库客户端

```typescript
// lib/db/client.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

let db: ReturnType<typeof drizzle<typeof schema>> | null = null;

export async function getDb() {
  if (db) return db;

  let username = process.env.DB_USERNAME || 'postgres';
  let password = process.env.DB_PASSWORD || 'postgres';

  // 生产环境从 Secrets Manager 获取凭证
  if (process.env.DB_SECRET_ARN) {
    const credentials = await loadDbCredentials(process.env.DB_SECRET_ARN);
    username = credentials.username;
    password = credentials.password;
  }

  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME,
    user: username,
    password: password,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  db = drizzle(pool, { schema });
  return db;
}
```

> CDK 配置详见 [0_cdk.md](0_cdk.md#2-databaseconstruct)

## 迁移管理

```bash
# 生成迁移文件
npx drizzle-kit generate

# 执行迁移
npx drizzle-kit migrate

# 查看迁移状态
npx drizzle-kit status
```

迁移文件位置: `drizzle/migrations/`
