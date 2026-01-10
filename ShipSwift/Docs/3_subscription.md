# iOS 订阅系统最佳实践

基于 **StoreKit 2 + App Store Server API** 的订阅系统实现指南。

## 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS Client                                │
│  ┌──────────────────┐              ┌─────────────────────────┐  │
│  │   StoreManager   │              │      APIService         │  │
│  │   (StoreKit 2)   │              │    (HTTP Client)        │  │
│  └────────┬─────────┘              └────────────┬────────────┘  │
└───────────┼──────────────────────────────────────┼──────────────┘
            │                                      │
            │ 购买请求                              │ Bearer Token
            ▼                                      ▼
    ┌───────────────┐                     ┌─────────────────────────────────┐
    │   App Store   │                     │         API Gateway             │
    │               │                     │  ┌─────────────────────────┐    │
    └───────┬───────┘                     │  │ 公开路由（无认证）       │    │
            │                             │  │ /health                 │    │
            │                             │  │ /v1/subscriptions/webhook│←───┼─── Apple
            │                             │  ├─────────────────────────┤    │
            │                             │  │ 受保护路由（JWT 认证）   │    │
            │                             │  │ /{proxy+}               │    │
            │                             │  └─────────────────────────┘    │
            │                             └──────────────┬──────────────────┘
            │                                            │
            │ Transaction (JWS)                          ▼
            │                             ┌─────────────────────────────────┐
            │                             │          App Runner (Hono)       │
            │                             │                                  │
            │                             │  /v1/subscriptions/verify  [认证] │
            │                             │  /v1/subscriptions/status  [认证] │
            │                             │  /v1/subscriptions/webhook [公开] │
            │                             └──────────────┬──────────────────┘
            │                                            │
            │                                            │ 验证 JWS 签名
            │                                            ▼
            │                             ┌─────────────────────────────────┐
            │                             │        Aurora Database          │
            └─────────────────────────────│  - subscriptions                │
                                          │  - subscription_transactions    │
                                          └─────────────────────────────────┘
```

### 核心流程

1. **购买流程**：用户购买 → StoreKit 返回 JWS → iOS 调用 verify API → 存储订阅状态
2. **试用期转正**：Apple 调用 Webhook（`DID_RENEW`）→ 更新 `is_trial_period = false`
3. **状态同步**：App 启动时调用 status API，与本地 StoreKit 状态对比
4. **续期/过期处理**：Apple 通过 Webhook 实时通知状态变更

---

## 订阅产品设计

### 推荐产品结构

| Product ID | 类型 | 周期 | 免费试用 |
|------------|------|------|----------|
| `com.yourcompany.app.monthly` | Auto-Renewable | 1 个月 | 7 天 |
| `com.yourcompany.app.quarterly` | Auto-Renewable | 3 个月 | 7 天 |
| `com.yourcompany.app.yearly` | Auto-Renewable | 12 个月 | 7 天 |

### 用户状态流转

**Apple 试用期扣款机制**：
- 购买时需绑定支付方式并确认订阅，但**不扣款**
- 试用期内可随时取消，**不产生任何费用**
- 试用期结束后自动扣款，开始正式订阅周期

```
                              ┌─────────────┐
                              │   未订阅    │
                              └──────┬──────┘
                                     │ 购买（绑定支付方式，不扣款）
                                     ▼
                              ┌─────────────┐
                              │  试用期中   │ (7天免费)
                              │   (trial)   │
                              └──────┬──────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
                    ▼                                 ▼
             试用期内取消                        试用结束
             (不扣款)                           (自动扣款)
                    │                                 │
                    ▼                                 ▼
             ┌───────────┐                     ┌───────────┐
             │  已过期   │                     │ 正式订阅  │
             │ (expired) │                     │ (active)  │
             └───────────┘                     └─────┬─────┘
                                                     │
                              ┌──────────────────────┼──────────────────────┐
                              │                      │                      │
                              ▼                      ▼                      ▼
                         用户取消                续期成功              扣费失败
                              │                      │                      │
                              ▼                      ▼                      ▼
                       ┌───────────┐          ┌───────────┐          ┌───────────┐
                       │ 已取消    │          │ 正式订阅  │          │  已过期   │
                       │(cancelled)│          │ (active)  │          │ (expired) │
                       │ 到期前有效 │          └───────────┘          └───────────┘
                       └─────┬─────┘
                             │
                             ▼
                       ┌───────────┐
                       │  已过期   │
                       │ (expired) │
                       └───────────┘
