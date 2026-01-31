# 认证系统最佳实践

本文档定义了基于 **API Gateway + Cognito** 的认证架构最佳实践，适用于 iOS App + Serverless 后端的项目。

## 架构概览

采用 **客户端直连 Cognito + API Gateway JWT 验证** 架构，同时支持匿名访客模式：

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Client                               │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │   AuthService   │              │      APIService         │   │
│  │  (Amplify SDK)  │              │    (HTTP Client)        │   │
│  └────────┬────────┘              └────────────┬────────────┘   │
└───────────┼────────────────────────────────────┼────────────────┘
            │                                    │
            ▼ 直连认证                           ▼ Bearer Token / Identity ID
    ┌───────────────┐                   ┌─────────────────────┐
    │    Cognito    │◄──────────┐       │   API Gateway       │
    │   User Pool   │           │       │  (JWT Authorizer)   │
    │  + Hosted UI  │           │       └──────────┬──────────┘
    └───────────────┘           │                  │
            ▲                   │                  ▼
            │ OAuth             │       ┌─────────────────────┐
    ┌───────────────┐           │       │     App Runner      │
    │  Identity     │───────────┘       │    (Hono 后端)      │
    │  Providers    │                   └─────────────────────┘
    │ Apple/Google  │
    └───────────────┘

    ┌───────────────┐
    │ Identity Pool │  ◄── 支持匿名访客 (Unauthenticated)
    │ (可选)        │      访客也能获得唯一 Identity ID
    └───────────────┘
```

### 核心优势

1. **开发/生产一致**：本地开发和线上使用相同的认证流程
2. **安全性**：密码不经过后端，JWT 由 API Gateway 统一验证
3. **可扩展**：通过配置 Identity Provider 支持多种登录方式
4. **简化后端**：后端只处理业务逻辑，不涉及认证

> CDK 配置详见 [0_cdk.md](0_cdk.md#4-cognito--api-gateway)

---

## 匿名登录（访客模式）

使用 Cognito Identity Pool 支持匿名用户，让用户无需注册即可使用核心功能。**这是默认的最佳实践架构**。

### 核心概念

| 概念 | 说明 |
|------|------|
| **User Pool** | 管理已注册用户（邮箱、Apple、Google 登录） |
| **Identity Pool** | 为所有用户（包括匿名访客）提供唯一 Identity ID 和 AWS 临时凭证 |
| **Identity ID** | 每个用户的唯一标识，格式如 `us-east-1:abc123-def456-...` |
| **previousIdentityId** | 登录前保存的匿名 Identity ID，用于数据迁移 |

### 完整工作流程

```
首次打开 App
    │
    ↓
获取 Identity ID（Cognito Identity Pool）
    │
    ↓
SessionState = .anonymous(identityId: "us-east-1:abc...")
    │
    ├─ 使用功能（扫描、查看历史等）
    │   └─ API 请求携带 X-Identity-Id header
    │   └─ 后端通过 identityId 创建/查找匿名用户
    │
    ↓
用户点击登录
    │
    ↓
⚠️ 保存 previousIdentityId = 当前 identityId
    │
    ↓
Cognito 登录成功
    │
    ↓
⚠️ Cognito 分配新的 identityId（已认证身份，与匿名时不同！）
    │
    ↓
调用 POST /api/auth/sync
    ├─ identityId: 新的已认证 identityId
    └─ previousIdentityId: 匿名时的 identityId
    │
    ↓
后端处理：
    ├─ 查找/创建已登录用户
    └─ 迁移匿名用户数据到已登录用户
    │
    ↓
SessionState = .authenticated(identityId, tokens, profile)
```

### ⚠️ 关键问题：Identity ID 变化

**Cognito Identity Pool 在用户状态变化时会分配不同的 Identity ID：**
- 匿名用户：`us-east-1:anonymous-xxx-xxx`
- 已认证用户：`us-east-1:authenticated-xxx-xxx`（**不同！**）

**解决方案**：在登录前保存 `previousIdentityId`，登录后传给后端进行数据迁移。

### ⚠️ 重要限制

**删除 App 后 Identity ID 会丢失！**

- Identity ID 缓存在 App 本地存储
- 卸载 App 后，本地缓存被清除
- 重新安装会获得新的 Identity ID
- **结论**：匿名用户数据在卸载后无法恢复（可接受的设计）

### CDK 配置

> 完整 CDK 配置详见 [0_cdk.md](0_cdk.md#5-identity-pool-匿名登录)

```typescript
import * as cognito from 'aws-cdk-lib/aws-cognito';

// Identity Pool
const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
  identityPoolName: 'my-app-identity-pool',
  allowUnauthenticatedIdentities: true,  // 允许匿名访客
  cognitoIdentityProviders: [{
    clientId: userPoolClient.userPoolClientId,
    providerName: userPool.userPoolProviderName,
  }],
});

// IAM 角色配置（区分匿名和已认证用户）
const unauthenticatedRole = new iam.Role(this, 'UnauthRole', {
  assumedBy: new iam.FederatedPrincipal(
    'cognito-identity.amazonaws.com',
    {
      StringEquals: { 'cognito-identity.amazonaws.com:aud': identityPool.ref },
      'ForAnyValue:StringLike': { 'cognito-identity.amazonaws.com:amr': 'unauthenticated' },
    },
    'sts:AssumeRoleWithWebIdentity'
  ),
});

// 匿名用户权限（限制访问自己的数据）
unauthenticatedRole.addToPolicy(new iam.PolicyStatement({
  actions: ['s3:PutObject', 's3:GetObject'],
  resources: [`arn:aws:s3:::${bucket.bucketName}/\${cognito-identity.amazonaws.com:sub}/*`],
}));
```

### iOS 客户端配置

#### amplifyconfiguration.json

在现有配置基础上添加 `CredentialsProvider` 部分：

```json
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_XXXXXXXX",
            "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
            "Region": "us-east-1"
          }
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
              "Region": "us-east-1"
            }
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "myapp-auth.auth.us-east-1.amazoncognito.com",
              "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
              "SignInRedirectURI": "myapp://callback",
              "SignOutRedirectURI": "myapp://signout",
              "Scopes": ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
            },
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  }
}
```

#### AuthService 扩展

```swift
import Amplify
import AWSCognitoAuthPlugin

