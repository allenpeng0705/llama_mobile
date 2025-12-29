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
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String _status = 'Ready';
  String _completion = '';
  
  final _modelPathController = TextEditingController(text: '/path/to/your/model.gguf');
  final _promptController = TextEditingController(text: 'Hello, how are you?');

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
    _releaseModel();
    super.dispose();
  }

  Future<void> _loadModel() async {
    if (_isModelLoaded) return;
    
    setState(() {
      _status = 'Loading model...';
    });
    
    try {
      final config = ModelConfig(
        modelPath: _modelPathController.text,
        contextSize: 2048,
        useMemoryCache: true,
      );
      
      final success = await _llamaSdk.loadModel(config);
      
      setState(() {
        _isModelLoaded = success;
        _status = success ? 'Model loaded successfully' : 'Failed to load model';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading model: $e';
      });
    }
  }

  Future<void> _generateCompletion() async {
    if (!_isModelLoaded || _isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _status = 'Generating completion...';
      _completion = '';
    });
    
    try {
      final config = GenerationConfig(
        prompt: _promptController.text,
        temperature: 0.7,
        maxTokens: 200,
      );
      
      final result = await _llamaSdk.generateCompletion(config);
      
      setState(() {
        _completion = result;
        _status = 'Completion generated successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating completion: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _releaseModel() async {
    if (!_isModelLoaded) return;
    
    setState(() {
      _status = 'Releasing resources...';
    });
    
    try {
      await _llamaSdk.release();
      
      setState(() {
        _isModelLoaded = false;
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
                color: _isModelLoaded ? Colors.green : Colors.blue,
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
              readOnly: _isModelLoaded,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isModelLoaded ? null : _loadModel,
                  child: const Text('Load Model'),
                ),
                ElevatedButton(
                  onPressed: _isModelLoaded && !_isGenerating ? _generateCompletion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isGenerating ? const CircularProgressIndicator() : const Text('Generate Completion'),
                ),
                ElevatedButton(
                  onPressed: _isModelLoaded ? _releaseModel : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Release Model'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prompt input
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                border: OutlineInputBorder(),
                hintText: 'Enter your prompt here',
              ),
              maxLines: 3,
              enabled: _isModelLoaded && !_isGenerating,
            ),
            const SizedBox(height: 16),

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
