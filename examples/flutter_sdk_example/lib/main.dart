import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

// Main application state
class AppState extends ChangeNotifier {
  bool isModelLoaded = false;
  String modelPath = "";
  LlamaContext? llamaContext;
  LlamaMobile? llamaMobile;
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

  // Feature switches - matching iOSSDKExample
  bool useStreaming = false;
  bool useAsync = false;
  bool useJsonResponse = true;
  bool useChatMode = true;
  bool useCustomTemplate = false;

  // Model configuration parameters
  int nGpuLayers = 99;
  int nThreads = 4;
  int nCtx = 2048;

  // Chat configuration
  String systemPrompt =
      "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone.";

  // Grammar support
  String? selectedGrammar;
  List<String> availableGrammars = [];

  // Image-related properties
  String? selectedImagePath;
  List<Map<String, String>> availablePackagedImages = [];

  // Download state
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadStatus = "";
  String downloadSpeed = "";
  String downloadSize = "";
  String? downloadError;

  // Model loading state
  bool isLoading = false;

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
    print("=== Starting to load available models ===");

    // Use platform-specific model loading logic
    if (Platform.isAndroid) {
      print("Using Android-specific model loading logic");

      // 1. First priority: Scan app-specific external files directory
      // This is where the user put their files: /storage/emulated/0/Android/data/com.example.flutter_sdk_example/files/models
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          print("App-specific external storage directory: ${externalDir.path}");

          // Check direct models directory in external files dir
          final directExternalModelsDir = Directory(
            '${externalDir.path}/models',
          );
          print(
            "Direct external models directory: ${directExternalModelsDir.path}",
          );
          bool directModelsDirExists = await directExternalModelsDir.exists();
          print(
            "Direct external models directory exists: $directModelsDirExists",
          );

          if (directModelsDirExists) {
            final modelFiles = await directExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.gguf') ||
                          file.path.endsWith('.bin') ||
                          file.path.endsWith('.safetensors') ||
                          file.path.endsWith('.mmproj')),
                )
                .toList();
            print(
              "Found ${modelFiles.length} model files in direct external directory",
            );
            for (var entity in modelFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                models.add({"name": fileName, "path": entity.path});
                print("Added model: $fileName from ${entity.path}");
              }
            }
          } else {
            // Create models directory if it doesn't exist
            await directExternalModelsDir.create(recursive: true);
            print(
              "Created direct external models directory: ${directExternalModelsDir.path}",
            );
            print("Please add your model files to this directory:");
            print("${directExternalModelsDir.path}");
          }
        }
      } catch (e) {
        print("Error scanning app-specific external storage directories: $e");
      }

      // 2. Second priority: Scan documents directory for models
      try {
        final directory = await getApplicationDocumentsDirectory();
        print("App documents directory: ${directory.path}");
        final modelsDir = Directory('${directory.path}/models');
        print("Documents models directory: ${modelsDir.path}");
        bool modelsDirExists = await modelsDir.exists();
        print("Documents models directory exists: $modelsDirExists");
        if (modelsDirExists) {
          final modelFiles = await modelsDir
              .list()
              .where(
                (file) =>
                    file is File &&
                    (file.path.endsWith('.gguf') ||
                        file.path.endsWith('.bin') ||
                        file.path.endsWith('.safetensors') ||
                        file.path.endsWith('.mmproj')),
              )
              .toList();
          print(
            "Found ${modelFiles.length} model files in documents directory",
          );
          for (var entity in modelFiles) {
            if (entity is File) {
              String fileName = entity.path.split('/').last;
              models.add({"name": fileName, "path": entity.path});
              print("Added model: $fileName from ${entity.path}");
            }
          }
        } else {
          // Create models directory if it doesn't exist
          await modelsDir.create(recursive: true);
          print("Created documents models directory: ${modelsDir.path}");
          print("Please add your model files to this directory:");
          print("${modelsDir.path}");
        }
      } catch (e) {
        print("Error scanning documents directory: $e");
      }

      // Remove duplicates by file name (keep the first occurrence)
      final seenFileNames = <String>{};
      final uniqueModels = models.where((model) {
        final fileName = model["name"]!;
        if (seenFileNames.contains(fileName)) {
          return false;
        }
        seenFileNames.add(fileName);
        return true;
      }).toList();

      availableModels = uniqueModels;
    } else if (Platform.isIOS) {
      print("Using iOS-specific model loading logic");

      // 1. First priority: Scan documents directory for actual user-added models
      try {
        final directory = await getApplicationDocumentsDirectory();
        print("App documents directory: ${directory.path}");
        final modelsDir = Directory('${directory.path}/models');
        print("Models directory: ${modelsDir.path}");
        bool modelsDirExists = await modelsDir.exists();
        print("Models directory exists: $modelsDirExists");
        if (modelsDirExists) {
          final modelFiles = await modelsDir
              .list()
              .where((file) => file is File && file.path.endsWith('.gguf'))
              .toList();
          print(
            "Found ${modelFiles.length} model files in documents directory",
          );
          for (var entity in modelFiles) {
            if (entity is File) {
              String fileName = entity.path.split('/').last;
              models.add({"name": fileName, "path": entity.path});
              print("Added model: $fileName from ${entity.path}");
            }
          }
        } else {
          await modelsDir.create(recursive: true);
          print("Created models directory: ${modelsDir.path}");
          print("Please add your model files to this directory:");
          print("${modelsDir.path}");
        }
      } catch (e) {
        print("Error scanning documents directory: $e");
      }

      // 2. Second priority: Load models from assets/models directory
      // Flutter generates an AssetManifest.json file that we can parse to get all assets
      try {
        print("Checking assets/models directory");
        // Load AssetManifest.json
        String manifestContent = await rootBundle.loadString(
          'AssetManifest.json',
        );
        Map<String, dynamic> manifest = jsonDecode(manifestContent);

        // Extract all model files from assets/models
        List<String> modelAssets = manifest.keys
            .where(
              (key) =>
                  key.startsWith('assets/models/') && key.endsWith('.gguf'),
            )
            .toList();

        print("Found ${modelAssets.length} model files in assets/models");
        for (String assetPath in modelAssets) {
          String fileName = assetPath.split('/').last;
          models.add({"name": fileName, "path": assetPath});
          print("Added model: $fileName from $assetPath");
        }
      } catch (e) {
        print("Error loading AssetManifest.json: $e");
        // Fallback: Add common model files
        List<String> commonModelFiles = [
          "model.gguf",
          "Qwen3-Embedding-0.6B-Q8_0.gguf",
          "Qwen3-1.7B-Q4_K_M.gguf",
        ];

        print("Adding common model files as fallback");
        for (String modelName in commonModelFiles) {
          String assetPath = "assets/models/$modelName";
          models.add({"name": modelName, "path": assetPath});
          print("Added model: $modelName from $assetPath");
        }
      }

      // 3. If no models found, add a sample model as fallback
      print("Total models found before fallback: ${models.length}");
      if (models.isEmpty) {
        print("No models found, adding fallback model");
        models.add({
          "name": "Sample Model",
          "path": "assets/models/model.gguf",
        });
      }

      availableModels = models;
    } else {
      print("Using default model loading logic for other platforms");
      try {
        final directory = await getApplicationDocumentsDirectory();
        print("App documents directory: ${directory.path}");
        final modelsDir = Directory('${directory.path}/models');
        print("Models directory: ${modelsDir.path}");
        bool modelsDirExists = await modelsDir.exists();
        print("Models directory exists: $modelsDirExists");
        if (modelsDirExists) {
          final modelFiles = await modelsDir
              .list()
              .where((file) => file is File && file.path.endsWith('.gguf'))
              .toList();
          print(
            "Found ${modelFiles.length} model files in documents directory",
          );
          for (var entity in modelFiles) {
            if (entity is File) {
              String fileName = entity.path.split('/').last;
              models.add({"name": fileName, "path": entity.path});
              print("Added model: $fileName from ${entity.path}");
            }
          }
        } else {
          await modelsDir.create(recursive: true);
          print("Created models directory: ${modelsDir.path}");
          print("Please add your model files to this directory:");
          print("${modelsDir.path}");
        }
      } catch (e) {
        print("Error scanning documents directory: $e");
      }
      availableModels = models;
    }

    print("Final available models: $availableModels");

    // Set default model path if any models are found
    if (availableModels.isNotEmpty) {
      modelPath = availableModels.first["path"]!;
      print("Default model path set to: $modelPath");
    }

    print("=== Finished loading available models ===");

    // Populate mmproj models (for multimodal)
    List<Map<String, String>> mmprojModels = [
      {"name": "Empty", "path": ""},
    ];

    if (Platform.isAndroid) {
      // Android-specific: scan external directories for mmproj models
      try {
        final externalDir = await getExternalStorageDirectory();
        print("Android external storage directory: ${externalDir?.path}");
        if (externalDir != null) {
          // Check direct models directory
          final directExternalModelsDir = Directory(
            '${externalDir.path}/models',
          );
          print(
            "Checking direct mmproj models directory: ${directExternalModelsDir.path}",
          );
          print(
            "Direct mmproj models directory exists: ${await directExternalModelsDir.exists()}",
          );
          if (await directExternalModelsDir.exists()) {
            final mmprojFiles = await directExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.mmproj') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.bin')),
                )
                .toList();
            print(
              "Found ${mmprojFiles.length} mmproj files in direct directory",
            );
            for (var entity in mmprojFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                mmprojModels.add({"name": fileName, "path": entity.path});
                print("Added mmproj model: $fileName from ${entity.path}");
              }
            }
          }

          // Check legacy LlamaMobile/models directory
          final legacyExternalModelsDir = Directory(
            '${externalDir.path}/LlamaMobile/models',
          );
          print(
            "Checking legacy mmproj models directory: ${legacyExternalModelsDir.path}",
          );
          print(
            "Legacy mmproj models directory exists: ${await legacyExternalModelsDir.exists()}",
          );
          if (await legacyExternalModelsDir.exists()) {
            final mmprojFiles = await legacyExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.mmproj') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.bin')),
                )
                .toList();
            print(
              "Found ${mmprojFiles.length} mmproj files in legacy directory",
            );
            for (var entity in mmprojFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                mmprojModels.add({"name": fileName, "path": entity.path});
                print("Added mmproj model: $fileName from ${entity.path}");
              }
            }
          }
        }
      } catch (e) {
        print("Error scanning for mmproj models: $e");
      }
    } else if (Platform.isIOS) {
      // iOS-specific: scan documents directory for mmproj models
      try {
        final directory = await getApplicationDocumentsDirectory();
        print("iOS documents directory: ${directory.path}");
        final modelsDir = Directory('${directory.path}/models');
        print("iOS mmproj models directory: ${modelsDir.path}");
        bool modelsDirExists = await modelsDir.exists();
        print("iOS mmproj models directory exists: $modelsDirExists");
        if (modelsDirExists) {
          final mmprojFiles = await modelsDir
              .list()
              .where(
                (file) =>
                    file is File &&
                    (file.path.endsWith('.mmproj') ||
                        file.path.endsWith('.gguf') ||
                        file.path.endsWith('.bin')),
              )
              .toList();
          print(
            "Found ${mmprojFiles.length} mmproj files in iOS documents directory",
          );
          for (var entity in mmprojFiles) {
            if (entity is File) {
              String fileName = entity.path.split('/').last;
              mmprojModels.add({"name": fileName, "path": entity.path});
              print("Added iOS mmproj model: $fileName from ${entity.path}");
            }
          }
        }
      } catch (e) {
        print("Error scanning for iOS mmproj models: $e");
      }
    }

    // Always include available models (for both Android and iOS)
    print(
      "Adding ${availableModels.length} models from availableModels to mmprojModels",
    );
    mmprojModels.addAll(availableModels);

    // Remove duplicates
    final seenMmprojNames = <String>{};
    availableMmprojModels = mmprojModels.where((model) {
      final fileName = model["name"]!;
      if (seenMmprojNames.contains(fileName)) {
        return false;
      }
      seenMmprojNames.add(fileName);
      return true;
    }).toList();

    // Set default mmproj model path to "Empty"
    mmprojModelPath = "";

    // Populate vocoder models (for TTS)
    List<Map<String, String>> vocoderModels = [
      {"name": "Empty", "path": ""},
    ];

    if (Platform.isAndroid) {
      // Android-specific: scan external directories for vocoder models
      try {
        final externalDir = await getExternalStorageDirectory();
        print("Android external storage directory: ${externalDir?.path}");
        if (externalDir != null) {
          // Check direct models directory
          final directExternalModelsDir = Directory(
            '${externalDir.path}/models',
          );
          print(
            "Checking direct vocoder models directory: ${directExternalModelsDir.path}",
          );
          print(
            "Direct vocoder models directory exists: ${await directExternalModelsDir.exists()}",
          );
          if (await directExternalModelsDir.exists()) {
            final vocoderFiles = await directExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.bin') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.pth')),
                )
                .toList();
            print(
              "Found ${vocoderFiles.length} vocoder files in direct directory",
            );
            for (var entity in vocoderFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                vocoderModels.add({"name": fileName, "path": entity.path});
                print("Added vocoder model: $fileName from ${entity.path}");
              }
            }
          }

          // Check legacy LlamaMobile/models directory
          final legacyExternalModelsDir = Directory(
            '${externalDir.path}/LlamaMobile/models',
          );
          print(
            "Checking legacy vocoder models directory: ${legacyExternalModelsDir.path}",
          );
          print(
            "Legacy vocoder models directory exists: ${await legacyExternalModelsDir.exists()}",
          );
          if (await legacyExternalModelsDir.exists()) {
            final vocoderFiles = await legacyExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.bin') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.pth')),
                )
                .toList();
            print(
              "Found ${vocoderFiles.length} vocoder files in legacy directory",
            );
            for (var entity in vocoderFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                vocoderModels.add({"name": fileName, "path": entity.path});
                print("Added vocoder model: $fileName from ${entity.path}");
              }
            }
          }
        }
      } catch (e) {
        print("Error scanning for vocoder models: $e");
      }
    }

    // Always include available models (for both Android and iOS)
    print(
      "Adding ${availableModels.length} models from availableModels to vocoderModels",
    );
    vocoderModels.addAll(availableModels);

    // Remove duplicates
    final seenVocoderNames = <String>{};
    availableVocoderModels = vocoderModels.where((model) {
      final fileName = model["name"]!;
      if (seenVocoderNames.contains(fileName)) {
        return false;
      }
      seenVocoderNames.add(fileName);
      return true;
    }).toList();

    // Set default vocoder model path to "Empty"
    vocoderModelPath = "";

    // Populate LoRA models
    List<Map<String, String>> loraModels = [
      {"name": "Empty", "path": ""},
    ];

    if (Platform.isAndroid) {
      // Android-specific: scan external directories for LoRA models
      try {
        final externalDir = await getExternalStorageDirectory();
        print("Android external storage directory: ${externalDir?.path}");
        if (externalDir != null) {
          // Check direct models directory
          final directExternalModelsDir = Directory(
            '${externalDir.path}/models',
          );
          print(
            "Checking direct LoRA models directory: ${directExternalModelsDir.path}",
          );
          print(
            "Direct LoRA models directory exists: ${await directExternalModelsDir.exists()}",
          );
          if (await directExternalModelsDir.exists()) {
            final loraFiles = await directExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.bin') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.safetensors') ||
                          file.path.endsWith('.lora')),
                )
                .toList();
            print("Found ${loraFiles.length} LoRA files in direct directory");
            for (var entity in loraFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                loraModels.add({"name": fileName, "path": entity.path});
                print("Added LoRA model: $fileName from ${entity.path}");
              }
            }
          }

          // Check legacy LlamaMobile/models directory
          final legacyExternalModelsDir = Directory(
            '${externalDir.path}/LlamaMobile/models',
          );
          print(
            "Checking legacy LoRA models directory: ${legacyExternalModelsDir.path}",
          );
          print(
            "Legacy LoRA models directory exists: ${await legacyExternalModelsDir.exists()}",
          );
          if (await legacyExternalModelsDir.exists()) {
            final loraFiles = await legacyExternalModelsDir
                .list()
                .where(
                  (file) =>
                      file is File &&
                      (file.path.endsWith('.bin') ||
                          file.path.endsWith('.gguf') ||
                          file.path.endsWith('.safetensors') ||
                          file.path.endsWith('.lora')),
                )
                .toList();
            print("Found ${loraFiles.length} LoRA files in legacy directory");
            for (var entity in loraFiles) {
              if (entity is File) {
                String fileName = entity.path.split('/').last;
                loraModels.add({"name": fileName, "path": entity.path});
                print("Added LoRA model: $fileName from ${entity.path}");
              }
            }
          }
        }
      } catch (e) {
        print("Error scanning for LoRA models: $e");
      }
    }

    // Always include available models (for both Android and iOS)
    print(
      "Adding ${availableModels.length} models from availableModels to loraModels",
    );
    loraModels.addAll(availableModels);

    // Remove duplicates
    final seenLoRANames = <String>{};
    availableLoRAModels = loraModels.where((model) {
      final fileName = model["name"]!;
      if (seenLoRANames.contains(fileName)) {
        return false;
      }
      seenLoRANames.add(fileName);
      return true;
    }).toList();

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
    print("=== Starting to load available packaged images ===");

    // 1. First priority: Scan documents directory for actual user-added images
    try {
      final directory = await getApplicationDocumentsDirectory();
      print("App documents directory: ${directory.path}");
      final imagesDir = Directory('${directory.path}/images');
      print("Images directory: ${imagesDir.path}");
      bool imagesDirExists = await imagesDir.exists();
      print("Images directory exists: $imagesDirExists");
      if (imagesDirExists) {
        final imageFiles = await imagesDir
            .list()
            .where(
              (file) =>
                  file is File &&
                  (file.path.endsWith('.jpg') ||
                      file.path.endsWith('.jpeg') ||
                      file.path.endsWith('.png') ||
                      file.path.endsWith('.gif') ||
                      file.path.endsWith('.webp')),
            )
            .toList();
        print("Found ${imageFiles.length} image files in documents directory");
        for (var entity in imageFiles) {
          if (entity is File) {
            String fileName = entity.path.split('/').last;
            // Use full file name including extension
            images.add({"name": fileName, "path": entity.path});
            print("Added image: $fileName from ${entity.path}");
          }
        }
      } else {
        // Create images directory if it doesn't exist
        await imagesDir.create(recursive: true);
        print("Created images directory: ${imagesDir.path}");
        print("Please add your image files to this directory:");
        print("${imagesDir.path}");
      }
    } catch (e) {
      print("Error scanning documents directory: $e");
    }

    // 2. Second priority: Load images from assets/images directory
    // Flutter generates an AssetManifest.json file that we can parse to get all assets
    try {
      print("Checking assets/images directory");
      // Load AssetManifest.json
      String manifestContent = await rootBundle.loadString(
        'AssetManifest.json',
      );
      Map<String, dynamic> manifest = jsonDecode(manifestContent);

      // Extract all image files from assets/images
      List<String> imageAssets = manifest.keys
          .where(
            (key) =>
                key.startsWith('assets/images/') &&
                (key.endsWith('.jpg') ||
                    key.endsWith('.jpeg') ||
                    key.endsWith('.png') ||
                    key.endsWith('.gif') ||
                    key.endsWith('.webp')),
          )
          .toList();

      print("Found ${imageAssets.length} image files in assets/images");
      for (String assetPath in imageAssets) {
        String fileName = assetPath.split('/').last;
        // Use full file name including extension
        images.add({"name": fileName, "path": assetPath});
        print("Added image: $fileName from $assetPath");
      }
    } catch (e) {
      print("Error loading AssetManifest.json: $e");
      // Fallback: Add common image files
      List<String> commonImageFiles = [
        "sample1.jpg",
        "sample2.jpg",
        "sample3.png",
        "sample4.png",
        "cat.jpg",
        "dog.jpg",
        "car.jpg",
        "house.jpg",
        "city.jpg",
        "nature.jpg",
        "food.jpg",
        "person.jpg",
        "landscape.jpg",
        "portrait.jpg",
        "technology.jpg",
      ];

      print("Adding common image files as fallback");
      for (String imageName in commonImageFiles) {
        String assetPath = "assets/images/$imageName";
        // Use full file name including extension
        images.add({"name": imageName, "path": assetPath});
        print("Added image: $imageName from $assetPath");
      }
    }

    // 3. If no images found, add a placeholder
    print("Total images found before fallback: ${images.length}");
    if (images.isEmpty) {
      print("No images found, adding placeholder");
      images.add({
        "name": "Placeholder",
        "path": "assets/images/placeholder.png",
      });
    }

    availablePackagedImages = images;
    print("Final available packaged images: $availablePackagedImages");
    print("=== Finished loading available packaged images ===");
  }

  // Load model
  Future<void> loadModel() async {
    try {
      isLoading = true;
      notifyListeners();
      print("=== Starting model loading process ===");
      print("Model path: $modelPath");
      print("nCtx: $nCtx");
      print("nGpuLayers: $nGpuLayers");
      print("nThreads: $nThreads");
      print("enableEmbedding: $enableEmbedding");

      if (modelPath.isEmpty) {
        errorMessage = "Please select a model first";
        print("Error: No model selected");
        notifyListeners();
        return;
      }

      // Check if main model file exists (skip check for assets)
      print("DEBUG: modelPath = '$modelPath'");
      print(
        "DEBUG: modelPath starts with 'assets/' = ${modelPath.startsWith('assets/')}",
      );
      bool fileExists = true;
      String finalModelPath = modelPath;

      // Handle asset paths by copying to temp
      if (modelPath.startsWith('assets/')) {
        print("Handling asset path: $modelPath");
        final tempPath = await copyAssetToTemp(modelPath);
        if (tempPath == null) {
          errorMessage = "Failed to copy asset to temporary file: $modelPath";
          print("Error: Failed to copy asset to temporary file");
          notifyListeners();
          return;
        }
        finalModelPath = tempPath;
        print("Asset copied to temp: $finalModelPath");
      } else {
        // Check if regular file exists
        fileExists = await File(modelPath).exists();
        print("Model file exists: $fileExists");
        if (!fileExists) {
          errorMessage = "Model file not found at path: $modelPath";
          print("Error: Model file not found at path: $modelPath");
          notifyListeners();
          return;
        }
      }

      // Verify the temp file exists
      final tempFile = File(finalModelPath);
      final tempFileExists = await tempFile.exists();
      final tempFileSize = tempFileExists ? await tempFile.length() : 0;
      print("Temp file exists: $tempFileExists");
      print("Temp file size: $tempFileSize bytes");

      // Additional file system checks
      if (tempFileExists) {
        try {
          // Check if we can read the file
          final fileStat = await tempFile.stat();
          print("File stat: $fileStat");
          print("File mode: ${fileStat.mode}");
          print("File size: ${fileStat.size}");
          print("File modified: ${fileStat.modified}");

          // Try to read a small portion of the file to verify access
          final fileHandle = await tempFile.open();
          final buffer = List<int>.filled(100, 0);
          final bytesRead = await fileHandle.readInto(buffer);
          await fileHandle.close();
          print("Successfully read $bytesRead bytes from the file");
          print("First 10 bytes: ${buffer.sublist(0, 10)}");
        } catch (e) {
          print("Error accessing file: $e");
          errorMessage = "Error accessing model file: $e";
          notifyListeners();
          return;
        }
      }

      // Create LlamaMobile instance
      print("Creating LlamaMobile instance");
      llamaMobile = LlamaMobile();
      print("LlamaMobile instance created: ${llamaMobile != null}");

      // Initialize the context with all parameters
      print("Initializing model context with path: $finalModelPath");
      // Qwen3 chat template - using proper Jinja format
      final qwen3Template =
          "{%- for message in messages -%}\n" +
          "  {{- '<|im_start|>' + message.role + '\n' + message.content + '<|im_end|>\n' -}}\n" +
          "{%- endfor -%}\n" +
          "{%- if add_generation_prompt -%}\n" +
          "  {{- '<|im_start|>assistant\n' -}}\n" +
          "{%- endif -%}";

      // Determine which chat template to use
      String? chatTemplateToUse;
      if (useCustomTemplate) {
        chatTemplateToUse = qwen3Template;
        print("[INFO] Using custom Qwen3 chat template");
      } else {
        print("[INFO] Using model's built-in chat template");
      }

      print("Parameters:");
      if (chatTemplateToUse != null) {
        print("  chatTemplate: $chatTemplateToUse");
      } else {
        print("  chatTemplate: (using built-in template)");
      }
      print("  nCtx: $nCtx");
      print("  nGpuLayers: $nGpuLayers");
      print("  nThreads: $nThreads");
      print("  embedding: $enableEmbedding");
      print("  poolingType: 0");
      print("  embdNormalize: 1");
      print("  nBatch: 1024");
      print("  nUBatch: 1024");
      final context = await llamaMobile!.initContextAsync(
        modelPath: finalModelPath,
        //chatTemplate: chatTemplateToUse,
        nCtx: nCtx,
        nGpuLayers: nGpuLayers, // Use user-specified GPU layers
        nThreads: nThreads,
        embedding: enableEmbedding,
        poolingType: 0,
        embdNormalize: 1,
        nBatch: 1024,
        nUBatch: 1024,
        flashAttention: true, // Enable flash attention for better performance
      );
      print("Context initialization completed: ${context != null}");

      if (context != null) {
        llamaContext = context;
        isModelLoaded = true;
        errorMessage = "Model loaded successfully";
        print("Main model loaded successfully: $modelPath");

        // Chat template is now set during initialization
        print("Chat template already set during initialization");

        // Load LoRA adapter if path is provided
        if (loraModelPath.isNotEmpty) {
          print("Loading LoRA adapter: $loraModelPath");
          String loraPath = loraModelPath;
          bool loraValid = true;

          // Handle asset paths for LoRA
          if (loraModelPath.startsWith('assets/')) {
            final tempPath = await copyAssetToTemp(loraModelPath);
            if (tempPath != null) {
              loraPath = tempPath;
              print("LoRA asset copied to temp: $loraPath");
              // Update the app state's loraModelPath to use the temp path
              this.loraModelPath = loraPath;
            } else {
              print("Failed to copy LoRA asset to temp");
              loraValid = false;
            }
          } else {
            // For non-asset paths (like Android external storage), don't check existence
            // because the file is on the device/emulator, not on the development machine
            print(
              "Skipping existence check for non-asset LoRA path: $loraModelPath",
            );
            loraValid = true;
          }

          if (loraValid) {
            try {
              final success = await context.loadLoraAdapterAsync(loraPath, 1.0);
              print("LoRA adapter loaded successfully: $success");
            } catch (e) {
              print("Error loading LoRA adapter: $e");
            }
          }
        }

        // Load TTS model if vocoder path is provided
        if (vocoderModelPath.isNotEmpty) {
          print("Loading TTS model: $vocoderModelPath");
          String ttsPath = vocoderModelPath;
          bool ttsValid = true;

          // Handle asset paths for TTS
          if (vocoderModelPath.startsWith('assets/')) {
            final tempPath = await copyAssetToTemp(vocoderModelPath);
            if (tempPath != null) {
              ttsPath = tempPath;
              print("TTS asset copied to temp: $ttsPath");
              // Update the app state's vocoderModelPath to use the temp path
              this.vocoderModelPath = ttsPath;
            } else {
              print("Failed to copy TTS asset to temp");
              ttsValid = false;
            }
          } else {
            // For non-asset paths (like Android external storage), don't check existence
            // because the file is on the device/emulator, not on the development machine
            print(
              "Skipping existence check for non-asset vocoder path: $vocoderModelPath",
            );
            ttsValid = true;
          }

          if (ttsValid) {
            try {
              // Try loading as outETTSv03 first
              var success = await context.loadTTSModelAsync(
                ttsPath,
                TTSModelType.outETTSv03,
              );
              print("TTS model loaded successfully (v03): $success");

              // If v03 fails, try v02
              if (!success) {
                success = await context.loadTTSModelAsync(
                  ttsPath,
                  TTSModelType.outETTSv02,
                );
                print("TTS model loaded successfully (v02): $success");
              }
            } catch (e) {
              print("Error loading TTS model: $e");
            }
          }
        }

        // Load mmproj model if path is provided for multimodal
        if (mmprojModelPath.isNotEmpty) {
          print("Loading mmproj model: $mmprojModelPath");
          String mmprojPath = mmprojModelPath;
          bool mmprojValid = true;

          // Handle asset paths for mmproj
          if (mmprojModelPath.startsWith('assets/')) {
            final tempPath = await copyAssetToTemp(mmprojModelPath);
            if (tempPath != null) {
              mmprojPath = tempPath;
              print("mmproj asset copied to temp: $mmprojPath");
              // Update the app state's mmprojModelPath to use the temp path
              this.mmprojModelPath = mmprojPath;
            } else {
              print("Failed to copy mmproj asset to temp");
              mmprojValid = false;
            }
          } else {
            // For non-asset paths (like Android external storage), don't check existence
            // because the file is on the device/emulator, not on the development machine
            print(
              "Skipping existence check for non-asset mmproj path: $mmprojModelPath",
            );
            mmprojValid = true;
          }

          if (mmprojValid) {
            try {
              // Initialize multimodal support with the mmproj model
              print(
                "Initializing multimodal support with mmproj model: $mmprojPath",
              );
              final success = await context.initMultimodalAsync(
                mmprojPath,
                nGpuLayers > 0, // Use GPU if layers are specified
              );
              print("Multimodal support initialized: $success");
              if (!success) {
                errorMessage =
                    "Failed to initialize multimodal support. Please check if the mmproj model is compatible with the main model.";
                print("Error: Multimodal initialization returned false");
                notifyListeners();
              }
            } catch (e) {
              errorMessage = "Error initializing multimodal support: $e";
              print("Error loading mmproj model: $e");
              notifyListeners();
            }
          }
        }
      } else {
        errorMessage = "Failed to initialize model context";
        isModelLoaded = false;
        print("Failed to initialize model context - returned null");
      }
      print("Model loading process completed");
      print("isModelLoaded: $isModelLoaded");
      print("errorMessage: $errorMessage");
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = "Error loading model: ${e.toString()}";
      isModelLoaded = false;
      isLoading = false;
      print("Error loading model: $e");
      print("Stack trace: ${e.toString()}");
      notifyListeners();
    }
  }

  // Unload model
  Future<void> unloadModel() async {
    try {
      isLoading = true;
      notifyListeners();

      print("[INFO] Unloading model and releasing resources...");

      // Release multimodal resources if initialized
      if (mmprojModelPath != null && mmprojModelPath!.isNotEmpty) {
        print("[INFO] Releasing multimodal resources...");
        await llamaContext?.releaseMultimodal();
      }

      // Release vocoder resources if initialized
      if (vocoderModelPath.isNotEmpty) {
        print("[INFO] Releasing vocoder resources...");
        await llamaContext?.releaseVocoder();
      }

      // Release main context
      print("[INFO] Releasing main context...");
      await llamaContext?.free();

      // Clear the context
      llamaContext = null;

      // Optionally reset LlamaMobile instance
      // llamaMobile = null;

      isModelLoaded = false;
      errorMessage = null;
      print("[INFO] All resources released successfully");
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = "Error unloading model: ${e.toString()}";
      isLoading = false;
      print("Error unloading model: $e");
      notifyListeners();
    }
  }

  // Copy asset to temporary file and return the path
  Future<String?> copyAssetToTemp(String assetPath) async {
    try {
      print("Copying asset to temp: $assetPath");

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      print("Temp directory: ${tempDir.path}");

      // Extract filename from asset path
      final fileName = assetPath.split('/').last;
      print("Filename: $fileName");

      // Create temporary file path
      final tempPath = '${tempDir.path}/$fileName';
      print("Temp path: $tempPath");

      // Check if temp file already exists
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        print("Temp file already exists, returning existing path");
        return tempPath;
      }

      // Load asset as byte data
      final byteData = await rootBundle.load(assetPath);
      print("Asset loaded successfully, size: ${byteData.lengthInBytes} bytes");

      // Validate byte data length
      if (byteData.lengthInBytes <= 0) {
        print("Error: Asset has zero or negative length");
        return null;
      }

      // Write to temporary file using proper byte data conversion
      await tempFile.writeAsBytes(
        byteData.buffer.asUint8List(0, byteData.lengthInBytes),
      );
      print("Asset copied to temp file successfully");

      return tempPath;
    } catch (e) {
      print("Error copying asset to temp: $e");
      return null;
    }
  }

  // Copy all model files from assets/models to temporary directory
  Future<Map<String, String>> copyAllModelsToTemp() async {
    try {
      print("=== Starting to copy all models to temp ===");

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      print("Temp directory: ${tempDir.path}");

      // List of model files to copy
      final modelFiles = [
        "assets/models/SmolLM-360M-Instruct.Q6_K.gguf",
        "assets/models/Qwen3-1.7B-Q4_K_M.gguf",
        "assets/models/SmolVLM-256M-Instruct-Q8_0.gguf",
        "assets/models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf",
        "assets/models/OuteTTS-0.2-500M-Q6_K.gguf",
        "assets/models/WavTokenizer-Large-75-F16.gguf",
        "assets/models/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf",
      ];

      final copiedModels = <String, String>{};

      // Copy each model file
      for (final modelPath in modelFiles) {
        try {
          final tempPath = await copyAssetToTemp(modelPath);
          if (tempPath != null) {
            copiedModels[modelPath] = tempPath;
            print("Copied model: $modelPath → $tempPath");
          } else {
            print("Failed to copy model: $modelPath");
          }
        } catch (e) {
          print("Error copying model $modelPath: $e");
        }
      }

      print("=== Finished copying models to temp ===");
      print("Copied ${copiedModels.length} out of ${modelFiles.length} models");
      print("Copied models: $copiedModels");

      return copiedModels;
    } catch (e) {
      print("Error in copyAllModelsToTemp: $e");
      return {};
    }
  }

  // Get models directory for downloads
  Future<String> getModelsDirectory() async {
    Directory modelsDir;

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        modelsDir = Directory('${externalDir.path}/models');
      } else {
        modelsDir = Directory(
          '${(await getApplicationDocumentsDirectory()).path}/models',
        );
      }
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      modelsDir = Directory('${documentsDir.path}/models');
    }

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
      print("Created models directory: ${modelsDir.path}");
    }

    return modelsDir.path;
  }

  // Format bytes to human readable format
  String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024.0 && unitIndex < 3) {
      size /= 1024.0;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  // Download model from Hugging Face
  Future<void> downloadFromHuggingFace() async {
    const repoID = "microsoft/Phi-3-mini-4k-instruct-gguf";
    const filename = "Phi-3-mini-4k-instruct-q4.gguf";
    const bearerToken = "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";

    final modelsDir = await getModelsDirectory();
    await startDownload(
      repoID: repoID,
      filename: filename,
      destinationPath: modelsDir,
      bearerToken: bearerToken,
      isHuggingFace: true,
    );
  }

  // Download model from URL
  Future<void> downloadFromURL() async {
    const url =
        "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf";
    const filename = "Phi-3-mini-4k-instruct-q4.gguf";
    const bearerToken = "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";

    final modelsDir = await getModelsDirectory();
    await startDownload(
      repoID: url,
      filename: filename,
      destinationPath: modelsDir,
      bearerToken: bearerToken,
      isHuggingFace: false,
    );
  }

  // Start download with progress tracking
  Future<void> startDownload({
    required String repoID,
    required String filename,
    required String destinationPath,
    required String bearerToken,
    required bool isHuggingFace,
  }) async {
    downloadProgress = 0.0;
    downloadStatus = "Preparing download...";
    downloadSpeed = "";
    downloadSize = "";
    downloadError = null;
    isDownloading = true;
    notifyListeners();

    final localPath = '$destinationPath/$filename';
    print("Starting download: $repoID to $localPath");

    try {
      final params = DownloadParams(
        url: repoID,
        localPath: localPath,
        username: isHuggingFace ? null : null,
        password: bearerToken,
        headers: isHuggingFace
            ? {'Authorization': 'Bearer $bearerToken'}
            : null,
      );

      final result = await LlamaMobile().downloadModelWithParamsAsync(params);

      isDownloading = false;

      if (result != null && result.success) {
        downloadStatus = "Download completed!";
        downloadProgress = 1.0;
        print("Download successful: ${result.localPath}");

        final file = File(result.localPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          downloadSize = formatBytes(fileSize);
        }

        await loadAvailableModels();
        notifyListeners();
      } else {
        downloadError = result?.errorMessage ?? "Unknown error";
        downloadStatus = "Download failed";
        print("Download failed: ${downloadError}");
        notifyListeners();
      }
    } catch (e) {
      isDownloading = false;
      downloadError = "Download error: $e";
      downloadStatus = "Download failed";
      print("Download exception: $e");
      notifyListeners();
    }
  }
}