extension AuthService {

    // MARK: - 匿名登录

    /// 获取当前用户的 Identity ID（匿名或已登录用户都有）
    func fetchIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw ServiceError.sessionInvalid
        }

        switch cognitoSession.getIdentityId() {
        case .success(let identityId):
            return identityId
        case .failure(let error):
            throw error
        }
    }

    /// 获取 AWS 临时凭证（用于直接访问 S3 等 AWS 服务）
    func fetchAWSCredentials() async throws -> AWSTemporaryCredentials {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw ServiceError.sessionInvalid
        }

        switch cognitoSession.getAWSCredentials() {
        case .success(let credentials):
            guard let tempCredentials = credentials as? AWSTemporaryCredentials else {
                throw ServiceError.credentialsInvalid
            }
            return tempCredentials
        case .failure(let error):
            throw error
        }
    }

    /// 检查当前是否为匿名用户
    func isGuestUser() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return !session.isSignedIn
        } catch {
            return true
        }
    }
}
```

#### 使用示例

```swift
// App 启动时获取 Identity ID
func onAppLaunch() async {
    do {
        let identityId = try await AuthService.shared.fetchIdentityId()
        print("用户 Identity ID: \(identityId)")

        // 用 identityId 作为用户标识，同步数据到后端
        await syncUserData(identityId: identityId)
    } catch {
        print("获取 Identity ID 失败: \(error)")
    }
}

// 检查用户状态并引导注册
func checkAndPromptSignUp() async {
    let isGuest = await AuthService.shared.isGuestUser()

    if isGuest {
        // 显示注册引导
        showSignUpPrompt()
    }
}
```

### 后端 API 设计

#### 中间件：支持匿名和已登录用户

```typescript
// 匿名用户中间件（仅需 Identity ID）
export const identityMiddleware = createMiddleware<IdentityContext>(async (c, next) => {
  const identityId = c.req.header("x-identity-id");
  if (!identityId) {
    throw new HTTPException(401, { message: "Missing x-identity-id header" });
  }
  c.set("identityId", identityId);
  await next();
});

// 已登录用户中间件（需要 JWT）
export const jwtMiddleware = createMiddleware<JwtContext>(async (c, next) => {
  // 验证 JWT 并设置 jwtPayload
  await next();
});
```

#### 用户同步 API（关键！处理数据迁移）

```typescript
// POST /api/auth/sync - 登录后同步用户身份
const syncSchema = z.object({
  identityId: z.string().min(1),
  previousIdentityId: z.string().optional(),  // 匿名时的 identityId
});

r.post("/sync", jwtMiddleware, async (c) => {
  const cognitoSub = getCognitoSub(c);
  const { identityId, previousIdentityId } = syncSchema.parse(await c.req.json());

  // 1. 查找现有用户（通过 cognitoSub）
  let existingUser = await db.select().from(users)
    .where(eq(users.cognitoSub, cognitoSub)).limit(1);

  if (existingUser.length > 0) {
    // 更新 identityId
    await db.update(users)
      .set({ identityId, updatedAt: new Date() })
      .where(eq(users.id, existingUser[0].id));

    // 迁移匿名用户数据
    if (previousIdentityId && previousIdentityId !== identityId) {
      await migrateGuestData(previousIdentityId, existingUser[0].id);
    }
    return c.json({ userId: existingUser[0].id });
  }

  // 2. 创建新用户
  const [newUser] = await db.insert(users).values({
    cognitoSub, identityId, isGuest: false,
  }).returning();

  // 迁移匿名用户数据
  if (previousIdentityId && previousIdentityId !== identityId) {
    await migrateGuestData(previousIdentityId, newUser.id);
  }

  return c.json({ userId: newUser.id });
});

// 数据迁移函数
async function migrateGuestData(previousIdentityId: string, targetUserId: string) {
  const guestUser = await db.select().from(users)
    .where(and(eq(users.identityId, previousIdentityId), eq(users.isGuest, true)))
    .limit(1);

  if (guestUser.length === 0) return;

  const guestUserId = guestUser[0].id;

  // 迁移所有关联数据到目标用户
  await db.update(reports).set({ userId: targetUserId }).where(eq(reports.userId, guestUserId));
  await db.update(conversations).set({ userId: targetUserId }).where(eq(conversations.userId, guestUserId));
  // ... 其他表

  // 删除匿名用户记录
  await db.delete(users).where(eq(users.id, guestUserId));
  console.log(`Migrated guest data from ${guestUserId} to ${targetUserId}`);
}
```

#### API Gateway 路由配置

匿名用户需要访问某些 API，但不需要 JWT 认证。通过 API Gateway 配置专用路由：

| 路由 | 授权类型 | 说明 |
|------|---------|------|
| `GET /api/scan` | NONE | 匿名用户获取历史 |
| `POST /api/scan` | NONE | 匿名用户创建扫描 |
| `GET /api/scan/{proxy+}` | NONE | 匿名用户获取详情 |
| `{proxy+}` | JWT | 其他 API 需要登录 |

### 数据库设计

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cognito_sub VARCHAR(255) UNIQUE,          -- 仅已登录用户有
  identity_id VARCHAR(255) NOT NULL UNIQUE, -- 所有用户都有
  is_guest BOOLEAN NOT NULL DEFAULT true,   -- 是否匿名用户
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_identity_id ON users(identity_id);
CREATE INDEX idx_users_cognito_sub ON users(cognito_sub);
```

### 功能权限矩阵

| 功能 | 匿名用户 | 已登录用户 |
|------|---------|-----------|
| 核心功能（扫描等） | ✅ | ✅ |
| 查看历史 | ✅ | ✅ |
| Chat 聊天 | ❌ 需登录 | ✅ |
| 跨设备同步 | ❌ | ✅ |

---

## iOS 客户端配置

### 1. SPM 依赖

在 Xcode 中添加 Swift Package:
- URL: `https://github.com/aws-amplify/amplify-swift`
- 添加产品: `Amplify`, `AWSCognitoAuthPlugin`, `AWSPluginsCore`

### 2. Xcode 配置

