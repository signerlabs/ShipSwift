# AWS CDK 最佳实践

使用 AWS CDK 管理所有 AWS 资源，实现基础设施即代码（IaC）。

## 推荐架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS Client                                       │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               │               ▼
            ┌───────────────┐       │     ┌─────────────────────┐
            │    Cognito    │       │     │   API Gateway       │
            │   User Pool   │◄──────┼─────│  (JWT Authorizer)   │
            │  + Hosted UI  │       │     └──────────┬──────────┘
            └───────┬───────┘       │                │
                    │               │                ▼
                    ▼               │     ┌─────────────────────┐
            ┌───────────────┐       │     │     App Runner      │
            │ Identity Pool │◄──────┘     │   (Hono 后端)       │
            │ (匿名+已认证) │              └──────────┬──────────┘
            └───────────────┘                        │
                    ▲                 ┌──────────────┴──────────────┐
                    │ OAuth           │                             │
            ┌───────────────┐         ▼                             ▼
            │   Identity    │ ┌───────────────┐           ┌─────────────────┐
            │   Providers   │ │   RDS Proxy   │           │   S3 Bucket     │
            │  Apple/Google │ │  (连接池)     │           │  (文件存储)     │
            └───────────────┘ └───────┬───────┘           └─────────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │    Aurora     │
                              │ Serverless v2 │
                              └───────────────┘
```

## 推荐 AWS 服务

| 服务 | 用途 | 优势 |
|------|------|------|
| **Cognito User Pool** | 用户认证 | 原生支持 Apple/Google 登录，JWT 自动刷新 |
| **Cognito Identity Pool** | 匿名访客 + 凭证管理 | 支持匿名用户，自动分配唯一 ID 和 AWS 临时凭证 |
| **API Gateway HTTP API** | API 网关 | JWT Authorizer 统一认证，低延迟 |
| **App Runner** | 后端运行时 | 自动部署、自动扩缩、无需管理服务器 |
| **Aurora Serverless v2** | 数据库 | 自动扩缩、按需计费、PostgreSQL 兼容 |
| **RDS Proxy** | 数据库连接池 | 避免连接风暴、提高稳定性 |
| **Secrets Manager** | 密钥管理 | 自动轮换、安全存储数据库凭证 |
| **S3** | 文件存储 | 无限容量、低成本 |
| **VPC** | 网络隔离 | 私有子网保护数据库 |

---

## Secrets 管理最佳实践

### 推荐：创建模式（模板项目更友好）

使用 `new Secret()` 创建，CDK 自动管理 IAM 权限和 ARN。

```typescript
// ✅ 推荐：创建模式
const appSecret = new secretsmanager.Secret(this, 'AppSecret', {
  secretName: 'my-app/secrets',
  description: 'Application secrets (API keys, OAuth credentials)',
  secretObjectValue: {
    AUTH_APPLE_PRIVATE_KEY: cdk.SecretValue.unsafePlainText('PLACEHOLDER'),
    AUTH_GOOGLE_CLIENT_SECRET: cdk.SecretValue.unsafePlainText('PLACEHOLDER'),
    OPENAI_API_KEY: cdk.SecretValue.unsafePlainText('PLACEHOLDER'),
  },
});
```

> ⚠️ **重要**：占位符文案（如 `PLACEHOLDER`）一旦设定**永远不要修改**！
> 如果修改占位符文案，CDK 会用新值覆盖你手动设置的真实密钥。

### 首次部署流程（有社交登录时）

社交登录（Apple/Google）需要在部署时读取 Secret 中的私钥，但 Secret 刚创建时是占位符，会导致部署失败。

**解决方案：分两步部署**

```bash
# 步骤 1: 禁用社交登录，创建 Secret
# 修改 cdk.json: "enableSocialLogin": "false"
npm run cdk:deploy

