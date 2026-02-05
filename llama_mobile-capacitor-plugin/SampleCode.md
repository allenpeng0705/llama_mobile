# LlamaMobile Capacitor Plugin - Sample Code

This document provides detailed examples of how to use the LlamaMobile Capacitor Plugin in your web application.

> **Note:** The LlamaMobile Capacitor Plugin is not currently available for web platforms. All methods will throw a "LlamaMobile is not available on web" error when called in a web environment. This documentation shows the theoretical usage based on the plugin's TypeScript definitions.

## Table of Contents

- [Setup](#setup)
- [Model Initialization](#model-initialization)
- [Text Completion](#text-completion)
- [Chat Completion](#chat-completion)
- [Embedding Generation](#embedding-generation)
- [Tokenization](#tokenization)
- [LoRA Adapters](#lora-adapters)
- [Text-to-Speech (TTS)](#text-to-speech-tts)
- [Multimodal Support](#multimodal-support)
- [Model Downloading](#model-downloading)
- [Streaming Completion](#streaming-completion)
- [Error Handling](#error-handling)
- [Complete Example](#complete-example)

## Setup

First, install the plugin in your Capacitor project:

```bash
npm install @llama-mobile/capacitor-plugin
npx cap sync
```

Import the plugin in your TypeScript/JavaScript file:

```typescript
import { Plugins } from '@capacitor/core';
const { LlamaMobileCapacitorPlugin } = Plugins;

// Alternatively, for Capacitor 4+
import { LlamaMobileCapacitorPlugin } from '@llama-mobile/capacitor-plugin';
```

## Model Initialization

### Initialize Context

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.initContext({
    modelPath: '/path/to/model.gguf',
    nCtx: 2048,              // Context window size
    nGpuLayers: 35,          // Number of layers to offload to GPU (0 = CPU only)
    nThreads: 4,              // Number of CPU threads
    nBatch: 512,              // Batch size for processing
    nUBatch: 512,             // Micro-batch size
    useMmap: true,            // Use memory mapping for the model
    useMlock: false,           // Lock model memory in RAM
    embedding: false,          // Enable embedding generation
    flashAttention: false,      // Use flash attention optimization
  });

  console.log('Context initialized successfully with handle:', result.contextHandle);
  const contextHandle = result.contextHandle;
} catch (error) {
  console.error('Error initializing context:', error);
}
```

### Release Context

```typescript
try {
  await LlamaMobileCapacitorPlugin.releaseContext({
    contextHandle: contextHandle
  });
  console.log('Context released successfully');
} catch (error) {
  console.error('Error releasing context:', error);
}
```

## Text Completion

### Basic Text Completion

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Once upon a time',
      maxTokens: 256,
      temperature: 0.8,          // Higher = more creative
      topP: 0.95,
      topK: 40,
      nThreads: 4,
    }
  });

  console.log('Generated text:', result.text);
  console.log('Tokens generated:', result.tokensGenerated);
  console.log('Tokens evaluated:', result.tokensEvaluated);
} catch (error) {
  console.error('Error generating completion:', error);
}
```

### Creative Writing

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Write a short story about a robot learning to love',
      maxTokens: 512,
      temperature: 0.9,
      topP: 0.9,
    }
  });

  console.log('Creative output:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

### Factual/Technical Writing

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Explain quantum computing in simple terms',
      maxTokens: 256,
      temperature: 0.3,
      topP: 0.7,
    }
  });

  console.log('Factual output:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

### Using Stop Sequences

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'List three programming languages:',
      maxTokens: 256,
      temperature: 0.7,
      stopSequences: ['\n\n', '4.', 'five'],  // Stop at these sequences
    }
  });

  console.log('Output:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

### Using Grammar

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Generate a JSON object',
      maxTokens: 256,
      grammar: `
        root ::= object
        object ::= "{" ws string ws ":" ws value "}"
        value ::= object | array | string | number | "true" | "false" | "null"
        array ::= "[" ws (value ("," ws value)*)? ws "]"
        string ::= '"' ([^"\\] | "\\" .)* '"'
        number ::= [0-9]+ ("." [0-9]+)?
        ws ::= [ \\t\\n]*
      `,
    }
  });

  console.log('Grammar-constrained output:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

## Chat Completion

### Basic Chat

```typescript
try {
  const messages = [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'What is Capacitor?' },
  ];

  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      chatMessages: messages,
      maxTokens: 256,
    }
  });

  console.log('Assistant response:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

### Generate Response

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateResponse({
    contextHandle: contextHandle,
    userMessage: 'What is the capital of France?',
    maxTokens: 256,
  });

  console.log('Assistant response:', result.text);
} catch (error) {
  console.error('Error:', error);
}
```

### Clear Conversation

```typescript
try {
  await LlamaMobileCapacitorPlugin.clearConversation({
    contextHandle: contextHandle
  });
  console.log('Conversation cleared');
} catch (error) {
  console.error('Error:', error);
}
```

## Embedding Generation

### Generate Embedding

```typescript
try {
  // First initialize context with embedding enabled
  const contextResult = await LlamaMobileCapacitorPlugin.initContext({
    modelPath: '/path/to/embedding-model.gguf',
    embedding: true,           // Enable embedding generation
    poolingType: 1,            // 0 = none, 1 = mean, 2 = max, 3 = last token
    embdNormalize: 2,          // Normalize embeddings
  });

  const embeddingResult = await LlamaMobileCapacitorPlugin.generateEmbeddings({
    contextHandle: contextResult.contextHandle,
    text: 'Hello, world!',
  });

  console.log('Embedding dimension:', embeddingResult.embedding.length);
  console.log('First 5 values:', embeddingResult.embedding.slice(0, 5));
} catch (error) {
  console.error('Error generating embedding:', error);
}
```

## Tokenization

### Tokenize Text

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.tokenize({
    contextHandle: contextHandle,
    text: 'Hello, world!',
  });
  console.log('Tokens:', result.tokens);
  console.log('Token count:', result.tokens.length);
} catch (error) {
  console.error('Error tokenizing:', error);
}
```

### Detokenize Tokens

```typescript
try {
  const tokenizeResult = await LlamaMobileCapacitorPlugin.tokenize({
    contextHandle: contextHandle,
    text: 'Hello, world!',
  });

  const detokenizeResult = await LlamaMobileCapacitorPlugin.detokenize({
    contextHandle: contextHandle,
    tokens: tokenizeResult.tokens,
  });
  console.log('Detokenized text:', detokenizeResult.text);
} catch (error) {
  console.error('Error detokenizing:', error);
}
```

## LoRA Adapters

### Apply LoRA Adapter

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.applyLoraAdapters({
    contextHandle: contextHandle,
    adapters: [
      {
        path: '/path/to/adapter.gguf',
        scale: 1.0,              // Scale factor for adapter influence
      },
    ],
  });
  console.log('LoRA adapter applied:', result.success);
} catch (error) {
  console.error('Error applying LoRA adapter:', error);
}
```

### Apply Multiple LoRA Adapters

```typescript
try {
  await LlamaMobileCapacitorPlugin.applyLoraAdapters({
    contextHandle: contextHandle,
    adapters: [
      {
        path: '/path/to/adapter1.gguf',
        scale: 0.8,
      },
      {
        path: '/path/to/adapter2.gguf',
        scale: 0.5,
      },
    ],
  });

  const adaptersResult = await LlamaMobileCapacitorPlugin.getLoadedLoraAdapters({
    contextHandle: contextHandle,
  });
  console.log('Loaded adapters:', adaptersResult.adapters);
} catch (error) {
  console.error('Error:', error);
}
```

### Remove All LoRA Adapters

```typescript
try {
  await LlamaMobileCapacitorPlugin.removeLoraAdapters({
    contextHandle: contextHandle,
  });
  console.log('All LoRA adapters removed');
} catch (error) {
  console.error('Error:', error);
}
```

## Text-to-Speech (TTS)

### Initialize Vocoder

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.initVocoder({
    contextHandle: contextHandle,
    vocoderModelPath: '/path/to/vocoder-model.gguf',
  });
  console.log('Vocoder initialized:', result.success);
} catch (error) {
  console.error('Error initializing vocoder:', error);
}
```

### Generate Speech

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateSpeech({
    contextHandle: contextHandle,
    text: 'Hello, this is a text-to-speech test.',
    sampleRate: 24000,
    method: 'BUILT_IN',
  });

  console.log('Speech generated successfully');
  console.log('Duration:', result.duration, 'seconds');
  console.log('Sample rate:', result.sampleRate);
  console.log('Audio path:', result.audioPath);
} catch (error) {
  console.error('Error generating speech:', error);
}
```

### Generate Speech Stream

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateSpeechStream({
    contextHandle: contextHandle,
    text: 'Hello, this is a streaming text-to-speech test.',
    sampleRate: 24000,
  });

  console.log('Speech stream generated');
  console.log('Duration:', result.duration, 'seconds');
  console.log('Sample rate:', result.sampleRate);
} catch (error) {
  console.error('Error generating speech stream:', error);
}
```

### Save Audio to WAV

```typescript
try {
  // Assuming you have audio samples from generateSpeech
  const audioSamples = [/* your audio samples */];
  const result = await LlamaMobileCapacitorPlugin.saveAudioToWav({
    contextHandle: contextHandle,
    filePath: '/path/to/output.wav',
    audioData: audioSamples,
    sampleRate: 24000,
  });
  console.log('Audio saved:', result.success);
} catch (error) {
  console.error('Error saving audio:', error);
}
```

## Multimodal Support

### Initialize Multimodal

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.initMultimodal({
    contextHandle: contextHandle,
    mmprojPath: '/path/to/mmproj.gguf',  // Multimodal projector file
    useGpu: true,            // Use GPU for processing
  });
  console.log('Multimodal initialized:', result.success);
} catch (error) {
  console.error('Error initializing multimodal:', error);
}
```

### Generate Multimodal Completion

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Describe this image',
      maxTokens: 256,
      mediaPaths: [
        '/path/to/image1.jpg',
        '/path/to/image2.png',
      ],
    },
  });

  console.log('Multimodal response:', result.text);
} catch (error) {
  console.error('Error generating multimodal completion:', error);
}
```

### Check Multimodal Support

```typescript
try {
  const isEnabledResult = await LlamaMobileCapacitorPlugin.isMultimodalEnabled({
    contextHandle: contextHandle,
  });
  
  const visionResult = await LlamaMobileCapacitorPlugin.supportsVision({
    contextHandle: contextHandle,
  });
  
  const audioResult = await LlamaMobileCapacitorPlugin.supportsAudio({
    contextHandle: contextHandle,
  });

  console.log('Multimodal enabled:', isEnabledResult.enabled);
  console.log('Supports vision:', visionResult.supported);
  console.log('Supports audio:', audioResult.supported);
} catch (error) {
  console.error('Error:', error);
}
```

### Release Multimodal

```typescript
try {
  await LlamaMobileCapacitorPlugin.releaseMultimodal({
    contextHandle: contextHandle,
  });
  console.log('Multimodal released');
} catch (error) {
  console.error('Error:', error);
}
```

## Model Downloading

### Download from URL

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.downloadModel({
    url: 'https://example.com/model.gguf',
    localPath: '/path/to/save/model.gguf',
    headers: { 'Authorization': 'Bearer token' },
  });

  if (result.success) {
    console.log('Model downloaded to:', result.localPath);
  } else {
    console.log('Download failed:', result.errorMessage);
  }
} catch (error) {
  console.error('Error downloading model:', error);
}
```

