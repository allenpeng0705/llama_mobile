import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  Button,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert
} from 'react-native';
import LlamaMobile from 'llama_mobile-react-native-sdk';

const App = () => {
  const [initialized, setInitialized] = useState(false);
  const [modelLoaded, setModelLoaded] = useState(false);
  const [prompt, setPrompt] = useState('Hello, how are you?');
  const [response, setResponse] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [modelPath, setModelPath] = useState('/path/to/your/model.gguf');

  // Initialize the SDK on app start
  useEffect(() => {
    const initSDK = async () => {
      try {
        await LlamaMobile.initialize();
        setInitialized(true);
      } catch (error) {
        Alert.alert('Error', 'Failed to initialize SDK: ' + error.message);
      }
    };
    initSDK();
  }, []);

  // Load the model
  const handleLoadModel = async () => {
    try {
      setIsGenerating(true);
      await LlamaMobile.loadModel(modelPath, {
        n_threads: 4,
        n_gpu_layers: 1,
        n_ctx: 2048
      });
      setModelLoaded(true);
    } catch (error) {
      Alert.alert('Error', 'Failed to load model: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Generate text
  const handleGenerateText = async () => {
    if (!modelLoaded) {
      Alert.alert('Error', 'Please load a model first');
      return;
    }

    try {
      setIsGenerating(true);
      setResponse('');
      
      const result = await LlamaMobile.generateText(prompt, {
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 100
      });
      
      setResponse(result.text);
    } catch (error) {
      Alert.alert('Error', 'Failed to generate text: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Generate text with streaming
  const handleGenerateTextStream = async () => {
    if (!modelLoaded) {
      Alert.alert('Error', 'Please load a model first');
      return;
    }

    try {
      setIsGenerating(true);
      setResponse('');
      
      await LlamaMobile.generateTextStream(
        prompt, 
        {
          temperature: 0.7,
          max_tokens: 100
        },
        (token) => {
          setResponse(prev => prev + token);
        },
        (error) => {
          Alert.alert('Error', 'Stream generation failed: ' + error.message);
          setIsGenerating(false);
        },
        () => {
          setIsGenerating(false);
        }
      );
    } catch (error) {
      Alert.alert('Error', 'Failed to start stream: ' + error.message);
      setIsGenerating(false);
    }
  };

  // Unload the model
  const handleUnloadModel = async () => {
    try {
      await LlamaMobile.unloadModel();
      setModelLoaded(false);
    } catch (error) {
      Alert.alert('Error', 'Failed to unload model: ' + error.message);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Llama Mobile React Native SDK Example</Text>
        <Text style={styles.subtitle}>Version: {LlamaMobile.VERSION}</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>SDK Status</Text>
        <Text style={styles.status}>
          Initialized: {initialized ? '✅' : '❌'}
        </Text>
        <Text style={styles.status}>
          Model Loaded: {modelLoaded ? '✅' : '❌'}
        </Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Model Configuration</Text>
        <TextInput
          style={styles.input}
          placeholder="Model Path"
          value={modelPath}
          onChangeText={setModelPath}
        />
        <View style={styles.buttonRow}>
          <Button
            title="Load Model"
            onPress={handleLoadModel}
            disabled={isGenerating}
          />
          <Button
            title="Unload Model"
            onPress={handleUnloadModel}
            disabled={isGenerating || !modelLoaded}
          />
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Text Generation</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          placeholder="Enter your prompt here..."
          value={prompt}
          onChangeText={setPrompt}
          multiline
          numberOfLines={4}
        />
        <View style={styles.buttonRow}>
          <Button
            title="Generate Text"
            onPress={handleGenerateText}
            disabled={isGenerating || !modelLoaded}
          />
          <Button
            title="Generate Stream"
            onPress={handleGenerateTextStream}
            disabled={isGenerating || !modelLoaded}
          />
        </View>
      </View>

      {isGenerating && (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Generating...</Text>
        </View>
      )}

      {response && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Response</Text>
          <View style={styles.response}>
            <Text>{response}</Text>
          </View>
        </View>
      )}

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Note: Replace the model path with the actual path to your GGUF model file.
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5'
  },
  header: {
    padding: 20,
    backgroundColor: '#007AFF',
    alignItems: 'center'
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 5
  },
  subtitle: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)'
  },
  section: {
    padding: 20,
    backgroundColor: 'white',
    marginBottom: 10
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10
  },
  status: {
    fontSize: 16,
    marginBottom: 5
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 10,
    marginBottom: 10,
    fontSize: 16
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top'
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10
  },
  loading: {
    padding: 20,
    alignItems: 'center'
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16
  },
  response: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 15,
    backgroundColor: '#f9f9f9'
  },
  footer: {
    padding: 20,
    alignItems: 'center'
  },
  footerText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center'
  }
});

export default App;