// Message model
class Message {
  final String id;
  final String role;
  final String text;
  final String? thought;

  Message({required this.role, required this.text, this.thought, String? id})
    : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Message copyWith({String? text, String? thought}) {
    return Message(
      role: role,
      text: text ?? this.text,
      thought: thought ?? this.thought,
      id: id,
    );
  }
}

// Parse response to extract thought (between <think> tags) and reply (after </think>)
(String, String?) parseResponseForThoughtAndReply(String response) {
  // First, extract "choices[0]['text']" field content from the JSON response
  var textContent = response;

  // Try to parse as JSON and extract the "choices[0]['text']" field
  try {
    final json = jsonDecode(response);
    if (json is Map<String, dynamic>) {
      final choices = json['choices'];
      if (choices is List && choices.isNotEmpty) {
        final firstChoice = choices[0];
        if (firstChoice is Map<String, dynamic>) {
          final extractedText = firstChoice['text'];
          if (extractedText is String) {
            textContent = extractedText;
          }
        }
      }
    }
  } catch (e) {
    // Not JSON, use response as-is
  }

  String? thought;
  String reply = textContent;

  // Extract thought if found using simple string operations
  const openingTag = "<think>";
  const closingTag = "</think>";

  int openIndex = textContent.indexOf(openingTag);
  if (openIndex != -1) {
    int closeIndex = textContent.indexOf(closingTag, openIndex);
    if (closeIndex != -1) {
      // Extract thought content between tags
      thought = textContent
          .substring(openIndex + openingTag.length, closeIndex)
          .trim();

      // Extract reply content after closing tag
      reply = textContent.substring(closeIndex + closingTag.length).trim();
    }
  }

  return (reply, thought);
}

