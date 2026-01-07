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
      ),
      home: const LlamaMobileExample(),
    );
  }
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
  String _completion = '';
  
  // Model parameters
  final _modelPathController = TextEditingController(text: '/path/to/your/model.gguf');
  int _nCtx = 2048;
  int _nGpuLayers = 0;
  int _nThreads = 4;
  
  // Generation parameters
  final _promptController = TextEditingController(text: 'Hello, how are you?');
  int _maxTokens = 100;
  double _temperature = 0.8;
  int _topK = 40;
  double _topP = 0.95;
  GrammarName? _selectedGrammar;
  
  final List<GrammarName> _grammars = GrammarName.values;

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
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

  Future<void> _generate() async {
    if (!_isInitialized || _isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _status = 'Generating...';
      _completion = '';
    });
    
    try {
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
      
      final result = await _llamaSdk.generate(params);
      
      setState(() {
        _completion = result;
        _status = 'Generated successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
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
        _completion = '';
      });
    } catch (e) {
      setState(() {
        _status = 'Error releasing resources: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Llama Mobile Flutter SDK Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Text(
              _status,
              style: TextStyle(
                color: _isInitialized ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),

            // Model Configuration Section
            const Text(
              'Model Configuration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GPU Layers'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Threads'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '4',
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
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isInitialized ? null : _initialize,
                  child: const Text('Initialize'),
                ),
                ElevatedButton(
                  onPressed: _isInitialized && !_isGenerating ? _generate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isGenerating ? const CircularProgressIndicator() : const Text('Generate'),
                ),
                ElevatedButton(
                  onPressed: _isInitialized ? _release : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Release'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Generation Parameters Section
            const Text(
              'Generation Parameters',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            
            // Prompt input
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                border: OutlineInputBorder(),
                hintText: 'Enter your prompt here',
              ),
              maxLines: 3,
              enabled: _isInitialized && !_isGenerating,
            ),
            const SizedBox(height: 16),
            
            // Generation parameters grid
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
                          hintText: '100',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxTokens = int.tryParse(value) ?? 100;
                        },
                        controller: TextEditingController(text: _maxTokens.toString()),
                        enabled: _isInitialized && !_isGenerating,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Temperature'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0.8',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _temperature = double.tryParse(value) ?? 0.8;
                        },
                        controller: TextEditingController(text: _temperature.toString()),
                        enabled: _isInitialized && !_isGenerating,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top K'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '40',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _topK = int.tryParse(value) ?? 40;
                        },
                        controller: TextEditingController(text: _topK.toString()),
                        enabled: _isInitialized && !_isGenerating,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top P'),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0.95',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _topP = double.tryParse(value) ?? 0.95;
                        },
                        controller: TextEditingController(text: _topP.toString()),
                        enabled: _isInitialized && !_isGenerating,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Grammar selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grammar (optional)'),
                DropdownButtonFormField<GrammarName>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a grammar',
                  ),
                  value: _selectedGrammar,
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
                  enabled: _isInitialized && !_isGenerating,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Completion output
            const Text(
              'Completion:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              constraints: const BoxConstraints(minHeight: 200),
              child: Text(_completion.isEmpty ? 'No completion generated yet' : _completion),
            ),
          ],
        ),
      ),
    );
  }
}