# 步骤 2: 更新 Secret 真实值
aws secretsmanager put-secret-value \
  --secret-id my-app/secrets \
  --secret-string '{
    "AUTH_APPLE_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
    "AUTH_GOOGLE_CLIENT_SECRET": "GOCSPX-xxxxx",
    "OPENAI_API_KEY": "sk-proj-xxxxx"
  }'

# 步骤 3: 启用社交登录，重新部署
# 修改 cdk.json: "enableSocialLogin": "true"
npm run cdk:deploy
```

### 后续部署

直接 `npm run cdk:deploy`，不会覆盖已设置的 Secret 值（因为占位符不变）。

### 为什么不用引用模式

| 模式 | 首次部署 | ARN 管理 | 新项目复用 |
|-----|---------|---------|-----------|
| **创建模式** | ✅ 自动创建 | ✅ CDK 自动处理 | ✅ 直接部署 |
| **引用模式** | ❌ 需手动创建 | ❌ 需硬编码完整 ARN | ❌ 每个项目都要手动配置 |

**引用模式的问题**：
- `fromSecretNameV2` 返回的 `secretArn` 不包含后缀，Lambda 可能找不到 Secret
- 需要用 `fromSecretCompleteArn` 并硬编码完整 ARN（含后缀如 `-eBU0rH`）
- 新项目需要先手动创建 Secret，获取 ARN，再更新代码

---

## 项目结构

```
project-server/
├── bin/
│   └── app.ts                    # CDK 入口
├── lib/
│   ├── project-stack.ts          # 主 Stack
│   └── constructs/
│       ├── vpc-construct.ts      # VPC 网络
│       ├── database-construct.ts # 数据库
│       └── apprunner-construct.ts# App Runner
├── src/                          # 业务代码
├── drizzle/                      # 数据库迁移
├── cdk.json
└── package.json
```

---

## 核心 Construct

### 1. VpcConstruct

创建三层网络架构：

```typescript
import * as ec2 from 'aws-cdk-lib/aws-ec2';

const vpc = new ec2.Vpc(this, 'Vpc', {
  maxAzs: 2,
  ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),

  subnetConfiguration: [
    {
      name: 'Public',
      subnetType: ec2.SubnetType.PUBLIC,
      cidrMask: 24,
    },
    {
      name: 'Private',
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      cidrMask: 24,
    },
    {
      name: 'Isolated',
      subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      cidrMask: 24,
    },
  ],

  // 开发环境：1 个 NAT Gateway 节省成本
  // 生产环境：每个 AZ 一个 NAT Gateway
  natGateways: 1,
});
```

**子网用途**：
| 子网类型 | 用途 | 公网访问 |
|---------|------|---------|
| Public | NAT Gateway | 有 |
| Private | App Runner、RDS Proxy、Lambda | 通过 NAT |
| Isolated | Aurora 数据库 | 无 |

**VPC 端点**（优化成本和安全）：

```typescript
// Secrets Manager 端点
vpc.addInterfaceEndpoint('SecretsManagerEndpoint', {
  service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
  subnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
});

// CloudWatch Logs 端点
vpc.addInterfaceEndpoint('CloudWatchLogsEndpoint', {
  service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
  subnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
});
```

### 2. DatabaseConstruct

创建 Aurora Serverless v2 + RDS Proxy：

```typescript
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

// 数据库凭证
const secret = new secretsmanager.Secret(this, 'DatabaseSecret', {
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'postgres' }),
    generateStringKey: 'password',
    excludePunctuation: true,
    passwordLength: 32,
  },
});

// Aurora Serverless v2 集群
const cluster = new rds.DatabaseCluster(this, 'AuroraCluster', {
  engine: rds.DatabaseClusterEngine.auroraPostgres({
    version: rds.AuroraPostgresEngineVersion.VER_15_8,
  }),

  defaultDatabaseName: 'my_database',
  credentials: rds.Credentials.fromSecret(secret),

  // Serverless v2 配置
  serverlessV2MinCapacity: 0.5,  // 最低 0.5 ACU
  serverlessV2MaxCapacity: 16,   // 最高 16 ACU
  writer: rds.ClusterInstance.serverlessV2('Writer'),

  // 网络配置
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },

  // 备份配置
  backup: {
    retention: cdk.Duration.days(7),
  },

  // [仅开发环境] 启用 RDS Data API，便于本地直接查询数据库调试
  // 生产环境建议关闭，App Runner/Lambda 通过 RDS Proxy 访问即可
  enableDataApi: true,

  // 开发环境可删除
  deletionProtection: false,
  removalPolicy: cdk.RemovalPolicy.DESTROY,
});

