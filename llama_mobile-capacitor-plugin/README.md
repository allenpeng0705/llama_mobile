# llama_mobile-capacitor-plugin

Capacitor plugin for loading and running LLM models on mobile devices using `llama_mobile-ios-SDK` (iOS) and `llama_mobile-android-java-SDK` (Android).

## Features

- Initialize LLM models on iOS and Android devices
- Generate text completions with customizable parameters
- Support for grammar-based generation (JSON, arithmetic, etc.)
- Multimodal completion (text + images)
- Tokenization and detokenization
- Embedding generation
- LoRA adapter support
- Conversation management
- Efficient resource management
- Cross-platform compatibility

## Installation

### From NPM

```bash
npm install llama_mobile-capacitor-plugin
npx cap sync
```

### From Source

```bash
# Clone the repository
git clone <repository-url>
cd llama_mobile-capacitor-plugin

# Install dependencies
npm install

# Build the plugin
npm run build

# Link locally (optional)
npm link
cd your-capacitor-app
npm link llama_mobile-capacitor-plugin
npx cap sync
```

## Model File Bundling

To use LLM models with this plugin, you need to bundle them with your Capacitor app:

### iOS

1. Add your model file (e.g., `model.gguf`) to your Xcode project
2. Ensure the model is included in your app's target under "Build Phases" > "Copy Bundle Resources"
3. Get the model path using:

```typescript
import { Capacitor } from '@capacitor/core';

const modelPath = Capacitor.getPlatform() === 'ios' 
  ? 'model.gguf' 
  : '/assets/model.gguf';
```

### Android

1. Create a `models` folder in `src/main/assets/` directory of your Android app
2. Copy your model file (e.g., `model.gguf`) into this folder
3. Get the model path using:

```typescript
import { Capacitor } from '@capacitor/core';

const modelPath = Capacitor.getPlatform() === 'ios' 
  ? 'model.gguf' 
  : '/assets/model.gguf';
```

## API Documentation

### Initialize

Initialize the LLM context with a model file and configuration parameters.

```typescript
import { LlamaMobile, InitParams } from 'llama_mobile-capacitor-plugin';

const initParams: InitParams = {
  modelPath: '/assets/model.gguf',
  nCtx: 2048,
  nGpuLayers: 4,
  nThreads: 4,
  useMmap: true
};

try {
  const result = await LlamaMobile.initialize(initParams);
  console.log('Initialization successful:', result.success);
} catch (error) {
  console.error('Initialization failed:', error);
}
```

#### InitParams Options

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `modelPath` | string | Path to the model file | Required |
| `nCtx` | number | Context window size | 2048 |
| `nGpuLayers` | number | Number of layers to offload to GPU | 0 |
| `nThreads` | number | Number of CPU threads to use | 4 |
| `nBatch` | number | Batch size for processing | 512 |
| `nUbatch` | number | Unbatching size | 512 |
| `useMmap` | boolean | Use memory mapping for model file | true |
| `useMlock` | boolean | Lock model in memory | false |
| `chatTemplate` | string | Chat template for conversation | undefined |
| `systemPrompt` | string | System prompt for conversation | undefined |
| `embedding` | boolean | Enable embedding generation | false |
| `poolingType` | number | Pooling type for embeddings | 0 |
| `embdNormalize` | boolean | Normalize embeddings | false |
| `flashAttn` | boolean | Enable Flash Attention | false |
| `cacheTypeK` | string | Cache type for K values | undefined |
| `cacheTypeV` | string | Cache type for V values | undefined |

### Generate Completion

Generate text completions based on a prompt and completion parameters.

```typescript
import { LlamaMobile, CompletionParams } from 'llama_mobile-capacitor-plugin';

const completionParams: CompletionParams = {
  prompt: 'Hello, my name is',
  maxTokens: 100,
  temperature: 0.8,
  topK: 40,
  topP: 0.95
};

try {
  const result = await LlamaMobile.generate(completionParams);
  console.log('Completion:', result.output);
} catch (error) {
  console.error('Generation failed:', error);
}
```

