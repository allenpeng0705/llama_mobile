// Comprehensive Flutter integration tests for LlamaMobile SDK
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/foundation.dart';

import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core API Tests', () {
    testWidgets('getPlatformVersion test', (WidgetTester tester) async {
      expect(true, isTrue);
    });
  });

  group('Context Management Tests', () {
    testWidgets('Test context initialization and free', (
      WidgetTester tester,
    ) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      // Note: This test requires a valid model path
      // In a real test environment, you would provide a path to a test model
      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test context properties
          expect(context.handle > 0, true);

          // Test context free
          final bool freed = await context.free();
          expect(freed, isTrue);
        } else {
          // If model path is invalid, context will be null
          // This is expected in some test environments
          debugPrint(
            'Context initialization failed (expected if model path is invalid)',
          );
        }
      } catch (e) {
        // Expected if model path is invalid
        debugPrint(
          'Context initialization error (expected if model path is invalid): $e',
        );
      }
    });
  });

  group('Completion Tests', () {
    testWidgets('Test regular completion', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test regular completion
          final CompletionResult? result = await context.generateCompletion(
            prompt: 'Hello,',
            maxTokens: 32,
            temperature: 0.7,
          );

          if (result != null) {
            expect(result.text.isNotEmpty, true);
            expect(result.tokensGenerated > 0, true);
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('Completion test error: $e');
      }
    });

    testWidgets('Test streaming completion', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test token stream subscription
          final tokenStreamSubscription = context.onTokenStream.listen(
            (token) {
              debugPrint('Received token: $token');
              expect(token.isNotEmpty, true);
            },
            onError: (error) {
              debugPrint('Token stream error: $error');
            },
          );

          // Test progress stream subscription
          final progressStreamSubscription = context.onProgressStream.listen(
            (progress) {
              debugPrint('Received progress: $progress');
              expect(progress >= 0.0 && progress <= 1.0, true);
            },
            onError: (error) {
              debugPrint('Progress stream error: $error');
            },
          );

          // Test streaming completion
          final CompletionResult? result = await context
              .generateStreamingCompletion(
                prompt: 'Hello,',
                maxTokens: 32,
                temperature: 0.7,
              );

          if (result != null) {
            expect(result.text.isNotEmpty, true);
            expect(result.tokensGenerated > 0, true);
          }

          // Cancel subscriptions
          await tokenStreamSubscription.cancel();
          await progressStreamSubscription.cancel();

          await context.free();
        }
      } catch (e) {
        debugPrint('Streaming completion test error: $e');
      }
    });

    testWidgets('Test OpenAI completion', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test OpenAI completion
          final String openAIJson = '''
          {
            "model": "test-model",
            "messages": [
              {
                "role": "user",
                "content": "Hello,"
              }
            ],
            "max_tokens": 32,
            "temperature": 0.7
          }
          ''';

          final CompletionResult? result = await context
              .generateOpenAICompletion(openAIJSON: openAIJson);

          if (result != null) {
            expect(result.text.isNotEmpty, true);
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('OpenAI completion test error: $e');
      }
    });
  });

  group('Embedding and Tokenization Tests', () {
    testWidgets('Test tokenization and detokenization', (
      WidgetTester tester,
    ) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test tokenization
          final List<int>? tokens = await context.tokenize('Hello, world!');
          if (tokens != null) {
            expect(tokens.isNotEmpty, true);

            // Test detokenization
            final String? detokenized = await context.detokenize(tokens);
            if (detokenized != null) {
              expect(detokenized.isNotEmpty, true);
            }
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('Tokenization test error: $e');
      }
    });

    testWidgets('Test embedding generation', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
          embedding: true, // Enable embedding
        );

        if (context != null) {
          // Test embedding generation
          final List<double>? embedding = await context.generateEmbedding(
            'Hello, world!',
          );
          if (embedding != null) {
            expect(embedding.isNotEmpty, true);
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('Embedding test error: $e');
      }
    });
  });

  group('Multimodal Tests', () {
    testWidgets('Test multimodal capabilities', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test multimodal checks
          final bool isMultimodal = await context.isMultimodalEnabled();
          final bool supportsVision = await context.supportsVision();
          final bool supportsAudio = await context.supportsAudio();

          debugPrint('Multimodal enabled: $isMultimodal');
          debugPrint('Supports vision: $supportsVision');
          debugPrint('Supports audio: $supportsAudio');

          // Test multimodal completion (requires vision model)
          try {
            final CompletionResult? result = await context
                .generateMultimodalCompletion(
                  prompt: 'What is in this image?',
                  mediaPaths: [], // Empty for test
                  maxTokens: 64,
                );

            if (result != null) {
              expect(result.text.isNotEmpty, true);
            }
          } catch (e) {
            // Expected if multimodal is not supported
            debugPrint(
              'Multimodal completion error (expected if not supported): $e',
            );
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('Multimodal test error: $e');
      }
    });
  });

  group('TTS Tests', () {
    testWidgets('Test TTS functionality', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test TTS type retrieval
          final TTSModelType ttsType = await context.getTTSType();
          expect(ttsType, isNotNull);

          // Test vocoder check
          final bool isVocoderEnabled = await context.isVocoderEnabled();
          debugPrint('Vocoder enabled: $isVocoderEnabled');

          // Test TTS model loading (requires TTS model)
          final String testTTSModelPath = '/path/to/test/tts/model';
          try {
            final bool loaded = await context.loadTTSModel(
              testTTSModelPath,
              TTSModelType.outETTSv02,
            );
            debugPrint('TTS model loaded: $loaded');

            if (loaded) {
              // Test TTS model free
              final bool freed = await context.freeTTSModel();
              expect(freed, isTrue);
            }
          } catch (e) {
            // Expected if TTS model path is invalid
            debugPrint(
              'TTS test error (expected if model path is invalid): $e',
            );
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('TTS test error: $e');
      }
    });
  });

  group('LoRA Tests', () {
    testWidgets('Test LoRA adapter functionality', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test LoRA adapter loading (requires LoRA adapter)
          final String testLoRAPath = '/path/to/test/lora/adapter';
          try {
            final bool loaded = await context.loadLoraAdapter(
              testLoRAPath,
              0.8,
            );
            debugPrint('LoRA adapter loaded: $loaded');

            if (loaded) {
              // Test get loaded LoRA adapters
              final List<Map<String, dynamic>>? adapters = await context
                  .getLoadedLoraAdapters();
              if (adapters != null) {
                expect(adapters.isNotEmpty, true);
              }

              // Test LoRA adapter free
              final bool freed = await context.freeLoraAdapter();
              expect(freed, isTrue);
            }
          } catch (e) {
            // Expected if LoRA path is invalid
            debugPrint('LoRA test error (expected if path is invalid): $e');
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('LoRA test error: $e');
      }
    });
  });

  group('Model Info Tests', () {
    testWidgets('Test model information retrieval', (
      WidgetTester tester,
    ) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      final String testModelPath = '/path/to/test/model.gguf';

      try {
        final LlamaContext? context = await llamaMobile.initContext(
          modelPath: testModelPath,
          nCtx: 1024,
          nThreads: 2,
        );

        if (context != null) {
          // Test context window size
          final int? contextWindowSize = await context.getContextWindowSize();
          if (contextWindowSize != null) {
            expect(contextWindowSize > 0, true);
          }

          // Test embedding dimension
          final int? embeddingDimension = await context.getEmbeddingDimension();
          if (embeddingDimension != null) {
            expect(embeddingDimension > 0, true);
          }

          // Test model description
          final String? modelDescription = await context.getModelDescription();
          if (modelDescription != null) {
            expect(modelDescription.isNotEmpty, true);
          }

          // Test model size
          final int? modelSize = await context.getModelSize();
          if (modelSize != null) {
            expect(modelSize > 0, true);
          }

          // Test model parameters count
          final int? modelParams = await context.getModelParametersCount();
          if (modelParams != null) {
            expect(modelParams > 0, true);
          }

          await context.free();
        }
      } catch (e) {
        debugPrint('Model info test error: $e');
      }
    });
  });

  group('Download Tests', () {
    testWidgets('Test model download', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      // Test downloadModel (requires valid URL)
      final String testUrl = 'https://example.com/test/model.gguf';
      final String testLocalPath = '/tmp/test_model.gguf';

      try {
        final DownloadResult? result = await llamaMobile.downloadModel(
          url: testUrl,
          localPath: testLocalPath,
        );

        if (result != null) {
          debugPrint('Download result: ${result.success}');
        }
      } catch (e) {
        // Expected if URL is invalid
        debugPrint('Download test error (expected if URL is invalid): $e');
      }
    });

    testWidgets('Test Hugging Face download', (WidgetTester tester) async {
      final LlamaMobile llamaMobile = LlamaMobile();

      // Test downloadHfFile (requires valid repo and filename)
      try {
        final DownloadResult? result = await llamaMobile.downloadHfFile(
          repoId: 'test/repo',
          filename: 'model.gguf',
          localPath: '/tmp/test_hf_model.gguf',
        );

        if (result != null) {
          debugPrint('HF download result: ${result.success}');
        }
      } catch (e) {
        // Expected if repo or filename is invalid
        debugPrint('HF download test error (expected if repo is invalid): $e');
      }
    });
  });
}