```

### App Store Notification 事件对照

| 通知类型 | 子类型 | 含义 | 状态变更 |
|----------|--------|------|----------|
| `SUBSCRIBED` | `INITIAL_BUY` | 首次订阅（含试用） | → `trial` 或 `active` |
| `SUBSCRIBED` | `RESUBSCRIBE` | 重新订阅 | → `active` |
| `DID_RENEW` | - | 试用结束转正式 / 续期成功 | → `active` |
| `DID_CHANGE_RENEWAL_STATUS` | `AUTO_RENEW_DISABLED` | 用户取消自动续期 | → `cancelled` |
| `DID_CHANGE_RENEWAL_STATUS` | `AUTO_RENEW_ENABLED` | 用户重新开启续期 | → `active` |
| `EXPIRED` | `VOLUNTARY` | 用户主动取消后到期 | → `expired` |
| `EXPIRED` | `BILLING_RETRY` | 扣费失败过期 | → `expired` |
| `DID_FAIL_TO_RENEW` | - | 扣费失败 | → `expired` |
| `REFUND` | - | 退款 | → `expired` |

---

## 数据库设计

### subscriptions 表

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Apple 订阅标识
    original_transaction_id VARCHAR(255) NOT NULL UNIQUE,
    product_id VARCHAR(255) NOT NULL,

    -- 订阅状态: trial, active, cancelled, expired
    status VARCHAR(50) NOT NULL,

    -- 试用期信息
    is_trial_period BOOLEAN NOT NULL DEFAULT false,
    trial_start_at TIMESTAMP WITH TIME ZONE,
    trial_end_at TIMESTAMP WITH TIME ZONE,

    -- 时间信息
    purchase_date TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,

    -- 续期信息
    auto_renew_status BOOLEAN DEFAULT true,
    auto_renew_product_id VARCHAR(255),

    -- 环境: Production, Sandbox
    environment VARCHAR(20) NOT NULL DEFAULT 'Production',

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT check_subscription_status
        CHECK (status IN ('trial', 'active', 'cancelled', 'expired'))
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at);
```

### subscription_transactions 表

用于审计和问题排查：

```sql
CREATE TABLE subscription_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,

    -- 交易标识
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    original_transaction_id VARCHAR(255) NOT NULL,

    -- 交易类型（来自 App Store Notification）
    notification_type VARCHAR(50) NOT NULL,
    subtype VARCHAR(50),

    -- 原始数据（用于调试）
    signed_transaction_info TEXT,
    signed_renewal_info TEXT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscription_transactions_original_id
    ON subscription_transactions(original_transaction_id);
```

### Drizzle Schema

```typescript
// lib/db/schema.ts
import { pgTable, uuid, varchar, text, timestamp, boolean, check } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),

  originalTransactionId: varchar('original_transaction_id', { length: 255 }).notNull().unique(),
  productId: varchar('product_id', { length: 255 }).notNull(),

  status: varchar('status', { length: 50 }).notNull(),

  isTrialPeriod: boolean('is_trial_period').notNull().default(false),
  trialStartAt: timestamp('trial_start_at', { withTimezone: true }),
  trialEndAt: timestamp('trial_end_at', { withTimezone: true }),

  purchaseDate: timestamp('purchase_date', { withTimezone: true }).notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }),

  autoRenewStatus: boolean('auto_renew_status').default(true),
  autoRenewProductId: varchar('auto_renew_product_id', { length: 255 }),

  environment: varchar('environment', { length: 20 }).notNull().default('Production'),

  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (table) => ({
  statusCheck: check('check_subscription_status',
    sql`status IN ('trial', 'active', 'cancelled', 'expired')`
  ),
}));

export const subscriptionTransactions = pgTable('subscription_transactions', {
  id: uuid('id').primaryKey().defaultRandom(),
  subscriptionId: uuid('subscription_id').references(() => subscriptions.id, { onDelete: 'set null' }),

  transactionId: varchar('transaction_id', { length: 255 }).notNull().unique(),
  originalTransactionId: varchar('original_transaction_id', { length: 255 }).notNull(),

  notificationType: varchar('notification_type', { length: 50 }).notNull(),
  subtype: varchar('subtype', { length: 50 }),

  signedTransactionInfo: text('signed_transaction_info'),
  signedRenewalInfo: text('signed_renewal_info'),

  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
```

---

## 后端实现

### 环境变量配置

```bash
# App Store Server API
APPLE_KEY_ID=XXXXXXXXXX                              # Key ID
APPLE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # Issuer ID
APPLE_PRIVATE_KEY=LS0tLS1CRUdJTi4uLg==               # Base64 编码的私钥
APPLE_BUNDLE_ID=com.yourcompany.app                  # Bundle ID
APPLE_APP_ID=123456789                               # App Store App ID
```

