import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

// Main application state
class AppState extends ChangeNotifier {
  bool isModelLoaded = false;
  String modelPath = "";
  LlamaContext? llamaContext;
  List<Map<String, String>> availableModels = [];
  String? errorMessage;

  // Additional model paths for multimodal and TTS
  String mmprojModelPath = "";
  List<Map<String, String>> availableMmprojModels = [];

  String vocoderModelPath = "";
  List<Map<String, String>> availableVocoderModels = [];

  // LoRA model support
  String loraModelPath = "";
  List<Map<String, String>> availableLoRAModels = [];

  // Feature flags
  bool enableEmbedding = false;

  // Chat configuration
  String systemPrompt =
      "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone.";

  // Grammar support
  String? selectedGrammar;
  List<String> availableGrammars = [];

  // Image-related properties
  String? selectedImagePath;
  List<Map<String, String>> availablePackagedImages = [];

  // Load grammar content from assets
  Future<String?> loadGrammarContent(String grammarName) async {
    try {
      final file = File('assets/grammars/$grammarName.gbnf');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print("Error loading grammar: $e");
      return null;
    }
  }

  // Load available models
  Future<void> loadAvailableModels() async {
    List<Map<String, String>> models = [];

    // 1. Try to load models from assets/models directory
    // Note: Flutter doesn't support listing assets at runtime, but we can expect specific models
    // For this example, we'll check if common model files exist
    List<String> commonModelNames = [
      "model.gguf",
      "llama2.gguf",
      "mistral.gguf",
      "gemma.gguf",
    ];

    for (String modelName in commonModelNames) {
      String assetPath = "assets/models/$modelName";
      // In Flutter, we can't directly check if an asset exists, but we can try to load it
      // For this example, we'll assume the models are there if the file exists in the directory
      try {
        final file = File('assets/models/$modelName');
        if (await file.exists()) {
          models.add({"name": modelName, "path": file.path});
        }
      } catch (e) {
        print("Error checking model file: $e");
      }
    }

    // 2. Try to load models from documents directory (for user-added models)
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      if (await modelsDir.exists()) {
        final modelFiles = await modelsDir
            .list()
            .where((file) => file is File && file.path.endsWith('.gguf'))
            .toList();
        for (var entity in modelFiles) {
          if (entity is File) {
            String fileName = entity.path.split('/').last;
            models.add({"name": fileName, "path": entity.path});
          }
        }
      }
    } catch (e) {
      print("Error scanning documents directory: $e");
    }

    // 3. If no models found, add a sample model as fallback
    if (models.isEmpty) {
      models.add({"name": "Sample Model", "path": "assets/models/model.gguf"});
    }

    availableModels = models;

    // Set default model path if any models are found
    if (availableModels.isNotEmpty) {
      modelPath = availableModels.first["path"]!;
    }

    // Populate mmproj models (for multimodal) - show all models plus "Empty" option
    availableMmprojModels = [
      {"name": "Empty", "path": ""},
      ...availableModels,
    ];

    // Set default mmproj model path to "Empty"
    mmprojModelPath = "";

    // Populate vocoder models (for TTS) - show all models plus "Empty" option
    availableVocoderModels = [
      {"name": "Empty", "path": ""},
      ...availableModels,
    ];

    // Set default vocoder model path to "Empty"
    vocoderModelPath = "";

    // Populate LoRA models - show all models plus "Empty" option
    availableLoRAModels = [
      {"name": "Empty", "path": ""},
      ...availableModels,
    ];

    // Set default LoRA model path to "Empty"
    loraModelPath = "";

    // Load available grammar files
    availableGrammars = [
      "json",
      "json_arr",
      "list",
      "arithmetic",
      "c",
      "chess",
      "english",
      "japanese",
    ];
    // Set default grammar to null (Empty)
    selectedGrammar = null;

