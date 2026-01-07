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

  static const String ROLE_USER = "user";
  static const String ROLE_ASSISTANT = "assistant";
}

class LlamaMobileExample extends StatefulWidget {
  const LlamaMobileExample({super.key});

  @override
  State<LlamaMobileExample> createState() => _LlamaMobileExampleState();
}

class _LlamaMobileExampleState extends State<LlamaMobileExample> {
  final _llamaSdk = LlamaMobileFlutterSdk();
  bool _isInitialized = false;
  bool _isGenerating = false;
  String _status = 'Ready';
  
  // Model parameters
  final _modelPathController = TextEditingController(text: '/path/to/your/model.gguf');
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
  
  final List<GrammarName> _grammars = GrammarName.values;
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
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
      _messages.add(Message(Message.ROLE_USER, prompt));
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
        _messages.add(Message(Message.ROLE_ASSISTANT, ''));
      });
      
      // Scroll to bottom again to show assistant message placeholder
      _scrollToBottom();
      
      // Generate response
      final result = await _llamaSdk.generate(params);
      
      setState(() {
        // Update the last message with the generated result
        _messages[_messages.length - 1] = Message(Message.ROLE_ASSISTANT, result);
        _status = 'Generated successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating: $e';
        // Remove the empty assistant message if there was an error
        if (_messages.isNotEmpty && _messages.last.role == Message.ROLE_ASSISTANT && _messages.last.text.isEmpty) {
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

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == Message.ROLE_USER;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                ),
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
              Icons.brain_circle_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Model Not Loaded',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please configure and load a model to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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
                const CircularProgressIndicator(size: 16),
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
                          value: _selectedGrammar,
                          hint: const Text('Select grammar'),
                          items: _grammars.map((grammar) {
                            return DropdownMenuItem<GrammarName>(
                              value: grammar,
                              child: Text(grammar.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGrammar = value;
                            });
                          },
                          enabled: !_isGenerating,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    return Scaffold(
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
      ),
      body: _isInitialized ? _buildChatUI() : _buildModelNotLoadedUI(),
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
                        controller: TextEditingController(text: _nCtx.toString()),
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
                        controller: TextEditingController(text: _nGpuLayers.toString()),
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
                        controller: TextEditingController(text: _nThreads.toString()),
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
                        controller: TextEditingController(text: _maxTokens.toString()),
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
                        controller: TextEditingController(text: _temperature.toString()),
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
                        controller: TextEditingController(text: _topK.toString()),
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
                        controller: TextEditingController(text: _topP.toString()),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