### Download from Hugging Face

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.downloadHfFile({
    repoId: 'llama-mobile/llama-3.2-3b-instruct',
    filename: 'llama-3.2-3b-instruct-q4_k_m.gguf',
    destinationPath: '/path/to/save/model.gguf',
    bearerToken: 'optional_token',
  });

  if (result.success) {
    console.log('Model downloaded from Hugging Face:', result.localPath);
  } else {
    console.log('Download failed:', result.errorMessage);
  }
} catch (error) {
  console.error('Error downloading from Hugging Face:', error);
}
```

## Streaming Completion

### Set Up Listeners

```typescript
try {
  // Add token listener
  const tokenListener = await LlamaMobileCapacitorPlugin.addListener('token', (data) => {
    console.log('Received token:', data.token);
  });

  // Add progress listener
  const progressListener = await LlamaMobileCapacitorPlugin.addListener('progress', (data) => {
    console.log('Progress:', (data.progress * 100).toFixed(1) + '%');
  });

  // Generate completion with streaming
  const result = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextHandle,
    params: {
      prompt: 'Tell me a story',
      maxTokens: 512,
    },
  });

  console.log('Final result:', result.text);

  // Remove listeners when done
  await tokenListener.remove();
  await progressListener.remove();
} catch (error) {
  console.error('Error:', error);
}
```

### Stop Completion

```typescript
try {
  await LlamaMobileCapacitorPlugin.stopCompletion({
    contextHandle: contextHandle,
  });
  console.log('Completion stopped successfully');
} catch (error) {
  console.error('Error stopping completion:', error);
}
```

## Error Handling

### Try-Catch Pattern

```typescript
try {
  const contextResult = await LlamaMobileCapacitorPlugin.initContext({
    modelPath: '/path/to/model.gguf',
  });

  const completionResult = await LlamaMobileCapacitorPlugin.generateCompletion({
    contextHandle: contextResult.contextHandle,
    params: {
      prompt: 'Hello',
      maxTokens: 100,
    },
  });

  console.log('Result:', completionResult.text);
} catch (error) {
  console.error('Error occurred:', error);
}
```

### Check Conversation Status

```typescript
try {
  const result = await LlamaMobileCapacitorPlugin.isConversationActive({
    contextHandle: contextHandle,
  });
  console.log('Conversation active:', result.active);
} catch (error) {
  console.error('Error:', error);
}
```

### Model Information

```typescript
try {
  const contextSizeResult = await LlamaMobileCapacitorPlugin.getContextWindowSize({
    contextHandle: contextHandle,
  });
  
  const embeddingDimResult = await LlamaMobileCapacitorPlugin.getEmbeddingDimension({
    contextHandle: contextHandle,
  });
  
  const descriptionResult = await LlamaMobileCapacitorPlugin.getModelDescription({
    contextHandle: contextHandle,
  });
  
  const modelSizeResult = await LlamaMobileCapacitorPlugin.getModelSize({
    contextHandle: contextHandle,
  });
  
  const paramCountResult = await LlamaMobileCapacitorPlugin.getModelParametersCount({
    contextHandle: contextHandle,
  });

  console.log('Context window size:', contextSizeResult.size);
  console.log('Embedding dimension:', embeddingDimResult.dimension);
  console.log('Model description:', descriptionResult.description);
  console.log('Model size:', modelSizeResult.size);
  console.log('Parameter count:', paramCountResult.count);
} catch (error) {
  console.error('Error:', error);
}
```

## Complete Example

Here's a complete example that demonstrates various features:

```typescript
import { LlamaMobileCapacitorPlugin } from '@llama-mobile/capacitor-plugin';

