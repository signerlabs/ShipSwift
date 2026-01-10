# 火山引擎流式语音识别 (ASR) 集成指南

本文档介绍如何在 iOS 应用中集成火山引擎流式语音识别服务。

## 目录

1. [前置准备](#前置准备)
2. [文件说明](#文件说明)
3. [快速集成](#快速集成)
4. [自定义集成](#自定义集成)
5. [配置说明](#配置说明)
6. [技术实现细节](#技术实现细节)
7. [常见问题](#常见问题)

---

## 前置准备

### 1. 开通火山引擎服务

1. 登录 [火山引擎控制台](https://console.volcengine.com/)
2. 进入「语音技术」→「语音识别」
3. 开通「流式语音识别」服务，选择「通用-中文」
4. 创建应用，获取以下凭证：
   - **App ID**: 应用 ID
   - **Access Token**: 访问令牌

### 2. 配置 Info.plist

添加麦克风权限说明：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风进行语音识别</string>
```

### 3. 复制组件文件

将以下两个文件复制到项目中：

```
slPackage/slASR/
├── SLVolcEngineASRService.swift   # 核心 ASR 服务
└── SLChatInputView.swift          # 完整的聊天输入视图
```

---

## 文件说明

### SLVolcEngineASRService.swift

核心 ASR 服务类，包含：

| 组件 | 说明 |
|------|------|
| `SLASRConfig` | 配置结构体（appId, accessToken, cluster, language） |
| `SLVolcEngineASRService` | ASR 服务类（WebSocket、音频采集、协议处理） |
| `SLASRError` | 错误类型枚举 |

### SLChatInputView.swift

完整的聊天输入视图，内置：

| 组件 | 说明 |
|------|------|
| `SLChatInputView` | 主视图（文本输入 + 语音输入 + 发送按钮） |
| `SLASRState` | 录音状态枚举（idle/recording/transcribing） |
| `SLAudioWaveformView` | 音波动画视图 |

---

## 快速集成

只需复制两个文件，即可使用完整的聊天输入功能：

```swift
import SwiftUI

struct ContentView: View {
    @State private var text = ""

    // 配置凭证
    let asrConfig = SLASRConfig(
        appId: "你的AppID",
        accessToken: "你的AccessToken"
    )

    var body: some View {
        VStack {
            // 消息列表
            ScrollView {
                // ...
            }

            // 聊天输入框
            SLChatInputView(text: $text, asrConfig: asrConfig) {
                sendMessage()
            }
        }
    }

    func sendMessage() {
        print("发送: \(text)")
        text = ""
    }
}
```

### SLChatInputView 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | `Binding<String>` | - | 输入文本（必填） |
| `asrConfig` | `SLASRConfig` | - | ASR 配置（必填） |
| `isDisabled` | `Bool` | `false` | 是否禁用输入 |
| `placeHolderText` | `LocalizedStringKey` | `"输入消息..."` | 占位符文本 |
| `minLines` | `Int` | `1` | 最小行数 |
| `onSend` | `() -> Void` | - | 发送回调（必填） |

---

## 自定义集成

如果需要自定义 UI，可以直接使用 `SLVolcEngineASRService`：

```swift
struct CustomVoiceView: View {
    @State private var text = ""
    @State private var isRecording = false
    @State private var asrService: SLVolcEngineASRService?

    let config = SLASRConfig(
        appId: "你的AppID",
        accessToken: "你的AccessToken"
    )

    var body: some View {
        VStack(spacing: 20) {
            // 显示识别结果
            Text(text.isEmpty ? "点击按钮开始说话" : text)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // 录音按钮
            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isRecording ? .red : .blue)
            }
        }
        .padding()
    }

    func startRecording() {
        text = ""

        let service = SLVolcEngineASRService(config: config)
        asrService = service

        // 实时更新
        service.onTranscriptionUpdate = { result in
            self.text = result
        }

        // 识别完成
        service.onTranscriptionComplete = { result in
            self.text = result
            self.isRecording = false
        }

        // 错误处理
        service.onError = { error in
            print("错误: \(error.localizedDescription)")
            self.isRecording = false
        }

        Task {
            do {
                try await service.startRecording()
                isRecording = true
            } catch {
                print("启动失败: \(error)")
            }
        }
    }

    func stopRecording() {
        Task {
            await asrService?.stopRecording()
        }
    }
}
```

### SLVolcEngineASRService API

```swift
// 初始化
let service = SLVolcEngineASRService(config: SLASRConfig(...))

// 回调
service.onTranscriptionUpdate = { text in }   // 实时更新
service.onTranscriptionComplete = { text in } // 识别完成
service.onError = { error in }                // 错误回调

// 方法
try await service.startRecording()  // 开始录音
await service.stopRecording()       // 停止录音
service.cancelRecording()           // 取消录音

// 状态（只读）
service.isRecording      // 是否录音中
service.transcribedText  // 当前识别文本
service.error            // 最后一次错误
```

---

## 配置说明

### SLASRConfig 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `appId` | `String` | - | 火山引擎应用 ID（必填） |
| `accessToken` | `String` | - | 访问令牌（必填） |
| `cluster` | `String` | `volcengine_streaming_common` | 集群 ID |
| `language` | `String` | `zh-CN` | 识别语言 |

### 支持的语言

- `zh-CN`: 中文普通话
- `en-US`: 英语（需开通对应服务）

---

## 技术实现细节

### 整体架构

```
┌─────────────────────────────────────────────────────┐
│                  SLChatInputView                     │
│  ┌─────────────┐ ┌─────────────┐ ┌───────────────┐  │
│  │  TextField  │ │  Waveform   │ │  Transcribing │  │
│  │   (idle)    │ │ (recording) │ │   (loading)   │  │
│  └─────────────┘ └─────────────┘ └───────────────┘  │
│  ┌─────────────────────────────────────────────────┐│
│  │         Microphone / Stop / Send Buttons        ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              SLVolcEngineASRService                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ AVAudioEngine│  │  WebSocket   │  │  Protocol │  │
│  │ (48k→16k PCM)│  │ (NWConnection│  │  (gzip)   │  │
│  └──────────────┘  └──────────────┘  └───────────┘  │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│           火山引擎 ASR 服务器                         │
│           openspeech.bytedance.com                   │
└─────────────────────────────────────────────────────┘
```

### 二进制协议格式

火山引擎 ASR 使用自定义二进制协议：

```
┌──────────────┬──────────────┬─────────────────┐
│  Header(4B)  │ Size(4B BE)  │ Payload(gzip)   │
└──────────────┴──────────────┴─────────────────┘
```

Header 字节含义：
- Byte 0: 版本 (0x11)
- Byte 1: 消息类型 (0x10=配置, 0x20=音频, 0x22=结束)
- Byte 2: 序列化(高4位) + 压缩(低4位)
- Byte 3: 保留

### 音频处理

| 阶段 | 格式 |
|------|------|
| 设备采集 | 48kHz Float32 |
| 发送服务器 | 16kHz Int16 PCM |
| 转换方式 | AVAudioConverter |

### 响应格式

成功响应 (code=1000)：
```json
{
    "code": 1000,
    "result": [{
        "text": "识别文本",
        "utterances": [{
            "text": "识别文本",
            "definite": 1
        }]
    }]
}
```

- `definite = 0`: 中间结果（边说边出）
- `definite = 1`: 最终结果

---

## 常见问题

### Q: 出现 "resource not granted" 错误

**原因**: 未开通流式语音识别服务

**解决**:
1. 登录火山引擎控制台
2. 进入「语音技术」→「语音识别」
3. 开通「流式语音识别」服务
4. 选择「通用-中文」模型

### Q: 连接失败

**检查**:
1. App ID 和 Access Token 是否正确
2. 网络是否正常
3. 是否在控制台激活了应用

### Q: 没有声音/识别不出来

**确保**:
1. Info.plist 中添加了麦克风权限描述
2. 用户已授权麦克风权限
3. 设备麦克风正常工作

### Q: macOS 编译警告

ASR 服务的 `AVAudioSession` 配置仅在 iOS 上生效，macOS 会跳过该配置。代码已使用 `#if os(iOS)` 处理。

### Q: 如何获取 Access Token

1. 登录火山引擎控制台
2. 进入「语音技术」→「语音识别」→「应用管理」
3. 创建或选择应用
4. 在应用详情中查看 Access Token

---

## 参考链接

- [火山引擎流式语音识别文档](https://www.volcengine.com/docs/6561/80818)
- [AVAudioEngine 文档](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Network.framework 文档](https://developer.apple.com/documentation/network)