// RDS Proxy
const proxy = cluster.addProxy('DatabaseProxy', {
  secrets: [secret],
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
  maxConnectionsPercent: 60,
  requireTLS: true,
});
```

### 3. AppRunnerConstruct

创建 App Runner 服务：

```typescript
import * as apprunner from '@aws-cdk/aws-apprunner-alpha';

// 安装 alpha 包
// npm install @aws-cdk/aws-apprunner-alpha

// VPC Connector
const vpcConnector = new apprunner.VpcConnector(this, 'VpcConnector', {
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
  securityGroups: [appRunnerSecurityGroup],
});

// IAM 角色
const instanceRole = new iam.Role(this, 'InstanceRole', {
  assumedBy: new iam.ServicePrincipal('tasks.apprunner.amazonaws.com'),
});

// 授予 Secrets Manager 读取权限
instanceRole.addToPolicy(new iam.PolicyStatement({
  actions: ['secretsmanager:GetSecretValue'],
  resources: [secret.secretArn],
}));

// App Runner Service
const service = new apprunner.Service(this, 'Service', {
  source: apprunner.Source.fromGitHub({
    repositoryUrl: 'https://github.com/your-org/your-repo',
    branch: 'main',
    configurationSource: apprunner.ConfigurationSourceType.API,
    connection: apprunner.GitHubConnection.fromConnectionArn(connectionArn),
    codeConfigurationValues: {
      runtime: apprunner.Runtime.NODEJS_22,
      port: '3000',
      buildCommand: 'npm ci --include=dev && npm run build',
      startCommand: 'node dist/src/server.js',
      environmentVariables: {
        NODE_ENV: 'production',
        DB_HOST: proxy.endpoint,
        DB_NAME: 'my_database',
        DB_SECRET_ARN: secret.secretArn,
      },
    },
  }),
  vpcConnector,
  instanceRole,
  cpu: apprunner.Cpu.ONE_VCPU,
  memory: apprunner.Memory.TWO_GB,
  autoDeploymentsEnabled: true,
});
```

**GitHub 连接**：

1. 在 AWS Console 创建连接：App Runner → GitHub connections
2. 授权 GitHub 访问
3. 记录 Connection ARN

### 4. Cognito + API Gateway

#### User Pool

```typescript
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

const userPool = new cognito.UserPool(this, 'UserPool', {
  userPoolName: 'my-app-user-pool',
  selfSignUpEnabled: true,

  // ⚠️ 重要：signInAliases 创建后不可修改！
  signInAliases: {
    email: true,
    phone: true,
    username: false,
  },

  autoVerify: { email: true, phone: true },

  standardAttributes: {
    email: { required: true, mutable: true },
    phoneNumber: { required: false, mutable: true },
    fullname: { required: false, mutable: true },
  },

  // 密码策略（简化：只要求8位，不要求大小写和数字）
  // 注意：密码策略创建后不可修改，如需更改需创建新的 User Pool
  passwordPolicy: {
    minLength: 8,
    requireLowercase: false,
    requireUppercase: false,
    requireDigits: false,
    requireSymbols: false,
  },

  accountRecovery: cognito.AccountRecovery.EMAIL_AND_PHONE_WITHOUT_MFA,
  removalPolicy: cdk.RemovalPolicy.DESTROY,  // 生产环境改为 RETAIN
  deletionProtection: false,                  // 生产环境改为 true
});

