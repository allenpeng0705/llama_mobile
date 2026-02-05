# LlamaMobile Flutter SDK - Sample Code

This document provides detailed examples of how to use the LlamaMobile Flutter SDK in your Flutter project.

## Table of Contents

- [Setup](#setup)
- [Logging](#logging)
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

First, add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: ./../llama_mobile/llama_mobile-flutter-SDK
```

Import the SDK in your Dart file:

```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
```

## Logging

Set the log level to control the verbosity of SDK output:

```dart
// Set log level to debug (most verbose)
await LlamaMobile.setLogLevel(LogLevel.debug);

// Set log level to info (default)
await LlamaMobile.setLogLevel(LogLevel.info);

// Set log level to warning
await LlamaMobile.setLogLevel(LogLevel.warning);

// Set log level to error (least verbose)
await LlamaMobile.setLogLevel(LogLevel.error);

// Disable logging entirely
await LlamaMobile.setLogLevel(LogLevel.none);

// Using raw integer value (0 = debug, 1 = info, 2 = warning, 3 = error, 4 = none)
await LlamaMobile.setLogLevelRaw(0);
```

## Model Initialization

### Synchronous Initialization

```dart
try {
  final context = await LlamaMobile.initContext(
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
  );

  if (context != null) {
    debugPrint('Context initialized successfully with handle: ${context.handle}');
  } else {
    debugPrint('Failed to initialize context');
  }
} catch (e) {
  debugPrint('Error initializing context: $e');
}
```

### Asynchronous Initialization

```dart
try {
  final context = await LlamaMobile.initContextAsync(
    modelPath: '/path/to/model.gguf',
    nCtx: 2048,
    nGpuLayers: 35,
    nThreads: 4,
  );

  if (context != null) {
    debugPrint('Context initialized asynchronously with handle: ${context.handle}');
  }
} catch (e) {
  debugPrint('Error initializing context asynchronously: $e');
}
```

### Using InitParams

```dart
try {
  final params = InitParams(
    modelPath: '/path/to/model.gguf',
    nCtx: 2048,
    nGpuLayers: 35,
    nThreads: 4,
    chatTemplate: 'chatml',      // Custom chat template
    systemPrompt: 'You are a helpful assistant.',  // System prompt
    useMmap: true,
    flashAttention: true,
  );

  final context = await LlamaMobile.initContextWithParams(params);
  if (context != null) {
    debugPrint('Context initialized with params');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Freeing Context

```dart
// Synchronous
final freed = await context.freeContext();
debugPrint('Context freed: $freed');

// Asynchronous
final freedAsync = await context.freeContextAsync();
debugPrint('Context freed asynchronously: $freedAsync');
```

## Text Completion

### Basic Text Completion

```dart
try {
  final params = CompletionParams(
    prompt: 'Once upon a time',
    maxTokens: 256,
    temperature: 0.8,          // Higher = more creative
    topP: 0.95,
    topK: 40,
    nThreads: 4,
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Generated text: ${result.text}');
    debugPrint('Tokens generated: ${result.tokensGenerated}');
    debugPrint('Time taken: ${result.timings}ms');
  }
} catch (e) {
  debugPrint('Error generating completion: $e');
}
```

### Creative Writing

```dart
try {
  final params = CompletionParams.fromCreativePrompt(
    'Write a short story about a robot learning to love',
    maxTokens: 512,
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Creative output: ${result.text}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Factual/Technical Writing

```dart
try {
  final params = CompletionParams.fromFactualPrompt(
    'Explain quantum computing in simple terms',
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Factual output: ${result.text}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Using Stop Sequences

```dart
try {
  final params = CompletionParams(
    prompt: 'List three programming languages:',
    maxTokens: 256,
    temperature: 0.7,
    stopSequences: ['\n\n', '4.', 'five'],  // Stop at these sequences
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Output: ${result.text}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Using Grammar

```dart
try {
  final params = CompletionParams(
    prompt: 'Generate a JSON object',
    maxTokens: 256,
    grammar: '''
      root ::= object
      object ::= "{" ws string ws ":" ws value "}"
      value ::= object | array | string | number | "true" | "false" | "null"
      array ::= "[" ws (value ("," ws value)*)? ws "]"
      string ::= '"' ([^"\\\\] | "\\\\" .)* '"'
      number ::= [0-9]+ ("." [0-9]+)?
      ws ::= [ \\t\\n]*
    ''',
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Grammar-constrained output: ${result.text}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

## Chat Completion

### Basic Chat

```dart
try {
  final messages = [
    ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
    ChatMessage(role: 'user', content: 'What is Flutter?'),
  ];

  final params = CompletionParams.forChat(
    messages: messages,
    maxTokens: 256,
  );

  final result = await context.generateCompletion(params);
  if (result != null) {
    debugPrint('Assistant response: ${result.text}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Multi-turn Conversation

```dart
List<ChatMessage> conversation = [
  ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
];

Future<void> chat(String userMessage) async {
  conversation.add(ChatMessage(role: 'user', content: userMessage));

  try {
    final params = CompletionParams.forChat(
      messages: conversation,
      maxTokens: 256,
      temperature: 0.7,
    );

    final result = await context.generateCompletion(params);
    if (result != null) {
      final assistantResponse = result.text;
      debugPrint('Assistant: $assistantResponse');
      conversation.add(ChatMessage(role: 'assistant', content: assistantResponse));
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}

await chat('Hello!');
await chat('Can you help me with Flutter?');
await chat('How do I use state management?');
```

### Clearing Conversation

```dart
await context.clearConversation();
debugPrint('Conversation cleared');
```

## Embedding Generation

### Generate Embedding

```dart
try {
  final params = InitParams(
    modelPath: '/path/to/embedding-model.gguf',
    embedding: true,           // Enable embedding generation
    poolingType: 1,            // 0 = none, 1 = mean, 2 = max, 3 = last token
    embdNormalize: 2,          // Normalize embeddings
  );

  final context = await LlamaMobile.initContextWithParams(params);
  if (context != null) {
    final embedding = await context.generateEmbedding(
      'Hello, world!',
      {'nThreads': 4},
    );

    if (embedding != null) {
      debugPrint('Embedding dimension: ${embedding.length}');
      debugPrint('First 5 values: ${embedding.take(5)}');
    }
  }
} catch (e) {
  debugPrint('Error generating embedding: $e');
}
```

### Asynchronous Embedding

```dart
try {
  final embedding = await context.generateEmbeddingAsync(
    'Generate embedding for this text',
    {'nThreads': 4},
  );

  if (embedding != null) {
    debugPrint('Embedding: $embedding');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

## Tokenization

### Tokenize Text

```dart
try {
  final tokens = await context.tokenize('Hello, world!');
  if (tokens != null) {
    debugPrint('Tokens: $tokens');
    debugPrint('Token count: ${tokens.length}');
  }
} catch (e) {
  debugPrint('Error tokenizing: $e');
}
```

### Detokenize Tokens

```dart
try {
  final tokens = await context.tokenize('Hello, world!');
  if (tokens != null) {
    final text = await context.detokenize(tokens);
    debugPrint('Detokenized text: $text');
  }
} catch (e) {
  debugPrint('Error detokenizing: $e');
}
```

## LoRA Adapters

### Load LoRA Adapter

```dart
try {
  final loaded = await context.loadLoraAdapter(
    '/path/to/adapter.gguf',
    scale: 1.0,              // Scale factor for adapter influence
  );
  debugPrint('LoRA adapter loaded: $loaded');
} catch (e) {
  debugPrint('Error loading LoRA adapter: $e');
}
```

### Load Multiple LoRA Adapters

```dart
try {
  await context.loadLoraAdapter('/path/to/adapter1.gguf', scale: 0.8);
  await context.loadLoraAdapter('/path/to/adapter2.gguf', scale: 0.5);
  
  final adapters = await context.getLoadedLoraAdapters();
  if (adapters != null) {
    for (final adapter in adapters) {
      debugPrint('Loaded adapter: ${adapter['adapterPath']} (scale: ${adapter['scale']})');
    }
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Free LoRA Adapter

```dart
try {
  final freed = await context.freeLoraAdapter();
  debugPrint('LoRA adapter freed: $freed');
} catch (e) {
  debugPrint('Error freeing LoRA adapter: $e');
}
```

### Remove All LoRA Adapters

```dart
await context.removeLoraAdapters();
debugPrint('All LoRA adapters removed');
```

## Text-to-Speech (TTS)

### Load TTS Model

```dart
try {
  final result = await context.loadTTSModel(
    '/path/to/tts-model.gguf',
    {
      'sampleRate': 24000,
      'nThreads': 4,
    },
  );

  if (result != null) {
    debugPrint('TTS model loaded successfully');
    debugPrint('Sample rate: ${result['sampleRate']}');
  }
} catch (e) {
  debugPrint('Error loading TTS model: $e');
}
```

### Generate Speech

```dart
try {
  final options = TTSOptions(
    sampleRate: 24000,
    speed: 1.0,
    saveToFile: true,
    outputFilePath: '/path/to/output.wav',
  );

  final result = await context.generateSpeech(
    'Hello, this is a text-to-speech test.',
    options,
  );

  if (result != null) {
    debugPrint('Speech generated successfully');
    debugPrint('Duration: ${result.duration}s');
    debugPrint('Sample rate: ${result.sampleRate}');
    debugPrint('Audio samples: ${result.audioSamples.length}');
    debugPrint('Output file: ${result.outputFilePath}');
  }
} catch (e) {
  debugPrint('Error generating speech: $e');
}
```

### Generate Speech for Long Text

```dart
try {
  final longText = 'This is a very long text that will be processed in chunks...';

  final result = await context.generateSpeechStreamForLongText(
    longText,
    TTSOptions(
      sampleRate: 24000,
      speed: 1.0,
      saveToFile: true,
      outputFilePath: '/path/to/long_output.wav',
    ),
  );

  if (result != null) {
    debugPrint('Long text speech generated');
    debugPrint('Duration: ${result.duration}s');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

### Free TTS Model

```dart
try {
  final freed = await context.freeTTSModel();
  debugPrint('TTS model freed: $freed');
} catch (e) {
  debugPrint('Error freeing TTS model: $e');
}
```

### Save Audio to WAV

```dart
try {
  final audioSamples = <int>[/* your audio samples */];
  final saved = await context.saveAudioToWav(
    '/path/to/output.wav',
    audioSamples,
    24000,  // sample rate
  );
  debugPrint('Audio saved: $saved');
} catch (e) {
  debugPrint('Error saving audio: $e');
}
```

## Multimodal Support

### Initialize Multimodal

```dart
try {
  final initialized = await context.initMultimodal(
    '/path/to/mmproj.gguf',  // Multimodal projector file
    useGpu: true,            // Use GPU for processing
  );
  debugPrint('Multimodal initialized: $initialized');
} catch (e) {
  debugPrint('Error initializing multimodal: $e');
}
```

### Generate Multimodal Completion

```dart
try {
  final params = CompletionParams(
    prompt: 'Describe this image',
    maxTokens: 256,
    mediaPaths: [
      '/path/to/image1.jpg',
      '/path/to/image2.png',
    ],
  );

  final result = await context.generateMultimodalCompletion(params);
  if (result != null) {
    debugPrint('Multimodal response: ${result.text}');
  }
} catch (e) {
  debugPrint('Error generating multimodal completion: $e');
}
```

### Check Multimodal Support

```dart
final isMultimodalEnabled = await context.isMultimodalEnabled();
final supportsVision = await context.supportsVision();
final supportsAudio = await context.supportsAudio();

debugPrint('Multimodal enabled: $isMultimodalEnabled');
debugPrint('Supports vision: $supportsVision');
debugPrint('Supports audio: $supportsAudio');
```

### Release Multimodal

```dart
await context.releaseMultimodal();
debugPrint('Multimodal released');
```

## Model Downloading

### Download from URL

```dart
try {
  final result = await LlamaMobile.downloadModel(
    url: 'https://example.com/model.gguf',
    localPath: '/path/to/save/model.gguf',
    username: 'optional_username',
    password: 'optional_password',
    headers: {'Authorization': 'Bearer token'},
  );

  if (result != null) {
    if (result.success) {
      debugPrint('Model downloaded to: ${result.localPath}');
    } else {
      debugPrint('Download failed: ${result.errorMessage}');
    }
  }
} catch (e) {
  debugPrint('Error downloading model: $e');
}
```

### Download from Hugging Face

```dart
try {
  final result = await LlamaMobile.downloadHfFile(
    repoId: 'llama-mobile/llama-3.2-3b-instruct',
    filename: 'llama-3.2-3b-instruct-q4_k_m.gguf',
    localPath: '/path/to/save/model.gguf',
    bearerToken: 'optional_token',
  );

  if (result != null) {
    if (result.success) {
      debugPrint('Model downloaded from Hugging Face: ${result.localPath}');
    } else {
      debugPrint('Download failed: ${result.errorMessage}');
    }
  }
} catch (e) {
  debugPrint('Error downloading from Hugging Face: $e');
}
```

### Asynchronous Download

```dart
try {
  final result = await LlamaMobile.downloadModelAsync(
    url: 'https://example.com/model.gguf',
    localPath: '/path/to/save/model.gguf',
  );

  if (result != null && result.success) {
    debugPrint('Model downloaded asynchronously: ${result.localPath}');
  }
} catch (e) {
  debugPrint('Error: $e');
}
```

## Streaming Completion

### Generate Streaming Completion

```dart
try {
  final params = CompletionParams(
    prompt: 'Tell me a story',
    maxTokens: 512,
  );

  final result = await context.generateStreamingCompletion(params);
  if (result != null) {
    debugPrint('Streaming result: ${result.text}');
  }
} catch (e) {
  debugPrint('Error generating streaming completion: $e');
}
```

### Listen to Token Stream

```dart
StreamSubscription<String>? tokenSubscription;

void startStreaming() {
  tokenSubscription = context.onTokenStream.listen((token) {
    debugPrint('Received token: $token');
  });
}

void stopStreaming() {
  tokenSubscription?.cancel();
}
```

### Listen to Progress Stream

```dart
StreamSubscription<double>? progressSubscription;

void startProgressMonitoring() {
  progressSubscription = context.onProgressStream.listen((progress) {
    debugPrint('Progress: ${(progress * 100).toStringAsFixed(1)}%');
  });
}

void stopProgressMonitoring() {
  progressSubscription?.cancel();
}
```

### Stop Completion

```dart
try {
  final stopped = await context.stopCompletion();
  debugPrint('Completion stopped: $stopped');
} catch (e) {
  debugPrint('Error stopping completion: $e');
}
```

## Error Handling

### Try-Catch Pattern

```dart
try {
  final context = await LlamaMobile.initContext(
    modelPath: '/path/to/model.gguf',
  );

  if (context != null) {
    final result = await context.generateCompletion(
      CompletionParams(prompt: 'Hello'),
    );

    if (result != null) {
      debugPrint('Result: ${result.text}');
    } else {
      debugPrint('No result returned');
    }
  } else {
    debugPrint('Failed to initialize context');
  }
} catch (e) {
  debugPrint('Error occurred: $e');
}
```

### Check Context Status

```dart
final isActive = await context.isConversationActive();
debugPrint('Conversation active: $isActive');
```

### Model Information

```dart
final contextSize = await context.getContextWindowSize();
final embeddingDim = await context.getEmbeddingDimension();
final description = await context.getModelDescription();
final modelSize = await context.getModelSize();
final paramCount = await context.getModelParametersCount();

debugPrint('Context window size: $contextSize');
debugPrint('Embedding dimension: $embeddingDim');
debugPrint('Model description: $description');
debugPrint('Model size: $modelSize');
debugPrint('Parameter count: $paramCount');
```

## Complete Example

Here's a complete example that demonstrates various features:

```dart
import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:flutter/foundation.dart';

class LlamaMobileExample extends StatefulWidget {
  @override
  _LlamaMobileExampleState createState() => _LlamaMobileExampleState();
}

class _LlamaMobileExampleState extends State<LlamaMobileExample> {
  LlamaContext? _context;
  List<String> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() => _isLoading = true);

    try {
      await LlamaMobile.setLogLevel(LogLevel.info);

      _context = await LlamaMobile.initContext(
        modelPath: '/path/to/model.gguf',
        nCtx: 2048,
        nGpuLayers: 35,
        nThreads: 4,
        systemPrompt: 'You are a helpful assistant.',
      );

      if (_context != null) {
        debugPrint('Model initialized successfully');
        _addMessage('System', 'Model loaded and ready!');
      }
    } catch (e) {
      debugPrint('Error initializing model: $e');
      _addMessage('Error', 'Failed to initialize model: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCompletion(String prompt) async {
    if (_context == null) {
      _addMessage('Error', 'Model not initialized');
      return;
    }

    setState(() => _isLoading = true);
    _addMessage('User', prompt);

    try {
      final params = CompletionParams(
        prompt: prompt,
        maxTokens: 256,
        temperature: 0.7,
        topP: 0.95,
      );

      final result = await _context!.generateCompletion(params);

      if (result != null) {
        _addMessage('Assistant', result.text);
      }
    } catch (e) {
      debugPrint('Error generating completion: $e');
      _addMessage('Error', 'Failed to generate response: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateEmbedding(String text) async {
    if (_context == null) {
      _addMessage('Error', 'Model not initialized');
      return;
    }

    try {
      final embedding = await _context!.generateEmbedding(
        text,
        {'nThreads': 4},
      );

      if (embedding != null) {
        _addMessage('System', 'Embedding generated: ${embedding.length} dimensions');
      }
    } catch (e) {
      debugPrint('Error generating embedding: $e');
      _addMessage('Error', 'Failed to generate embedding: $e');
    }
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add('$role: $content');
    });
  }

  @override
  void dispose() {
    _context?.freeContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LlamaMobile Example')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _generateCompletion(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Always use try-catch blocks** when calling SDK methods to handle errors gracefully.

2. **Free contexts when done** to release resources:
   ```dart
   await context.freeContext();
   ```

3. **Use async methods for long-running operations** to avoid blocking the UI thread.

4. **Set appropriate log levels** for production vs development:
   ```dart
   // Development
   await LlamaMobile.setLogLevel(LogLevel.debug);
   
   // Production
   await LlamaMobile.setLogLevel(LogLevel.error);
   ```

5. **Use GPU acceleration** when available for better performance:
   ```dart
   await LlamaMobile.initContext(
     modelPath: '/path/to/model.gguf',
     nGpuLayers: 35,  // Offload layers to GPU
   );
   ```

6. **Adjust context window size** based on your needs:
   - Small (512-1024): Quick responses, less memory
   - Medium (2048-4096): Balanced performance
   - Large (8192+): Long conversations, more memory

7. **Use appropriate temperature** for different use cases:
   - 0.1-0.3: Factual, precise answers
   - 0.5-0.7: Balanced responses
   - 0.8-1.0: Creative, diverse responses

8. **Monitor progress** for long-running operations using streams.

9. **Handle streaming responses** for better user experience with long outputs.

10. **Clean up resources** properly in dispose methods:
    ```dart
    @override
    void dispose() {
      _context?.freeContext();
      super.dispose();
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