class LlamaMobileExample {
  private contextHandle: number | null = null;
  private tokenListener: any = null;
  private progressListener: any = null;

  async initializeModel() {
    try {
      console.log('Initializing model...');
      
      const result = await LlamaMobileCapacitorPlugin.initContext({
        modelPath: '/path/to/model.gguf',
        nCtx: 2048,
        nGpuLayers: 35,
        nThreads: 4,
        systemPrompt: 'You are a helpful assistant.',
      });

      this.contextHandle = result.contextHandle;
      console.log('Model initialized successfully with handle:', this.contextHandle);
      
      // Set up listeners
      await this.setupListeners();
    } catch (error) {
      console.error('Error initializing model:', error);
    }
  }

  async setupListeners() {
    try {
      // Token listener
      this.tokenListener = await LlamaMobileCapacitorPlugin.addListener('token', (data) => {
        console.log('Token:', data.token);
      });

      // Progress listener
      this.progressListener = await LlamaMobileCapacitorPlugin.addListener('progress', (data) => {
        console.log('Progress:', (data.progress * 100).toFixed(1) + '%');
      });
    } catch (error) {
      console.error('Error setting up listeners:', error);
    }
  }

  async generateCompletion(prompt: string) {
    if (!this.contextHandle) {
      console.error('Model not initialized');
      return;
    }

    try {
      console.log('Generating completion for:', prompt);
      
      const result = await LlamaMobileCapacitorPlugin.generateCompletion({
        contextHandle: this.contextHandle,
        params: {
          prompt: prompt,
          maxTokens: 256,
          temperature: 0.7,
          topP: 0.95,
        },
      });

      console.log('Assistant response:', result.text);
      return result.text;
    } catch (error) {
      console.error('Error generating completion:', error);
      return null;
    }
  }