// 启用高级安全功能
const cfnUserPool = userPool.node.defaultChild as cognito.CfnUserPool;
cfnUserPool.addPropertyOverride('UserPoolAddOns', {
  AdvancedSecurityMode: 'AUDIT',
});
```

#### Cognito Domain（用于 Hosted UI）

```typescript
const userPoolDomain = userPool.addDomain('Domain', {
  cognitoDomain: {
    domainPrefix: 'my-app-auth',  // 必须全局唯一
  },
});
```

#### Identity Provider - Apple

```typescript
// 1. 在 Secrets Manager 存储 Apple 私钥
const applePrivateKey = new secretsmanager.Secret(this, 'AppleSignInPrivateKey', {
  secretName: 'my-app-apple-signin-key',
  description: 'Apple Sign In private key',
  secretStringValue: cdk.SecretValue.unsafePlainText(
`-----BEGIN PRIVATE KEY-----
YOUR_APPLE_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----`
  ),
});

// 2. 配置 Apple Identity Provider
const appleProvider = new cognito.UserPoolIdentityProviderApple(this, 'AppleIdp', {
  userPool,
  clientId: 'com.yourcompany.app.auth',  // Apple Services ID
  teamId: 'YOUR_TEAM_ID',
  keyId: 'YOUR_KEY_ID',
  privateKeyValue: applePrivateKey.secretValue,
  scopes: ['email', 'name'],
  attributeMapping: {
    email: cognito.ProviderAttribute.APPLE_EMAIL,
    fullname: cognito.ProviderAttribute.APPLE_NAME,
  },
});
```

#### Identity Provider - Google

```typescript
const googleProvider = new cognito.UserPoolIdentityProviderGoogle(this, 'GoogleIdp', {
  userPool,
  clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
  clientSecretValue: cdk.SecretValue.unsafePlainText('YOUR_GOOGLE_CLIENT_SECRET'),
  scopes: ['email', 'profile', 'openid'],
  attributeMapping: {
    email: cognito.ProviderAttribute.GOOGLE_EMAIL,
    fullname: cognito.ProviderAttribute.GOOGLE_NAME,
  },
});
```

#### App Client

```typescript
const userPoolClient = userPool.addClient('IOSClient', {
  userPoolClientName: 'my-app-ios-client',
  generateSecret: false,  // iOS 不使用 client secret

  accessTokenValidity: cdk.Duration.hours(1),
  idTokenValidity: cdk.Duration.hours(1),
  refreshTokenValidity: cdk.Duration.days(30),

  enableTokenRevocation: true,
  preventUserExistenceErrors: true,

  // ⚠️ 重要：必须包含 COGNITO，否则 Hosted UI 会显示选择页面
  supportedIdentityProviders: [
    cognito.UserPoolClientIdentityProvider.COGNITO,
    cognito.UserPoolClientIdentityProvider.custom('SignInWithApple'),
    cognito.UserPoolClientIdentityProvider.custom('Google'),
  ],

  authFlows: {
    userPassword: true,
    userSrp: true,
  },

  oAuth: {
    flows: { authorizationCodeGrant: true },
    scopes: [
      cognito.OAuthScope.EMAIL,
      cognito.OAuthScope.OPENID,
      cognito.OAuthScope.PROFILE,
      cognito.OAuthScope.COGNITO_ADMIN,  // ⚠️ 删除账户需要此 scope
    ],
    callbackUrls: ['myapp://callback'],
    logoutUrls: ['myapp://signout'],
  },
});

// 确保 App Client 在 Identity Providers 之后创建
userPoolClient.node.addDependency(appleProvider);
userPoolClient.node.addDependency(googleProvider);
```

#### 5. Identity Pool（匿名登录）

Identity Pool 为所有用户（包括匿名访客）提供唯一标识和 AWS 临时凭证。

```typescript
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';

// 创建 Identity Pool
const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
  identityPoolName: 'my-app-identity-pool',
  allowUnauthenticatedIdentities: true,  // ⚠️ 关键：允许匿名访客

  // 关联 User Pool（已登录用户通过这里验证）
  cognitoIdentityProviders: [{
    clientId: userPoolClient.userPoolClientId,
    providerName: userPool.userPoolProviderName,
  }],
});

