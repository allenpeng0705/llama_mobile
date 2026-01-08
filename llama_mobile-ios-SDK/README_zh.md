# LlamaMobile iOS SDK

一个基于Swift的生产级SDK，用于`llama_mobile`库，为iOS应用程序提供清晰的原生界面，同时保持与Flutter/Capacitor的兼容性。

## 功能特性

- **原生Swift接口**: 用于与`llama_mobile`交互的清晰、类型安全的Swift API
- **自包含**: 嵌入式`llama_mobile.xcframework`，便于集成
- **自动框架更新**: 简单的脚本确保您始终使用最新框架
- **全面示例**: 展示完整SDK使用的演示应用
- **内存安全**: 具有托管内存处理的适当Swift-C互操作

## 安装

### Swift Package Manager (SPM)

在项目的`Package.swift`中添加SDK作为依赖：

```swift
dependencies: [
    .package(path: "/path/to/llama_mobile-ios-SDK")
]
```

然后将其添加到您的目标：

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["LlamaMobileSDK"]
    )
]
```

## 使用

### 基本初始化

```swift
import LlamaMobileSDK

let llamaMobile = LlamaMobile()

// 使用模型参数初始化
let initParams = LlamaMobile.InitParams(
    modelPath: "/path/to/your/model.gguf",
    nCtx: 2048,
    nGpuLayers: 4,
    nThreads: 4,
    useMmap: true,
    embedding: true  // 如果需要，启用嵌入
)

let success = llamaMobile.initialize(with: initParams)
if success {
    print("模型加载成功！")
} else {
    print("加载模型失败")
}
```

### 生成补全

```swift
// 创建补全参数
let completionParams = LlamaMobile.CompletionParams(
    prompt: "你好，世界！",
    nPredict: 128,
    temperature: 0.7,
    topK: 40,
    topP: 0.9,
    penaltyRepeat: 1.1,
    stopSequences: ["\n", "<|endoftext|>"]
)

// 生成补全
if let result = llamaMobile.completion(with: completionParams) {
    print("补全结果: \(result.text)")
    print("预测的标记数: \(result.tokensPredicted)")
    print("总标记数: \(result.totalTokens)")
}
```

### 多模态补全（图像/音频）

在使用多模态补全之前，您必须初始化多模态组件：

```swift
// 初始化多模态组件
let multimodalSuccess = llamaMobile.initMultimodal()
if multimodalSuccess {
    print("多模态组件初始化成功！")
}

// 创建补全参数
let multimodalParams = LlamaMobile.CompletionParams(
    prompt: "描述这张图片：",
    nPredict: 256,
    temperature: 0.7
)

// 图片文件路径
let imagePath = "/path/to/image.jpg"

// 生成多模态补全
if let result = llamaMobile.multimodalCompletion(with: multimodalParams, mediaPaths: [imagePath]) {
    print("多模态补全结果: \(result.text)")
}
```

### LoRA适配器

LoRA适配器允许您在不重新训练的情况下微调模型的行为：

```swift
// 应用单个LoRA适配器
let adapter = LlamaMobile.LoraAdapter(
    path: "/path/to/financial-adapter.lora",
    scale: 0.8
)

if llamaMobile.applyLoraAdapters(adapters: [adapter]) {
    print("LoRA适配器应用成功")
    
    // 使用适配后的模型生成补全
    let financialPrompt = "解释股票市场基本面"
    let financialParams = LlamaMobile.CompletionParams(
        prompt: financialPrompt,
        nPredict: 200,
        temperature: 0.6
    )
    
    if let result = llamaMobile.completion(with: financialParams) {
        print("金融解释: \(result.text)")
    }
}

// 移除适配器以返回基础模型
llamaMobile.removeLoraAdapters()

// 检查已加载的适配器
let loadedAdapters = llamaMobile.getLoadedLoraAdapters()
print("已加载的LoRA适配器: \(loadedAdapters.count)")
```

### 标记化

在文本和模型标记之间转换：

```swift
// 标记化文本
let text = "你好，世界！"
if let tokenizeResult = llamaMobile.tokenize(text: text) {
    print("标记: \(tokenizeResult.tokens)")
    print("标记计数: \(tokenizeResult.tokens.count)")
}