// Message Bubble Widget
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool useJsonResponse;

  const MessageBubble({
    Key? key,
    required this.message,
    this.useJsonResponse = true,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isShowingThought = false;

  @override
  Widget build(BuildContext context) {
    bool isUser = widget.message.role == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser &&
                widget.message.thought != null &&
                widget.message.thought!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isShowingThought = !_isShowingThought;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isShowingThought
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: Colors.amber[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Thought",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                      if (_isShowingThought) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.message.thought!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!isUser &&
                widget.message.thought != null &&
                widget.message.thought!.isNotEmpty)
              const SizedBox(height: 4),
            Container(
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
                widget.message.text,
                style: TextStyle(color: isUser ? Colors.white : Colors.black),
              ),
            ),
          ],
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

  Future<void> sendMessage() async {
    if (_textController.text.trim().isEmpty || isLoading) return;

    String messageText = _textController.text.trim();
    setState(() {
      messages.add(Message(role: "user", text: messageText));
      _textController.clear();
      isLoading = true;
    });

    // Generate response
    await generateResponse(messageText);
  }

  Future<void> generateResponse(String prompt) async {
    try {
      if (widget.appState.llamaContext != null) {
        // Generate response based on Streaming switch
        if (widget.appState.useStreaming) {
          // Use streaming generation
          print("[INFO] Using streaming generation");

          // Add initial assistant message
          setState(() {
            messages.add(Message(role: "assistant", text: ""));
          });

          // Create completion parameters
          CompletionParams params;
          if (widget.appState.useChatMode) {
            // Chat mode: use chatMessages with history
            print("[INFO] Using Chat mode with message history");

            // Create chat messages from conversation history
            List<ChatMessage> chatMessages = [];

            // Add system message
            chatMessages.add(
              ChatMessage(
                role: "system",
                content: widget.appState.systemPrompt,
              ),
            );

            // Add all conversation messages
            for (var msg in messages) {
              chatMessages.add(ChatMessage(role: msg.role, content: msg.text));
            }

            // Create completion parameters with structured chat messages
            params = CompletionParams.forChat(
              chatMessages: chatMessages,
              maxTokens: 2048,
              temperature: 0.7,
              topK: 40,
              topP: 0.9,
              minP: 0.1,
              penaltyLastN: 64,
              penaltyRepeat: 1.0,
              penaltyFreq: 0.0,
              penaltyPresent: 0.0,
              stopSequences: ["<|im_end|>"],
              useJsonResponse: widget.appState.useJsonResponse,
            );
          } else {
            // Direct prompt mode: use prompt only
            print("[INFO] Using Direct Prompt mode");

            // Create completion parameters with direct prompt
            params = CompletionParams(
              prompt: prompt,
              maxTokens: 4096,
              temperature: 0.7,
              topK: 40,
              topP: 0.9,
              minP: 0.1,
              penaltyLastN: 64,
              penaltyRepeat: 1.0,
              penaltyFreq: 0.0,
              penaltyPresent: 0.0,
              stopSequences: ["<|im_end|>"],
              useJsonResponse: widget.appState.useJsonResponse,
            );
          }

          // Listen to token stream
          StreamSubscription<String>? tokenSubscription;
          tokenSubscription = widget.appState.llamaContext?.onTokenStream
              .listen((token) {
                setState(() {
                  // Update last message with new token
                  if (messages.isNotEmpty &&
                      messages.last.role == "assistant") {
                    messages[messages.length - 1] = messages.last.copyWith(
                      text: messages.last.text + token,
                    );
                  }
                });
              });

          // Generate completion with streaming (async version)
          final result = await widget.appState.llamaContext
              ?.generateStreamingCompletionWithParamsAsync(params);

          // Cancel token subscription
          await tokenSubscription?.cancel();

          if (result != null) {
            print("[INFO] Streaming completed successfully");

            // Parse the final response to extract thought and reply
            if (messages.isNotEmpty && messages.last.role == "assistant") {
              final lastMessage = messages.last;
              final (parsedReply, parsedThought) =
                  parseResponseForThoughtAndReply(lastMessage.text);

              setState(() {
                messages[messages.length - 1] = lastMessage.copyWith(
                  text: parsedReply,
                  thought: parsedThought,
                );
              });
            }
          } else {
            print("[ERROR] Streaming generation failed");
            setState(() {
              widget.appState.errorMessage = "Failed to generate response";
            });
          }

          setState(() {
            isLoading = false;
          });
        } else {
          // Use normal generation
          print("[INFO] Using normal generation");

          CompletionParams params;
          String response;

          if (widget.appState.useChatMode) {
            // Chat mode: use chatMessages with history
            print("[INFO] Using Chat mode with message history");

            // Create chat messages from conversation history
            List<ChatMessage> chatMessages = [];

            // Add system message
            chatMessages.add(
              ChatMessage(
                role: "system",
                content: widget.appState.systemPrompt,
              ),
            );

            // Add all conversation messages
            for (var msg in messages) {
              chatMessages.add(ChatMessage(role: msg.role, content: msg.text));
            }

            // Create completion parameters with structured chat messages
            params = CompletionParams.forChat(
              chatMessages: chatMessages,
              maxTokens: 4096,
              temperature: 0.7,
              topK: 40,
              topP: 0.9,
              minP: 0.1,
              penaltyLastN: 64,
              penaltyRepeat: 1.0,
              penaltyFreq: 0.0,
              penaltyPresent: 0.0,
              stopSequences: ["<|im_end|>"],
              useJsonResponse: widget.appState.useJsonResponse,
            );

            // Generate completion with chat messages (sync or async version based on useAsync flag)
            if (widget.appState.useAsync) {
              print("[INFO] Using Async API for chat");
              final result = await widget.appState.llamaContext
                  ?.generateCompletionWithParamsAsync(params);
              response = result?.text ?? "";
            } else {
              print("[INFO] Using Sync API for chat");
              final result = await widget.appState.llamaContext
                  ?.generateCompletionWithParams(params);
              response = result?.text ?? "";
            }
          } else {
            // Direct prompt mode: use prompt only
            print("[INFO] Using Direct Prompt mode");

            // Create completion parameters with direct prompt
            params = CompletionParams(
              prompt: prompt,
              maxTokens: 4096,
              temperature: 0.7,
              topK: 40,
              topP: 0.9,
              minP: 0.1,
              penaltyLastN: 64,
              penaltyRepeat: 1.0,
              penaltyFreq: 0.0,
              penaltyPresent: 0.0,
              stopSequences: ["<|im_end|>"],
              useJsonResponse: widget.appState.useJsonResponse,
            );

            // Generate completion (sync or async version based on useAsync flag)
            if (widget.appState.useAsync) {
              print("[INFO] Using Async API for completion");
              final result = await widget.appState.llamaContext
                  ?.generateCompletionWithParamsAsync(params);
              response = result?.text ?? "";
            } else {
              print("[INFO] Using Sync API for completion");
              final result = await widget.appState.llamaContext
                  ?.generateCompletionWithParams(params);
              response = result?.text ?? "";
            }
          }

          // Log complete raw response from LLM
          final separator = List.filled(50, "=").join();
          print("\n$separator");
          print(
            "[RAW MODEL RESPONSE] START (length: ${response.length} characters)",
          );
          print(response);
          print("[RAW MODEL RESPONSE] END");
          print("$separator\n");

          // Clean response by removing ending tags and stop sequences (iOS SDK Example style)
          var cleanedText = response;

          // Remove ending tags and stop sequences
          cleanedText = cleanedText.replaceAll("<|im_end|>", "");
          cleanedText = cleanedText.replaceAll("", "");

          // Remove stop sequences that might still be present
          for (var stopSeq in params.stopSequences ?? []) {
            cleanedText = cleanedText.replaceAll(stopSeq, "");
          }

          // Trim whitespace
          String assistantResponse = cleanedText.trim();

          // Parse response to extract thought and reply if JSON response is enabled
          var finalText = assistantResponse;
          String? messageThought;

          final (parsedReply, parsedThought) = parseResponseForThoughtAndReply(
            assistantResponse,
          );
          finalText = parsedReply;
          messageThought = parsedThought;

          setState(() {
            messages.add(
              Message(
                role: "assistant",
                text: finalText,
                thought: messageThought,
              ),
            );
            isLoading = false;
          });
        }
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text("Streaming:"),
                        Switch(
                          value: widget.appState.useStreaming,
                          onChanged: (value) {
                            setState(() {
                              widget.appState.useStreaming = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("Async:"),
                        Switch(
                          value: widget.appState.useAsync,
                          onChanged: (value) {
                            setState(() {
                              widget.appState.useAsync = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("JSON Response:"),
                        Switch(
                          value: widget.appState.useJsonResponse,
                          onChanged: (value) {
                            setState(() {
                              widget.appState.useJsonResponse = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
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
                          return MessageBubble(
                            message: messages[index],
                            useJsonResponse: widget.appState.useJsonResponse,
                          );
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
  String detokenizedText = "";
  bool isProcessing = false;

  void tokenizeText() async {
    if (_textController.text.isEmpty ||
        !widget.appState.isModelLoaded ||
        isProcessing)
      return;

    try {
      setState(() {
        isProcessing = true;
      });
      // Use the actual tokenization method
      final result = await widget.appState.llamaContext?.tokenize(
        _textController.text,
      );
      if (result != null) {
        setState(() {
          tokens = result;
          tokenCount = result.length.toString();
          detokenizedText = "";
        });
      } else {
        widget.appState.errorMessage =
            "Error tokenizing text: Tokenization returned null";
      }
    } catch (e) {
      widget.appState.errorMessage = "Error tokenizing text: $e";
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void detokenizeTokens() async {
    if (tokens.isEmpty || !widget.appState.isModelLoaded || isProcessing)
      return;

    try {
      setState(() {
        isProcessing = true;
      });
      // Use the actual detokenization method
      final result = await widget.appState.llamaContext?.detokenize(tokens);
      if (result != null) {
        setState(() {
          detokenizedText = result;
        });
      } else {
        widget.appState.errorMessage =
            "Error detokenizing text: Detokenization returned null";
      }
    } catch (e) {
      widget.appState.errorMessage = "Error detokenizing text: $e";
    } finally {
      setState(() {
        isProcessing = false;
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "Text to Tokenize",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !isProcessing && widget.appState.isModelLoaded,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    isProcessing ||
                        !widget.appState.isModelLoaded ||
                        _textController.text.isEmpty
                    ? null
                    : tokenizeText,
                child: Text(isProcessing ? "Tokenizing..." : "Tokenize"),
              ),
              const SizedBox(height: 10),
              if (tokens.isNotEmpty)
                ElevatedButton(
                  onPressed: isProcessing ? null : detokenizeTokens,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(isProcessing ? "Detokenizing..." : "Detokenize"),
                ),
              const SizedBox(height: 20),
              Text("Token Count: $tokenCount"),
              const SizedBox(height: 20),
              if (tokens.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tokens:"),
                        const SizedBox(height: 10),
                        Text(
                          tokens.toString(),
                          style: const TextStyle(fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (detokenizedText.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Detokenized Text:"),
                        const SizedBox(height: 10),
                        Text(
                          detokenizedText,
                          style: const TextStyle(fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
  bool isProcessing = false;

  void generateEmbedding() async {
    print("[DEBUG] Flutter: generateEmbedding called");

    if (_textController.text.isEmpty ||
        !widget.appState.isModelLoaded ||
        isProcessing) {
      print(
        "[DEBUG] Flutter: generateEmbedding - Skipping: text empty: ${_textController.text.isEmpty}, model loaded: ${widget.appState.isModelLoaded}, processing: $isProcessing",
      );
      return;
    }

    try {
      setState(() {
        isProcessing = true;
      });
      print(
        "[DEBUG] Flutter: generateEmbedding - Starting embedding generation for text: ${_textController.text}",
      );
      // Use the actual embedding method
      final result = await widget.appState.llamaContext?.generateEmbeddingAsync(
        _textController.text,
      );
      print(
        "[DEBUG] Flutter: generateEmbedding - Embedding result received: $result",
      );
      if (result != null) {
        print(
          "[DEBUG] Flutter: generateEmbedding - Embedding successful, length: ${result.length}",
        );
        setState(() {
          embedding = result;
          embeddingLength = result.length.toString();
        });
      } else {
        print("[DEBUG] Flutter: generateEmbedding - Embedding returned null");
        widget.appState.errorMessage =
            "Error generating embedding: Embedding returned null";
      }
    } catch (e) {
      print("[DEBUG] Flutter: generateEmbedding - Error: $e");
      widget.appState.errorMessage = "Error generating embedding: $e";
    } finally {
      setState(() {
        isProcessing = false;
      });
      print("[DEBUG] Flutter: generateEmbedding - Processing complete");
    }
  }

  String formatEmbeddingResult() {
    if (embedding.isEmpty) return "Embedding will appear here";

    // Show only first 20 values to avoid overwhelming the UI
    final truncatedEmbedding = embedding.take(20).toList();
    final formattedValues = truncatedEmbedding
        .map((value) => value.toStringAsFixed(6))
        .join(", ");
    var result = "[$formattedValues";

    if (embedding.length > 20) {
      result += ", ... (and ${embedding.length - 20} more values)";
    }

    result += "\n\nEmbedding dimension: ${embedding.length}";
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "Text to Embed",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !isProcessing && widget.appState.isModelLoaded,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    isProcessing ||
                        !widget.appState.isModelLoaded ||
                        _textController.text.isEmpty
                    ? null
                    : generateEmbedding,
                child: Text(
                  isProcessing
                      ? "Generating Embedding..."
                      : "Generate Embedding",
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Embedding Result:"),
                      const SizedBox(height: 10),
                      Text(
                        formatEmbeddingResult(),
                        style: const TextStyle(fontFamily: 'Courier'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
  void _onAppStateChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
            child: Form(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Model Configuration Section
                  const SectionHeader(title: "Model Configuration"),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Model Picker
                          widget.appState.availableModels.isEmpty
                              ? const Text(
                                  "No models found in the bundle",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                )
                              : Column(
                                  children: [
                                    DropdownButtonFormField<
                                      Map<String, String>?
                                    >(
                                      isExpanded: true,
                                      value:
                                          widget
                                                  .appState
                                                  .availableModels
                                                  .isNotEmpty &&
                                              widget
                                                  .appState
                                                  .modelPath
                                                  .isNotEmpty
                                          ? widget.appState.availableModels
                                                .firstWhere(
                                                  (model) =>
                                                      model["path"] ==
                                                      widget.appState.modelPath,
                                                  orElse: () => widget
                                                      .appState
                                                      .availableModels
                                                      .first,
                                                )
                                          : null,
                                      items: [
                                        const DropdownMenuItem<
                                          Map<String, String>?
                                        >(
                                          value: null,
                                          child: Text(
                                            "Empty",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...widget.appState.availableModels.map((
                                          model,
                                        ) {
                                          return DropdownMenuItem<
                                            Map<String, String>?
                                          >(
                                            value: model,
                                            child: Text(
                                              model["name"]!,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                      onChanged: widget.appState.isModelLoaded
                                          ? null
                                          : (Map<String, String>? value) {
                                              setState(() {
                                                widget.appState.modelPath =
                                                    value?["path"] ?? "";
                                              });
                                            },
                                      decoration: const InputDecoration(
                                        labelText: "Select Main Model",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                          // MMProj Model Picker
                          Container(
                            width: double.infinity,
                            child: DropdownButtonFormField<Map<String, String>>(
                              isExpanded: true,
                              value:
                                  widget
                                      .appState
                                      .availableMmprojModels
                                      .isNotEmpty
                                  ? widget.appState.availableMmprojModels.firstWhere(
                                      (model) {
                                        // Handle empty path case
                                        if (widget
                                            .appState
                                            .mmprojModelPath
                                            .isEmpty) {
                                          return model["path"] == "";
                                        }
                                        // Find by filename instead of full path
                                        // because path changes when copied to temp
                                        final modelFilename = model["path"]!
                                            .split('/')
                                            .last;
                                        final currentFilename = widget
                                            .appState
                                            .mmprojModelPath
                                            .split('/')
                                            .last;
                                        return modelFilename ==
                                                currentFilename ||
                                            model["path"] ==
                                                widget.appState.mmprojModelPath;
                                      },
                                      orElse: () => widget
                                          .appState
                                          .availableMmprojModels
                                          .first,
                                    )
                                  : null,
                              items: [
                                const DropdownMenuItem<Map<String, String>>(
                                  value: null,
                                  child: Text(
                                    "Empty",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...widget.appState.availableMmprojModels.map((
                                  model,
                                ) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: model,
                                    child: Text(
                                      model["name"]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: widget.appState.isModelLoaded
                                  ? null
                                  : (Map<String, String>? value) {
                                      setState(() {
                                        widget.appState.mmprojModelPath =
                                            value?["path"] ?? "";
                                      });
                                    },
                              decoration: const InputDecoration(
                                labelText: "Select MMProj Model",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Vocoder Model Picker
                          Container(
                            width: double.infinity,
                            child: DropdownButtonFormField<Map<String, String>>(
                              isExpanded: true,
                              value:
                                  widget
                                      .appState
                                      .availableVocoderModels
                                      .isNotEmpty
                                  ? widget.appState.availableVocoderModels.firstWhere(
                                      (model) {
                                        // Handle empty path case
                                        if (widget
                                            .appState
                                            .vocoderModelPath
                                            .isEmpty) {
                                          return model["path"] == "";
                                        }
                                        // Find by filename instead of full path
                                        // because path changes when copied to temp
                                        final modelFilename = model["path"]!
                                            .split('/')
                                            .last;
                                        final currentFilename = widget
                                            .appState
                                            .vocoderModelPath
                                            .split('/')
                                            .last;
                                        return modelFilename ==
                                                currentFilename ||
                                            model["path"] ==
                                                widget
                                                    .appState
                                                    .vocoderModelPath;
                                      },
                                      orElse: () => widget
                                          .appState
                                          .availableVocoderModels
                                          .first,
                                    )
                                  : null,
                              items: [
                                const DropdownMenuItem<Map<String, String>>(
                                  value: null,
                                  child: Text(
                                    "Empty",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...widget.appState.availableVocoderModels.map((
                                  model,
                                ) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: model,
                                    child: Text(
                                      model["name"]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: widget.appState.isModelLoaded
                                  ? null
                                  : (Map<String, String>? value) {
                                      setState(() {
                                        widget.appState.vocoderModelPath =
                                            value?["path"] ?? "";
                                      });
                                    },
                              decoration: const InputDecoration(
                                labelText: "Select Vocoder Model",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // LoRA Model Picker
                          Container(
                            width: double.infinity,
                            child: DropdownButtonFormField<Map<String, String>>(
                              isExpanded: true,
                              value:
                                  widget.appState.availableLoRAModels.isNotEmpty
                                  ? widget.appState.availableLoRAModels.firstWhere(
                                      (model) {
                                        // Handle empty path case
                                        if (widget
                                            .appState
                                            .loraModelPath
                                            .isEmpty) {
                                          return model["path"] == "";
                                        }
                                        // Find by filename instead of full path
                                        // because path changes when copied to temp
                                        final modelFilename = model["path"]!
                                            .split('/')
                                            .last;
                                        final currentFilename = widget
                                            .appState
                                            .loraModelPath
                                            .split('/')
                                            .last;
                                        return modelFilename ==
                                                currentFilename ||
                                            model["path"] ==
                                                widget.appState.loraModelPath;
                                      },
                                      orElse: () => widget
                                          .appState
                                          .availableLoRAModels
                                          .first,
                                    )
                                  : null,
                              items: [
                                const DropdownMenuItem<Map<String, String>>(
                                  value: null,
                                  child: Text(
                                    "Empty",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...widget.appState.availableLoRAModels.map((
                                  model,
                                ) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: model,
                                    child: Text(
                                      model["name"]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: widget.appState.isModelLoaded
                                  ? null
                                  : (Map<String, String>? value) {
                                      setState(() {
                                        widget.appState.loraModelPath =
                                            value?["path"] ?? "";
                                      });
                                    },
                              decoration: const InputDecoration(
                                labelText: "Select LoRA Model",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Chat Mode Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Chat Mode"),
                              Switch(
                                value: widget.appState.useChatMode,
                                onChanged: widget.appState.isModelLoaded
                                    ? null
                                    : (value) {
                                        setState(() {
                                          widget.appState.useChatMode = value;
                                        });
                                      },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Custom Template Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Custom Template"),
                              Switch(
                                value: widget.appState.useCustomTemplate,
                                onChanged: widget.appState.isModelLoaded
                                    ? null
                                    : (value) {
                                        setState(() {
                                          widget.appState.useCustomTemplate =
                                              value;
                                        });
                                      },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Enable Embedding Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Enable Embedding"),
                              Switch(
                                value: widget.appState.enableEmbedding,
                                onChanged: widget.appState.isModelLoaded
                                    ? null
                                    : (value) {
                                        setState(() {
                                          widget.appState.enableEmbedding =
                                              value;
                                        });
                                      },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // GPU Layers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("GPU Layers"),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nGpuLayers >
                                                  0) {
                                                widget.appState.nGpuLayers--;
                                              }
                                            });
                                          },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      widget.appState.nGpuLayers.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nGpuLayers <
                                                  100) {
                                                widget.appState.nGpuLayers++;
                                              }
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Threads
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Threads"),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nThreads >
                                                  1) {
                                                widget.appState.nThreads--;
                                              }
                                            });
                                          },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      widget.appState.nThreads.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nThreads <
                                                  8) {
                                                widget.appState.nThreads++;
                                              }
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Context Size
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Context Size"),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nCtx > 512) {
                                                widget.appState.nCtx -= 512;
                                              }
                                            });
                                          },
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      widget.appState.nCtx.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: widget.appState.isModelLoaded
                                        ? null
                                        : () {
                                            setState(() {
                                              if (widget.appState.nCtx < 4096) {
                                                widget.appState.nCtx += 512;
                                              }
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Model Actions Section
                  const SectionHeader(title: "Model Actions"),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Load Model Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  widget.appState.isModelLoaded ||
                                      widget.appState.isLoading
                                  ? null
                                  : () async {
                                      await widget.appState.loadModel();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: widget.appState.isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Loading...",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      "Load Model",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Unload Model Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  !widget.appState.isModelLoaded ||
                                      widget.appState.isLoading
                                  ? null
                                  : () async {
                                      await widget.appState.unloadModel();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Unload Model",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Download Model from HF Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.appState.isDownloading
                                  ? null
                                  : () async {
                                      await widget.appState
                                          .downloadFromHuggingFace();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Download Model from HF",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Download from URL Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.appState.isDownloading
                                  ? null
                                  : () async {
                                      await widget.appState.downloadFromURL();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Download from URL",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Chat Configuration Section
                  const SectionHeader(title: "Chat Configuration"),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // System Prompt
                          TextField(
                            controller: TextEditingController(
                              text: widget.appState.systemPrompt,
                            ),
                            onChanged: widget.appState.isModelLoaded
                                ? null
                                : (value) {
                                    widget.appState.systemPrompt = value;
                                  },
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: "System Prompt",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Note: System prompt changes require reloading the model",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Model Status Section
                  if (widget.appState.isModelLoaded) ...[
                    const SectionHeader(title: "Model Status"),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text("Status"),
                                Text(
                                  "Loaded",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Multimodal"),
                                Text(
                                  widget.appState.mmprojModelPath.isNotEmpty
                                      ? "Yes"
                                      : "No",
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Vision Support"),
                                Text(
                                  widget.appState.mmprojModelPath.isNotEmpty
                                      ? "Yes"
                                      : "No",
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Audio Support"),
                                Text(
                                  widget.appState.vocoderModelPath.isNotEmpty
                                      ? "Yes"
                                      : "No",
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Embedding"),
                                Text(
                                  widget.appState.enableEmbedding
                                      ? "Yes"
                                      : "No",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // LoRA Test Button
                  const SectionHeader(title: "LoRA Testing"),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoRATestView(appState: widget.appState),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Open LoRA Test Page",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Error Section
                  if (widget.appState.errorMessage != null) ...[
                    const SectionHeader(title: "Error", isError: true),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.appState.errorMessage ?? "",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Download progress popup
          if (widget.appState.isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Downloading Model",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: widget.appState.downloadProgress,
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(widget.appState.downloadProgress * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.appState.downloadStatus,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (widget.appState.downloadSize.isNotEmpty)
                        Text(
                          widget.appState.downloadSize,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      if (widget.appState.downloadSpeed.isNotEmpty)
                        Text(
                          widget.appState.downloadSpeed,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // Download error popup
          if (widget.appState.downloadError != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Download Error",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.appState.downloadError ?? "",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.appState.downloadError = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
  double scale = 1.0;
  bool isProcessing = false;
  bool loraApplied = false;

  void applyLoRA() async {
    if (widget.appState.loraModelPath.isEmpty ||
        !widget.appState.isModelLoaded ||
        isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final success =
          await widget.appState.llamaContext?.loadLoraAdapterAsync(
            widget.appState.loraModelPath,
            scale,
          ) ??
          false;

      if (success) {
        setState(() {
          loraApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LoRA adapter applied successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply LoRA adapter')),
        );
      }
    } catch (e) {
      widget.appState.errorMessage = "Error applying LoRA adapter: $e";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void removeLoRA() async {
    if (!loraApplied || !widget.appState.isModelLoaded || isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await widget.appState.llamaContext?.freeLoraAdapterAsync();
      setState(() {
        loraApplied = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LoRA adapter removed successfully')),
      );
    } catch (e) {
      widget.appState.errorMessage = "Error removing LoRA adapter: $e";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoRA Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // LoRA Adapter Configuration
              const SectionHeader(title: "LoRA Adapter Configuration"),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // LoRA Adapter Path
                      TextField(
                        controller: TextEditingController(
                          text: widget.appState.loraModelPath,
                        ),
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: "LoRA Adapter Path",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // LoRA Scale
                      TextField(
                        controller: TextEditingController(
                          text: scale.toString(),
                        ),
                        onChanged: (value) {
                          final parsedScale = double.tryParse(value);
                          if (parsedScale != null) {
                            setState(() {
                              scale = parsedScale;
                            });
                          }
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "LoRA Scale",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Apply/Remove LoRA Buttons
              const SectionHeader(title: "LoRA Actions"),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Apply LoRA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              widget.appState.loraModelPath.isEmpty ||
                                  !widget.appState.isModelLoaded ||
                                  isProcessing
                              ? null
                              : applyLoRA,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isProcessing ? "Applying LoRA..." : "Apply LoRA",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remove LoRA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              !loraApplied ||
                                  !widget.appState.isModelLoaded ||
                                  isProcessing
                              ? null
                              : removeLoRA,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isProcessing ? "Removing LoRA..." : "Remove LoRA",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LoRA Status
              const SectionHeader(title: "Status"),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        loraApplied ? Icons.check_circle : Icons.error,
                        color: loraApplied ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loraApplied
                            ? "LoRA adapter applied successfully"
                            : "No LoRA adapter applied",
                        style: TextStyle(
                          color: loraApplied ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom padding
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final bool isError;

  const SectionHeader({Key? key, required this.title, this.isError = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isError ? Colors.red : null,
        ),
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
  TextEditingController _promptController = TextEditingController(
    text: "what's on the image",
  );
  String multimodalResult = "";
  bool isProcessing = false;

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.appState.selectedImagePath = pickedFile.path;
      });
    }
  }

  void selectPackagedImage(Map<String, String> image) {
    setState(() {
      widget.appState.selectedImagePath = image["path"];
    });
  }

  void testMultimodal() async {
    if (_promptController.text.isEmpty ||
        widget.appState.selectedImagePath == null ||
        !widget.appState.isModelLoaded ||
        isProcessing)
      return;

    try {
      setState(() {
        isProcessing = true;
        multimodalResult = "Processing...";
      });

      // Use generateCompletionWithParamsAsync with mediaPaths for multimodal
      if (widget.appState.llamaContext != null) {
        // Handle asset image paths by copying to temp
        String imagePath = widget.appState.selectedImagePath!;
        if (imagePath.startsWith('assets/')) {
          final tempPath = await widget.appState.copyAssetToTemp(imagePath);
          if (tempPath != null) {
            imagePath = tempPath;
            print("Image asset copied to temp: $imagePath");
          }
        }

        // Create completion parameters with media paths
        final params = CompletionParams(
          prompt: _promptController.text,
          mediaPaths: [imagePath],
          maxTokens: 512,
          temperature: 0.7,
        );

        print("[DEBUG] Example App: Calling generateCompletionWithParams");
        print("[DEBUG] Example App: imagePath: $imagePath");
        print("[DEBUG] Example App: prompt: ${_promptController.text}");
        print("[DEBUG] Example App: mediaPaths: ${params.mediaPaths}");

        final result = await widget.appState.llamaContext
            ?.generateCompletionWithParamsAsync(params);

        print(
          "[DEBUG] Example App: Result: ${result != null ? 'Success' : 'Null'}",
        );
        if (result != null) {
          setState(() {
            multimodalResult =
                "Multimodal test completed!\n\nPrompt: ${_promptController.text}\n\nResponse: ${result.text}";
          });
        } else {
          setState(() {
            multimodalResult = "Error: No response from model";
          });
        }
      } else {
        setState(() {
          multimodalResult = "Error: Model not loaded";
        });
      }
    } catch (e) {
      widget.appState.errorMessage = "Error testing multimodal: $e";
      setState(() {
        multimodalResult = "Error: $e";
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Multimodal Test",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Input prompt for multimodal
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: "Input Prompt",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isProcessing,
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
                        // Check if the path is an asset (starts with 'assets/')
                        widget.appState.selectedImagePath!.startsWith('assets/')
                            ? Image.asset(
                                widget.appState.selectedImagePath!,
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text("Image failed to load"),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(widget.appState.selectedImagePath!),
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text("Image failed to load"),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 10),
                        Text(
                          widget.appState.selectedImagePath!.split('/').last,
                        ),
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
                      label: const Text("Gallery"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Select App Image"),
                            content: SingleChildScrollView(
                              child: Column(
                                children: widget
                                    .appState
                                    .availablePackagedImages
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
                      label: const Text("App Img"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed:
                      isProcessing ||
                          !widget.appState.isModelLoaded ||
                          _promptController.text.isEmpty ||
                          widget.appState.selectedImagePath == null
                      ? null
                      : testMultimodal,
                  child: Text(
                    isProcessing ? "Processing..." : "Test Multimodal",
                  ),
                ),
                const SizedBox(height: 20),

                // Multimodal result
                if (multimodalResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      multimodalResult,
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
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
  TextEditingController _ttsController = TextEditingController();
  String ttsResult = "";
  bool isProcessing = false;
  bool isPlaying = false;
  bool audioGenerated = false;
  String? audioFilePath;

  Future<void> generateAudioAsync() async {
    if (_ttsController.text.isEmpty ||
        !widget.appState.isModelLoaded ||
        isProcessing)
      return;

    try {
      setState(() {
        isProcessing = true;
        ttsResult = "Generating audio (Async)...";
        audioGenerated = false;
      });

      final result = await widget.appState.llamaContext?.generateSpeechAsync(
        _ttsController.text,
      );
      print("TTS Audio Generated successfully (Async)");

      if (result != null) {
        final audioSamplesList = result['audioSamples'];
        final audioSamples = audioSamplesList != null
            ? List<int>.from(audioSamplesList as List)
            : <int>[];
        final sampleRate = result['sampleRate'] as int;
        final duration = result['duration'] as double;
        final outputFilePath = result['outputFilePath'] as String?;

        print("Audio samples count: ${audioSamples.length}");
        print("Sample rate: $sampleRate");
        print("Duration: $duration seconds");

        String? filePath = outputFilePath;
        if (filePath == null) {
          final directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/tts_output_async.wav';

          print("Saving audio to WAV file: $filePath");

          final saveSuccess = await widget.appState.llamaContext
              ?.saveAudioToWavAsync(filePath, audioSamples, sampleRate);

          if (saveSuccess != true) {
            setState(() {
              ttsResult = "Error: Failed to save audio to WAV file";
              isProcessing = false;
            });
            return;
          }
        }

        setState(() {
          ttsResult =
              "Audio generated successfully (Async)!\n\nText: ${_ttsController.text}\nDuration: ${duration.toStringAsFixed(2)}s\nSaved to: ${filePath!.split('/').last}";
          audioFilePath = filePath;
          audioGenerated = true;
          isProcessing = false;
        });
      } else {
        setState(() {
          ttsResult = "Error: No audio generated";
          isProcessing = false;
        });
      }
    } catch (e) {
      widget.appState.errorMessage = "Error generating audio: $e";
      setState(() {
        ttsResult = "Error: $e";
        isProcessing = false;
      });
    }
  }

  Future<void> generateAudioSync() async {
    if (_ttsController.text.isEmpty ||
        !widget.appState.isModelLoaded ||
        isProcessing)
      return;

    try {
      setState(() {
        isProcessing = true;
        ttsResult = "Generating audio (Sync)...";
        audioGenerated = false;
      });

      final result = await widget.appState.llamaContext?.generateSpeechSync(
        _ttsController.text,
      );
      print("TTS Audio Generated successfully (Sync)");

      if (result != null) {
        final audioSamplesList = result['audioSamples'];
        final audioSamples = audioSamplesList != null
            ? List<int>.from(audioSamplesList as List)
            : <int>[];
        final sampleRate = result['sampleRate'] as int;
        final duration = result['duration'] as double;
        final outputFilePath = result['outputFilePath'] as String?;

        print("Audio samples count: ${audioSamples.length}");
        print("Sample rate: $sampleRate");
        print("Duration: $duration seconds");

        String? filePath = outputFilePath;
        if (filePath == null) {
          final directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/tts_output_sync.wav';

          print("Saving audio to WAV file: $filePath");

          final saveSuccess = await widget.appState.llamaContext
              ?.saveAudioToWavAsync(filePath, audioSamples, sampleRate);

          if (saveSuccess != true) {
            setState(() {
              ttsResult = "Error: Failed to save audio to WAV file";
              isProcessing = false;
            });
            return;
          }
        }

        setState(() {
          ttsResult =
              "Audio generated successfully (Sync)!\n\nText: ${_ttsController.text}\nDuration: ${duration.toStringAsFixed(2)}s\nSaved to: ${filePath!.split('/').last}";
          audioFilePath = filePath;
          audioGenerated = true;
          isProcessing = false;
        });
      } else {
        setState(() {
          ttsResult = "Error: No audio generated";
          isProcessing = false;
        });
      }
    } catch (e) {
      widget.appState.errorMessage = "Error generating audio: $e";
      setState(() {
        ttsResult = "Error: $e";
        isProcessing = false;
      });
    }
  }

  void playAudio() async {
    if (audioFilePath == null || isPlaying) return;

    try {
      setState(() {
        isPlaying = true;
      });

      // Play the audio file
      print("Playing audio from: $audioFilePath");
      // Use audioplayers package to play the audio
      // First, check if the file exists
      final file = File(audioFilePath!);
      if (await file.exists()) {
        print("Audio file size: ${await file.length()} bytes");
        print("Audio file is accessible and ready to play");

        // Use audioplayers to actually play the audio
        final player = AudioPlayer();
        await player.play(DeviceFileSource(audioFilePath!));

        // Wait for playback to complete
        await player.onPlayerComplete.first;
        await player.dispose();

        print("Audio playback completed successfully");
      } else {
        print("Audio file not found: $audioFilePath");
        await Future.delayed(const Duration(seconds: 1));
      }

      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      widget.appState.errorMessage = "Error playing audio: $e";
      print("Audio playback error: $e");
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "TTS Test",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _ttsController,
                  decoration: const InputDecoration(
                    labelText: "Text to Speech",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isProcessing,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isProcessing ||
                                !widget.appState.isModelLoaded ||
                                _ttsController.text.isEmpty
                            ? null
                            : generateAudioAsync,
                        child: Text(
                          isProcessing
                              ? "Generating..."
                              : "Generate Audio (Async)",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isProcessing ||
                                !widget.appState.isModelLoaded ||
                                _ttsController.text.isEmpty
                            ? null
                            : generateAudioSync,
                        child: Text(
                          isProcessing
                              ? "Generating..."
                              : "Generate Audio (Sync)",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Play button for audio playback
                ElevatedButton(
                  onPressed: !audioGenerated || isPlaying ? null : playAudio,
                  child: Text(isPlaying ? "Playing..." : "Play Audio"),
                ),

                const SizedBox(height: 20),

                if (ttsResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isProcessing
                            ? Colors.orange
                            : ttsResult.startsWith("Error")
                            ? Colors.red
                            : Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isProcessing
                          ? Colors.orange.withOpacity(0.1)
                          : ttsResult.startsWith("Error")
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ttsResult,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: isProcessing
                                ? Colors.orange.shade900
                                : ttsResult.startsWith("Error")
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                            fontWeight: isProcessing
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "Playing audio...",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Main App
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
      // Only copy models to temp directory for iOS
      // For Android, we'll access the app-specific folder directly
      if (Platform.isIOS) {
        await appState.copyAllModelsToTemp();
      }
      // Then load available models
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
              EmbeddingTestView(appState: appState),
              MultimodalTestView(appState: appState),
              TTSTestView(appState: appState),
              SettingsView(appState: appState),
            ],
          ),
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble), text: 'Chat'),
              Tab(icon: Icon(Icons.text_fields), text: 'Embed'),
              Tab(icon: Icon(Icons.camera), text: 'Image'),
              Tab(icon: Icon(Icons.volume_up), text: 'TTS'),
              Tab(icon: Icon(Icons.more_vert), text: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}
