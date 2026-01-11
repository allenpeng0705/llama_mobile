import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  Button,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
  Switch,
  TouchableOpacity,
  FlatList
} from 'react-native';
import LlamaMobile from 'llama_mobile-react-native-sdk';

const App = () => {
  const [initialized, setInitialized] = useState(false);
  const [modelLoaded, setModelLoaded] = useState(false);
  const [prompt, setPrompt] = useState('Hello, how are you?');
  const [response, setResponse] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [modelPath, setModelPath] = useState('/path/to/your/model.gguf');
  
  // Tokenization state
  const [tokenizeText, setTokenizeText] = useState('Hello world');
  const [tokens, setTokens] = useState([]);
  const [detokenizeText, setDetokenizeText] = useState('');
  
  // Embeddings state
  const [embedText, setEmbedText] = useState('This is a test sentence');
  const [embeddings, setEmbeddings] = useState([]);
  
  // LoRA adapters state
  const [loraPath, setLoraPath] = useState('/path/to/your/lora.adapter');
  const [loraScale, setLoraScale] = useState(1.0);
  const [loraApplied, setLoraApplied] = useState(false);
  
  // Multimodal state
  const [mmprojPath, setMmprojPath] = useState('/path/to/your/mmproj.gguf');
  const [multimodalEnabled, setMultimodalEnabled] = useState(false);
  const [imagePath, setImagePath] = useState('/path/to/your/image.jpg');
  
  // Conversation state
  const [conversationHistory, setConversationHistory] = useState([]);
  const [conversationMessage, setConversationMessage] = useState('Tell me a joke');
  const [conversationResponse, setConversationResponse] = useState('');
  
  // Grammar state
  const [grammarName, setGrammarName] = useState('json');
  const [grammarContent, setGrammarContent] = useState('');
  
  // UI state
  const [activeTab, setActiveTab] = useState('chat');
  const tabs = [
    { id: 'chat', name: 'Chat' },
    { id: 'tokenization', name: 'Tokenization' },
    { id: 'embeddings', name: 'Embeddings' },
    { id: 'lora', name: 'LoRA' },
    { id: 'multimodal', name: 'Multimodal' },
    { id: 'grammar', name: 'Grammar' }
  ];

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

  // Tokenization APIs
  const handleTokenize = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.tokenize(tokenizeText);
      setTokens(result.tokens);
    } catch (error) {
      Alert.alert('Error', 'Tokenization failed: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleDetokenize = async () => {
    try {
      if (tokens.length === 0) {
        Alert.alert('Error', 'No tokens to detokenize');
        return;
      }
      setIsGenerating(true);
      const result = await LlamaMobile.detokenize(tokens);
      setDetokenizeText(result.text);
    } catch (error) {
      Alert.alert('Error', 'Detokenization failed: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Embeddings API
  const handleGenerateEmbeddings = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.generateEmbeddings(embedText);
      setEmbeddings(result.embeddings);
    } catch (error) {
      Alert.alert('Error', 'Embeddings generation failed: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // LoRA adapters APIs
  const handleApplyLora = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.applyLoraAdapters([{ 
        path: loraPath, 
        scale: loraScale 
      }]);
      setLoraApplied(result.success);
      if (result.success) {
        Alert.alert('Success', 'LoRA adapter applied successfully');
      } else {
        Alert.alert('Error', 'Failed to apply LoRA adapter');
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to apply LoRA adapter: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleRemoveLora = async () => {
    try {
      setIsGenerating(true);
      await LlamaMobile.removeLoraAdapters();
      setLoraApplied(false);
      Alert.alert('Success', 'LoRA adapters removed successfully');
    } catch (error) {
      Alert.alert('Error', 'Failed to remove LoRA adapters: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Multimodal APIs
  const handleInitMultimodal = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.initMultimodal(mmprojPath, false);
      setMultimodalEnabled(result.success);
      if (result.success) {
        Alert.alert('Success', 'Multimodal support enabled');
      } else {
        Alert.alert('Error', 'Failed to enable multimodal support');
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to enable multimodal: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleReleaseMultimodal = async () => {
    try {
      setIsGenerating(true);
      await LlamaMobile.releaseMultimodal();
      setMultimodalEnabled(false);
      Alert.alert('Success', 'Multimodal support released');
    } catch (error) {
      Alert.alert('Error', 'Failed to release multimodal: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleMultimodalCompletion = async () => {
    try {
      if (!multimodalEnabled) {
        Alert.alert('Error', 'Multimodal support not enabled');
        return;
      }
      setIsGenerating(true);
      const result = await LlamaMobile.multimodalCompletion({
        prompt: prompt,
        maxTokens: 128
      }, [imagePath]);
      setResponse(result.output);
    } catch (error) {
      Alert.alert('Error', 'Multimodal completion failed: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Conversation APIs
  const handleGenerateConversationResponse = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.generateResponse(conversationMessage, 128);
      setConversationResponse(result.text);
      setConversationHistory(prev => [...prev, 
        { role: 'user', content: conversationMessage },
        { role: 'assistant', content: result.text }
      ]);
    } catch (error) {
      Alert.alert('Error', 'Conversation response generation failed: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleClearConversation = async () => {
    try {
      await LlamaMobile.clearConversation();
      setConversationHistory([]);
      setConversationResponse('');
      Alert.alert('Success', 'Conversation cleared');
    } catch (error) {
      Alert.alert('Error', 'Failed to clear conversation: ' + error.message);
    }
  };

  // Grammar API
  const handleGetGrammarContent = async () => {
    try {
      setIsGenerating(true);
      const result = await LlamaMobile.getGrammarContent({ grammarName: grammarName });
      setGrammarContent(result.content);
    } catch (error) {
      Alert.alert('Error', 'Failed to get grammar content: ' + error.message);
    } finally {
      setIsGenerating(false);
    }
  };

  // Render tab buttons
  const renderTabs = () => {
    return (
      <View style={styles.tabContainer}>
        {tabs.map(tab => (
          <TouchableOpacity
            key={tab.id}
            style={[
              styles.tabButton,
              activeTab === tab.id && styles.tabButtonActive
            ]}
            onPress={() => setActiveTab(tab.id)}
          >
            <Text
              style={[
                styles.tabText,
                activeTab === tab.id && styles.tabTextActive
              ]}
            >
              {tab.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    );
  };

  // Render chat tab
  const renderChatTab = () => {
    return (
      <View>
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
      </View>
    );
  };

  // Render tokenization tab
  const renderTokenizationTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Tokenize Text</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Enter text to tokenize..."
            value={tokenizeText}
            onChangeText={setTokenizeText}
            multiline
            numberOfLines={3}
          />
          <Button
            title="Tokenize"
            onPress={handleTokenize}
            disabled={isGenerating || !modelLoaded}
          />
        </View>

        {tokens.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Tokens ({tokens.length})</Text>
            <View style={styles.response}>
              <Text>{tokens.slice(0, 20).join(', ')} {tokens.length > 20 ? '...' : ''}</Text>
            </View>
            <Button
              title="Detokenize"
              onPress={handleDetokenize}
              disabled={isGenerating || !modelLoaded || tokens.length === 0}
            />
          </View>
        )}

        {detokenizeText && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Detokenized Text</Text>
            <View style={styles.response}>
              <Text>{detokenizeText}</Text>
            </View>
          </View>
        )}
      </View>
    );
  };

  // Render embeddings tab
  const renderEmbeddingsTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Generate Embeddings</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Enter text to embed..."
            value={embedText}
            onChangeText={setEmbedText}
            multiline
            numberOfLines={3}
          />
          <Button
            title="Generate Embeddings"
            onPress={handleGenerateEmbeddings}
            disabled={isGenerating || !modelLoaded}
          />
        </View>

        {embeddings.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Embeddings (Dimension: {embeddings.length})</Text>
            <View style={styles.response}>
              <Text>{embeddings.slice(0, 10).map(e => e.toFixed(4)).join(', ')} {embeddings.length > 10 ? '...' : ''}</Text>
            </View>
          </View>
        )}
      </View>
    );
  };

  // Render LoRA tab
  const renderLoraTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>LoRA Adapter</Text>
          <TextInput
            style={styles.input}
            placeholder="LoRA Adapter Path"
            value={loraPath}
            onChangeText={setLoraPath}
          />
          <TextInput
            style={styles.input}
            placeholder="LoRA Scale"
            value={loraScale.toString()}
            onChangeText={(text) => setLoraScale(parseFloat(text) || 1.0)}
            keyboardType="numeric"
          />
          <View style={styles.buttonRow}>
            <Button
              title="Apply LoRA"
              onPress={handleApplyLora}
              disabled={isGenerating || !modelLoaded}
            />
            <Button
              title="Remove LoRA"
              onPress={handleRemoveLora}
              disabled={isGenerating || !modelLoaded || !loraApplied}
            />
          </View>
          <Text style={styles.status}>
            LoRA Applied: {loraApplied ? '✅' : '❌'}
          </Text>
        </View>
      </View>
    );
  };

  // Render multimodal tab
  const renderMultimodalTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Multimodal Configuration</Text>
          <TextInput
            style={styles.input}
            placeholder="MMProj Path"
            value={mmprojPath}
            onChangeText={setMmprojPath}
          />
          <View style={styles.buttonRow}>
            <Button
              title="Enable Multimodal"
              onPress={handleInitMultimodal}
              disabled={isGenerating || !modelLoaded || multimodalEnabled}
            />
            <Button
              title="Release Multimodal"
              onPress={handleReleaseMultimodal}
              disabled={isGenerating || !modelLoaded || !multimodalEnabled}
            />
          </View>
          <Text style={styles.status}>
            Multimodal Enabled: {multimodalEnabled ? '✅' : '❌'}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Multimodal Completion</Text>
          <TextInput
            style={styles.input}
            placeholder="Image Path"
            value={imagePath}
            onChangeText={setImagePath}
          />
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Enter your prompt here..."
            value={prompt}
            onChangeText={setPrompt}
            multiline
            numberOfLines={3}
          />
          <Button
            title="Generate Multimodal Response"
            onPress={handleMultimodalCompletion}
            disabled={isGenerating || !modelLoaded || !multimodalEnabled}
          />
        </View>
      </View>
    );
  };

  // Render grammar tab
  const renderGrammarTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Grammar Support</Text>
          <TextInput
            style={styles.input}
            placeholder="Grammar Name"
            value={grammarName}
            onChangeText={setGrammarName}
          />
          <Button
            title="Get Grammar Content"
            onPress={handleGetGrammarContent}
            disabled={isGenerating || !modelLoaded}
          />
        </View>

        {grammarContent && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Grammar Content</Text>
            <View style={styles.response}>
              <Text>{grammarContent}</Text>
            </View>
          </View>
        )}
      </View>
    );
  };

  // Render conversation tab
  const renderConversationTab = () => {
    return (
      <View>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Conversation</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Enter your message..."
            value={conversationMessage}
            onChangeText={setConversationMessage}
            multiline
            numberOfLines={3}
          />
          <View style={styles.buttonRow}>
            <Button
              title="Send Message"
              onPress={handleGenerateConversationResponse}
              disabled={isGenerating || !modelLoaded}
            />
            <Button
              title="Clear Conversation"
              onPress={handleClearConversation}
              disabled={isGenerating || !modelLoaded || conversationHistory.length === 0}
            />
          </View>
        </View>

        {conversationResponse && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Response</Text>
            <View style={styles.response}>
              <Text>{conversationResponse}</Text>
            </View>
          </View>
        )}

        {conversationHistory.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Conversation History</Text>
            <View style={styles.response}>
              {conversationHistory.map((msg, index) => (
                <View key={index} style={styles.messageRow}>
                  <Text style={styles.messageRole}>{msg.role}: </Text>
                  <Text style={styles.messageContent}>{msg.content}</Text>
                </View>
              ))}
            </View>
          </View>
        )}
      </View>
    );
  };

  // Render active tab content
  const renderActiveTabContent = () => {
    switch (activeTab) {
      case 'chat':
        return renderChatTab();
      case 'tokenization':
        return renderTokenizationTab();
      case 'embeddings':
        return renderEmbeddingsTab();
      case 'lora':
        return renderLoraTab();
      case 'multimodal':
        return renderMultimodalTab();
      case 'grammar':
        return renderGrammarTab();
      case 'conversation':
        return renderConversationTab();
      default:
        return renderChatTab();
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

      {renderTabs()}
      {renderActiveTabContent()}

      {isGenerating && (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Processing...</Text>
        </View>
      )}

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Note: Replace file paths with actual paths to your model files.
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