// 解标记化
let tokens: [Int32] = [15496, 11, 995, 0]
if let detokenizedText = llamaMobile.detokenize(tokens: tokens) {
    print("解标记化文本: \(detokenizedText)")
}
```

### 嵌入

生成文本的数值表示：

```swift
// 注意：必须在InitParams中设置embedding: true
let text = "敏捷的棕色狐狸跳过懒狗"
if let embeddings = llamaMobile.embedding(text: text) {
    print("嵌入维度: \(embeddings.count)")
    print("前几个值: \(embeddings.prefix(5))")
}
```

### 声码器和文本转语音 (TTS)

将文本转换为语音：

```swift
// 初始化声码器（需要单独的声码器模型）
let vocoderPath = "/path/to/vocoder/model.bin"
if llamaMobile.initializeVocoder(modelPath: vocoderPath) {
    print("声码器初始化成功！")
    
    // 格式化TTS文本
    let textToSpeak = "你好，今天过得怎么样？"
    if let formattedText = llamaMobile.getFormattedAudioCompletion(textToSpeak: textToSpeak) {
        // 生成语音标记
        let ttsParams = LlamaMobile.CompletionParams(
            prompt: formattedText,
            nPredict: 1000,
            temperature: 0.0  // TTS通常使用0温度以获得确定性输出
        )
        
        if let ttsResult = llamaMobile.completion(with: ttsParams) {
            // 获取音频补全
            if let audioTokens = ttsResult.predictedTokens {
                // 将音频标记解码为音频样本
                if let audioSamples = llamaMobile.decodeAudioTokens(tokens: audioTokens) {
                    print("生成的音频样本: \(audioSamples.count)")
                    // 播放或保存音频样本
                }
            }
        }
    }
}