1. **Sign in with Apple Capability**: `Signing & Capabilities` → 添加
2. **URL Scheme**: `Info` → `URL Types` → 添加 `myapp`

### 3. amplifyconfiguration.json

```json
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify/cli",
        "Version": "0.1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "ap-southeast-1_XXXXXXXX",
            "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
            "Region": "ap-southeast-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "OAuth": {
              "WebDomain": "my-app-auth.auth.ap-southeast-1.amazoncognito.com",
              "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
              "SignInRedirectURI": "myapp://callback",
              "SignOutRedirectURI": "myapp://signout",
              "Scopes": ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
            }
          }
        }
      }
    }
  }
}
```

### 4. App 初始化

```swift
import Amplify
import AWSCognitoAuthPlugin

@main
struct MyApp: App {
    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
        } catch {
            fatalError("Amplify 配置失败: \(error)")
        }
    }
}
```

### 5. AuthService.swift

```swift
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

struct AuthTokens: Equatable {
    let idToken: String
    let accessToken: String
    let refreshToken: String
}

actor AuthService {
    static let shared = AuthService()

    // MARK: - 社交登录

    /// Apple 登录
    func signInWithApple(presentationAnchor: AuthUIPresentationAnchor) async throws -> AuthTokens {
        // ⚠️ 使用 preferPrivateSession 跳过浏览器权限弹窗
        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)

        let result = try await Amplify.Auth.signInWithWebUI(
            for: .apple,
            presentationAnchor: presentationAnchor,
            options: options
        )

        guard result.isSignedIn else {
            throw ServiceError.notSignedIn
        }
        return try await fetchTokens()
    }

    /// Google 登录
    func signInWithGoogle(presentationAnchor: AuthUIPresentationAnchor) async throws -> AuthTokens {
        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)

        let result = try await Amplify.Auth.signInWithWebUI(
            for: .google,
            presentationAnchor: presentationAnchor,
            options: options
        )

        guard result.isSignedIn else {
            throw ServiceError.notSignedIn
        }
        return try await fetchTokens()
    }

    // MARK: - 邮箱登录

    /// 邮箱注册
    func signUp(email: String, password: String) async throws {
        _ = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: AuthSignUpRequest.Options(
                userAttributes: [AuthUserAttribute(.email, value: email)]
            )
        )
    }

    /// 确认注册
    func confirmSignUp(email: String, code: String) async throws {
        _ = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
    }

    /// 邮箱登录
    func signIn(email: String, password: String) async throws -> AuthTokens {
        let result = try await Amplify.Auth.signIn(username: email, password: password)
        guard result.isSignedIn else {
            throw ServiceError.notSignedIn
        }
        return try await fetchTokens()
    }

    // MARK: - Token 管理

    func fetchTokens() async throws -> AuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw ServiceError.tokenMissing
        }

        switch cognitoSession.getCognitoTokens() {
        case .success(let tokens):
            return AuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw ServiceError.tokenMissing
        }
    }

    func refreshSession() async throws -> AuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession(options: .forceRefresh())
        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw ServiceError.tokenMissing
        }

        switch cognitoSession.getCognitoTokens() {
        case .success(let tokens):
            return AuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw ServiceError.tokenMissing
        }
    }

    // MARK: - 登出/注销

    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    /// ⚠️ 删除账户需要 aws.cognito.signin.user.admin scope
    func deleteUser() async throws {
        try await Amplify.Auth.deleteUser()
    }

    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return session.isSignedIn
        } catch {
            return false
        }
    }
}
```

### 6. UserManager.swift（状态管理）

```swift
/// 用户会话状态
enum SessionState: Equatable {
    case loading
    case anonymous(identityId: String)
    case authenticated(identityId: String, tokens: AuthTokens, profile: UserProfile)
    case error(message: String)

    var identityId: String? {
        switch self {
        case .anonymous(let id): return id
        case .authenticated(let id, _, _): return id
        default: return nil
        }
    }

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

@MainActor
@Observable
class UserManager {
    var sessionState: SessionState = .loading

    private let authService = AuthService.shared
    private let userProfileService = UserProfileService()

    init() {
        Task { await initializeSession() }
    }

    /// App 启动时初始化会话
    func initializeSession() async {
        do {
            let identityId = try await authService.fetchIdentityId()
            let isSignedIn = await authService.isSignedIn()

            if isSignedIn {
                let tokens = try await authService.fetchTokens()
                try await userProfileService.syncUser(idToken: tokens.idToken, identityId: identityId)
                let profile = try await userProfileService.getProfile(idToken: tokens.idToken)
                sessionState = .authenticated(identityId: identityId, tokens: tokens, profile: profile)
            } else {
                sessionState = .anonymous(identityId: identityId)
            }
        } catch {
            sessionState = .error(message: error.localizedDescription)
        }
    }

    /// 社交登录（关键：保存 previousIdentityId）
    func signInWithApple(window: UIWindow) async throws {
        // ⚠️ 保存匿名时的 Identity ID
        let previousIdentityId = sessionState.identityId

        let tokens = try await authService.signInWithApple(presentationAnchor: window)
        let identityId = try await authService.fetchIdentityId()

        // ⚠️ 传入 previousIdentityId 以迁移匿名数据
        try await userProfileService.syncUser(
            idToken: tokens.idToken,
            identityId: identityId,
            previousIdentityId: previousIdentityId
        )

        let profile = try await userProfileService.getProfile(idToken: tokens.idToken)
        sessionState = .authenticated(identityId: identityId, tokens: tokens, profile: profile)
    }

    /// 登出
    func signOut() async {
        await authService.signOut()
        do {
            let identityId = try await authService.fetchIdentityId()
            sessionState = .anonymous(identityId: identityId)
        } catch {
            await initializeSession()
        }
    }
}
```

### 7. App 状态变化处理

```swift
// App.swift
.onChange(of: userManager.sessionState) { oldState, newState in
    // 从已登录变成匿名时，清空所有缓存
    if case .authenticated = oldState, case .anonymous = newState {
        clearAllCaches()
    }

    // 从匿名变成已登录时，自动加载数据
    if case .anonymous = oldState, case .authenticated = newState {
        Task { await reloadAllData() }
    }
}

private func clearAllCaches() {
    dataManager.reset()
    chatManager.reset()
}
```

