import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llama Mobile Flutter SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LlamaMobileExample(),
    );
  }
}

// Message model for chat interface
class Message {
  final String role;
  final String text;

  Message(this.role, this.text);

  static const String roleUser = "user";
  static const String roleAssistant = "assistant";
}

class LlamaMobileExample extends StatefulWidget {
  const LlamaMobileExample({super.key});

  @override
  State<LlamaMobileExample> createState() => _LlamaMobileExampleState();
}

// Tab index constants
enum ExampleTab { chat, tokenization, embeddings, lora, multimodal, grammar }

class _LlamaMobileExampleState extends State<LlamaMobileExample> {
  final _llamaSdk = LlamaMobileFlutterSdk();
  bool _isInitialized = false;
  bool _isGenerating = false;
  String _status = 'Ready';

  // Model parameters
  final _modelPathController = TextEditingController(
    text: '/path/to/your/model.gguf',
  );
  int _nCtx = 2048;
  int _nGpuLayers = 0;
  int _nThreads = 4;

  // Generation parameters
  final _promptController = TextEditingController();
  int _maxTokens = 1024;
  double _temperature = 0.7;
  int _topK = 40;
  double _topP = 0.95;
  GrammarName? _selectedGrammar;

  // Tokenization parameters
  final _tokenizeTextController = TextEditingController(text: 'Hello world');
  List<int> _tokens = [];
  String _detokenizeResult = '';

  // Embeddings parameters
  final _embedTextController = TextEditingController(
    text: 'This is a test sentence',
  );
  List<double> _embeddings = [];

  // LoRA parameters
  final _loraPathController = TextEditingController(
    text: '/path/to/your/lora.adapter',
  );
  double _loraScale = 1.0;
  bool _loraApplied = false;

  // Multimodal parameters
  final _mmprojPathController = TextEditingController(
    text: '/path/to/your/mmproj.gguf',
  );
  bool _multimodalEnabled = false;
  final _imagePathController = TextEditingController(
    text: '/path/to/your/image.jpg',
  );

  // Grammar parameters
  final _grammarNameController = TextEditingController(text: 'json');
  String _grammarContent = '';

  final List<GrammarName> _grammars = GrammarName.values;
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
    _tokenizeTextController.dispose();
    _embedTextController.dispose();
    _loraPathController.dispose();
    _mmprojPathController.dispose();
    _imagePathController.dispose();
    _grammarNameController.dispose();
    _scrollController.dispose();
    _release();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    setState(() {
      _status = 'Initializing...';
    });

