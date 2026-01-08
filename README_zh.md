# llama_mobile

```
    _______________________
   /                       \
  /   ████████  ████████   \
 |    ██      ██      ██    |
 |    ██  LLAMA MOBILE ██    |
 |    ██      ██      ██    |
 |    ████████  ████████    |
 |                           |
 |  ╔════════════════════╗   |
 |  ║    AI ON THE GO    ║   |
 |  ║                     ║   |
 |  ║  • iOS & Android    ║   |
 |  ║  • Flutter          ║   |
 |  ║  • React Native     ║   |
 |  ║  • Capacitor        ║   |
 |  ╚════════════════════╝   |
 |                           |
 |       🧠 📱 🚀          |
  \_________________________/
        /\
       /  \
      /____\
```

一个轻量级、高性能的框架，用于在移动设备上运行AI模型，基于llama.cpp构建，支持iOS、Android、Flutter、ReactNative以及通过Capacitor构建的Web应用程序的跨平台兼容性。

## 项目概述

llama_mobile是一个移动优先的AI框架，它将llama.cpp的强大功能带到了各种移动平台和开发框架中。该项目专注于提供原生SDK和插件，以便将大型语言模型（LLMs）无缝集成到移动和Web应用程序中。

## 插件和SDK

llama_mobile为各种开发平台提供专门的SDK和插件，以简化AI模型到应用程序的集成。以下是所有可用SDK和插件的综合列表：

### 核心库