---

## 删除账户流程

删除账户需要两步操作：

```swift
// UserManager.swift
func deleteAccount() async throws {
    // 1. 先删除后端用户数据
    if let idToken = sessionState.tokens?.idToken {
        try await APIService.user.deleteProfile(idToken: idToken)
    }

    // 2. 再删除 Cognito 用户
    try await authService.deleteUser()
    sessionState = .signedOut()
}
```

后端需要提供删除用户数据的接口：

```typescript
// DELETE /api/user-profile/me
r.delete('/me', async c => {
  const userId = getUserId(c)
  await service.deleteProfile(userId)
  return c.json({ success: true })
})
```

---

## Identity Provider 支持状态

| Provider | Cognito 原生支持 | 实现方式 |
|----------|-----------------|---------|
| **匿名访客** | ✅ | Identity Pool + `fetchIdentityId()` |
| Apple | ✅ | `signInWithWebUI(for: .apple)` |
| Google | ✅ | `signInWithWebUI(for: .google)` |
| Facebook | ✅ | `signInWithWebUI(for: .facebook)` |
| Amazon | ✅ | `signInWithWebUI(for: .amazon)` |
| Email/Password | ✅ | `signIn(username:password:)` |
| 手机号 + 验证码 | ✅ | 需要配置 SMS，使用 `signUp` + `confirmSignUp` |
| 微信 | ❌ | 需要自定义实现（后端 OAuth + `federatedSignIn`） |

### 微信登录实现思路（待实现）

由于 Cognito 不原生支持微信，需要：

1. iOS 集成微信 SDK 获取 `code`
2. 后端用 `code` 换取微信 `access_token` 和 `openid`
3. 后端调用 Cognito Admin API 创建/查找用户
4. 后端生成自定义 token 或使用 Cognito Identity Pool 的 `federatedSignIn`

---

## 常见问题

### 1. Apple 登录弹出浏览器权限确认框

**问题**：每次登录都显示 "xxx wants to use amazoncognito.com to sign in"

**解决**：使用 `preferPrivateSession: true`

```swift
let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)
let result = try await Amplify.Auth.signInWithWebUI(
    for: .apple,
    presentationAnchor: window,
    options: options
)
```

### 2. 删除账户报错 "Access Token does not have required scopes"

**问题**：调用 `Amplify.Auth.deleteUser()` 失败

**解决**：
1. CDK 配置添加 `cognito.OAuthScope.COGNITO_ADMIN`
2. iOS `amplifyconfiguration.json` 添加 `"aws.cognito.signin.user.admin"`
3. **重新登录**获取包含新 scope 的 token

### 3. Apple 登录先显示 Hosted UI 选择页面

**问题**：点击 Apple 登录后先显示 Cognito Hosted UI，再跳转 Apple

**解决**：`supportedIdentityProviders` 必须包含 `COGNITO`

```typescript
supportedIdentityProviders: [
  cognito.UserPoolClientIdentityProvider.COGNITO,  // ⚠️ 必须包含
  cognito.UserPoolClientIdentityProvider.custom('SignInWithApple'),
],
```

### 4. 无法修改 User Pool 的登录方式

**问题**：想从 email 改为 phone 登录，但报错 "Updates are not allowed for property - UsernameAttributes"

**原因**：Cognito User Pool 的 `signInAliases` 创建后不可修改

**解决**：
- 创建新的 User Pool
- 或者在初始配置时就包含所有可能需要的登录方式（email + phone）

### 5. Token 过期处理（重要）

**问题**：API 请求返回 401，提示"登录已过期"

**Token 生命周期**：
| Token | 有效期 | 说明 |
|-------|--------|------|
| ID Token | 1 小时 | 用于 API 认证 |
| Access Token | 1 小时 | 用于 Cognito API |
| Refresh Token | 30 天 | 用于刷新上述 Token |

**最佳实践：使用 `getFreshIdToken()` 主动刷新**

⚠️ **关键**：不要直接使用缓存的 `sessionState.tokens?.idToken`，而是在每次 API 调用前使用 `getFreshIdToken()` 获取最新 token。

```swift
// ❌ 错误做法：直接使用缓存的 token（可能已过期）
guard let idToken = userManager.sessionState.tokens?.idToken else { return }
await apiService.fetchData(idToken: idToken)

// ✅ 正确做法：每次 API 调用前获取新鲜 token
guard let idToken = await userManager.getFreshIdToken() else { return }
await apiService.fetchData(idToken: idToken)
```

**`getFreshIdToken()` 实现原理**（slUserManager.swift）：

```swift
/// 获取最新的 ID Token（自动刷新过期的 Token）
func getFreshIdToken() async -> String? {
    guard sessionState.isSignedIn else { return nil }

    do {
        // fetchTokens() 会自动检查 token 是否过期
        // 如果过期，SDK 会使用 Refresh Token 获取新 token
        let tokens = try await authService.fetchTokens()

        // 同时更新缓存的 tokens
        switch sessionState {
        case .onboarding:
            sessionState = .onboarding(tokens: tokens)
        case .ready:
            sessionState = .ready(tokens: tokens)
        default:
            break
        }

        return tokens.idToken
    } catch {
        debugLog("❌ [slUserManager] Failed to get fresh token:", error)
        return nil
    }
}
```

**为什么这样做？**

1. `authService.fetchTokens()` 调用 `Amplify.Auth.fetchAuthSession()`
2. Amplify SDK 会自动检查 ID Token 是否过期
3. 如果过期，SDK 使用 Refresh Token 获取新的 ID Token
4. 如果 Refresh Token 也过期（30 天不活跃），才需要重新登录

**效果**：
- ✅ 活跃用户（每月至少打开一次 app）基本不会看到"登录已过期"
- ✅ 只有 30 天不活跃的用户才需要重新登录

**Refresh Token 过期的兜底处理**：

```swift
// 如果 getFreshIdToken() 返回 nil，可能是 Refresh Token 过期
guard let idToken = await userManager.getFreshIdToken() else {
    // 提示用户重新登录
    await userManager.signOut()
    return
}
```

### 6. 匿名用户 Identity ID 丢失

**问题**：用户卸载重装 App 后，之前的匿名数据无法恢复