// 匿名用户 IAM 角色
const unauthenticatedRole = new iam.Role(this, 'CognitoUnauthRole', {
  roleName: 'my-app-cognito-unauth-role',
  assumedBy: new iam.FederatedPrincipal(
    'cognito-identity.amazonaws.com',
    {
      StringEquals: {
        'cognito-identity.amazonaws.com:aud': identityPool.ref,
      },
      'ForAnyValue:StringLike': {
        'cognito-identity.amazonaws.com:amr': 'unauthenticated',
      },
    },
    'sts:AssumeRoleWithWebIdentity'
  ),
});

// 已认证用户 IAM 角色
const authenticatedRole = new iam.Role(this, 'CognitoAuthRole', {
  roleName: 'my-app-cognito-auth-role',
  assumedBy: new iam.FederatedPrincipal(
    'cognito-identity.amazonaws.com',
    {
      StringEquals: {
        'cognito-identity.amazonaws.com:aud': identityPool.ref,
      },
      'ForAnyValue:StringLike': {
        'cognito-identity.amazonaws.com:amr': 'authenticated',
      },
    },
    'sts:AssumeRoleWithWebIdentity'
  ),
});

// 绑定角色到 Identity Pool
new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoleAttachment', {
  identityPoolId: identityPool.ref,
  roles: {
    unauthenticated: unauthenticatedRole.roleArn,
    authenticated: authenticatedRole.roleArn,
  },
});

// 输出 Identity Pool ID
new cdk.CfnOutput(this, 'IdentityPoolId', {
  value: identityPool.ref,
  description: 'Cognito Identity Pool ID',
});
```

**匿名用户权限配置示例**（按需添加）：

```typescript
// 允许匿名用户上传文件到 S3（仅限自己的目录）
unauthenticatedRole.addToPolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['s3:PutObject', 's3:GetObject', 's3:DeleteObject'],
  resources: [
    `arn:aws:s3:::${bucket.bucketName}/guests/\${cognito-identity.amazonaws.com:sub}/*`,
  ],
}));

// 允许匿名用户调用特定 API Gateway 端点
unauthenticatedRole.addToPolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['execute-api:Invoke'],
  resources: [
    `arn:aws:execute-api:${this.region}:${this.account}:${httpApi.apiId}/*/*/*`,
  ],
}));
```

**已认证用户权限配置示例**：

```typescript
// 已认证用户有更多权限
authenticatedRole.addToPolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['s3:PutObject', 's3:GetObject', 's3:DeleteObject', 's3:ListBucket'],
  resources: [
    `arn:aws:s3:::${bucket.bucketName}/users/\${cognito-identity.amazonaws.com:sub}/*`,
    `arn:aws:s3:::${bucket.bucketName}`,
  ],
}));
```

**⚠️ 关于 Identity ID 持久性**：

| 场景 | Identity ID 是否保留 |
|------|---------------------|
| App 正常使用 | ✅ 保留（缓存在本地） |
| App 卸载后重装 | ❌ 生成新 ID（本地缓存丢失） |
| 匿名用户登录注册 | ✅ 保留（自动合并） |
| 同一账号多设备登录 | ✅ 相同 Identity ID |

#### HTTP API + JWT Authorizer

```typescript
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayv2Authorizers from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import * as apigatewayv2Integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';

// HTTP API
const httpApi = new apigatewayv2.HttpApi(this, 'HttpApi', {
  apiName: 'my-app-http-api',
  corsPreflight: {
    allowOrigins: ['*'],
    allowMethods: [apigatewayv2.CorsHttpMethod.ANY],
    allowHeaders: ['Content-Type', 'Authorization'],
  },
});

