# Llama Mobile React Native SDK Example

This is an example application demonstrating the usage of the Llama Mobile React Native SDK.

## Features

- SDK initialization
- Model loading and unloading
- Text generation with and without streaming
- Model path configuration
- Status indicators for SDK and model state

## Prerequisites

- Node.js 16 or later
- React Native development environment set up (Xcode for iOS, Android Studio for Android)
- A valid GGUF model file (e.g., `model.gguf`)

## Getting Started

### Installation

1. Install dependencies:

```bash
npm install
```

2. Install iOS pods:

```bash
cd ios && pod install && cd ..
```

### Configuration

1. Open the app in your code editor
2. In `src/App.js`, update the default model path on line 20:

```javascript
const [modelPath, setModelPath] = useState('/path/to/your/model.gguf');
```

Or you can update the model path directly in the app interface.

### Running the App

#### iOS

```bash
npm run ios
```

Or open `ios/LlamaMobileExample.xcworkspace` in Xcode and run the app.

#### Android

```bash
npm run android
```

Or open the `android` directory in Android Studio and run the app.

## Usage

1. The app will automatically initialize the SDK when it starts
2. Enter the path to your GGUF model file
3. Tap "Load Model" to load the model
4. Enter a prompt in the text area
5. Tap either:
   - "Generate Text" for non-streaming text generation
   - "Generate Stream" for streaming text generation
6. The response will be displayed below

## App Structure

```
├── App.js              # Main application component
├── package.json        # Dependencies and scripts
├── ios/                # iOS project files
├── android/            # Android project files
└── README.md           # This file
```

## SDK API Demonstrated

- `LlamaMobile.initialize()` - Initialize the SDK
- `LlamaMobile.loadModel(path, options)` - Load a GGUF model
- `LlamaMobile.generateText(prompt, options)` - Generate text without streaming
- `LlamaMobile.generateTextStream(prompt, options, onToken, onError, onComplete)` - Generate text with streaming
- `LlamaMobile.unloadModel()` - Unload the current model
- `LlamaMobile.VERSION` - Get the SDK version

## Troubleshooting

### Model Not Loading

- Ensure the model path is correct and the file exists
- Check that the model is in GGUF format
- Verify that the app has permission to access the file location

### Text Generation Issues

- Ensure the model has been successfully loaded
- Check the SDK status indicators at the top of the app
- Try reducing the `max_tokens` parameter for faster generation

### iOS Build Issues

```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
```

### Android Build Issues

```bash
cd android
./gradlew clean
```

## License

MIT