**原因**：Identity ID 缓存在 App 本地存储，卸载后丢失

**解决**：这是预期行为。可以通过以下方式缓解：
1. 引导用户在使用核心功能后尽早注册
2. 在 App 中提示："未登录状态下，卸载 App 将丢失数据"
3. 接受这个限制，将其视为产品设计的一部分

### 8. 匿名用户登录后 Identity ID 变化

**问题**：Cognito Identity Pool 在用户从匿名变为已认证时会分配新的 Identity ID，导致匿名期间的数据无法关联到登录后的账号。

**原因**：
- 匿名用户 Identity ID：`us-east-1:anonymous-xxx`
- 已认证用户 Identity ID：`us-east-1:authenticated-xxx`（不同！）

**解决方案**：在登录前保存 `previousIdentityId`，登录后传给后端进行数据迁移。

```swift
// UserManager.swift
func signInWithApple() async throws {
    // 1. 保存匿名时的 Identity ID
    let previousIdentityId = sessionState.identityId

    // 2. 执行登录
    let tokens = try await authService.signInWithApple(presentationAnchor: window)
    let identityId = try await authService.fetchIdentityId()

    // 3. 同步用户（传入 previousIdentityId 以迁移数据）
    try await userProfileService.syncUser(
        idToken: tokens.idToken,
        identityId: identityId,
        previousIdentityId: previousIdentityId  // 关键！
    )
    // ...
}
```

后端处理：
```typescript
// POST /api/auth/sync
if (previousIdentityId && previousIdentityId !== identityId) {
  // 查找匿名用户，迁移其数据到当前用户
  const guestUser = await db.select().from(users)
    .where(and(eq(users.identityId, previousIdentityId), eq(users.isGuest, true)));

  if (guestUser.length > 0) {
    // 迁移所有关联数据
    await db.update(reports).set({ userId: currentUser.id }).where(eq(reports.userId, guestUser[0].id));
    // 删除匿名用户记录
    await db.delete(users).where(eq(users.id, guestUser[0].id));
  }
}
```

### 9. 登录后状态管理最佳实践

**退出登录/删除账户后清空缓存**

在 App 主入口监听 `sessionState` 变化，自动清空缓存和重新加载数据：

```swift
// App.swift
.onChange(of: userManager.sessionState) { oldState, newState in
    // 从已登录变成匿名时，清空所有缓存
    if case .authenticated = oldState, case .anonymous = newState {
        clearAllCaches()
    }

    // 从匿名变成已登录时，自动加载数据
    if case .anonymous = oldState, case .authenticated = newState {
        Task { await reloadAllData() }
    }
}

private func clearAllCaches() {
    dataManager.reset()
    chatManager.reset()
    // ... 其他 manager
}
```

### 10. fullScreenCover 在登录后立即打开的时机问题

**问题**：登录成功后立即打开 `fullScreenCover` 可能导致背景渲染异常（透明）。

**原因**：登录 sheet 的关闭动画还没完成，就立即打开 fullScreenCover，导致动画冲突。

**错误做法**：
```swift
AuthView(mode: .sheet) {
    showAuthSheet = false
    // ❌ 延迟太短，sheet 还没关闭
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        showFullScreenCover = true
    }
}
```

**正确做法**：使用 `onDismiss` 回调，确保 sheet 完全关闭后再操作：
```swift
@State private var shouldOpenCoverAfterAuth = false

.sheet(isPresented: $showAuthSheet, onDismiss: {
    // sheet 完全关闭后才触发
    if shouldOpenCoverAfterAuth {
        shouldOpenCoverAfterAuth = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showFullScreenCover = true
        }
    }
}) {
    AuthView(mode: .sheet) {
        shouldOpenCoverAfterAuth = true
        showAuthSheet = false
    }
}
```

### 11. @Observable 类中使用 UserDefaults 存储的属性无法触发 UI 更新

**问题**：在 `@Observable` 类中使用计算属性读取 `UserDefaults`，修改值后 UI 不更新。

**原因**：计算属性不会被 `@Observable` 宏追踪，只有存储属性才会。

**错误做法**：
```swift
@Observable
class UserManager {
    // ❌ 计算属性，修改后不会触发 UI 更新
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
}
```

**正确做法**：使用存储属性 + `didSet` 同步到 UserDefaults：
```swift
@Observable
class UserManager {
    // ✅ 存储属性，会触发 UI 更新
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
}
```

**注意**：`@AppStorage` 只能在 `View` 中使用，不能在 `@Observable` 类中使用。

### 7. 匿名用户无法获取 Identity ID

**问题**：`fetchIdentityId()` 返回错误

**检查清单**：
1. Identity Pool 是否启用了 `allowUnauthenticatedIdentities: true`
2. `amplifyconfiguration.json` 是否包含 `CredentialsProvider.CognitoIdentity` 配置
3. IAM 角色是否正确配置了信任关系

---

## Token 类型说明

| Token | 用途 | 有效期 | 说明 |
|-------|------|--------|------|
| ID Token | API 认证 | 1 小时 | 放入 `Authorization: Bearer xxx` |
| Access Token | Cognito API | 1 小时 | 如更新用户属性、删除用户 |
| Refresh Token | 刷新 Token | 30 天 | 用于获取新的 ID/Access Token |

### ID Token vs Access Token 最佳实践

**⚠️ 重要：API 认证应使用 ID Token，不是 Access Token**

| 特性 | ID Token | Access Token |
|------|----------|--------------|
| 用途 | API 认证（推荐） | Cognito API 调用 |
| `aud` claim | Client ID | "access" |
| API Gateway 验证 | ✅ 通过 | ❌ 失败（401） |

**为什么使用 ID Token？**

API Gateway JWT Authorizer 配置了 `jwtAudience: [clientId]`，会验证 token 的 `aud` claim：
- ID Token 的 `aud` = Client ID → 验证通过
- Access Token 的 `aud` = "access" → 验证失败

**iOS 代码示例**：

```swift
// ✅ 正确：使用 ID Token 调用业务 API
let response = try await apiClient.request(
    endpoint,
    idToken: tokens.idToken
)

// ❌ 错误：使用 Access Token 会导致 401
let response = try await apiClient.request(
    endpoint,
    accessToken: tokens.accessToken  // 不要这样做！
)
```