// JWT Authorizer
const jwtAuthorizer = new apigatewayv2Authorizers.HttpJwtAuthorizer(
  'CognitoJwtAuthorizer',
  `https://cognito-idp.${this.region}.amazonaws.com/${userPool.userPoolId}`,
  {
    jwtAudience: [userPoolClient.userPoolClientId],
    identitySource: ['$request.header.Authorization'],
  }
);

// 公开路由（无需认证）
const publicPaths = [
  { path: '/health', methods: [apigatewayv2.HttpMethod.GET] },
  { path: '/v1/subscriptions/webhook', methods: [apigatewayv2.HttpMethod.POST] },
];

publicPaths.forEach(({ path, methods }) => {
  httpApi.addRoutes({
    path,
    methods,
    integration: new apigatewayv2Integrations.HttpUrlIntegration(
      `${path.replace(/\//g, '')}Integration`,
      `${appRunnerUrl}${path}`
    ),
  });
});

// 受保护路由（需要 JWT）
httpApi.addRoutes({
  path: '/{proxy+}',
  methods: [apigatewayv2.HttpMethod.ANY],
  integration: new apigatewayv2Integrations.HttpUrlIntegration(
    'ProxyIntegration',
    `${appRunnerUrl}/{proxy}`
  ),
  authorizer: jwtAuthorizer,
});
```

---

## 5. Lambda

### NodejsFunction 基础配置

```typescript
import { NodejsFunction, OutputFormat } from 'aws-cdk-lib/aws-lambda-nodejs';
import * as lambda from 'aws-cdk-lib/aws-lambda';

const myFunction = new NodejsFunction(this, 'MyFunction', {
  functionName: 'my-function',
  entry: 'lib/lambda/my-function/index.ts',
  handler: 'handler',
  runtime: lambda.Runtime.NODEJS_22_X,
  architecture: lambda.Architecture.ARM_64,  // ARM 便宜 20%
  memorySize: 512,
  timeout: cdk.Duration.minutes(1),

  environment: {
    NODE_ENV: 'production',
    DB_HOST: proxy.endpoint,
    DB_SECRET_ARN: secret.secretArn,
  },

  // VPC 配置（访问 RDS 时需要）
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
  securityGroups: [lambdaSecurityGroup],

  // 打包配置
  bundling: {
    minify: true,
    sourceMap: true,
    target: 'es2022',
    format: OutputFormat.ESM,
    externalModules: ['@aws-sdk/*'],  // SDK v3 内置
    nodeModules: ['drizzle-orm', 'postgres'],  // 需要打包的依赖
  },
});

// 授权
secret.grantRead(myFunction);
```

### CDK Custom Resource（部署时执行）

用于数据库迁移等部署时一次性任务：

```typescript
import * as cr from 'aws-cdk-lib/custom-resources';

// 迁移 Lambda（需要复制迁移文件）
const migrationFunction = new NodejsFunction(this, 'MigrationFunction', {
  entry: 'lib/lambda/db-migrate/index.ts',
  // ... 基础配置同上
  bundling: {
    format: OutputFormat.ESM,
    nodeModules: ['drizzle-orm', 'postgres'],
    commandHooks: {
      afterBundling(inputDir, outputDir) {
        return [
          `mkdir -p ${outputDir}/drizzle/migrations`,
          `cp -r ${inputDir}/drizzle/migrations/* ${outputDir}/drizzle/migrations/`,
        ];
      },
      beforeBundling: () => [],
      beforeInstall: () => [],
    },
  },
});

// Custom Resource
const migrationProvider = new cr.Provider(this, 'MigrationProvider', {
  onEventHandler: migrationFunction,
});

new cdk.CustomResource(this, 'MigrationResource', {
  serviceToken: migrationProvider.serviceToken,
  properties: {
    timestamp: Date.now(),  // 强制每次部署执行
  },
});
```

### EventBridge 定时任务

```typescript
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';

// 每天 UTC 00:00 执行
const rule = new events.Rule(this, 'DailySchedule', {
  schedule: events.Schedule.cron({ minute: '0', hour: '0' }),
});