#### CompletionParams Options

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `prompt` | string | Input prompt for completion | Required |
| `maxTokens` | number | Maximum tokens to generate | 100 |
| `temperature` | number | Sampling temperature | 0.8 |
| `topK` | number | Top-K sampling parameter | 40 |
| `topP` | number | Top-P sampling parameter | 0.95 |
| `minP` | number | Minimum probability parameter | 0.05 |
| `typicalP` | number | Typical probability parameter | 1.0 |
| `seed` | number | Random seed | -1 |
| `nThreads` | number | Number of CPU threads | 4 |
| `penaltyLastN` | number | Context window for repetition penalty | 64 |
| `penaltyRepeat` | number | Repetition penalty | 1.1 |
| `penaltyFreq` | number | Frequency penalty | 0.0 |
| `penaltyPresent` | number | Presence penalty | 0.0 |
| `mirostat` | number | Mirostat sampling mode | 0 |
| `mirostatTau` | number | Mirostat target entropy | 5.0 |
| `mirostatEta` | number | Mirostat learning rate | 0.1 |
| `ignoreEos` | boolean | Ignore end-of-sequence token | false |
| `stopSequences` | string[] | Stop sequences for generation | undefined |
| `grammar` | string | Grammar string for constrained generation | undefined |

### Grammar Support

Use predefined grammars for constrained text generation:

```typescript
import { LlamaMobile, GrammarName } from 'llama_mobile-capacitor-plugin';

// Get grammar content
try {
  const result = await LlamaMobile.getGrammarContent({ grammarName: GrammarName.json });
  const jsonGrammar = result.content;
  
  // Use grammar in completion
  const completionParams = {
    prompt: 'Generate a JSON object with name and age:',
    maxTokens: 100,
    grammar: jsonGrammar
  };
  
  const completion = await LlamaMobile.generate(completionParams);
  console.log('JSON completion:', completion.output);
} catch (error) {
  console.error('Grammar error:', error);
}
```

#### Available Grammars

- `arithmetic` - Mathematical expressions
- `c` - C programming language
- `chess` - Chess notation
- `english` - English language
- `japanese` - Japanese language
- `json` - JSON format
- `jsonArr` - JSON array format
- `list` - List format

### Multimodal Completion

Generate text completions with both text and image inputs:

```typescript
import { LlamaMobile, CompletionParams } from 'llama_mobile-capacitor-plugin';

const completionParams: CompletionParams = {
  prompt: 'Describe this image:',
  maxTokens: 200,
  temperature: 0.8
};

// Array of image paths (local file URIs)
const mediaPaths = ['/path/to/image1.jpg', '/path/to/image2.jpg'];

try {
  const result = await LlamaMobile.multimodalCompletion(completionParams, mediaPaths);
  console.log('Multimodal completion:', result.output);
} catch (error) {
  console.error('Multimodal generation failed:', error);
}
```

### Tokenization and Detokenization

Convert text to tokens and vice versa:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

// Tokenize text
const text = 'Hello, world!';
try {
  const tokenResult = await LlamaMobile.tokenize(text);
  console.log('Tokens:', tokenResult.tokens);
} catch (error) {
  console.error('Tokenization failed:', error);
}

// Detokenize tokens
const tokens = [1, 2, 3, 4, 5];
try {
  const detokenResult = await LlamaMobile.detokenize(tokens);
  console.log('Text:', detokenResult.text);
} catch (error) {
  console.error('Detokenization failed:', error);
}
```

### Embedding Generation

Generate text embeddings for semantic analysis:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

const text = 'Generate embeddings for this text';

try {
  const result = await LlamaMobile.generateEmbeddings(text);
  console.log('Embeddings:', result.embeddings);
  console.log('Embedding length:', result.embeddings.length);
} catch (error) {
  console.error('Embedding generation failed:', error);
}
```

### LoRA Adapter Support

Apply Low-Rank Adaptation (LoRA) adapters to fine-tune the model:

```typescript
import { LlamaMobile, LoraAdapter } from 'llama_mobile-capacitor-plugin';

// Apply LoRA adapters
const adapters: LoraAdapter[] = [
  { path: '/path/to/lora1.bin', scale: 0.8 },
  { path: '/path/to/lora2.bin', scale: 0.5 }
];

try {
  const result = await LlamaMobile.applyLoraAdapters(adapters);
  console.log('LoRA adapters applied:', result.success);
} catch (error) {
  console.error('Failed to apply LoRA adapters:', error);
}

// Remove LoRA adapters
try {
  await LlamaMobile.removeLoraAdapters();
  console.log('LoRA adapters removed');
} catch (error) {
  console.error('Failed to remove LoRA adapters:', error);
}
```

### Multimodal Initialization

Initialize multimodal support for models that support image inputs:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

// Initialize multimodal support
const mmprojPath = '/path/to/mmproj-model.bin';
const useGpu = true;

try {
  const result = await LlamaMobile.initMultimodal(mmprojPath, useGpu);
  console.log('Multimodal initialized:', result.success);
} catch (error) {
  console.error('Failed to initialize multimodal:', error);
}