    // Load available packaged images
    await loadAvailablePackagedImages();
  }

  // Load available packaged images
  Future<void> loadAvailablePackagedImages() async {
    List<Map<String, String>> images = [];

    // Common image names to check for in assets/images directory
    List<String> commonImageNames = [
      "sample1.jpg",
      "sample2.jpg",
      "sample3.png",
      "sample4.png",
    ];

    for (String imageName in commonImageNames) {
      String assetPath = "assets/images/$imageName";
      try {
        final file = File('assets/images/$imageName');
        if (await file.exists()) {
          images.add({"name": imageName, "path": file.path});
        }
      } catch (e) {
        print("Error checking image file: $e");
      }
    }

    // If no images found, add a placeholder
    if (images.isEmpty) {
      images.add({
        "name": "Placeholder",
        "path": "assets/images/placeholder.png",
      });
    }

    availablePackagedImages = images;
  }

  // Load model
  Future<void> loadModel() async {
    try {
      if (modelPath.isNotEmpty) {
        // Initialize LlamaMobile using the correct method
        final llamaMobile = LlamaMobile();
        final context = await llamaMobile.initContext(
          modelPath: modelPath,
          nCtx: 2048,
          nGpuLayers: 0,
          nThreads: 4,
        );
        if (context != null) {
          llamaContext = context;
        }
        isModelLoaded = true;
        errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}

// Message model
class Message {
  final String id;
  final String role;
  final String text;

  Message({required this.role, required this.text})
    : id = DateTime.now().millisecondsSinceEpoch.toString();
}

// Message Bubble Widget
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isUser = message.role == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(0),
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

// Chat View
class ChatView extends StatefulWidget {
  final AppState appState;

  const ChatView({Key? key, required this.appState}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextEditingController _textController = TextEditingController();
  List<Message> messages = [];
  bool isLoading = false;
  bool useOpenAIJSONAPI = true;

  void sendMessage() {
    if (_textController.text.trim().isEmpty || isLoading) return;

    String messageText = _textController.text.trim();
    setState(() {
      messages.add(Message(role: "user", text: messageText));
      _textController.clear();
      isLoading = true;
    });

    // Generate response
    generateResponse(messageText);
  }

  Future<void> generateResponse(String prompt) async {
    try {
      if (widget.appState.llamaContext != null) {
        // Create chat messages
        List<Map<String, String>> chatMessages = [
          {"role": "system", "content": widget.appState.systemPrompt},
          ...messages.map((msg) => {"role": msg.role, "content": msg.text}),
        ];

        // Load grammar content if selected
        String? grammarContent;
        if (widget.appState.selectedGrammar != null) {
          grammarContent = await widget.appState.loadGrammarContent(
            widget.appState.selectedGrammar!,
          );
        }

        String response;
        if (useOpenAIJSONAPI) {
          // Use OpenAI JSON format
          final openAIRequest = {"messages": chatMessages};

          final jsonRequest = json.encode(openAIRequest);
          print("OpenAI JSON Request: $jsonRequest");

          // Generate completion with OpenAI JSON format
          final result = await widget.appState.llamaContext?.generateCompletion(
            prompt: jsonRequest,
            maxTokens: 256,
            temperature: 0.7,
            useJsonResponse: true,
            grammar: grammarContent,
          );
          response = result?.text ?? "";
        } else {
          // Use standard completion
          final result = await widget.appState.llamaContext?.generateCompletion(
            prompt: prompt,
            maxTokens: 256,
            temperature: 0.7,
            grammar: grammarContent,
          );
          response = result?.text ?? "";
        }

        setState(() {
          messages.add(Message(role: "assistant", text: response));
          isLoading = false;
        });
      } else {
        setState(() {
          widget.appState.errorMessage = "Model not loaded";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        widget.appState.errorMessage = "Error generating response: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            if (widget.appState.isModelLoaded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    const Text("Use OpenAI JSON API:"),
                    Switch(
                      value: useOpenAIJSONAPI,
                      onChanged: (value) {
                        setState(() {
                          useOpenAIJSONAPI = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),

            if (!widget.appState.isModelLoaded)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 100, color: Colors.blue),
                      const SizedBox(height: 20),
                      const Text(
                        "Model Not Loaded",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Please load a model in the Settings tab first.",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: messages[index]);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              maxLines: 5,
                              minLines: 1,
                              enabled: !isLoading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              isLoading ? Icons.hourglass_empty : Icons.send,
                              color: Colors.blue,
                            ),
                            onPressed: sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Tokenization Test View
class TokenizationTestView extends StatefulWidget {
  final AppState appState;

  const TokenizationTestView({Key? key, required this.appState})
    : super(key: key);

  @override
  _TokenizationTestViewState createState() => _TokenizationTestViewState();
}

class _TokenizationTestViewState extends State<TokenizationTestView> {
  TextEditingController _textController = TextEditingController();
  List<int> tokens = [];
  String tokenCount = "0";

  void tokenizeText() {
    if (_textController.text.isEmpty || !widget.appState.isModelLoaded) return;

    try {
      // This would be implemented using the actual tokenization method
      setState(() {
        tokens = [1, 2, 3, 4, 5]; // Sample tokens
        tokenCount = "5"; // Sample count
      });
    } catch (e) {
      widget.appState.errorMessage = "Error tokenizing text: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "Text to Tokenize",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: tokenizeText,
              child: const Text("Tokenize"),
            ),
            const SizedBox(height: 20),
            Text("Token Count: $tokenCount"),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tokens.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Token $index: ${tokens[index]}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Embedding Test View
class EmbeddingTestView extends StatefulWidget {
  final AppState appState;

  const EmbeddingTestView({Key? key, required this.appState}) : super(key: key);

  @override
  _EmbeddingTestViewState createState() => _EmbeddingTestViewState();
}

class _EmbeddingTestViewState extends State<EmbeddingTestView> {
  TextEditingController _textController = TextEditingController();
  List<double> embedding = [];
  String embeddingLength = "0";

  void generateEmbedding() {
    if (_textController.text.isEmpty || !widget.appState.isModelLoaded) return;

    try {
      // This would be implemented using the actual embedding method
      setState(() {
        embedding = [0.1, 0.2, 0.3, 0.4, 0.5]; // Sample embedding
        embeddingLength = "5"; // Sample length
      });
    } catch (e) {
      widget.appState.errorMessage = "Error generating embedding: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "Text to Embed",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateEmbedding,
              child: const Text("Generate Embedding"),
            ),
            const SizedBox(height: 20),
            Text("Embedding Length: $embeddingLength"),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: embedding.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Dimension $index: ${embedding[index]}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LoRA Test View
class LoRATestView extends StatefulWidget {
  final AppState appState;

  const LoRATestView({Key? key, required this.appState}) : super(key: key);

  @override
  _LoRATestViewState createState() => _LoRATestViewState();
}

class _LoRATestViewState extends State<LoRATestView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text(
            "LoRA Adapter Test",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Map<String, String>>(
            value: widget.appState.availableLoRAModels.isNotEmpty
                ? widget.appState.availableLoRAModels.firstWhere(
                    (model) => model["path"] == widget.appState.loraModelPath,
                    orElse: () => widget.appState.availableLoRAModels.first,
                  )
                : null,
            items: widget.appState.availableLoRAModels.map((model) {
              return DropdownMenuItem<Map<String, String>>(
                value: model,
                child: Text(model["name"]!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.appState.loraModelPath = value?["path"] ?? "";
              });
            },
            decoration: const InputDecoration(
              labelText: "LoRA Model",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // This would be implemented to load the LoRA adapter
            },
            child: const Text("Load LoRA Adapter"),
          ),
        ],
      ),
    );
  }
}

// Multimodal Test View
class MultimodalTestView extends StatefulWidget {
  final AppState appState;

  const MultimodalTestView({Key? key, required this.appState})
    : super(key: key);

  @override
  _MultimodalTestViewState createState() => _MultimodalTestViewState();
}

class _MultimodalTestViewState extends State<MultimodalTestView> {
  // Pick image from system photo library
  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.appState.selectedImagePath = pickedFile.path;
      });
    }
  }

  // Select image from packaged assets
  void selectPackagedImage(Map<String, String> image) {
    setState(() {
      widget.appState.selectedImagePath = image["path"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Multimodal Test",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Map<String, String>>(
                value: widget.appState.availableMmprojModels.isNotEmpty
                    ? widget.appState.availableMmprojModels.firstWhere(
                        (model) =>
                            model["path"] == widget.appState.mmprojModelPath,
                        orElse: () =>
                            widget.appState.availableMmprojModels.first,
                      )
                    : null,
                items: widget.appState.availableMmprojModels.map((model) {
                  return DropdownMenuItem<Map<String, String>>(
                    value: model,
                    child: Text(model["name"]!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    widget.appState.mmprojModelPath = value?["path"] ?? "";
                  });
                },
                decoration: const InputDecoration(
                  labelText: "MMProj Model",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Image selection section
              const Text(
                "Image Selection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Selected image preview
              if (widget.appState.selectedImagePath != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text("Selected Image:"),
                      const SizedBox(height: 10),
                      Image.file(
                        File(widget.appState.selectedImagePath!),
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      Text(widget.appState.selectedImagePath!.split('/').last),
                    ],
                  ),
                ),

              // Image picking options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick from Gallery"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Show packaged images dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Select Packaged Image"),
                          content: SingleChildScrollView(
                            child: Column(
                              children: widget.appState.availablePackagedImages
                                  .map((image) {
                                    return ListTile(
                                      title: Text(image["name"]!),
                                      onTap: () {
                                        selectPackagedImage(image);
                                        Navigator.pop(context);
                                      },
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.image),
                    label: const Text("Packaged Images"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  // This would be implemented to test multimodal functionality
                },
                child: const Text("Test Multimodal"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TTS Test View
class TTSTestView extends StatefulWidget {
  final AppState appState;

  const TTSTestView({Key? key, required this.appState}) : super(key: key);

  @override
  _TTSTestViewState createState() => _TTSTestViewState();
}

class _TTSTestViewState extends State<TTSTestView> {
  TextEditingController _textController = TextEditingController();
  bool isGenerating = false;

  void generateAudio() {
    if (_textController.text.isEmpty || !widget.appState.isModelLoaded) return;

    setState(() {
      isGenerating = true;
    });

    // This would be implemented using the actual TTS method
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isGenerating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: "Text to Speak",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Map<String, String>>(
            value: widget.appState.availableVocoderModels.isNotEmpty
                ? widget.appState.availableVocoderModels.firstWhere(
                    (model) =>
                        model["path"] == widget.appState.vocoderModelPath,
                    orElse: () => widget.appState.availableVocoderModels.first,
                  )
                : null,
            items: widget.appState.availableVocoderModels.map((model) {
              return DropdownMenuItem<Map<String, String>>(
                value: model,
                child: Text(model["name"]!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.appState.vocoderModelPath = value?["path"] ?? "";
              });
            },
            decoration: const InputDecoration(
              labelText: "Vocoder Model",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: generateAudio,
            child: isGenerating
                ? const CircularProgressIndicator()
                : const Text("Generate Audio"),
          ),
        ],
      ),
    );
  }
}

// Settings View
class SettingsView extends StatefulWidget {
  final AppState appState;

  const SettingsView({Key? key, required this.appState}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          children: [
            const Text(
              "Model Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Map<String, String>>(
              value: widget.appState.availableModels.isNotEmpty
                  ? widget.appState.availableModels.firstWhere(
                      (model) => model["path"] == widget.appState.modelPath,
                      orElse: () => widget.appState.availableModels.first,
                    )
                  : null,
              items: widget.appState.availableModels.map((model) {
                return DropdownMenuItem<Map<String, String>>(
                  value: model,
                  child: Text(model["name"]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.appState.modelPath = value?["path"] ?? "";
                });
              },
              decoration: const InputDecoration(
                labelText: "Model",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await widget.appState.loadModel();
              },
              child: const Text("Load Model"),
            ),
            const SizedBox(height: 40),
            const Text(
              "Grammar Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: widget.appState.selectedGrammar,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text("None"),
                ),
                ...widget.appState.availableGrammars.map((grammar) {
                  return DropdownMenuItem<String>(
                    value: grammar,
                    child: Text(grammar),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  widget.appState.selectedGrammar = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Grammar",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "System Prompt",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(
                text: widget.appState.systemPrompt,
              ),
              onChanged: (value) {
                widget.appState.systemPrompt = value;
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              maxLines: 5,
            ),
            const SizedBox(height: 40),
            const Text(
              "LoRA Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Map<String, String>>(
              value: widget.appState.availableLoRAModels.isNotEmpty
                  ? widget.appState.availableLoRAModels.firstWhere(
                      (model) => model["path"] == widget.appState.loraModelPath,
                      orElse: () => widget.appState.availableLoRAModels.first,
                    )
                  : null,
              items: widget.appState.availableLoRAModels.map((model) {
                return DropdownMenuItem<Map<String, String>>(
                  value: model,
                  child: Text(model["name"]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.appState.loraModelPath = value?["path"] ?? "";
                });
              },
              decoration: const InputDecoration(
                labelText: "LoRA Model",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This would be implemented to load the LoRA adapter
              },
              child: const Text("Load LoRA Adapter"),
            ),
            const SizedBox(height: 40),
            const Text(
              "TTS Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                labelText: "Text to Speak",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Map<String, String>>(
              value: widget.appState.availableVocoderModels.isNotEmpty
                  ? widget.appState.availableVocoderModels.firstWhere(
                      (model) =>
                          model["path"] == widget.appState.vocoderModelPath,
                      orElse: () =>
                          widget.appState.availableVocoderModels.first,
                    )
                  : null,
              items: widget.appState.availableVocoderModels.map((model) {
                return DropdownMenuItem<Map<String, String>>(
                  value: model,
                  child: Text(model["name"]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.appState.vocoderModelPath = value?["path"] ?? "";
                });
              },
              decoration: const InputDecoration(
                labelText: "Vocoder Model",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This would be implemented to generate audio
              },
              child: const Text("Generate Audio"),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState();
    // Load available models asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await appState.loadAvailableModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llama Mobile SDK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(title: const Text('Llama Mobile SDK')),
          body: TabBarView(
            children: [
              ChatView(appState: appState),
              TokenizationTestView(appState: appState),
              EmbeddingTestView(appState: appState),
              MultimodalTestView(appState: appState),
              SettingsView(appState: appState),
            ],
          ),
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble), text: 'Chat'),
              Tab(icon: Icon(Icons.numbers), text: 'Tokenize'),
              Tab(icon: Icon(Icons.text_fields), text: 'Embed'),
              Tab(icon: Icon(Icons.camera), text: 'Image'),
              Tab(icon: Icon(Icons.more_vert), text: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}
