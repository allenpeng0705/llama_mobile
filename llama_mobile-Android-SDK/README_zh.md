# llama_mobile-android-SDK

一个高级Android SDK，封装了`llama_mobile-android`库，为与llama模型交互提供了更方便、更符合Kotlin习惯的API。

## 概述

`llama_mobile-android-SDK`在原始`llama_mobile-android`库之上提供了一个精简的高级API。它处理线程管理、错误处理，并为Android开发者提供了更直观的界面。

## 功能特性

- 简化的模型加载和文本生成API
- 内置线程支持，避免UI阻塞
- 基于回调的异步操作API
- 使用描述性异常的错误处理
- 一致的命名和Kotlin习惯用法

## 安装

### 前提条件

- Android SDK 21或更高版本
- Android NDK 25或更高版本
- CMake 3.22或更高版本

### 添加到您的项目

1. 克隆仓库：

```bash
git clone https://github.com/yourusername/llama_mobile.git
cd llama_mobile
```

2. 构建Android库和SDK：

```bash
./build-android.sh
```

3. 在您的Android Studio项目中添加两个模块作为依赖：

```gradle
// settings.gradle
include ':llama_mobile'
include ':llama_mobile_sdk'

project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
project(':llama_mobile_sdk').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-SDK')

// app/build.gradle
dependencies {
    implementation project(':llama_mobile_sdk')
}
```

## 使用

### 基本示例

```kotlin
import com.llamamobile.sdk.LlamaMobileSdk

// 初始化SDK
val llamaMobileSdk = LlamaMobileSdk()

// 加载模型
val modelConfig = LlamaMobileSdk.ModelConfig(
    modelPath = "/sdcard/Download/llama-model.gguf",
    contextSize = 1024,
    useMemoryCache = true
)

llamaMobileSdk.loadModel(modelConfig, object : LlamaMobileSdk.ResultCallback<Boolean> {
    override fun onSuccess(result: Boolean) {
        runOnUiThread {
            if (result) {
                // 模型加载成功
                Toast.makeText(this@MainActivity, "模型加载成功", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@MainActivity, "加载模型失败", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onError(error: Throwable) {
        runOnUiThread {
            Toast.makeText(this@MainActivity, "错误: ${error.message}", Toast.LENGTH_LONG).show()
        }
    }
})

// 生成文本
val generationConfig = LlamaMobileSdk.GenerationConfig(
    prompt = "你好，世界！",
    temperature = 0.8f,
    maxTokens = 100
)

llamaMobileSdk.generate(generationConfig, object : LlamaMobileSdk.GenerationListener {
    override fun onGenerationStart(prompt: String) {
        runOnUiThread {
            // 更新UI以显示生成开始
            statusTextView.text = "正在生成..."
        }
    }

    override fun onGenerationComplete(result: String) {
        runOnUiThread {
            // 显示生成的文本
            resultTextView.text = result
            statusTextView.text = "生成完成"
        }
    }

    override fun onError(error: Throwable) {
        runOnUiThread {
            Toast.makeText(this@MainActivity, "错误: ${error.message}", Toast.LENGTH_LONG).show()
        }
    }
})

// 完成后释放资源
llamaMobileSdk.release()
```

## API参考

### LlamaMobileSdk.ModelConfig

用于加载模型的配置。

| 参数 | 类型 | 描述 | 默认值 |
|------|------|------|--------|
| `modelPath` | String | llama模型文件路径(.gguf) | - |
| `contextSize` | Int | 上下文窗口大小 | 1024 |
| `useMemoryCache` | Boolean | 是否使用内存缓存 | true |

### LlamaMobileSdk.GenerationConfig

用于生成文本补全的配置。

| 参数 | 类型 | 描述 | 默认值 |
|------|------|------|--------|
| `prompt` | String | 文本生成的输入提示 | - |
| `temperature` | Float | 采样温度 | 0.8 |
| `maxTokens` | Int | 要生成的最大标记数 | 100 |

### LlamaMobileSdk.ResultCallback<T>

用于返回单个结果的操作的回调接口。

| 方法 | 描述 |
|------|------|
| `onSuccess(result: T)` | 当操作成功完成时调用 |
| `onError(error: Throwable)` | 当发生错误时调用 |

### LlamaMobileSdk.GenerationListener

用于文本生成事件的监听器接口。

| 方法 | 描述 |
|------|------|
| `onGenerationStart(prompt: String)` | 当生成开始时调用 |
| `onGenerationComplete(result: String)` | 当生成成功完成时调用 |
| `onError(error: Throwable)` | 当生成过程中发生错误时调用 |