- **llama_mobile-ios/**：用于将AI模型集成到iOS应用程序的原生iOS框架。支持Swift和Objective-C，并通过Metal加速实现最佳性能。
  - **README**：[llama_mobile-ios/README.md](llama_mobile-ios/README.md)
  - **构建脚本**：`scripts/build-ios.sh`

- **llama_mobile-android/**：用于将AI模型集成到Android应用程序的原生Android库。提供JNI绑定和Neon SIMD支持，以实现性能优化。
  - **README**：[llama_mobile-android/README.md](llama_mobile-android/README.md)
  - **构建脚本**：`scripts/build-android.sh`

### SDK封装

- **llama_mobile-ios-SDK/**：高级iOS SDK封装，简化了Swift应用程序中的模型加载、文本生成和嵌入操作。
  - **README**：[llama_mobile-ios-SDK/README.md](llama_mobile-ios-SDK/README.md)

- **llama_mobile-android-SDK/**：适用于Kotlin和Java应用程序的高级Android SDK封装。为AI模型操作提供了清晰的API和适当的错误处理。
  - **README**：[llama_mobile-android-SDK/README.md](llama_mobile-android-SDK/README.md)

### 跨平台插件

- **llama_mobile-flutter-SDK/**：Flutter插件，提供Dart API，用于将AI模型集成到跨平台Flutter应用程序中。支持iOS和Android目标平台。
  - **README**：[llama_mobile-flutter-SDK/README.md](llama_mobile-flutter-SDK/README.md)
  - **构建脚本**：`scripts/build-flutter.sh`

- **llama_mobile-react-native-SDK/**：React Native插件，提供JavaScript/TypeScript绑定，用于原生AI模型操作。允许在React Native应用程序中集成AI功能。
  - **README**：[llama_mobile-react-native-SDK/README.md](llama_mobile-react-native-SDK/README.md)

- **llama_mobile-capacitor/**：（计划中）用于将AI模型集成到Web应用程序的Capacitor插件。为跨平台Web应用程序启用AI功能。
  - **状态**：⏳ 开发中

### 示例应用

每个SDK和插件都附带示例应用程序，展示其基本用法：

#### iOS示例
- **iOS框架示例**：`examples/iOSFrameworkExample/` - 演示原生iOS框架的用法
- **iOS SDK示例**：`examples/iOSSDKExample/` - 展示如何使用高级iOS SDK封装
- **SwiftUI示例**：`examples/LlamaMobileSwiftUIExample/` - 现代SwiftUI应用程序示例

#### Android示例
- **Android库示例**：`examples/androidLibExample/` - 原生Android库的基本用法
- **Android SDK示例**：`examples/androidSDKExample/` - 高级Android SDK封装的用法
- **Android Java SDK示例**：`examples/androidJavaSDKExample/` - Java特定SDK用法示例
- **Android示例**：`examples/AndroidExample/` - 综合Android应用程序示例

#### 跨平台示例
- **Flutter SDK示例**：`examples/flutterSDKExample/` - Flutter插件集成示例

#### 核心示例
- **C++示例**：`examples/cpp/` - 直接使用核心C++库

## 架构

### 核心组件

- **lib/**：主库目录，包含：
  - **lib/tests/**：C/C++源代码的测试
  - **lib/llama_cpp/**：核心llama.cpp实现
  - 移动特定的适配和优化
  - 各种GGUF模型（常规、嵌入、VLM、多模态）

- **llama_mobile-ios/**：iOS框架项目文件夹
- **llama_mobile-android/**：Android库项目文件夹
- **llama_mobile-android-SDK/**：Android SDK封装项目文件夹
- **llama_mobile-flutter-SDK/**：Flutter插件项目文件夹
- **scripts/**：构建和实用脚本
- **CMakeLists.txt**：核心库的构建配置

### 计划组件

- **llama_mobile_reactnative/**：ReactNative插件
- **llama_mobile_capacitor/**：用于Web应用程序的Capacitor插件

## 构建脚本

项目包含各种构建脚本：

- **build_and_run_lib_test.sh**：构建核心库和测试，然后运行它们
- **build-ios.sh**：基于核心库构建iOS框架
- **build-android.sh**：构建Android库和SDK
- **build-flutter.sh**：构建Flutter插件
- （计划中）**build-reactnative.sh**：构建ReactNative插件

## 入门指南

### 构建核心库

```bash
# 构建核心库
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### 构建iOS框架

```bash
# 构建iOS框架
./build-ios.sh
```

### 构建Android库和SDK

```bash
# 构建Android库和SDK
./build-android.sh
```

### 构建和运行测试

#### 核心库测试

核心C++库包含一个全面的测试套件（`lib/tests/test_api.cpp`），涵盖：

- **模型初始化**：使用不同参数加载和初始化模型
- **文本完成**：基本和高级文本生成
- **分词**：文本和模型标记之间的转换
- **嵌入生成**：生成文本的数字表示
- **对话管理**：创建和管理对话上下文
- **语法约束生成**：生成符合特定语法规则的文本（例如JSON输出）

构建并运行核心库测试：

```bash
# 构建并运行测试
./scripts/build_and_run_lib_test.sh
```

或者，您可以手动构建和运行测试：

```bash
# 构建测试二进制文件
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make test_api

# 运行测试
./test_api
```

#### SDK测试

每个SDK都有自己的测试套件。请参考相应的SDK README文件获取详细信息：

- **iOS SDK**：`llama_mobile-ios-SDK/README.md`
- **Android Kotlin SDK**：`llama_mobile-android-SDK/README.md`
- **Android Java SDK**：`llama_mobile-android-java-SDK/README.md`
- **Flutter SDK**：`llama_mobile-flutter-SDK/README.md`
- **ReactNative SDK**：`llama_mobile-react-native-SDK/README.md`
- **Capacitor插件**：`llama_mobile-capacitor-plugin/CONTRIBUTING.md`

## 当前状态

该项目目前处于积极开发阶段，已完成以下组件：

- ✅ 核心C++库（基于llama.cpp）
- ✅ iOS框架
- ✅ Android库（llama_mobile-android）
- ✅ Android SDK封装（llama_mobile-android-SDK）
- ✅ 基本测试基础设施
- ✅ 核心库、iOS、Android和Flutter的构建脚本
- ✅ iOS、Android和Flutter的示例应用
- ✅ Flutter插件（llama_mobile-flutter-SDK）

计划开发：

- ⏳ ReactNative插件
- ⏳ Capacitor插件

## 支持的模型

该框架支持各种GGUF模型类型：

- 标准语言模型
- 嵌入模型
- 视觉语言模型（VLM）
- 多模态模型

## 集成计划

该框架目前支持与以下平台集成：

1. **原生应用程序**：
   - 通过`llama_mobile_ios`框架实现iOS应用
   - 通过`llama_mobile-android`库和`llama_mobile-android-SDK`封装实现Android应用

2. **跨平台框架**：
   - ✅ 通过Flutter插件（`llama_mobile-flutter-SDK`）实现Flutter应用
   - ⏳ 通过ReactNative插件实现ReactNative应用

3. **基于Web的应用程序**（计划中）：
   - 用于使用原生iOS/Android SDK的Web应用程序的Capacitor插件

## 贡献

欢迎贡献！请随时：

- 提交错误修复
- 提出新功能建议
- 改进文档
- 添加对其他平台的支持

## 许可证

本项目采用MIT许可证 - 有关详情，请参阅LICENSE文件。

## 致谢

- 基于Georgi Gerganov的[llama.cpp](https://github.com/ggerganov/llama.cpp)
- 受到各种移动AI框架的启发

## 路线图

1. ✅ 创建Flutter插件
2. 创建ReactNative插件
3. 开发用于Web应用程序的Capacitor插件
4. 添加全面的文档和示例
5. 优化移动设备的性能
6. 扩展模型支持和兼容性

请继续关注我们的更新，我们将继续开发和扩展这个框架！

## 构建说明

### 先决条件

#### 通用要求
- CMake 3.20或更高版本
- Python 3.x（用于一些实用脚本）

#### iOS构建要求
- 安装了Xcode的macOS
- 移动应用的iOS 13.0+部署目标

#### Android构建要求
- 安装了Android Studio
- Java Development Kit (JDK) 8或更高版本
- Android SDK（API级别21或更高）
- Android NDK版本29.0.14206865（构建原生库所需）
- 设置ANDROID_HOME环境变量，指向您的Android SDK目录

### 核心库

```bash
# 构建核心库
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### iOS框架

iOS框架需要预编译的Metal库以获得最佳性能。构建过程会自动处理这一点。

```bash
# 使用预编译的Metal库构建iOS框架
./scripts/build-ios.sh
```

#### Metal库编译详情

iOS框架依赖于预编译的Metal着色器库（用于设备的`ggml-llama.metallib`和用于模拟器的`ggml-llama-sim.metallib`）。这些库在构建过程中自动生成：

- **Metal语言版本**：`ios-metal2.3`（兼容iOS 13.0+）
- **部署目标**：iOS 14.0（与核心库要求兼容）

构建脚本（`scripts/build-ios.sh`）处理：
1. 从`lib/llama_cpp/ggml-metal.metal`编译Metal着色器
2. 生成设备和模拟器特定的metallib文件
3. 组装`llama_mobile.xcframework`
4. 复制必要的资源

#### 验证Metal库

验证生成的metallib文件的部署目标：

```bash
# 检查设备metallib部署目标
strings lib/llama_cpp/ggml-llama.metallib | grep -i "apple-ios"

# 检查模拟器metallib部署目标
strings lib/llama_cpp/ggml-llama-sim.metallib | grep -i "apple-ios"
```

### iOS示例应用

运行iOS示例应用：

1. 在Xcode中打开`examples/iOSFrameworkExample/iOSFrameworkExample.xcodeproj`
2. 选择目标设备或模拟器
3. 构建并运行项目

### 未来构建说明（计划中）

#### Android库和SDK

在为Android构建之前，您需要确保开发环境已正确配置：

#### 从Android Studio查找SDK和NDK路径

您可以直接从Android Studio查找SDK和NDK路径：

1. **打开Android Studio偏好设置/设置**：
   - 在macOS上：Android Studio → 偏好设置
   - 在Windows/Linux上：文件 → 设置

2. **查找Android SDK路径**：
   - 导航到：外观与行为 → 系统设置 → Android SDK
   - 您的SDK路径显示在窗口顶部
   - 示例：`/Users/yourname/Library/Android/sdk`（macOS）

3. **查找NDK路径**：
   - 仍在Android SDK设置中，选择"SDK工具"选项卡
   - 选中"显示包详细信息"复选框
   - 展开"NDK (Side by side)"部分
   - 显示已安装的NDK版本及其路径
   - 您还可以在顶部看到整体NDK位置
   - 示例：`/Users/yourname/Library/Android/sdk/ndk/29.0.14206865`

#### 设置ANDROID_HOME

构建脚本将尝试从常见位置自动检测您的Android SDK路径：
- macOS: `~/Library/Android/sdk` 或 `~/android-sdk`
- Linux: `~/Android/Sdk`、`~/android-sdk` 或 `/opt/android-sdk`
- Windows (Git Bash): `%USERPROFILE%/AppData/Local/Android/Sdk` 或 `%USERPROFILE%/Android/Sdk`

如果自动检测失败，请手动设置ANDROID_HOME：

### 临时设置（仅限当前终端会话）

```bash
# 在macOS/Linux上

export ANDROID_HOME=/path/to/your/android/sdk
./scripts/build-android.sh

# 在Windows (Git Bash)上
export ANDROID_HOME=C:/path/to/your/android/sdk
./scripts/build-android.sh
```

### 永久设置

#### 在macOS/Linux上

**对于Bash shell：**
1. 在文本编辑器中打开`~/.bash_profile`或`~/.bashrc`
2. 添加行：`export ANDROID_HOME=/path/to/your/android/sdk`
3. 保存文件
4. 运行：`source ~/.bash_profile`或`source ~/.bashrc`以应用更改

**对于Zsh shell（macOS Catalina及更高版本的默认值）：**
1. 在文本编辑器中打开`~/.zshrc`
2. 添加行：`export ANDROID_HOME=/path/to/your/android/sdk`
3. 保存文件
4. 运行：`source ~/.zshrc`以应用更改

**验证设置：**
```bash
echo $ANDROID_HOME
```
这应该显示您的Android SDK目录路径。

#### 设置NDK路径

构建脚本默认使用NDK版本29.0.14206865。如果您需要使用不同的NDK版本，可以指定：

```bash
# 使用特定NDK版本构建Android库
./scripts/build-android.sh --ndk-version=29.0.14206865
```

#### 构建Android库

```bash
# 构建Android库和SDK
./scripts/build-android.sh
```

### Android的Arm Neon支持

llama_mobile完全支持Android设备的Arm Neon SIMD（单指令多数据）技术，为Arm架构上的AI模型推理提供显著的性能改进。

#### 主要功能

- **默认启用**：使用Android NDK工具链为`arm64-v8a`构建时，Neon支持自动启用
- **运行时检测**：Neon功能通过Android的`getauxval()`系统调用在运行时检测
- **优化操作**：各种性能关键操作（包括矩阵乘法、张量操作和量化/反量化）都使用Neon指令进行优化
- **AArch64架构**：Neon保证在所有AArch64（ARM64）设备上可用，框架利用这一保证实现最佳性能

#### Neon检测和使用

框架自动检测并使用Neon功能：

1. **硬件功能检测**：代码在运行时检查Neon和相关扩展（dotprod、fp16、i8mm）
2. **优化路径选择**：对于每个支持的操作，选择最快可用的实现（Neon与通用）
3. **回退支持**：在特定Neon扩展不可用的情况下，框架优雅地回退到通用实现

#### 性能优势

使用Neon加速提供显著的性能改进：
- **2-4倍更快**的矩阵乘法操作
- **30-50%的整体性能提升**用于AI模型推理
- **减少电池消耗**，因为计算速度更快

#### 验证Neon支持

Neon支持由框架自动启用和使用。构建过程包括所有支持操作的优化Neon代码路径。

#### Flutter插件
```bash
# Flutter构建脚本
./scripts/build-flutter.sh
```

#### ReactNative插件
```bash
# 计划中的ReactNative构建脚本
./scripts/build-reactnative.sh
```

#### Capacitor插件
```bash
# 计划中的Capacitor构建脚本
./scripts/build-capacitor.sh
```

## 集成指南

### iOS集成

1. 将`llama_mobile.xcframework`添加到您的Xcode项目
2. 链接所需的系统框架（Metal、MetalKit）
3. 在代码中导入框架：
   ```swift
   import llama_mobile
   ```
4. 根据需要初始化库并加载模型

### Android集成

1. 将`llama_mobile-android`库作为模块依赖项添加到您的Android Studio项目
2. 在`settings.gradle`中添加以下内容：
   ```gradle
   include ':llama_mobile'
   project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
   ```
3. 在应用的`build.gradle`中添加依赖项：
   ```gradle
   dependencies {
       implementation project(':llama_mobile')
   }
   ```
4. 在Kotlin代码中导入库：
   ```kotlin
   import com.llamamobile.LlamaMobile
   ```
5. 根据需要初始化库并加载模型

### Flutter集成

#### Flutter设置先决条件

在使用Flutter插件之前，确保Flutter已正确安装和配置：

1. **安装Flutter SDK：**
   - 从[https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)下载Flutter SDK
   - 将SDK提取到位置，如`/Users/yourname/flutter`（macOS/Linux）或`C:\flutter`（Windows）

2. **设置Flutter PATH：**
   
   **对于macOS/Linux：**
   - **Bash shell：** 添加到`~/.bash_profile`或`~/.bashrc`：
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - **Zsh shell：** 添加到`~/.zshrc`：
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - 运行`source ~/.bashrc`或`source ~/.zshrc`以应用更改

   **对于Windows：**
   - 将`C:\flutter\bin`添加到系统PATH环境变量

3. **验证Flutter安装：**
   ```bash
flutter doctor
   ```
   在继续之前修复`flutter doctor`报告的任何问题

4. **确保最低Flutter版本：**
   - 此插件需要Flutter 3.0.0或更高版本
   - 检查您的Flutter版本：
     ```bash
flutter --version
     ```

#### 集成Flutter插件

1. 将`llama_mobile_flutter_sdk`添加到Flutter项目的`pubspec.yaml`：
   ```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
```

2. 在Dart代码中导入库：
   ```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
```

3. 初始化SDK并加载模型：
   ```dart
final llamaSdk = LlamaMobileFlutterSdk();
final config = ModelConfig(modelPath: 'path/to/model.gguf');
final success = await llamaSdk.loadModel(config);
```

4. 生成完成：
   ```dart
final generationConfig = GenerationConfig(prompt: 'Hello,');
final completion = await llamaSdk.generateCompletion(generationConfig);
print(completion);
```

5. 完成后释放资源：
   ```dart
await llamaSdk.release();
```

### 未来集成（计划中）

- **ReactNative**：围绕原生模块的JavaScript/TypeScript封装
- **Capacitor**：用于跨平台Web应用的Web兼容插件

## 在新项目中使用SDK

### iOS Swift应用

#### 步骤1：创建新的iOS项目
1. 打开Xcode并选择"Create a new Xcode project"
2. 选择"iOS" → "App"
3. 输入您的项目详细信息：
   - Product Name: `LlamaMobileDemo`
   - Team: 选择您的开发团队
   - Interface: `Storyboard`或`SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 13.0`或更高版本
4. 将项目保存到您想要的位置

#### 步骤2：添加自包含SDK
1. 在Xcode中，在Project Navigator中右键单击您的项目，选择"Add Files to LlamaMobileDemo..."
2. 导航到`/path/to/llama_mobile/llama_mobile-ios/llama_mobile.xcframework`
3. 选择xcframework并确保：
   - "Copy items if needed"已勾选
   - 您的目标在"Add to targets"下已选择
4. 点击"Add"

#### 步骤3：配置项目设置
1. 在Project Navigator中选择您的项目
2. 转到"Build Phases"标签
3. 在"Link Binary With Libraries"下，验证`llama_mobile.xcframework`已列出
4. 添加所需的系统框架：
   - 点击"+"按钮
   - 添加`Metal.framework`
   - 添加`MetalKit.framework`
   - 添加`Accelerate.framework`

#### 步骤4：添加所需权限
1. 打开`Info.plist`
2. 添加以下键：
   - 对于本地文件访问：`Privacy - File Provider Domain Usage Description`
   - 对于模型下载：`Privacy - Network Usage Description`

#### 步骤5：基本使用示例

```swift
import UIKit
import llama_mobile

class ViewController: UIViewController {
    private var modelPath: String?
    private var modelHandle: UnsafeMutableRawPointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLlamaMobile()
    }
    
    func setupLlamaMobile() {
        // 初始化库
        llama_mobile_init()
        
        // 将模型从bundle复制到documents目录
        copyModelToDocuments()
    }
    
    func copyModelToDocuments() {
        guard let modelURL = Bundle.main.url(forResource: "your-model", withExtension: "gguf") else {
            print("模型在bundle中未找到")
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("your-model.gguf")
        
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.copyItem(at: modelURL, to: destinationURL)
                modelPath = destinationURL.path
                loadModel()
            } catch {
                print("复制模型失败: \(error)")
            }
        } else {
            modelPath = destinationURL.path
            loadModel()
        }
    }
    
    func loadModel() {
        guard let modelPath = modelPath else { return }
        
        // 设置模型参数
        var params = llama_mobile_params()
        params.n_threads = 4
        params.n_gpu_layers = 4
        
        // 加载模型
        let result = llama_mobile_load_model(modelPath, &params)
        if result != nil {
            modelHandle = result
            print("模型加载成功")
            generateText()
        } else {
            print("加载模型失败")
        }
    }
    
    func generateText() {
        guard let modelHandle = modelHandle else { return }
        
        // 设置生成参数
        var genParams = llama_mobile_gen_params()
        genParams.max_new_tokens = 100
        genParams.temperature = 0.7
        
        // 生成文本
        let prompt = "Hello, how are you?"
        var output = ""
        
        let callback: llama_mobile_token_callback = { token_ptr, user_data in
            if let token_ptr = token_ptr {
                let token = String(cString: token_ptr)
                output += token
                print(token, terminator: "")
            }
            return 0
        }
        
        llama_mobile_generate(modelHandle, prompt, &genParams, callback, nil)
        print("\n生成完成: \(output)")
    }
    
    deinit {
        // 清理
        if let modelHandle = modelHandle {
            llama_mobile_free_model(modelHandle)
        }
        llama_mobile_cleanup()
    }
}
```

### Android应用

#### 步骤1：创建新的Android项目
1. 打开Android Studio
2. 选择"New Project"
3. 选择"Empty Activity"
4. 输入您的项目详细信息：