**私钥 Base64 编码**：
```bash
base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'
```

### API 端点

| 端点 | 认证 | 说明 |
|------|------|------|
| `POST /v1/subscriptions/verify` | JWT | iOS 购买后验证 |
| `GET /v1/subscriptions/status` | JWT | 查询订阅状态 |
| `POST /v1/subscriptions/webhook` | 公开 | Apple 回调 |

> CDK 公开路由配置详见 [0_cdk.md](0_cdk.md#http-api--jwt-authorizer)

### 实现示例

```typescript
// src/routes/subscription.ts
import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { SignedDataVerifier, Environment } from '@apple/app-store-server-library';
import { readFileSync } from 'fs';
import { join } from 'path';

const subscription = new Hono();

// 产品白名单
const ALLOWED_PRODUCT_IDS = [
  'com.yourcompany.app.monthly',
  'com.yourcompany.app.quarterly',
  'com.yourcompany.app.yearly',
];

// Apple 根证书
const appleRootCAs = [
  readFileSync(join(__dirname, '../certs/AppleRootCA-G3.cer')),
  readFileSync(join(__dirname, '../certs/AppleWWDRCAG6.cer')),
];

function getVerifier(env: Environment): SignedDataVerifier {
  const privateKey = Buffer.from(process.env.APPLE_PRIVATE_KEY!, 'base64').toString('utf-8');
  return new SignedDataVerifier(
    appleRootCAs,
    true,
    env,
    process.env.APPLE_BUNDLE_ID!,
    Number(process.env.APPLE_APP_ID!)
  );
}

// POST /v1/subscriptions/verify
subscription.post('/verify', authMiddleware, async (c) => {
  const cognitoSub = getUserId(c);
  const { signedTransactionInfo } = await c.req.json();

  // 1. 验证 JWS（先尝试 Sandbox，再尝试 Production）
  let transaction;
  let env = Environment.SANDBOX;
  try {
    transaction = await getVerifier(env).verifyAndDecodeTransaction(signedTransactionInfo);
  } catch {
    env = Environment.PRODUCTION;
    transaction = await getVerifier(env).verifyAndDecodeTransaction(signedTransactionInfo);
  }

  // 2. 校验产品 ID
  if (!ALLOWED_PRODUCT_IDS.includes(transaction.productId)) {
    throw new HTTPException(400, { message: '无效的产品 ID' });
  }

  // 3. 校验 appAccountToken（防止跨账号重放）
  if (transaction.appAccountToken !== cognitoSub) {
    throw new HTTPException(403, { message: '交易不属于当前用户' });
  }

  // 4. 存储订阅状态
  const isTrialPeriod = transaction.offerType === 1;
  const status = isTrialPeriod ? 'trial' : 'active';

  // ... 存储到数据库

  return c.json({ success: true, subscription: { ... } });
});

// GET /v1/subscriptions/status
subscription.get('/status', authMiddleware, async (c) => {
  const cognitoSub = getUserId(c);
  // ... 查询并返回订阅状态
});

// POST /v1/subscriptions/webhook (公开)
subscription.post('/webhook', async (c) => {
  const { signedPayload } = await c.req.json();

  // 验证并解析通知
  const notification = await getVerifier(env).verifyAndDecodeNotification(signedPayload);

  // 幂等检查（使用 notificationUUID）
  // ...

  // 根据 notificationType 更新订阅状态
  switch (notification.notificationType) {
    case 'DID_RENEW':
      // 更新为 active
      break;
    case 'EXPIRED':
    case 'DID_FAIL_TO_RENEW':
    case 'REFUND':
      // 更新为 expired
      break;
    case 'DID_CHANGE_RENEWAL_STATUS':
      // 更新 auto_renew_status
      break;
  }

  return c.json({ success: true });
});

export default subscription;
```

---

## iOS 客户端实现

### StoreManager

```swift
import StoreKit

@Observable
class StoreManager {
    private(set) var products: [Product] = []
    private(set) var isPro: Bool = false
    private(set) var isTrialPeriod: Bool = false

    // MARK: - 加载产品

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                "com.yourcompany.app.monthly",
                "com.yourcompany.app.quarterly",
                "com.yourcompany.app.yearly"
            ])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - 购买（带 appAccountToken 绑定）

    func purchase(_ product: Product, userIdentifier: String) async throws -> Bool {
        guard let appAccountToken = UUID(uuidString: userIdentifier) else {
            throw StoreError.invalidUserIdentifier
        }

        let result = try await product.purchase(options: [
            .appAccountToken(appAccountToken)
        ])

        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await syncToServer(transaction: transaction)
            await updatePurchaseStatus()
            return true

        case .success(.unverified):
            throw StoreError.verificationFailed

        case .pending:
            return false

        case .userCancelled:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - 后端同步

    private func syncToServer(transaction: Transaction) async {
        guard let jws = transaction.jwsRepresentation else { return }

        do {
            let tokens = try await AuthService.shared.fetchTokens()
            _ = try await APIService.shared.verifySubscription(
                idToken: tokens.idToken,
                signedTransactionInfo: jws
            )
        } catch {
            print("Server sync failed: \(error)")
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            await syncToServer(transaction: transaction)
        }
        await updatePurchaseStatus()
    }
}
```

### APIService 扩展

```swift
// MARK: - Subscription API

func verifySubscription(idToken: String, signedTransactionInfo: String) async throws -> SubscriptionResponse {
    let url = try buildURL(path: "/v1/subscriptions/verify")
    let body = ["signedTransactionInfo": signedTransactionInfo]
    let request = createRequest(url: url, method: "POST", idToken: idToken, body: body)
    return try await execute(request: request)
}

func getSubscriptionStatus(idToken: String) async throws -> SubscriptionStatusResponse {
    let url = try buildURL(path: "/v1/subscriptions/status")
    let request = createRequest(url: url, method: "GET", idToken: idToken)
    return try await execute(request: request)
}

// MARK: - Models

struct SubscriptionResponse: Codable {
    let success: Bool
    let subscription: SubscriptionInfo
}

struct SubscriptionStatusResponse: Codable {
    let hasActiveSubscription: Bool
    let subscription: SubscriptionInfo?
}

struct SubscriptionInfo: Codable {
    let productId: String
    let status: String
    let isTrialPeriod: Bool
    let expiresAt: String?
    let autoRenewStatus: Bool
}
```

---

## App Store Connect 配置

### 1. 创建订阅产品

1. 进入 **App** → **Subscriptions**
2. 创建 **Subscription Group**
3. 创建订阅产品，配置周期和价格

### 2. 配置免费试用

1. 订阅产品 → **Subscription Prices** → **Introductory Offers**
2. **Type**: Free Trial
3. **Duration**: 1 Week

### 3. 创建 App Store Server API Key

1. **Users and Access** → **Integrations** → **In-App Purchase**
2. **Generate API Key**
3. 下载 `.p8` 文件，记录 Key ID 和 Issuer ID

### 4. 配置 Server Notifications V2

1. **App** → **App Information** → **App Store Server Notifications**
2. 选择 **Version 2 Notifications**
3. 配置 Webhook URL

---

## 安全考虑

### 1. 用户绑定（appAccountToken）

防止跨账号重放攻击：

```swift
// iOS: 购买时绑定用户
let result = try await product.purchase(options: [
    .appAccountToken(UUID(uuidString: cognitoSub)!)
])
```

```typescript
// 后端: 验证时校验
if (transaction.appAccountToken !== cognitoSub) {
    throw new HTTPException(403, { message: '交易不属于当前用户' });
}
```

### 2. JWS 签名验证

所有来自客户端的交易必须通过 Apple 根证书验证签名。

### 3. Webhook 幂等

使用 `notificationUUID` 作为幂等键：

```typescript
const existing = await db.select()
    .from(subscriptionTransactions)
    .where(eq(subscriptionTransactions.transactionId, notification.notificationUUID));

if (existing.length > 0) {
    return c.json({ success: true }); // 已处理
}
```

### 4. 产品白名单

只接受预定义的产品 ID。

### 5. 试用期防滥用

Apple 自动处理，同一 Apple ID 只能享受一次免费试用。

---

## 测试

### Sandbox 订阅时间映射

| 实际周期 | Sandbox 周期 | 试用期 |
|----------|--------------|--------|
| 1 周 | 3 分钟 | ~25 秒 |
| 1 个月 | 5 分钟 | ~25 秒 |
| 3 个月 | 15 分钟 | ~25 秒 |
| 1 年 | 1 小时 | ~25 秒 |

### Xcode StoreKit 本地测试

1. 创建 StoreKit Configuration File（可同步 App Store Connect）
2. Scheme → Run → Options → 选择配置文件
3. 使用 Debug → StoreKit → Manage Transactions 管理测试交易

> **注意**：Xcode 本地测试的 JWS 由 Xcode 签名，后端验证会失败。可设置 `SKIP_JWS_VERIFICATION=true`（仅限开发环境）。

---

## 参考资料

- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [App Store Server Notifications V2](https://developer.apple.com/documentation/appstoreservernotifications)
- [StoreKit 2](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [@apple/app-store-server-library](https://github.com/apple/app-store-server-library-node)