**何时使用 Access Token？**

仅在调用 Cognito User Pool API 时使用：

```swift
// 调用 Cognito API 更新用户属性
await cognitoService.updateUserAttributes(
    accessToken: tokens.accessToken,  // 这里用 Access Token
    attributes: [...]
)

// 删除 Cognito 用户
try await Amplify.Auth.deleteUser()  // SDK 内部使用 Access Token
```

### iOS tRPC 客户端最佳实践

#### 响应格式处理

tRPC 使用 superjson 序列化，响应数据包装在 `json` 字段中：

```json
// tRPC 实际响应格式
{
  "result": {
    "data": {
      "json": {
        "onboardingCompleted": false
      }
    }
  }
}
```

**iOS 解码模型**：

```swift
/// tRPC 响应格式 (使用 superjson 序列化)
struct TRPCResponse<T: Decodable>: Decodable {
    let result: TRPCResult<T>
}

struct TRPCResult<T: Decodable>: Decodable {
    let data: TRPCData<T>
}

struct TRPCData<T: Decodable>: Decodable {
    let json: T  // ⚠️ 关键：数据在 json 字段内
}

// 使用示例
let response: TRPCResponse<OnboardingStatus> = try JSONDecoder().decode(...)
let status = response.result.data.json  // 访问实际数据
```

#### POST 请求 Content-Type

tRPC mutation（POST 请求）必须设置 `Content-Type: application/json`，即使没有请求体：

```swift
/// 无参数的 tRPC mutation
func post<T: Decodable>(_ endpoint: Endpoint, idToken: String) async throws -> T {
    // ⚠️ 必须发送空 JSON body，否则会返回 415 Unsupported Media Type
    let emptyBody = "{}".data(using: .utf8)
    return try await request(endpoint, body: emptyBody, idToken: idToken)
}
```

**常见错误**：

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 415 Unsupported Media Type | POST 请求没有 Content-Type | 发送空 JSON body `{}` |
| 解码失败 keyNotFound | 没有处理 superjson 的 `json` 包装 | 添加 `TRPCData` 中间层 |

---

## 完整配置流程

### 配置概览

配置 Cognito + Apple Sign In 需要完成以下步骤：

| 步骤 | 平台 | 说明 |
|------|------|------|
| 1 | Apple Developer | 创建 App ID、Services ID、Key |
| 2 | AWS CDK | 部署 Cognito User Pool |
| 3 | Apple Developer | 配置 Return URL（需要 Cognito Domain） |
| 4 | AWS Secrets Manager | 上传 Apple 私钥 |
| 5 | iOS Xcode | 配置 SPM、Capabilities、URL Scheme |
| 6 | iOS 项目 | 添加 amplifyconfiguration.json |

---

### 步骤 1: Apple Developer 配置