// 完成后释放声码器
llamaMobile.releaseVocoder()
```

## API参考

本节提供了LlamaMobile SDK中所有公共API的全面参考。

### 核心类

#### `LlamaMobile()`
创建SDK的新实例。

```swift
let llamaMobile = LlamaMobile()
```

### 初始化

#### `initialize(with: InitParams) -> Bool`
使用指定的参数初始化模型。

#### `initMultimodal() -> Bool`
初始化用于处理图像/音频的多模态组件。

### 补全

#### `completion(with: CompletionParams) -> CompletionResult?`
为提示生成文本补全。

#### `multimodalCompletion(with: CompletionParams, mediaPaths: [String]) -> CompletionResult?`
使用图像/音频输入生成文本补全。

### LoRA适配器

#### `applyLoraAdapters(adapters: [LoraAdapter]) -> Bool`
将LoRA适配器应用于模型。

#### `removeLoraAdapters()`
移除所有应用的LoRA适配器。

#### `getLoadedLoraAdapters() -> [LoraAdapter]`
返回当前加载的LoRA适配器列表。

### 标记化

#### `tokenize(text: String) -> TokenizeResult?`
将文本转换为模型标记。

#### `tokenizeWithMedia(text: String, mediaPaths: [String]) -> TokenizeResult?`
使用媒体输入标记化文本。

#### `detokenize(tokens: [Int32]) -> String?`
将标记转换回文本。

#### `setGuideTokens(tokens: [Int32]) -> Bool`
为生成设置引导标记。

### 嵌入

#### `embedding(text: String) -> [Float]?`
生成文本嵌入。

### 声码器和TTS

#### `initializeVocoder(modelPath: String) -> Bool`
初始化用于TTS的声码器。

#### `releaseVocoder()`
释放声码器资源。

#### `isVocoderEnabled() -> Bool`
检查声码器是否已初始化。

#### `getTtsType() -> Int32`
获取模型支持的TTS类型。

#### `getFormattedAudioCompletion(speakerJsonStr: String?, textToSpeak: String) -> String?`
为TTS生成格式化文本。

#### `decodeAudioTokens(tokens: [Int32]) -> [Float]?`
将音频标记解码为音频样本。

## SDK结构

```
llama_mobile-ios-SDK/
├── LlamaMobileSDK/
│   ├── LlamaMobile.swift          # 核心Swift包装类
│   ├── LlamaMobileSDK-Bridging-Header.h  # C API桥接头文件
│   └── LlamaMobileSDK.h           # 公共头文件
├── Frameworks/
│   └── llama_mobile.xcframework/  # 嵌入式llama_mobile框架
├── Package.swift                  # Swift Package Manager配置
├── examples/
│   └── iOSSDKExample/             # 演示应用
└── README.md                      # 此文件
```

## 构建SDK

1. **克隆仓库**:
   ```bash
   git clone <repository-url>
   cd llama_mobile-ios-SDK
   ```

2. **构建SDK**:
   ```bash
   swift build
   ```

## 更新框架

SDK包含一个脚本，用于自动将嵌入式`llama_mobile.xcframework`更新到最新版本：

1. **在`llama_mobile-ios`目录中构建最新框架**:
   ```bash
   cd /path/to/llama_mobile/llama_mobile-ios
   # 根据其说明构建框架
   ```

2. **从根目录运行更新脚本**:
   ```bash
   cd /path/to/llama_mobile
   ./build-ios-SDK.sh
   ```

该脚本将：
- 验证框架是否存在于`llama_mobile-ios/`中
- 从SDK中移除任何旧框架
- 将最新框架复制到`llama_mobile-ios-SDK/Frameworks/`
- 使脚本可执行以便将来使用

## 示例应用

SDK包含一个全面的示例应用程序，位于`examples/iOSSDKExample/`，展示了：

- 模型加载功能
- 提示输入处理
- 补全生成
- 用户界面组件
- 错误处理

要运行示例：

```bash
cd llama_mobile-ios-SDK/examples/iOSSDKExample/
swift build
# 在Xcode中打开或使用您首选的方法运行
```

## 注意事项和限制

- **进度回调**: 由于C函数指针闭包捕获限制，目前已禁用。可以通过适当的上下文管理解决方案重新访问此功能。
- **平台支持**: iOS 15.0+
- **Swift版本**: Swift 5.9+
- **框架大小**: 嵌入式xcframework会增加应用程序的整体大小

## 贡献

请参考主要的`llama_mobile`仓库以获取贡献指南。

## 测试

### 运行测试

SDK包含一个全面的测试套件，验证所有核心功能。

#### 使用Xcode

1. 在Xcode中打开SDK项目
2. 选择`LlamaMobileSDKTests`目标
3. 点击"测试"按钮或使用⌘+U

#### 使用命令行

```bash
cd llama_mobile-ios-SDK
sudo xcodebuild test -scheme LlamaMobileSDK -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### 测试资源

测试需要模型文件和语法文件才能运行。您需要手动添加这些资源：

#### 模型

1. 下载GGUF格式的模型（例如`mistral-7b-v0.1.Q4_K_M.gguf`）
2. 将模型文件复制到：
   ```
   llama_mobile-ios-SDK/Tests/LlamaMobileSDKTests/Resources/models/
   ```

#### 语法

1. 从主库复制语法文件：
   ```bash
   cp -r /path/to/llama_mobile/lib/grammars/* llama_mobile-ios-SDK/Tests/LlamaMobileSDKTests/Resources/grammars/
   ```

### 测试结构

```
Tests/
└── LlamaMobileSDKTests/
    ├── Resources/
    │   ├── models/       # 在此放置模型文件
    │   └── grammars/     # 在此放置语法文件
    ├── TestCoreFunctionality.swift   # 核心API测试
    ├── TestGrammar.swift             # 语法支持测试
    └── TestImport.swift              # 模块导入测试
```

### 测试类型

- **核心功能测试**: 验证模型加载、补全生成和基本API功能
- **语法测试**: 验证使用语法文件的约束生成（JSON、算术等）
- **导入测试**: 确保正确的模块导入和初始化

## 许可证

与主要的`llama_mobile`库相同的许可证。