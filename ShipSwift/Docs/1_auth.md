# 认证系统最佳实践

本文档定义了基于 **API Gateway + Cognito** 的认证架构最佳实践，适用于 iOS App + Serverless 后端的项目。

## 架构概览

采用 **客户端直连 Cognito + API Gateway JWT 验证** 架构：

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Client                               │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │   AuthService   │              │      APIService         │   │
│  │  (Amplify SDK)  │              │    (HTTP Client)        │   │
│  └────────┬────────┘              └────────────┬────────────┘   │
└───────────┼────────────────────────────────────┼────────────────┘
            │                                    │
            ▼ 直连认证                           ▼ Bearer Token
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
```

### 核心优势

1. **开发/生产一致**：本地开发和线上使用相同的认证流程
2. **安全性**：密码不经过后端，JWT 由 API Gateway 统一验证
3. **可扩展**：通过配置 Identity Provider 支持多种登录方式
4. **简化后端**：后端只处理业务逻辑，不涉及认证

> CDK 配置详见 [0_cdk.md](0_cdk.md#4-cognito--api-gateway)

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

### 5. Token 过期处理

**问题**：API 请求返回 401

**解决**：
```swift
// Amplify SDK 会自动刷新 token，但如果 refresh token 也过期了需要重新登录
do {
    let tokens = try await authService.refreshSession()
    // 使用新 token 重试请求
} catch {
    // refresh token 过期，需要重新登录
    await userManager.signOut()
}
```

---

## Token 类型说明

| Token | 用途 | 有效期 | 说明 |
|-------|------|--------|------|
| ID Token | API 认证 | 1 小时 | 放入 `Authorization: Bearer xxx` |
| Access Token | Cognito API | 1 小时 | 如更新用户属性、删除用户 |
| Refresh Token | 刷新 Token | 30 天 | 用于获取新的 ID/Access Token |

---

## Apple Developer 配置步骤

1. **创建 App ID**
   - 登录 Apple Developer Console
   - Certificates, Identifiers & Profiles → Identifiers
   - 创建 App ID，启用 "Sign in with Apple"

2. **创建 Services ID**
   - 创建新的 Services ID（用于 Web/Cognito）
   - 配置 "Sign in with Apple"
   - Domains: `your-cognito-domain.auth.region.amazoncognito.com`
   - Return URLs: `https://your-cognito-domain.auth.region.amazoncognito.com/oauth2/idpresponse`

3. **创建 Key**
   - Keys → 创建新 Key
   - 启用 "Sign in with Apple"
   - 下载 `.p8` 私钥文件（只能下载一次）
   - 记录 Key ID

4. **获取 Team ID**
   - 在 Membership 页面查看

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