rule.addTarget(new targets.LambdaFunction(schedulerFunction));
```

### Lambda 调用 Lambda

```typescript
// CDK 授权
targetFunction.grantInvoke(callerFunction);

// 传递 ARN 到环境变量
callerFunction.addEnvironment('TARGET_LAMBDA_ARN', targetFunction.functionArn);
```

> Lambda handler 代码写法详见 [4_lambda.md](4_lambda.md)

---

## 6. 消息服务 (SES/SNS)

App Runner 或 Lambda 需要发送邮件/短信时，授予 IAM 权限：

```typescript
import * as iam from 'aws-cdk-lib/aws-iam';

// SES 发邮件权限
instanceRole.addToPolicy(new iam.PolicyStatement({
  actions: ['ses:SendEmail', 'ses:SendRawEmail'],
  resources: ['*'],
}));

// SNS 发短信权限
instanceRole.addToPolicy(new iam.PolicyStatement({
  actions: ['sns:Publish'],
  resources: ['*'],
}));
```

> SES 域名验证、SNS 配置等需在 AWS Console 手动完成，详见 [5_messaging.md](5_messaging.md)

---

## 安全组配置

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   App Runner    │────▶│   RDS Proxy     │────▶│    Aurora       │
│  Security Group │     │  Security Group │     │  Security Group │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                      ▲
         │                      │
         └──────────────────────┘
              Port 5432
```

```typescript
// App Runner → RDS Proxy
proxySecurityGroup.addIngressRule(
  appRunnerSecurityGroup,
  ec2.Port.tcp(5432),
  'Allow App Runner to connect to RDS Proxy'
);

// RDS Proxy → Aurora
auroraSecurityGroup.addIngressRule(
  proxySecurityGroup,
  ec2.Port.tcp(5432),
  'Allow RDS Proxy to connect to Aurora'
);
```

---

## 部署命令

```bash
# 安装依赖
npm install

# 检查 CDK 版本
npx cdk --version

# 合成 CloudFormation 模板（不部署，用于检查）
npx cdk synth

# 部署
npx cdk deploy

# 部署并跳过确认
npx cdk deploy --require-approval never

# 查看变更
npx cdk diff

# 销毁
npx cdk destroy
```

---

## 开发调试：RDS Data API

> **仅限开发环境使用**，生产环境建议关闭

启用 `enableDataApi: true` 后，可以在本地直接通过 AWS CLI 查询数据库，无需 VPN 或 Bastion Host。

### 查询示例

```bash
# 设置变量（替换为实际值）
CLUSTER_ARN="arn:aws:rds:us-east-1:123456789:cluster:my-aurora-cluster"
SECRET_ARN="arn:aws:secretsmanager:us-east-1:123456789:secret:my-db-credentials-xxxxx"

# 执行 SQL 查询
aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database my_database \
  --sql "SELECT * FROM users WHERE id = 'xxx'" \
  --region us-east-1
```

### 获取 ARN

```bash
# 获取 RDS 集群 ARN
aws rds describe-db-clusters \
  --query "DBClusters[?contains(DBClusterIdentifier, 'my-app')].DBClusterArn" \
  --output text

# 获取 Secrets Manager ARN
aws secretsmanager list-secrets \
  --query "SecretList[?contains(Name, 'db-credentials')].ARN" \
  --output text
```

### 为什么不在生产环境启用

- 增加攻击面（可从 VPC 外部访问）
- 性能不如 RDS Proxy（HTTP 开销）
- App Runner/Lambda 已经通过 RDS Proxy 访问，不需要

---

## 常见问题与解决方案

### 1. App Runner 连接不上 RDS Proxy

**症状**：App Runner 超时或连接拒绝

**原因**：安全组规则未正确配置

**解决**：
```typescript
// 确保 App Runner 安全组可以访问 RDS Proxy
proxySecurityGroup.addIngressRule(
  appRunnerSecurityGroup,
  ec2.Port.tcp(5432),
  'Allow App Runner'
);
```

