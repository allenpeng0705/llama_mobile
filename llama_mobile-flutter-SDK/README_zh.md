# Llama Mobile Flutter SDK

一个跨平台的Flutter SDK，用于Llama Mobile，它集成了原生iOS和Android SDK，提供了统一的API用于模型加载、文本补全生成和资源管理。

## 功能特性

- **统一API**：适用于iOS和Android平台的单一Dart接口
- **模型管理**：轻松加载模型和释放资源
- **文本生成**：使用可配置参数生成文本补全
- **跨平台**：在iOS和Android设备上无缝工作
- **性能优化**：利用原生平台能力实现最佳性能

## 安装

### 前提条件

- Flutter SDK 3.0.0或更高版本
- iOS 13.0或更高版本
- Android 7.0 (API级别24)或更高版本

### 依赖配置

在您的`pubspec.yaml`文件中添加以下依赖：

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile-flutter-SDK
```

然后运行：

```bash
flutter pub get
```

## API文档

### 数据模型

#### InitParams

用于初始化模型的配置：

```dart
class InitParams {
  final String modelPath;        // GGUF模型文件路径
  final int nCtx;               // 模型上下文大小（默认值：2048）
  final int nGpuLayers;         // 使用的GPU层数（默认值：0）
  final int nThreads;           // 使用的CPU线程数（默认值：4）
  final int nBatch;             // 模型处理的批量大小（默认值：512）
  final int nUbatch;            // 模型处理的微批量大小（默认值：512）
  final bool useMmap;           // 是否使用内存映射文件（默认值：true）
  final bool useMlock;          // 是否锁定内存（默认值：false）
  final bool embedding;         // 是否生成嵌入向量（默认值：false）
}
```

#### CompletionParams

用于生成文本补全的配置：

```dart
class CompletionParams {
  final String prompt;           // 生成的提示文本
  final int maxTokens;           // 生成的最大token数（默认值：100）
  final double temperature;      // 采样温度参数（默认值：0.8）
  final int topK;                // Top-K采样参数（默认值：40）
  final double topP;             // Top-P采样参数（默认值：0.95）
  final double minP;             // Min-P采样参数（默认值：0.05）
  final double typicalP;         // Typical-P采样参数（默认值：1.0）
  final int seed;                // 随机种子（默认值：-1表示随机）
  final int nThreads;            // 使用的CPU线程数（默认值：4）
  final int penaltyLastN;        // 惩罚窗口大小（默认值：64）
  final double penaltyRepeat;    // 重复惩罚（默认值：1.1）
  final double penaltyFreq;      // 频率惩罚（默认值：0.0）
  final double penaltyPresent;   // 存在惩罚（默认值：0.0）
  final int mirostat;            // Mirostat采样模式（0：禁用，1：v1，2：v2）
  final double mirostatTau;      // Mirostat目标熵（默认值：5.0）
  final double mirostatEta;      // Mirostat学习率（默认值：0.1）
  final bool ignoreEos;          // 是否忽略序列结束标记（默认值：false）
  final List<String> stopSequences; // 停止序列列表（默认值：空）
  final String? grammar;         // 约束生成的语法字符串（可选）
}
```

#### GrammarName

内置语法类型的枚举：

```dart
enum GrammarName {
  json,        // JSON语法
  arithmetic,  // 算术表达式
  list,        // 列表格式
}
```

### 方法

#### initialize

使用给定配置从指定路径初始化模型：

```dart
Future<bool> initialize(InitParams params)
```

**参数：**
- `params`：初始化配置对象

**返回值：**
- 如果模型初始化成功返回`true`，否则返回`false`

#### generate

根据给定的提示和配置生成文本补全：

```dart
Future<String> generate(CompletionParams params)
```

**参数：**
- `params`：补全配置对象

**返回值：**
- 生成的文本补全字符串

#### getGrammarContent

获取内置语法的内容：

```dart
Future<String?> getGrammarContent(GrammarName grammarName)
```

**参数：**
- `grammarName`：内置语法的名称

**返回值：**
- 如果找到则返回语法内容字符串，否则返回null

#### release

释放加载的模型并释放资源：

```dart
Future<void> release()
```

## 使用示例

```dart
import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _llamaSdk = LlamaMobileFlutterSdk();
  bool _isModelLoaded = false;

  Future<void> _loadModel() async {
    try {
      final config = ModelConfig(
        modelPath: '/path/to/your/model.gguf',
        contextSize: 2048,
        useMemoryCache: true,
      );
      
      final success = await _llamaSdk.loadModel(config);
      setState(() {
        _isModelLoaded = success;
      });
    } catch (e) {
      print('加载模型错误: $e');
    }
  }

  Future<void> _generateText() async {
    if (!_isModelLoaded) return;
    
    try {
      final config = GenerationConfig(
        prompt: '你好，你怎么样？',
        temperature: 0.7,
        maxTokens: 150,
      );
      
      final result = await _llamaSdk.generateCompletion(config);
      print('生成的补全: $result');
    } catch (e) {
      print('生成文本错误: $e');
    }
  }

  @override
  void dispose() {
    _llamaSdk.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 您的UI实现代码
  }
}
```

## 平台特定配置

### iOS

iOS实现需要`llama_mobile-ios-SDK`可用。这会通过插件`podspec`文件中的CocoaPods依赖自动配置。

### Android

Android实现需要`llama_mobile-android-SDK`可用。这会通过插件`build.gradle`文件中的Gradle依赖自动配置。

## 故障排除

### 模型加载问题

- 确保模型路径正确且文件存在
- 检查您是否有访问模型文件的必要权限
- 验证模型格式是否兼容（GGUF格式）

### 生成问题

- 在尝试生成补全之前确保已加载模型
- 检查提示文本是否正确格式化
- 如有需要，调整温度参数和maxTokens参数

## 示例应用

展示Llama Mobile Flutter SDK用法的示例应用程序可在`examples/flutter_sdk_example`目录中找到。

## 许可证

本项目采用MIT许可证。有关详情，请参阅[LICENSE](LICENSE)文件。

## 贡献

欢迎贡献！请参阅[CONTRIBUTING](CONTRIBUTING.md)文件获取更多信息。

## 支持

如有问题和疑问，请在项目仓库中创建issue。