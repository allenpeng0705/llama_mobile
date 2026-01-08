# llama_mobile React Native SDK

一个自包含的React Native SDK，用于在iOS和Android设备上运行大型语言模型。

## 概述

`llama_mobile-react-native-SDK`是一个自包含的React Native模块，提供了在iOS和Android平台上访问llama_mobile AI模型的能力。该SDK设计为无需外部依赖即可使用，因为它直接嵌入了所有必要的原生组件。

### 主要特性

- **自包含**：嵌入iOS xcframework和Android原生库
- **跨平台**：在iOS和Android设备上均可使用
- **流支持**：通过流式API实时生成文本
- **内存管理**：自动上下文处理和内存清理
- **可定制**：配置线程、GPU层和上下文大小等模型参数

## 安装

### 前提条件

- React Native 0.60或更高版本
- Node.js 16或更高版本
- npm 8或更高版本

### 步骤1：将SDK添加到您的项目

将整个`llama_mobile-react-native-SDK`目录复制到您的React Native项目中，然后安装它：

```bash
npm install ./llama_mobile-react-native-SDK
```

### 步骤2：配置iOS

1. 在Xcode中打开您的iOS项目
2. 确保SDK已链接（React Native 0.60+应通过CocoaPods自动处理此操作）
3. 在`ios`目录中运行`pod install`

### 步骤3：配置Android

Android不需要额外配置（React Native 0.60+应自动处理链接）。

## 基本用法

### 导入SDK

```javascript
import LlamaMobile from 'llama_mobile-react-native-SDK';
```

### 初始化SDK

```javascript
// 使用默认设置初始化
await LlamaMobile.initialize();
```

### 加载模型

```javascript
// 从设备文件系统加载模型
const modelPath = '/path/to/your/model.gguf';

const params = {
  n_threads: 4,
  n_gpu_layers: 1,
  n_ctx: 2048
};

try {
  await LlamaMobile.loadModel(modelPath, params);
  console.log('模型加载成功');
} catch (error) {
  console.error('加载模型错误:', error);
}
```

### 生成文本

```javascript
const prompt = '从前有座山';
const generateParams = {
  temperature: 0.7,
  top_p: 0.9,
  max_tokens: 100
};

try {
  const result = await LlamaMobile.generateText(prompt, generateParams);
  console.log('生成的文本:', result.text);
} catch (error) {
  console.error('生成文本错误:', error);
}
```

### 流式生成文本

```javascript
const prompt = '给我讲个故事';
const generateParams = {
  temperature: 0.7,
  max_tokens: 500
};

try {
  await LlamaMobile.generateTextStream(
    prompt, 
    generateParams,
    (token) => {
      // 处理每个生成的token
      console.log('Token:', token);
    },
    (error) => {
      // 处理任何错误
      console.error('流错误:', error);
    },
    () => {
      // 流完成
      console.log('流完成');
    }
  );
} catch (error) {
  console.error('启动流错误:', error);
}
```

### 卸载模型

```javascript
try {
  await LlamaMobile.unloadModel();
  console.log('模型卸载成功');
} catch (error) {
  console.error('卸载模型错误:', error);
}
```

## API参考

### 常量

#### `VERSION`

SDK的当前版本。

```javascript
console.log('SDK版本:', LlamaMobile.VERSION);
```

### 方法

#### `initialize()`

初始化llama_mobile SDK。

- 返回值: `Promise<void>`

#### `loadModel(modelPath, params)`

使用给定参数从指定路径加载模型。

- **参数:**
  - `modelPath`: `string` - 模型文件路径（GGUF格式）
  - `params`: `object` - 模型加载参数
    - `n_threads`: `number` (可选) - 使用的CPU线程数（默认值: 4）
    - `n_gpu_layers`: `number` (可选) - 卸载到GPU的层数（默认值: 0）
    - `n_ctx`: `number` (可选) - 上下文窗口大小（默认值: 2048）
    - `n_batch`: `number` (可选) - 批量大小（默认值: 512）

- 返回值: `Promise<void>`

#### `generateText(prompt, params)`

从加载的模型生成文本。

- **参数:**
  - `prompt`: `string` - 文本生成的输入提示
  - `params`: `object` - 生成参数
    - `temperature`: `number` (可选) - 采样温度参数（默认值: 0.8）
    - `top_p`: `number` (可选) - Top-p采样参数（默认值: 0.95）
    - `max_tokens`: `number` (可选) - 生成的最大token数（默认值: 100）

- 返回值: `Promise<object>` - 生成的文本结果
  - `text`: `string` - 生成的文本

#### `generateTextStream(prompt, params, onToken, onError, onComplete)`

从加载的模型实时流式生成文本。

- **参数:**
  - `prompt`: `string` - 文本生成的输入提示
  - `params`: `object` - 生成参数（与`generateText`相同）
  - `onToken`: `function` - 每个生成token的回调
  - `onError`: `function` - 错误回调
  - `onComplete`: `function` - 生成完成时的回调

- 返回值: `Promise<void>`

#### `stopGeneration()`

停止任何正在进行的文本生成。

- 返回值: `Promise<void>`

#### `unloadModel()`

卸载当前加载的模型并释放资源。

- 返回值: `Promise<void>`

## 测试

### 运行测试

```bash
cd llama_mobile-react-native-SDK
npm install
npm run test
```

### 测试覆盖率

SDK包含所有API方法的全面Jest测试：

- 初始化
- 模型加载/卸载
- 文本生成
- 流生成
- 错误处理

## 构建说明

### 构建自包含SDK

SDK附带一个构建脚本，确保所有原生组件都正确嵌入：

```bash
cd llama_mobile-react-native-SDK
./build-react-native-sdk.sh
```

### 更新原生SDK组件

要更新嵌入的iOS和Android SDK组件：

```bash
./build-react-native-sdk.sh --update-sdks
```

这将构建中间SDK的新副本（如果可用）并将它们嵌入到React Native SDK中。

## 平台特定说明

### iOS

- 需要iOS 14或更高版本
- 使用Metal进行GPU加速
- 在SDK中嵌入`llama_mobile.xcframework`

### Android

- 需要Android 7.0（API级别24）或更高版本
- 使用Vulkan进行GPU加速（如果可用）
- 嵌入JNI库和Java类

## 故障排除

### 常见问题

1. **模型未找到**：确保模型文件路径正确且可访问
2. **内存不足**：减少`n_ctx`大小或`n_gpu_layers`参数
3. **iOS构建错误**：再次运行`pod install`并检查Xcode项目设置
4. **Android链接问题**：确保SDK在`settings.gradle`中正确链接

### 性能提示

- 增加`n_threads`以加快CPU生成速度
- 使用`n_gpu_layers`将工作卸载到GPU（仅iOS）
- 减少`n_ctx`以节省内存
- 根据设备内存调整`n_batch`

## 许可证

本SDK采用MIT许可证。

## 支持

如有问题和疑问，请参考项目的GitHub仓库。