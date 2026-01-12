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