  async generateEmbedding(text: string) {
    if (!this.contextHandle) {
      console.error('Model not initialized');
      return;
    }

    try {
      const result = await LlamaMobileCapacitorPlugin.generateEmbeddings({
        contextHandle: this.contextHandle,
        text: text,
      });

      console.log('Embedding generated:', result.embedding.length, 'dimensions');
      return result.embedding;
    } catch (error) {
      console.error('Error generating embedding:', error);
      return null;
    }
  }

  async cleanup() {
    try {
      // Remove listeners
      if (this.tokenListener) {
        await this.tokenListener.remove();
      }
      if (this.progressListener) {
        await this.progressListener.remove();
      }

      // Release context
      if (this.contextHandle) {
        await LlamaMobileCapacitorPlugin.releaseContext({
          contextHandle: this.contextHandle,
        });
        console.log('Context released successfully');
      }
    } catch (error) {
      console.error('Error during cleanup:', error);
    }
  }
}

// Usage example
const example = new LlamaMobileExample();
example.initializeModel();

// Later
example.generateCompletion('What is the weather like today?');

// When done
example.cleanup();
```

## Best Practices

1. **Always use try-catch blocks** when calling plugin methods to handle errors gracefully.

2. **Release resources when done** to free up memory:
   ```typescript
   await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
   ```

3. **Set appropriate parameters** for your use case:
   - `nGpuLayers`: Adjust based on available GPU memory
   - `nThreads`: Set to match your device's CPU cores
   - `nCtx`: Balance between context window size and memory usage

4. **Handle streaming responses** for better user experience with long outputs:
   - Use token listeners to display output as it's generated
   - Use progress listeners to show processing status

5. **Clean up listeners** when they're no longer needed:
   ```typescript
   const listener = await LlamaMobileCapacitorPlugin.addListener('token', callback);
   // Later
   await listener.remove();
   ```

6. **Use appropriate temperature** for different tasks:
   - 0.1-0.3: Factual, precise answers
   - 0.5-0.7: Balanced responses
   - 0.8-1.0: Creative, diverse responses

7. **Check for web platform limitations** before calling methods:
   ```typescript
   import { Capacitor } from '@capacitor/core';
   
   if (Capacitor.getPlatform() !== 'web') {
     // Call LlamaMobile methods
   } else {
     console.log('LlamaMobile is not available on web');
   }
   ```

## Troubleshooting

### Model fails to load

- Check the model path is correct
- Ensure the model file exists
- Verify sufficient memory is available
- Try reducing `nGpuLayers` if GPU memory is limited

### Slow performance

- Increase `nGpuLayers` to use more GPU
- Adjust `nThreads` based on CPU cores
- Reduce `nCtx` if context window is too large
- Enable `flashAttention` if supported

### Out of memory errors

- Reduce `nCtx` (context window size)
- Reduce `nGpuLayers` (GPU offloading)
- Reduce `nBatch` and `nUBatch` (batch sizes)
- Use a smaller model

### Poor quality responses

- Adjust `temperature` for more/less creativity
- Adjust `topP` and `topK` for diversity control
- Use appropriate `systemPrompt`
- Try different `chatTemplate` if available

For more information, visit the [LlamaMobile GitHub repository](https://github.com/llama-mobile/llama_mobile).