// Check if multimodal is enabled
try {
  const result = await LlamaMobile.isMultimodalEnabled();
  console.log('Multimodal enabled:', result.enabled);
} catch (error) {
  console.error('Failed to check multimodal status:', error);
}

// Release multimodal resources
try {
  await LlamaMobile.releaseMultimodal();
  console.log('Multimodal resources released');
} catch (error) {
  console.error('Failed to release multimodal resources:', error);
}
```

### Conversation Management

Manage conversations with context preservation:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

// Generate a response in a conversation context
const userMessage = 'What is the capital of France?';
const maxTokens = 100;

try {
  const result = await LlamaMobile.generateResponse(userMessage, maxTokens);
  console.log('Response:', result.text);
  console.log('Tokens generated:', result.tokensGenerated);
  console.log('Time to first token:', result.timeToFirstToken);
  console.log('Total time:', result.totalTime);
} catch (error) {
  console.error('Failed to generate response:', error);
}

// Clear conversation history
try {
  await LlamaMobile.clearConversation();
  console.log('Conversation cleared');
} catch (error) {
  console.error('Failed to clear conversation:', error);
}
```

### Stop Completion

Stop an ongoing generation:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

try {
  await LlamaMobile.stopCompletion();
  console.log('Completion stopped');
} catch (error) {
  console.error('Failed to stop completion:', error);
}
```

### Release Resources

Release the LLM context and free up resources:

```typescript
import { LlamaMobile } from 'llama_mobile-capacitor-plugin';

try {
  await LlamaMobile.release();
  console.log('Resources released successfully');
} catch (error) {
  console.error('Failed to release resources:', error);
}
```

## Build Scripts

### build-capacitor.sh

Build the iOS and Android Java SDKs and update the Capacitor plugin:

```bash
# Run from the project root
./scripts/build-capacitor.sh
```

### build-capacitor-plugin.sh

Update the Capacitor plugin with the latest SDKs:

```bash
# Run from the plugin directory
./build-capacitor-plugin.sh
```

## Examples

### Basic Usage

```typescript
import { LlamaMobile, InitParams, CompletionParams } from 'llama_mobile-capacitor-plugin';
import { Capacitor } from '@capacitor/core';

// Initialize with model
const initModel = async () => {
  const modelPath = Capacitor.getPlatform() === 'ios' 
    ? 'model.gguf' 
    : '/assets/model.gguf';
  
  const initParams: InitParams = {
    modelPath,
    nCtx: 2048,
    nGpuLayers: Capacitor.getPlatform() === 'ios' ? 4 : 0,
    nThreads: 4
  };
  
  try {
    const result = await LlamaMobile.initialize(initParams);
    if (result.success) {
      console.log('Model initialized successfully');
    }
  } catch (error) {
    console.error('Initialization failed:', error);
  }
};

// Generate completion
const generateText = async (prompt: string) => {
  const completionParams: CompletionParams = {
    prompt,
    maxTokens: 200,
    temperature: 0.7,
    topP: 0.9
  };
  
  try {
    const result = await LlamaMobile.generate(completionParams);
    return result.output;
  } catch (error) {
    console.error('Generation failed:', error);
    return null;
  }
};

// Release when done
const cleanup = async () => {
  try {
    await LlamaMobile.release();
  } catch (error) {
    console.error('Cleanup failed:', error);
  }
};
```

## Troubleshooting

### iOS Issues

- Ensure the model file is properly added to your Xcode project and included in the target
- Check that the model path is correct (case-sensitive on iOS)
- For GPU-related issues, try reducing the number of `nGpuLayers`

### Android Issues

- Make sure the model file is in the correct `assets` folder structure
- Check file permissions if you're loading from external storage
- For performance issues, try adjusting `nThreads` based on your device's CPU cores

### Common Issues

- **Out of memory errors**: Try reducing `nCtx` or use a smaller model
- **Slow generation**: Increase `nThreads` or use GPU acceleration if available
- **Model not found**: Verify the model path and bundling method

## Development

### Prerequisites

- Node.js 16 or higher
- npm or yarn
- iOS: Xcode 14 or higher
- Android: Android Studio 2022 or higher, Android SDK 24 or higher

### Build Commands

```bash
# Install dependencies
npm install

# Build the plugin
npm run build

# Run linting
npm run lint

# Run type checking
npm run typecheck
```

### Testing

```bash
# Build the example app
cd example-app
npm install
npm run build

# Run on iOS
npx cap run ios

# Run on Android
npx cap run android
```

## License

[MIT](LICENSE)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

