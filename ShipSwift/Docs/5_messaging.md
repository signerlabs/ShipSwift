# 消息服务配置

支持 AWS (SES/SNS) 和阿里云 (短信/邮件推送) 双服务商，通过工厂模式切换。

## 架构

```typescript
// 工厂模式，通过环境变量切换
const provider = env.MESSAGING_PROVIDER // 'aws' | 'alibaba'

// 使用
const { emailProvider, smsProvider } = MessagingProviderFactory.createFromEnvironment()
await emailProvider.sendVerificationEmail(email, code)
await smsProvider.sendVerificationSMS(phone, code)
```

## 服务商选择

| 场景 | 推荐 | 原因 |
|------|------|------|
| 中国大陆用户 | 阿里云 | 短信到达率高，邮件不易进垃圾箱 |
| 海外用户 | AWS | 全球覆盖，与其他 AWS 服务集成 |

---

## AWS 配置

### 环境变量

```bash
MESSAGING_PROVIDER=aws
AWS_REGION=ap-southeast-1
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_SES_SOURCE_EMAIL=noreply@yourdomain.com
AWS_SNS_SOURCE_NUMBER=+1234567890  # 可选
```

### SES 配置步骤

1. **验证发送域名**
   - AWS Console → SES → Verified identities
   - 添加域名，配置 DNS 记录 (DKIM, SPF)

2. **移出沙盒模式**
   - SES → Account dashboard → Request production access
   - 填写使用说明，等待审核

3. **IAM 权限**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": ["ses:SendEmail", "ses:SendRawEmail"],
       "Resource": "*"
     }]
   }
   ```

### SNS 配置步骤

1. **配置 SMS**
   - AWS Console → SNS → Mobile → Text messaging (SMS)
   - 设置支出限额和偏好

2. **IAM 权限**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": ["sns:Publish"],
       "Resource": "*"
     }]
   }
   ```

### 费用

| 服务 | 费用 |
|------|------|
| SES | $0.10 / 千封邮件 |
| SNS SMS (美国) | $0.00645 / 条 |
| SNS SMS (国际) | 因国家而异 |

---

## 阿里云配置

### 环境变量

```bash
MESSAGING_PROVIDER=alibaba
ALIBABA_ACCESS_KEY_ID=xxx
ALIBABA_ACCESS_KEY_SECRET=xxx

# 短信
ALIBABA_SMS_SIGN_NAME=YourApp
ALIBABA_SMS_TEMPLATE_VERIFY=SMS_123456789
ALIBABA_SMS_TEMPLATE_LOGIN=SMS_123456790

# 邮件
ALIBABA_EMAIL_FROM=noreply@yourdomain.com
ALIBABA_EMAIL_ACCOUNT=noreply@yourdomain.com
```

### 短信服务配置

1. **开通服务**
   - 阿里云控制台 → 短信服务 → 立即开通

2. **创建签名**
   - 国内消息 → 签名管理 → 添加签名
   - 签名名称：应用名称
   - 等待审核 (1-2 工作日)

3. **创建模板**
   - 模板管理 → 添加模板
   - 模板内容：`您的验证码是${code}，验证码5分钟内有效，请勿泄露给他人。`
   - 记录模板 CODE

4. **RAM 权限**
   - 授予 `AliyunDysmsFullAccess`

### 邮件推送配置

1. **开通服务**
   - 阿里云控制台 → 邮件推送 → 立即开通

2. **配置发信域名**
   - 新建域名，配置 DNS 记录：
     - SPF: `v=spf1 include:spf1.dm.aliyun.com -all`
     - DMARC: `v=DMARC1; p=none`
     - CNAME: 系统生成

3. **创建发信地址**
   - 新建发信地址：`noreply@yourdomain.com`
   - 验证发信地址

4. **RAM 权限**
   - 授予 `AliyunDirectMailFullAccess`

### 费用

| 服务 | 费用 |
|------|------|
| 短信 | ¥0.045 / 条 |
| 邮件 (免费版) | 每日 200 封 |
| 邮件 (按量) | ¥0.5 / 千封 |

---

## 代码实现

### Provider 接口

```typescript
// types/messaging.ts
export interface EmailProvider {
  sendVerificationEmail(email: string, code: string): Promise<void>
  sendPasswordResetEmail(email: string, code: string): Promise<void>
  generateVerificationCode(): string
}

export interface SMSProvider {
  sendVerificationSMS(phone: string, code: string): Promise<void>
  generateVerificationCode(): string
}
```

### 工厂类

```typescript
// providers/messaging-provider-factory.ts
export class MessagingProviderFactory {
  static createFromEnvironment(): { emailProvider: EmailProvider; smsProvider: SMSProvider } {
    const provider = env.MESSAGING_PROVIDER || 'alibaba'

    if (provider === 'aws') {
      return {
        emailProvider: new AwsEmailProvider({ ... }),
        smsProvider: new AwsSmsProvider({ ... }),
      }
    }

    return {
      emailProvider: new AlibabaEmailProvider(),
      smsProvider: new AlibabaSmsProvider(),
    }
  }
}
```

---

## 常见问题

### 短信发送失败

- **签名/模板审核未通过**：检查内容是否符合规范
- **频率限制**：阿里云每分钟 1 条/号码
- **余额不足**：检查账户余额

### 邮件进垃圾箱

- 配置 SPF、DKIM、DMARC 记录
- 使用企业域名，避免免费邮箱域名
- 优化邮件内容，避免垃圾邮件特征

### 权限错误

- 检查 AccessKey 配置
- 确认 IAM/RAM 权限
- 验证区域配置