    try {
      final params = InitParams(
        modelPath: _modelPathController.text,
        nCtx: _nCtx,
        nGpuLayers: _nGpuLayers,
        nThreads: _nThreads,
        nBatch: 512,
        nUbatch: 512,
        useMmap: true,
        useMlock: false,
        embedding: false,
      );

      final success = await _llamaSdk.initialize(params);

      setState(() {
        _isInitialized = success;
        _status = success ? 'Initialized successfully' : 'Failed to initialize';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    // Clear input field
    _promptController.clear();

    // Add user message to chat
    setState(() {
      _messages.add(Message(Message.roleUser, prompt));
      _isGenerating = true;
      _status = 'Generating response...';
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Get grammar content if selected
      String? grammarContent;
      if (_selectedGrammar != null) {
        grammarContent = await _llamaSdk.getGrammarContent(_selectedGrammar!);
      }

      final params = CompletionParams(
        prompt: prompt,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        minP: 0.05,
        typicalP: 1.0,
        seed: -1,
        nThreads: _nThreads,
        penaltyLastN: 64,
        penaltyRepeat: 1.1,
        penaltyFreq: 0.0,
        penaltyPresent: 0.0,
        mirostat: 0,
        mirostatTau: 5.0,
        mirostatEta: 0.1,
        ignoreEos: false,
        stopSequences: [],
        grammar: grammarContent,
      );

      // Add assistant message placeholder
      setState(() {
        _messages.add(Message(Message.roleAssistant, ''));
      });

      // Scroll to bottom again to show assistant message placeholder
      _scrollToBottom();

      // Generate response
      final result = await _llamaSdk.generate(params);

      setState(() {
        // Update the last message with the generated result
        _messages[_messages.length - 1] = Message(
          Message.roleAssistant,
          result,
        );
        _status = 'Generated successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating: $e';
        // Remove the empty assistant message if there was an error
        if (_messages.isNotEmpty &&
            _messages.last.role == Message.roleAssistant &&
            _messages.last.text.isEmpty) {
          _messages.removeLast();
        }
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });

      // Scroll to bottom to show the final message
      _scrollToBottom();
    }
  }

  Future<void> _release() async {
    if (!_isInitialized) return;

    setState(() {
      _status = 'Releasing resources...';
    });

    try {
      await _llamaSdk.release();

      setState(() {
        _isInitialized = false;
        _status = 'Resources released successfully';
        _messages.clear();
      });
    } catch (e) {
      setState(() {
        _status = 'Error releasing resources: $e';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModelNotLoadedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please load a model first'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Tokenization APIs
  Future<void> _handleTokenize() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Tokenizing text...';
    });

    try {
      final tokens = await _llamaSdk.tokenize(_tokenizeTextController.text);
      setState(() {
        _tokens = tokens;
        _status = 'Tokenization successful';
      });
    } catch (e) {
      setState(() {
        _status = 'Error tokenizing text: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _handleDetokenize() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    if (_tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tokens to detokenize'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Detokenizing tokens...';
    });

    try {
      final text = await _llamaSdk.detokenize(_tokens);
      setState(() {
        _detokenizeResult = text;
        _status = 'Detokenization successful';
      });
    } catch (e) {
      setState(() {
        _status = 'Error detokenizing tokens: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Embeddings API
  Future<void> _handleGenerateEmbeddings() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Generating embeddings...';
    });

    try {
      final embeddings = await _llamaSdk.generateEmbeddingsForPrompt(
        _embedTextController.text,
      );
      setState(() {
        _embeddings = embeddings;
        _status = 'Embeddings generation successful';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating embeddings: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // LoRA adapters APIs
  Future<void> _handleApplyLora() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Applying LoRA adapter...';
    });

    try {
      final loraAdapters = [
        LoraAdapter(path: _loraPathController.text, scale: _loraScale),
      ];
      final success = await _llamaSdk.applyLoraAdapters(loraAdapters);
      setState(() {
        _loraApplied = success;
        _status = success
            ? 'LoRA adapter applied successfully'
            : 'Failed to apply LoRA adapter';
      });
    } catch (e) {
      setState(() {
        _status = 'Error applying LoRA adapter: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // LoRA adapters can be removed by re-initializing the model

  // Multimodal APIs
  Future<void> _handleInitMultimodal() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Initializing multimodal...';
    });

    try {
      // Note: The Flutter SDK's initMultimodal doesn't accept parameters
      final success = await _llamaSdk.initMultimodal();
      setState(() {
        _multimodalEnabled = success;
        _status = success
            ? 'Multimodal initialized successfully'
            : 'Failed to initialize multimodal';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing multimodal: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Multimodal resources are released when the model is released

  Future<void> _handleMultimodalCompletion() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    if (!_multimodalEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multimodal support not enabled'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Generating multimodal response...';
    });

    try {
      final params = CompletionParams(
        prompt: _promptController.text,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        minP: 0.05,
        typicalP: 1.0,
        seed: -1,
        nThreads: _nThreads,
        penaltyLastN: 64,
        penaltyRepeat: 1.1,
        penaltyFreq: 0.0,
        penaltyPresent: 0.0,
        mirostat: 0,
        mirostatTau: 5.0,
        mirostatEta: 0.1,
        ignoreEos: false,
        stopSequences: [],
      );

      // Note: Multimodal completion is handled differently in the Flutter SDK
      final result = await _llamaSdk.generate(params);
      setState(() {
        _promptController.text = '';
        _messages.add(Message(Message.roleUser, _promptController.text));
        _messages.add(Message(Message.roleAssistant, result));
        _status = 'Multimodal completion successful';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating multimodal response: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Grammar API
  Future<void> _handleGetGrammarContent() async {
    if (!_isInitialized) {
      _showModelNotLoadedSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Getting grammar content...';
    });

    try {
      // Convert string to GrammarName enum
      final grammarName = GrammarName.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            _grammarNameController.text.toLowerCase(),
        orElse: () => GrammarName.json, // Default to json if not found
      );

      final content = await _llamaSdk.getGrammarContent(grammarName);
      setState(() {
        _grammarContent = content ?? '';
        _status = 'Grammar content retrieved successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting grammar content: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == Message.roleUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: isUser ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelNotLoadedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Model Not Loaded',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please configure and load a model to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _initialize,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Load Model'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),

        // Status indicator
        if (_isGenerating)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: const CircularProgressIndicator(),
                ),
                const SizedBox(width: 8),
                Text(_status),
              ],
            ),
          ),

        // Input area
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grammar selection (optional)
              if (_grammars.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('Grammar:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<GrammarName>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue: _selectedGrammar,
                          hint: const Text('Select grammar'),
                          items: _grammars.map((grammar) {
                            return DropdownMenuItem<GrammarName>(
                              value: grammar,
                              child: Text(grammar.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: _isGenerating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedGrammar = value;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                ),

              // Message input and send button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Type your message...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      minLines: 1,
                      enabled: !_isGenerating,
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ExampleTab.values.length,
      initialIndex: ExampleTab.chat.index,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Llama Mobile Flutter SDK Example'),
          actions: [
            IconButton(
              onPressed: () {
                // Show model configuration dialog
                showDialog(
                  context: context,
                  builder: (context) => _buildModelConfigDialog(),
                );
              },
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: ExampleTab.values.map((tab) {
              String tabName;
              IconData tabIcon;

              switch (tab) {
                case ExampleTab.chat:
                  tabName = 'Chat';
                  tabIcon = Icons.chat_bubble_outline;
                  break;
                case ExampleTab.tokenization:
                  tabName = 'Tokenization';
                  tabIcon = Icons.text_fields;
                  break;
                case ExampleTab.embeddings:
                  tabName = 'Embeddings';
                  tabIcon = Icons.analytics;
                  break;
                case ExampleTab.lora:
                  tabName = 'LoRA';
                  tabIcon = Icons.adjust;
                  break;
                case ExampleTab.multimodal:
                  tabName = 'Multimodal';
                  tabIcon = Icons.image;
                  break;
                case ExampleTab.grammar:
                  tabName = 'Grammar';
                  tabIcon = Icons.code;
                  break;
              }

              return Tab(icon: Icon(tabIcon), text: tabName);
            }).toList(),
          ),
        ),
        body: _isInitialized ? _buildTabContent() : _buildModelNotLoadedUI(),
      ),
    );
  }

  // Tab content selector
  Widget _buildTabContent() {
    return TabBarView(
      children: ExampleTab.values.map((tab) {
        switch (tab) {
          case ExampleTab.chat:
            return _buildChatUI();
          case ExampleTab.tokenization:
            return _buildTokenizationTab();
          case ExampleTab.embeddings:
            return _buildEmbeddingsTab();
          case ExampleTab.lora:
            return _buildLoraTab();
          case ExampleTab.multimodal:
            return _buildMultimodalTab();
          case ExampleTab.grammar:
            return _buildGrammarTab();
        }
      }).toList(),
    );
  }

  // Tokenization Tab UI
  Widget _buildTokenizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tokenization API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenizeTextController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Text to Tokenize',
              hintText: 'Enter text to tokenize...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGenerating ? null : _handleTokenize,
            child: const Text('Tokenize'),
          ),
          const SizedBox(height: 24),
          if (_tokens.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generated Tokens:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _tokens.take(20).join(', '),
                      style: const TextStyle(fontFamily: 'Monospace'),
                    ),
                  ),
                ),
                if (_tokens.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${_tokens.length - 20} more tokens',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _handleDetokenize,
                  child: const Text('Detokenize'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          if (_detokenizeResult.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detokenized Text:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_detokenizeResult),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Embeddings Tab UI
  Widget _buildEmbeddingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Embeddings API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _embedTextController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Text to Embed',
              hintText: 'Enter text to generate embeddings...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGenerating ? null : _handleGenerateEmbeddings,
            child: const Text('Generate Embeddings'),
          ),
          const SizedBox(height: 24),
          if (_embeddings.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Embeddings (Dimension: ${_embeddings.length}):',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _embeddings
                          .take(10)
                          .map((e) => e.toStringAsFixed(4))
                          .join(', '),
                      style: const TextStyle(fontFamily: 'Monospace'),
                    ),
                  ),
                ),
                if (_embeddings.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${_embeddings.length - 10} more values',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'First 5 values in detail:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _embeddings
                        .take(5)
                        .map((e) => Text(e.toStringAsFixed(6)))
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // LoRA Tab UI
  Widget _buildLoraTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LoRA Adapters API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loraPathController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'LoRA Adapter Path',
              hintText: 'Enter path to LoRA adapter...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: _loraScale.toString()),
            onChanged: (value) {
              _loraScale = double.tryParse(value) ?? 1.0;
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'LoRA Scale',
              hintText: '1.0',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _handleApplyLora,
                  child: const Text('Apply LoRA'),
                ),
              ),
              const SizedBox(width: 16),
              // Note: LoRA adapters can be removed by re-initializing the model
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'LoRA Applied: ${_loraApplied ? '✅' : '❌'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _loraApplied ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Multimodal Tab UI
  Widget _buildMultimodalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Multimodal API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mmprojPathController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'MMProj Path',
              hintText: 'Enter path to mmproj file...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _handleInitMultimodal,
                  child: const Text('Enable Multimodal'),
                ),
              ),
              const SizedBox(width: 16),
              // Note: Multimodal resources are released when the model is released
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Multimodal Enabled: ${_multimodalEnabled ? '✅' : '❌'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _multimodalEnabled ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          if (_multimodalEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multimodal Completion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _imagePathController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Image Path',
                    hintText: 'Enter path to image...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Prompt',
                    hintText: 'Enter your prompt...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _handleMultimodalCompletion,
                  child: const Text('Generate Multimodal Response'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Grammar Tab UI
  Widget _buildGrammarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grammar API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _grammarNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Grammar Name',
              hintText: 'Enter grammar name (e.g., json, list)...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGenerating ? null : _handleGetGrammarContent,
            child: const Text('Get Grammar Content'),
          ),
          const SizedBox(height: 24),
          if (_grammarContent.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grammar Content:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      _grammarContent,
                      style: const TextStyle(fontFamily: 'Monospace'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildModelConfigDialog() {
    return AlertDialog(
      title: const Text('Model Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model path input
            TextField(
              controller: _modelPathController,
              decoration: const InputDecoration(
                labelText: 'Model Path',
                border: OutlineInputBorder(),
                hintText: 'Enter path to GGUF model file',
              ),
              readOnly: _isInitialized,
            ),
            const SizedBox(height: 16),

            // Model parameters grid
            const Text('Model Parameters'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Context Size'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '2048',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _nCtx = int.tryParse(value) ?? 2048;
                        },
                        controller: TextEditingController(
                          text: _nCtx.toString(),
                        ),
                        readOnly: _isInitialized,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GPU Layers'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _nGpuLayers = int.tryParse(value) ?? 0;
                        },
                        controller: TextEditingController(
                          text: _nGpuLayers.toString(),
                        ),
                        readOnly: _isInitialized,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Threads'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '4',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _nThreads = int.tryParse(value) ?? 4;
                        },
                        controller: TextEditingController(
                          text: _nThreads.toString(),
                        ),
                        readOnly: _isInitialized,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Generation parameters
            const Text('Generation Parameters'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max Tokens'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '1024',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxTokens = int.tryParse(value) ?? 1024;
                        },
                        controller: TextEditingController(
                          text: _maxTokens.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Temperature'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0.7',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _temperature = double.tryParse(value) ?? 0.7;
                        },
                        controller: TextEditingController(
                          text: _temperature.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top K'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '40',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _topK = int.tryParse(value) ?? 40;
                        },
                        controller: TextEditingController(
                          text: _topK.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top P'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0.95',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _topP = double.tryParse(value) ?? 0.95;
                        },
                        controller: TextEditingController(
                          text: _topP.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_isInitialized)
          TextButton(
            onPressed: _release,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Release Model'),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        if (!_isInitialized)
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initialize();
            },
            child: const Text('Load Model'),
          ),
      ],
    );
  }
}
