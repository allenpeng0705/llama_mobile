import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Llama Mobile Flutter SDK Example'),
        ),
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
                              controller: TextEditingController(text: _nCtx.toString()),
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
                              controller: TextEditingController(text: _nGpuLayers.toString()),
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
                        controller: TextEditingController(text: _nThreads.toString()),
                        onChanged: (value) {
                          _nThreads = int.tryParse(value) ?? 4;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isModelLoaded ? _releaseModel : _initializeModel,
                        child: Text(_isModelLoaded ? 'Release Model' : 'Load Model'),
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
                              controller: TextEditingController(text: _maxTokens.toString()),
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
                              controller: TextEditingController(text: _temperature.toString()),
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
                              controller: TextEditingController(text: _topK.toString()),
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
                              controller: TextEditingController(text: _topP.toString()),
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
                        value: _selectedGrammar,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Grammar'),
                          ),
                          ...GrammarName.values.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGrammar = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isModelLoaded && !_isGenerating ? _generateText : null,
                        child: Text(_isGenerating ? 'Generating...' : 'Generate Text'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Result Section
              Card(
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
                      Text(_generationResult.isEmpty ? 'No result yet.' : _generationResult),
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
      
      final result = await _llamaSdk.generate(params);
      
      setState(() {
        _generationResult = result;
        _statusMessage = 'Generation completed successfully!';
      });
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
  
  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
    _releaseModel();
    super.dispose();
  }
}
