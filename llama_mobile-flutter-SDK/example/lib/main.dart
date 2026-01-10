import 'package:flutter/material.dart';
import 'dart:async';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _llamaSdk = LlamaMobileFlutterSdk();

  // Model configuration
  final TextEditingController _modelPathController = TextEditingController(
    text: '/sdcard/Download/model.gguf', // Android path example
  );
  int _nCtx = 2048;
  int _nGpuLayers = 0;
  int _nThreads = 4;

  // Generation configuration
  final TextEditingController _promptController = TextEditingController(
    text: 'Tell me a story about a cat.',
  );
  int _maxTokens = 100;
  double _temperature = 0.8;
  int _topK = 40;
  double _topP = 0.95;
  GrammarName? _selectedGrammar;

  // UI state
  bool _isModelLoaded = false;
  String _generationResult = '';
  bool _isGenerating = false;
  String _statusMessage = 'Ready';
  String _streamedResult = '';
  bool _isStreaming = false;
  String _conversationId = '';
  List<Map<String, dynamic>> _conversationHistory = [];
  bool _useDetailedResponse = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Llama Mobile Flutter SDK Example')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Model Loading Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Configuration',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _modelPathController,
                        decoration: const InputDecoration(
                          labelText: 'Model Path',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Context Size (nCtx)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _nCtx.toString(),
                              ),
                              onChanged: (value) {
                                _nCtx = int.tryParse(value) ?? 2048;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'GPU Layers (nGpuLayers)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _nGpuLayers.toString(),
                              ),
                              onChanged: (value) {
                                _nGpuLayers = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Threads (nThreads)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _nThreads.toString(),
                        ),
                        onChanged: (value) {
                          _nThreads = int.tryParse(value) ?? 4;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isModelLoaded
                            ? _releaseModel
                            : _initializeModel,
                        child: Text(
                          _isModelLoaded ? 'Release Model' : 'Load Model',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Generation Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generation Configuration',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          labelText: 'Prompt',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max Tokens',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _maxTokens.toString(),
                              ),
                              onChanged: (value) {
                                _maxTokens = int.tryParse(value) ?? 100;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Temperature',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _temperature.toString(),
                              ),
                              onChanged: (value) {
                                _temperature = double.tryParse(value) ?? 0.8;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Top K',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _topK.toString(),
                              ),
                              onChanged: (value) {
                                _topK = int.tryParse(value) ?? 40;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Top P',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _topP.toString(),
                              ),
                              onChanged: (value) {
                                _topP = double.tryParse(value) ?? 0.95;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GrammarName>(
                        decoration: const InputDecoration(
                          labelText: 'Grammar (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedGrammar,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Grammar'),
                          ),
                          ...GrammarName.values.map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGrammar = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Use Detailed Response'),
                        value: _useDetailedResponse,
                        onChanged: (value) {
                          setState(() {
                            _useDetailedResponse = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isModelLoaded &&
                                      !_isGenerating &&
                                      !_isStreaming
                                  ? _generateText
                                  : null,
                              child: Text(
                                _isGenerating
                                    ? 'Generating...'
                                    : 'Generate Text',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isModelLoaded &&
                                      !_isGenerating &&
                                      !_isStreaming
                                  ? _streamText
                                  : null,
                              icon: const Icon(Icons.stream),
                              label: Text(
                                _isStreaming ? 'Streaming...' : 'Stream Text',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((_isGenerating || _isStreaming))
                        ElevatedButton.icon(
                          onPressed: _stopGeneration,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Generation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results Section
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generation Result',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _generationResult.isEmpty
                                  ? 'No result yet.'
                                  : _generationResult,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Streaming Result',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _streamedResult.isEmpty
                                  ? 'No streamed result yet.'
                                  : _streamedResult,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conversation Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isModelLoaded && _conversationId.isEmpty
                                  ? _createConversation
                                  : null,
                              child: const Text('Create New Conversation'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isModelLoaded && _conversationId.isNotEmpty
                                  ? _clearConversation
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Clear Conversation'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_conversationId.isNotEmpty)
                        Column(
                          children: [
                            Text('Conversation ID: $_conversationId'),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  _isModelLoaded &&
                                      !_isGenerating &&
                                      !_isStreaming
                                  ? _generateConversationResponse
                                  : null,
                              icon: const Icon(Icons.chat),
                              label: const Text(
                                'Generate Conversation Response',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Conversation History:'),
                                        const SizedBox(height: 8),
                                        if (_conversationHistory.isEmpty)
                                          const Text('No history yet.')
                                        else
                                          ..._conversationHistory.map(
                                            (message) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                              child: Text(
                                                '${message['role'].toString().toUpperCase()}: ${message['content']}',
                                                style: TextStyle(
                                                  fontWeight:
                                                      message['role'] ==
                                                          'assistant'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Message
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeModel() async {
    try {
      setState(() {
        _statusMessage = 'Loading model...';
      });

      final params = InitParams(
        modelPath: _modelPathController.text,
        nCtx: _nCtx,
        nGpuLayers: _nGpuLayers,
        nThreads: _nThreads,
      );

      final success = await _llamaSdk.initialize(params);

      setState(() {
        if (success) {
          _isModelLoaded = true;
          _statusMessage = 'Model loaded successfully!';
        } else {
          _statusMessage = 'Failed to load model.';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading model: $e';
      });
    }
  }

  Future<void> _releaseModel() async {
    try {
      await _llamaSdk.release();
      setState(() {
        _isModelLoaded = false;
        _statusMessage = 'Model released successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error releasing model: $e';
      });
    }
  }

  Future<void> _generateText() async {
    try {
      setState(() {
        _isGenerating = true;
        _generationResult = '';
        _statusMessage = 'Generating text...';
      });

      // Get grammar content if selected
      String? grammarContent;
      if (_selectedGrammar != null) {
        grammarContent = await _llamaSdk.getGrammarContent(_selectedGrammar!);
      }

      final params = CompletionParams(
        prompt: _promptController.text,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        grammar: grammarContent,
        stopSequences: [],
      );

      if (_useDetailedResponse) {
        // Use the new generateResponse method for detailed results
        final result = await _llamaSdk.generateResponse(params);
        setState(() {
          _generationResult = result.text;
          _statusMessage =
              'Generation completed successfully! Generated ${result.tokensGenerated} tokens, evaluated ${result.tokensEvaluated} tokens.';
        });
      } else {
        // Use the legacy generate method
        final result = await _llamaSdk.generate(params);
        setState(() {
          _generationResult = result;
          _statusMessage = 'Generation completed successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating text: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _streamText() async {
    try {
      setState(() {
        _isStreaming = true;
        _streamedResult = '';
        _statusMessage = 'Streaming text...';
      });

      // Get grammar content if selected
      String? grammarContent;
      if (_selectedGrammar != null) {
        grammarContent = await _llamaSdk.getGrammarContent(_selectedGrammar!);
      }

      final params = CompletionParams(
        prompt: _promptController.text,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        grammar: grammarContent,
        stopSequences: [],
      );

      // Use the new streamCompletion method
      await _llamaSdk.streamCompletion(params, (token) {
        setState(() {
          _streamedResult += token;
        });
      });

      setState(() {
        _statusMessage = 'Streaming completed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error streaming text: $e';
      });
    } finally {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  Future<void> _stopGeneration() async {
    try {
      await _llamaSdk.stopCompletion();
      setState(() {
        _statusMessage = 'Generation stopped by user.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping generation: $e';
      });
    }
  }

  Future<void> _createConversation() async {
    try {
      setState(() {
        _statusMessage = 'Creating conversation...';
      });

      final params = ConversationParams(
        systemPrompt: 'You are a helpful assistant.',
        chatTemplate: 'default',
      );

      final conversationId = await _llamaSdk.createConversation(params);

      // Get initial conversation history
      final history = await _llamaSdk.getConversationHistory(conversationId);

      setState(() {
        _conversationId = conversationId;
        _conversationHistory = history;
        _statusMessage = 'Conversation created successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating conversation: $e';
      });
    }
  }

  Future<void> _generateConversationResponse() async {
    try {
      setState(() {
        _isGenerating = true;
        _statusMessage = 'Generating conversation response...';
      });

      // Get grammar content if selected
      String? grammarContent;
      if (_selectedGrammar != null) {
        grammarContent = await _llamaSdk.getGrammarContent(_selectedGrammar!);
      }

      final params = CompletionParams(
        prompt: _promptController.text,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        grammar: grammarContent,
        stopSequences: [],
      );

      // Use the new generateConversationResponse method
      final result = await _llamaSdk.generateConversationResponse(
        _conversationId,
        params,
      );

      // Update conversation history
      final history = await _llamaSdk.getConversationHistory(_conversationId);

      setState(() {
        _generationResult = result;
        _conversationHistory = history;
        _statusMessage = 'Conversation response generated successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating conversation response: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearConversation() async {
    try {
      setState(() {
        _statusMessage = 'Clearing conversation...';
      });

      await _llamaSdk.clearConversation(_conversationId);

      // Update conversation history
      final history = await _llamaSdk.getConversationHistory(_conversationId);

      setState(() {
        _conversationHistory = history;
        _statusMessage = 'Conversation cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing conversation: $e';
      });
    }
  }

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();

    // Stop any ongoing generation
    if (_isGenerating || _isStreaming) {
      _stopGeneration();
    }

    // Clear conversation if it exists
    if (_conversationId.isNotEmpty) {
      _clearConversation();
    }

    _releaseModel();
    super.dispose();
  }
}