### 2. Lambda 无法访问 Secrets Manager

**症状**：`getaddrinfo ENOTFOUND secretsmanager.*.amazonaws.com`

**原因**：Lambda 在私有子网，无法访问 AWS 服务端点

**解决**：添加 VPC 端点或确保有 NAT Gateway：
```typescript
vpc.addInterfaceEndpoint('SecretsManagerEndpoint', {
  service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
});
```

### 3. CDK 部署卡在 Custom Resource

**症状**：部署长时间等待 `CREATE_IN_PROGRESS`

**原因**：
- Lambda 超时（网络问题）
- Lambda 代码错误（未返回响应）
- 迁移执行时间过长

**解决**：
1. 检查 Lambda 日志：CloudWatch → Log groups
2. 确保 Lambda 有正确的网络配置
3. 增加 Lambda 超时时间
4. 确保迁移代码正确处理 CloudFormation 回调

### 4. Cognito signInAliases 无法修改

**症状**：`Updates are not allowed for property - UsernameAttributes`

**原因**：Cognito User Pool 创建后无法修改 signInAliases

**解决**：
- 删除并重建 User Pool
- 或在初始配置时就包含所有可能需要的登录方式

### 5. App Runner 构建失败

**症状**：`Build failed`

**常见原因**：
1. Node.js 版本不匹配
2. 构建命令错误
3. 缺少依赖

**解决**：
```typescript
codeConfigurationValues: {
  runtime: apprunner.Runtime.NODEJS_22,
  // 确保包含开发依赖（用于 TypeScript 编译）
  buildCommand: 'npm ci --include=dev && npm run build',
  startCommand: 'node dist/src/server.js',
}
```

### 6. API Gateway 返回 401/403

**症状**：请求被拒绝

**检查清单**：
1. Token 是否有效（未过期）
2. Token 是否来自正确的 User Pool
3. `jwtAudience` 是否匹配 Client ID
4. 请求头是否正确：`Authorization: Bearer <token>`

### 7. RDS Proxy TLS 连接问题

**症状**：`SSL connection is required`

**解决**：
```typescript
// 数据库客户端配置
const pool = new Pool({
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
});
```

### 8. TypeScript 路径别名在 Lambda/App Runner 中不生效

**症状**：本地开发正常，部署后报错 `Cannot find module '@/xxx'`

**原因**：TypeScript 的 `paths` 配置只是类型检查时的映射，esbuild 和 Node.js 运行时不会解析

**解决**：不使用路径别名，直接用相对路径：

```typescript
// 避免
import { db } from '@/db/client';

// 使用相对路径
import { db } from '../db/client';
```

项目结构保持扁平，IDE 会自动补全相对路径

---

## 成本优化

### 开发环境

| 资源 | 配置 | 预估月费用 |
|------|------|-----------|
| NAT Gateway | 1 个 | ~$32 |
| Aurora Serverless v2 | 0.5-2 ACU | ~$43 |
| App Runner | 最小配置 | ~$5 |
| Secrets Manager | 1 个密钥 | ~$0.40 |

**总计：~$80/月**

### 节省成本的配置

```typescript
// 1. NAT Gateway：只用 1 个
natGateways: 1,

// 2. Aurora：最低容量
serverlessV2MinCapacity: 0.5,

// 3. App Runner：最小规格
cpu: apprunner.Cpu.QUARTER_VCPU,
memory: apprunner.Memory.HALF_GB,

// 4. 开发环境可删除
removalPolicy: cdk.RemovalPolicy.DESTROY,
deletionProtection: false,
```

---

## 生产环境检查清单

- [ ] `deletionProtection: true`
- [ ] `removalPolicy: cdk.RemovalPolicy.RETAIN`
- [ ] 多 AZ 部署：`natGateways: 2`
- [ ] Aurora 备份：`retention: cdk.Duration.days(30)`
- [ ] CloudWatch 告警配置
- [ ] VPC Flow Logs 启用
- [ ] Secrets 定期轮换
