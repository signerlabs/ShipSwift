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

### 本地开发

```bash
# 生成迁移文件
npx drizzle-kit generate

# 执行迁移
npx drizzle-kit migrate

# 查看迁移状态
npx drizzle-kit status
```

迁移文件位置: `drizzle/`

### 生产环境迁移（推荐：应用启动时迁移）

**推荐在应用启动时自动执行迁移**，而不是使用 Lambda 或 CI/CD 流水线。

```typescript
// src/lib/migrate.ts
import { migrate } from "drizzle-orm/postgres-js/migrator";
import { getDb } from "../../lib/db/client.js";
import { logger } from "./logger.js";
import * as path from "path";
import * as fs from "fs";

function getMigrationsFolder(): string {
  const possiblePaths = [
    path.resolve(__dirname, "../../../drizzle"),  // 生产环境
    path.resolve(__dirname, "../../drizzle"),     // 开发环境
    path.resolve(process.cwd(), "drizzle"),       // 相对于 cwd
  ];

  for (const p of possiblePaths) {
    if (fs.existsSync(p)) return p;
  }
  return possiblePaths[0]!;
}

export async function runMigrations(): Promise<void> {
  const migrationsFolder = getMigrationsFolder();

  // 列出迁移文件（调试用）
  const files = fs.readdirSync(migrationsFolder)
    .filter(f => f.endsWith('.sql'))
    .sort();
  logger.info({ folder: migrationsFolder, count: files.length }, "[Migrate] Files found");

  // 执行迁移
  const db = await getDb();
  await migrate(db, { migrationsFolder });
  logger.info("[Migrate] Completed successfully");
}
```

```typescript
// src/server.ts
import { runMigrations } from "./lib/migrate.js";

async function startServer() {
  // 1. 执行数据库迁移
  try {
    await runMigrations();
  } catch (err) {
    logger.error({ err }, "[Startup] Migration failed, continuing...");
  }

  // 2. 启动 HTTP 服务
  serve({ fetch: app.fetch, port });
}

startServer();
```

**为什么推荐应用启动时迁移：**

| 方案 | 优点 | 缺点 |
|------|------|------|
| **应用启动时迁移** ✅ | 迁移文件随代码部署，无打包问题 | 迁移失败可能阻止启动 |
| Lambda 自定义资源 | 与 CDK 部署集成 | 打包机制复杂，容易出错 |
| CI/CD 流水线 | 迁移与部署解耦 | 需要额外的基础设施访问配置 |

**App Runner 部署流程：**

```
git push origin main
    ↓
App Runner 自动构建和部署
    ↓
应用启动时执行迁移（drizzle migrate）
    ↓
启动 HTTP 服务
```

## 迁移最佳实践

### 核心原则

1. **始终使用 `drizzle-kit generate`** 生成迁移文件，避免手动创建
2. **一个表只在一个迁移中创建**，不要在多个迁移文件中重复定义
3. **检查 `_journal.json` 时间戳**，确保时间戳严格递增

### 幂等 SQL 写法

**drizzle-kit 生成的 SQL 默认不是幂等的**，手动修改或创建迁移时必须使用幂等语句：

```sql
-- ========================================
-- 创建表
-- ========================================

-- ✅ 正确：使用 IF NOT EXISTS
CREATE TABLE IF NOT EXISTS "appointments" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "name" varchar(100) NOT NULL
);

-- ========================================
-- 添加列
-- ========================================

-- ✅ 正确：使用异常处理
DO $$ BEGIN
  ALTER TABLE "users" ADD COLUMN "identity_id" varchar(255) UNIQUE;
EXCEPTION
  WHEN duplicate_column THEN null;
END $$;

-- ❌ 错误：重复执行会失败
ALTER TABLE "users" ADD COLUMN "identity_id" varchar(255);

-- ========================================
-- 重命名列
-- ========================================

-- ✅ 正确：使用异常处理
DO $$ BEGIN
  ALTER TABLE "user_profiles" RENAME COLUMN "old_name" TO "new_name";
EXCEPTION
  WHEN undefined_column THEN null;
END $$;

-- ========================================
-- 添加枚举值
-- ========================================

-- ✅ 正确：使用 IF NOT EXISTS（PostgreSQL 9.3+）
ALTER TYPE "public"."status_enum" ADD VALUE IF NOT EXISTS 'new_status';

-- ❌ 错误：drizzle-kit 默认生成的（重复执行会失败）
ALTER TYPE "public"."status_enum" ADD VALUE 'new_status';

-- ========================================
-- 创建索引
-- ========================================

-- ✅ 正确：使用 IF NOT EXISTS
CREATE INDEX IF NOT EXISTS "idx_user_id" ON "appointments" ("user_id");

-- ========================================
-- 添加外键约束
-- ========================================

-- ✅ 正确：检查约束是否存在
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'appointments_user_id_fk'
  ) THEN
    ALTER TABLE "appointments" ADD CONSTRAINT "appointments_user_id_fk"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE cascade;
  END IF;
END $$;
```

**重要提示：** drizzle-kit generate 生成的迁移文件需要手动检查并添加幂等语法。

### Drizzle 迁移机制

Drizzle 在数据库中维护 `__drizzle_migrations` 表跟踪已执行的迁移：

```sql
-- 查看迁移记录
SELECT * FROM drizzle.__drizzle_migrations;
```

**注意事项：**
- 迁移按 `_journal.json` 中的 `idx` 顺序执行
- 如果迁移 hash 已存在，即使 SQL 执行失败，drizzle 也会跳过
- 日志显示 "Migrations completed successfully" 不代表 SQL 真正执行成功

### 常见问题排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 迁移显示成功但表不存在 | 迁移记录已存在，被跳过 | 创建新的幂等迁移文件 |
| `_journal.json` 时间戳乱序 | 手动创建迁移时时间戳错误 | 确保新迁移时间戳大于前一个 |
| `duplicate_object` 错误 | 约束已存在 | 使用 `DO $$ ... EXCEPTION` 包装 |
| 多个迁移创建同一个表 | 迁移文件重复 | 删除重复的迁移，只保留一个 |

### 修复迁移问题

当迁移状态混乱时，创建修复迁移：

```sql
-- 0004_fix_table.sql
-- 使用完全幂等的语句，无论之前状态如何都能正确执行

CREATE TABLE IF NOT EXISTS "my_table" (...);

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'my_fk') THEN
    ALTER TABLE "my_table" ADD CONSTRAINT "my_fk" ...;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "my_idx" ON "my_table" (...);
```