### LlamaMobileSdk方法

| 方法 | 描述 |
|------|------|
| `loadModel(config: ModelConfig, callback: ResultCallback<Boolean>)` | 使用指定配置加载模型 |
| `generate(config: GenerationConfig, listener: GenerationListener)` | 使用指定配置生成文本补全 |
| `release()` | 释放SDK使用的所有资源 |

## 示例应用

可以在`examples/androidSDKExample`目录中找到演示如何使用SDK的Android示例应用。

## 许可证

MIT许可证

## 故障排除

### 权限问题

- 确保应用程序具有读取模型文件的必要权限：

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

- 对于Android 13+，使用MediaStore API访问文件。

### 内存问题

- 减小`contextSize`参数以使用更少的内存。
- 设置`useMemoryCache = false`以减少内存使用。

### 性能问题

- SDK在单个后台线程上运行。对于多个并发操作，请创建单独的SDK实例。
- 考虑减少`maxTokens`以加快生成速度。

## 测试

### 测试结构

Android SDK包含两种类型的测试：

#### 单元测试

单元测试在隔离环境中验证核心功能：

```
src/test/
├── java/com/llamamobile/sdk/      # 单元测试类
└── resources/
    ├── models/                    # 在此放置用于单元测试的模型文件
    └── grammars/                  # 在此放置用于单元测试的语法文件
```

#### 仪器化测试

仪器化测试在实际Android设备或模拟器上验证功能：

```
src/androidTest/
├── java/com/llamamobile/sdk/      # 仪器化测试类
└── resources/
    ├── models/                    # 在此放置用于仪器化测试的模型文件
    └── grammars/                  # 在此放置用于仪器化测试的语法文件
```

### 测试资源

#### 模型

1. 下载GGUF格式的模型（例如`mistral-7b-v0.1.Q4_K_M.gguf`）
2. 将模型文件复制到两个测试资源文件夹：

```bash
# 用于单元测试
cp model.gguf src/test/resources/models/

# 用于仪器化测试
cp model.gguf src/androidTest/resources/models/
```

#### 语法

语法文件用于约束生成测试：

```bash
# 从核心库复制语法文件
cp -r ../lib/grammars/* src/test/resources/grammars/
cp -r ../lib/grammars/* src/androidTest/resources/grammars/
```

### 运行测试

#### 运行单元测试

使用Gradle运行单元测试：

```bash
./gradlew test
```

#### 运行仪器化测试

使用Gradle在连接的设备/模拟器上运行仪器化测试：

```bash
./gradlew connectedAndroidTest
```

#### 运行特定测试

```bash
# 运行特定的单元测试
./gradlew test --tests "com.llamamobile.sdk.LlamaMobileSdkUnitTests"

# 运行特定的仪器化测试
./gradlew connectedAndroidTest --tests "com.llamamobile.sdk.LlamaMobileSdkInstrumentedTests"
```

### 测试覆盖范围

Android SDK测试覆盖：

- SDK初始化和模型加载
- 文本生成和补全
- 错误处理
- 线程和回调功能
- 语法约束生成

### 示例测试类

```kotlin
// src/test/java/com/llamamobile/sdk/LlamaMobileSdkUnitTests.kt
package com.llamamobile.sdk

import org.junit.Test
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull

class LlamaMobileSdkUnitTests {
    
    @Test
    fun testModelConfigCreation() {
        val modelConfig = LlamaMobileSdk.ModelConfig(
            modelPath = "/path/to/model.gguf",
            contextSize = 2048,
            useMemoryCache = true
        )
        
        assertNotNull(modelConfig)
        assertEquals("/path/to/model.gguf", modelConfig.modelPath)
        assertEquals(2048, modelConfig.contextSize)
        assertEquals(true, modelConfig.useMemoryCache)
    }
    
    @Test
    fun testGenerationConfigCreation() {
        val generationConfig = LlamaMobileSdk.GenerationConfig(
            prompt = "你好，世界！",
            temperature = 0.7f,
            maxTokens = 50
        )
        
        assertNotNull(generationConfig)
        assertEquals("你好，世界！", generationConfig.prompt)
        assertEquals(0.7f, generationConfig.temperature, 0.01f)
        assertEquals(50, generationConfig.maxTokens)
    }
}
```

## 贡献

欢迎贡献！请随时提交Pull Request。