登录 [Apple Developer Console](https://developer.apple.com) → `Certificates, Identifiers & Profiles`

#### 1.1 创建 App ID

1. `Identifiers` → 点击 `+` → 选择 `App IDs` → Continue
2. 选择 `App` → Continue
3. 填写：
   - Description: `My App`
   - Bundle ID: `com.yourcompany.myapp`（与 Xcode 中一致）
4. 勾选 `Sign in with Apple` → Continue → Register

#### 1.2 创建 Services ID

Services ID 用于 Web/Cognito OAuth 回调。

1. `Identifiers` → 点击 `+` → 选择 `Services IDs` → Continue
2. 填写：
   - Description: `My App Auth Service`
   - Identifier: `com.yourcompany.myapp.serviceid`（建议加 `.serviceid` 后缀区分）
3. Continue → Register
4. **先不要配置 Sign in with Apple**（需要等 Cognito 部署后获取 Domain）

#### 1.3 创建 Key（私钥）

1. `Keys` → 点击 `+`
2. 填写 Key Name: `My App Sign In Key`
3. 勾选 `Sign in with Apple` → Configure
4. Primary App ID: 选择刚创建的 App ID
5. Save → Continue → Register
6. **⚠️ 立即下载 `.p8` 文件**（只能下载一次！）
7. 记录 **Key ID**（如 `6J2QTCMPYH`）

#### 1.4 获取 Team ID

`Membership` 页面 → 复制 **Team ID**（如 `C6FPV8XHV8`）

---

### 步骤 2: 部署 AWS CDK

确保 CDK 中的 Cognito 配置正确：

```typescript
// cognito-construct.ts
const appleProvider = new cognito.UserPoolIdentityProviderApple(this, 'AppleIdp', {
  userPool: this.userPool,
  clientId: 'com.yourcompany.myapp.serviceid',  // Services ID
  teamId: 'YOUR_TEAM_ID',
  keyId: 'YOUR_KEY_ID',
  privateKeyValue: props.appSecret.secretValueFromJson('AUTH_APPLE_PRIVATE_KEY'),
  scopes: ['email', 'name'],
  attributeMapping: {
    email: cognito.ProviderAttribute.APPLE_EMAIL,
    fullname: cognito.ProviderAttribute.APPLE_NAME,
  },
});
```

部署获取 Cognito Domain：

```bash
npx cdk deploy
```

部署完成后记录输出的 Cognito Domain（如 `myapp-auth.auth.us-east-1.amazoncognito.com`）

---

### 步骤 3: 配置 Apple Services ID 的 Return URL

**⚠️ 这一步必须在 CDK 部署后进行**，因为需要 Cognito Domain。

1. 回到 Apple Developer Console → `Identifiers` → 选择之前创建的 **Services ID**
2. 勾选 `Sign in with Apple` → Configure
3. 配置：

| 字段 | 值 |
|------|-----|
| **Primary App ID** | 选择你的 App ID |
| **Domains and Subdomains** | `myapp-auth.auth.us-east-1.amazoncognito.com` |
| **Return URLs** | `https://myapp-auth.auth.us-east-1.amazoncognito.com/oauth2/idpresponse` |

4. Next → Done → Continue → Save

**注意**：
- Domain 不带 `https://` 前缀
- Return URL 必须带 `https://` 和完整路径 `/oauth2/idpresponse`
- 可以配置多个 Domain/Return URL（开发、测试、生产环境）

---

### 步骤 4: 配置 AWS Secrets Manager

将 Apple 私钥（.p8 文件内容）上传到 Secrets Manager：

```bash
# 查看当前 secrets
aws secretsmanager get-secret-value --secret-id myapp/app-secrets --query SecretString --output text | jq

# 更新私钥（注意换行符处理）
# 方法1: 直接在 AWS Console 中编辑 AUTH_APPLE_PRIVATE_KEY 字段
# 方法2: 使用 AWS CLI
```

私钥格式示例：
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
...
-----END PRIVATE KEY-----
```

---

### 步骤 5: iOS Xcode 配置

#### 5.1 添加 SPM 依赖

1. Xcode → File → Add Package Dependencies
2. URL: `https://github.com/aws-amplify/amplify-swift`
3. 添加产品：`Amplify`, `AWSCognitoAuthPlugin`, `AWSPluginsCore`

#### 5.2 添加 Sign in with Apple Capability

1. 选择项目 → Target → `Signing & Capabilities`
2. 点击 `+ Capability`
3. 搜索并添加 `Sign in with Apple`

#### 5.3 配置 URL Scheme

OAuth 回调需要 URL Scheme。

**方法1: 通过 Xcode UI**
1. Target → `Info` → `URL Types`
2. 点击 `+` 添加：
   - Identifier: `myapp`
   - URL Schemes: `myapp`
   - Role: `Editor`

**方法2: 通过 Info.plist**

在项目**根目录**创建 `Info.plist`（不是在源码目录，避免被自动同步复制）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>myapp</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>myapp</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

然后在 Build Settings 中设置 `INFOPLIST_FILE = Info.plist`

---

### 步骤 6: 添加 amplifyconfiguration.json

在项目中创建 `amplifyconfiguration.json`（添加到 Xcode 项目中）：

```json
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_XXXXXXXX",
            "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "myapp-auth.auth.us-east-1.amazoncognito.com",
              "AppClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
              "SignInRedirectURI": "myapp://callback",
              "SignOutRedirectURI": "myapp://signout",
              "Scopes": [
                "email",
                "openid",
                "profile",
                "aws.cognito.signin.user.admin"
              ]
            },
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  }
}
```

**注意**：
- `PoolId` 和 `AppClientId` 从 CDK 部署输出获取
- `SignInRedirectURI` 和 `SignOutRedirectURI` 的 scheme 必须与 URL Scheme 一致
- `aws.cognito.signin.user.admin` scope 用于删除账户功能

---

### 配置检查清单

| 检查项 | 位置 | 状态 |
|-------|------|------|
| App ID 创建并启用 Sign in with Apple | Apple Developer | ⬜ |
| Services ID 创建 | Apple Developer | ⬜ |
| Key 创建并下载 .p8 文件 | Apple Developer | ⬜ |
| CDK Cognito 部署完成 | AWS | ⬜ |
| Services ID 配置 Domain 和 Return URL | Apple Developer | ⬜ |
| AUTH_APPLE_PRIVATE_KEY 上传 | AWS Secrets Manager | ⬜ |
| Amplify SDK 添加 | Xcode SPM | ⬜ |
| Sign in with Apple Capability | Xcode | ⬜ |
| URL Scheme 配置 | Xcode Info.plist | ⬜ |
| amplifyconfiguration.json 添加 | iOS 项目 | ⬜ |

---

### 调试技巧

#### 添加日志

在 `AuthService` 中添加调试日志：

```swift
func signInWithApple(presentationAnchor: AuthUIPresentationAnchor) async throws -> AuthTokens {
    debugLog("🍎 [AuthService] signInWithApple started")

    do {
        let result = try await Amplify.Auth.signInWithWebUI(
            for: .apple,
            presentationAnchor: presentationAnchor,
            options: options
        )
        debugLog("🍎 [AuthService] signInWithWebUI returned, isSignedIn:", result.isSignedIn)
        // ...
    } catch {
        debugLog("🍎 [AuthService] ❌ Error:", String(describing: error))
        throw error
    }
}
```

#### 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| "未完成注册" | Return URL 未配置或错误 | 检查 Apple Services ID 的 Return URL |
| "The Internet connection appears to be offline" | 网络问题或 Domain 配置错误 | 检查网络连接和 Domain 配置 |
| "invalid_client" | Services ID 或私钥配置错误 | 检查 CDK 中的 clientId 和私钥 |

---

### 网络权限预请求

**问题**：iOS 首次发起网络请求时会弹出网络权限弹窗。如果在 Apple 登录过程中才触发，用户授权后登录可能已经失败。

**解决方案**：在 AuthView 显示时立即发起一个简单的网络请求，预先触发权限弹窗：

```swift
var body: some View {
    NavigationStack {
        // ...
    }
    .task {
        // 预先触发网络权限请求
        await prefetchNetworkPermission()
    }
}

private func prefetchNetworkPermission() async {
    guard let url = URL(string: "https://www.apple.com") else { return }
    _ = try? await URLSession.shared.data(from: url)
}
```

这样用户在看到登录界面时就会收到网络权限弹窗，授权后再点击登录就不会有问题。

---

## Google 登录配置

### 配置概览

配置 Cognito + Google Sign In 需要完成以下步骤：

| 步骤 | 平台 | 说明 |
|------|------|------|
| 1 | Google Cloud Console | 创建项目、配置 OAuth 同意屏幕 |
| 2 | Google Cloud Console | 创建 OAuth 2.0 客户端（Web 应用类型） |
| 3 | AWS CDK | 配置 Google Identity Provider |
| 4 | AWS Secrets Manager | 上传 Google Client Secret |
| 5 | CDK 部署 | 部署更新 |

---

### 步骤 1: Google Cloud Console 创建项目

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建新项目或选择现有项目
3. 记录项目名称

---

### 步骤 2: 配置 OAuth 同意屏幕

1. 导航到 `APIs & Services` → `OAuth consent screen`
2. 用户类型选择 **External**
3. 填写应用信息：
   - App name: `My App`
   - User support email: 选择你的邮箱
   - Developer contact information: 填写邮箱
4. 点击 `Save and Continue`
5. Scopes 页面点击 `Add or Remove Scopes`，添加：
   - `email`
   - `profile`
   - `openid`
6. 点击 `Save and Continue`
7. Test users 页面可以跳过（发布后所有用户可用）
8. 点击 `Back to Dashboard`

---

### 步骤 3: 创建 OAuth 2.0 客户端

1. 导航到 `APIs & Services` → `Credentials`
2. 点击 `+ Create Credentials` → `OAuth client ID`
3. 应用类型选择 **Web application**（⚠️ 不是 iOS）
4. 填写：
   - Name: `My App Cognito`
   - Authorized redirect URIs: 添加 Cognito 回调 URL

```
https://myapp-auth.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
```

5. 点击 `Create`
6. 记录生成的：
   - **Client ID**: `123456789-xxxxxx.apps.googleusercontent.com`
   - **Client Secret**: `GOCSPX-xxxxxxxxxxxxxxxx`

**⚠️ 注意**：
- 必须选择 **Web application** 类型，不是 iOS 类型
- Cognito 使用 Web OAuth 流程，即使是 iOS App 也需要 Web 类型的客户端
- 回调 URL 中的 domain 需要与你的 Cognito Domain 一致

---

### 步骤 4: CDK 配置

在 `cognito-construct.ts` 中添加 Google Identity Provider：

```typescript
// Google Identity Provider
const googleProvider = new cognito.UserPoolIdentityProviderGoogle(
  this,
  'GoogleIdp',
  {
    userPool: this.userPool,
    clientId: '123456789-xxxxxx.apps.googleusercontent.com',  // Google Client ID
    clientSecretValue: props.appSecret.secretValueFromJson('AUTH_GOOGLE_CLIENT_SECRET'),
    scopes: ['email', 'profile', 'openid'],
    attributeMapping: {
      email: cognito.ProviderAttribute.GOOGLE_EMAIL,
      fullname: cognito.ProviderAttribute.GOOGLE_NAME,
    },
  }
);

// App Client 中添加 Google 支持
this.userPoolClient = this.userPool.addClient('IOSClient', {
  // ...
  supportedIdentityProviders: [
    cognito.UserPoolClientIdentityProvider.COGNITO,
    cognito.UserPoolClientIdentityProvider.custom('SignInWithApple'),
    cognito.UserPoolClientIdentityProvider.custom('Google'),  // 添加 Google
  ],
  // ...
});

// 确保依赖关系
this.userPoolClient.node.addDependency(googleProvider);
```

---

### 步骤 5: 配置 AWS Secrets Manager

将 Google Client Secret 添加到 Secrets Manager：

```bash
# 获取当前 secret
aws secretsmanager get-secret-value --secret-id myapp/app-secrets --query SecretString --output text

# 更新 secret（添加 AUTH_GOOGLE_CLIENT_SECRET）
# 方法1: 在 AWS Console 中直接编辑
# 方法2: 使用 AWS CLI put-secret-value（需要包含所有字段）
```

Secret 中需要添加：
```json
{
  "AUTH_GOOGLE_CLIENT_SECRET": "GOCSPX-xxxxxxxxxxxxxxxx"
}
```

---

### 步骤 6: 部署 CDK

```bash
npx cdk deploy
```

---

### Google 登录配置检查清单

| 检查项 | 位置 | 状态 |
|-------|------|------|
| Google Cloud 项目创建 | Google Cloud Console | ⬜ |
| OAuth 同意屏幕配置 | Google Cloud Console | ⬜ |
| OAuth 2.0 客户端创建（Web 应用类型） | Google Cloud Console | ⬜ |
| Authorized redirect URI 配置 | Google Cloud Console | ⬜ |
| CDK Google Provider 配置 | AWS CDK | ⬜ |
| AUTH_GOOGLE_CLIENT_SECRET 上传 | AWS Secrets Manager | ⬜ |
| CDK 部署完成 | AWS | ⬜ |

---

### Google 登录常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| "redirect_uri_mismatch" | 回调 URL 不匹配 | 检查 Google Console 中的 Authorized redirect URIs |
| "invalid_client" | Client ID 或 Secret 错误 | 检查 CDK 配置和 Secrets Manager |
| "access_denied" | OAuth 同意屏幕未配置 | 配置 OAuth 同意屏幕并添加 scopes |
| 选择账号后无响应 | 使用了 iOS 类型的客户端 | 创建 Web application 类型的客户端 |

---

## 设计决策

### 为什么客户端直连 Cognito？

1. **减少延迟**：认证操作不经过后端
2. **简化后端**：后端不需要处理认证逻辑
3. **利用 SDK**：Amplify SDK 自动处理 token 刷新
4. **安全性**：密码不经过后端

### 为什么使用 API Gateway JWT Authorizer？

1. **统一验证**：所有请求在网关层统一验证
2. **开发/生产一致**：本地开发也使用真实的 Cognito 认证
3. **性能**：JWT 验证在网关完成，减少后端负担
4. **标准化**：使用 AWS 官方组件，稳定可靠

### 后端的职责

后端只负责：
- 处理业务逻辑（用户档案、订单等）
- 从 JWT 中提取用户信息（userId, email）
- 不处理认证逻辑

---

## 密码策略

### 推荐配置（简化用户体验）

默认采用简化的密码策略，只要求最小长度 8 位：

```swift
// slAuthViewConfig
var minPasswordLength: Int = 8
var requireStrongPassword: Bool = false  // 不要求大小写和数字
```

### CDK Cognito 配置

```typescript
passwordPolicy: {
  minLength: 8,
  requireLowercase: false,
  requireUppercase: false,
  requireDigits: false,
  requireSymbols: false,
},
```

### 如需启用强密码

如果业务需要更高安全性，可以启用强密码：

```swift
// iOS 客户端
AuthViewConfig(
    minPasswordLength: 8,
    requireStrongPassword: true  // 要求包含大小写和数字
)
```

```typescript
// CDK Cognito
passwordPolicy: {
  minLength: 8,
  requireLowercase: true,
  requireUppercase: true,
  requireDigits: true,
  requireSymbols: false,
},
```

**注意**：iOS 客户端的密码验证规则必须与 Cognito 配置一致，否则可能出现客户端验证通过但 Cognito 拒绝的情况。
