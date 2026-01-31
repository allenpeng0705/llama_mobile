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
      title: 'LlamaMobile Flutter SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LlamaMobile Flutter SDK'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 24),
              Text(
                'LlamaMobile Flutter SDK',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Plugin successfully loaded!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                'To use the SDK in your app:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Add llama_mobile_flutter_sdk to pubspec.yaml\n'
                '2. Import: import \'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart\';\n'
                '3. Create LlamaMobile instance\n'
                '4. Initialize context with a model\n'
                '5. Generate completions, conversations, etc.',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
