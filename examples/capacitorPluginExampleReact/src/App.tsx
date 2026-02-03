import { useState, useEffect, useRef } from 'react';
import { LlamaMobileCapacitorPlugin } from '../../../llama_mobile-capacitor-plugin/src/index';
import './App.css';
import Chat from './components/Chat';
import Embed from './components/Embed';
import Image from './components/Image';
import TTS from './components/TTS';
import More from './components/More';
import { Message, ModelInfo } from './types';

// Extend Window interface to include Capacitor
declare global {
  interface Window {
    Capacitor?: {
      getPlatform: () => string;
    };
  }
}


function App() {
  // State
  const [activeTab, setActiveTab] = useState<string>('chat');
  const [modelPath, setModelPath] = useState<string>(() => {
    // Load from localStorage to persist across re-mounts
    const savedPath = localStorage.getItem('modelPath');
    console.log('Loading modelPath from localStorage:', savedPath);
    return savedPath || '';
  });
  const [nCtx, setNCtx] = useState<number>(2048);
  const [nGpuLayers, setNGpuLayers] = useState<number>(16);
  const [nThreads, setNThreads] = useState<number>(4);
  const [inputMessage, setInputMessage] = useState<string>('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [generatedText, setGeneratedText] = useState<string>('');
  const [embeddingText, setEmbeddingText] = useState<string>('Hello, world!');
  const [embeddings, setEmbeddings] = useState<number[]>([]);
  const [ttsText, setTtsText] = useState<string>('Good Morning, how are you?');
  const [mmprojModelPath, setMmprojModelPath] = useState<string>(() => {
    // Load from localStorage to persist across re-mounts
    const savedPath = localStorage.getItem('mmprojModelPath');
    console.log('Loading mmprojModelPath from localStorage:', savedPath);
    return savedPath || '';
  });
  const [vocoderModelPath, setVocoderModelPath] = useState<string>('');
  const [loraPath, setLoraPath] = useState<string>('');
  const [loraScale, setLoraScale] = useState<number>(0.8);
  
  // Download state
  const [isDownloading, setIsDownloading] = useState<boolean>(false);
  const [downloadProgress, setDownloadProgress] = useState<number>(0);
  const [downloadStatus, setDownloadStatus] = useState<string>('');
  const [downloadError, setDownloadError] = useState<string>('');
  
  // Download form state
  const [hfRepoId, setHfRepoId] = useState<string>('meta-llama/Llama-3.2-1B-Instruct');
  const [hfFilename, setHfFilename] = useState<string>('Llama-3.2-1B-Instruct.Q4_K_M.gguf');
  const [hfBearerToken, setHfBearerToken] = useState<string>('');
  
  // TTS audio state
  const [audioSamples, setAudioSamples] = useState<number[]>([]);
  const [audioFilePath, setAudioFilePath] = useState<string>('');
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  
  // Image-multimodal state
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [selectedImagePath, setSelectedImagePath] = useState<string | null>(null);
  const [multimodalText, setMultimodalText] = useState<string>('');
  const [multimodalResult, setMultimodalResult] = useState<string>('');
  const [isMultimodalEnabled, setIsMultimodalEnabled] = useState<boolean>(false);
  const [enableEmbedding, setEnableEmbedding] = useState<boolean>(false);
  
  // New switch states
  const [customTemplate, setCustomTemplate] = useState<boolean>(false);
  const [chatMode, setChatMode] = useState<boolean>(true);
  const [streaming, setStreaming] = useState<boolean>(false);
  const [jsonResponse, setJsonResponse] = useState<boolean>(true);
  
  // Model selection state
  const [availableModels, setAvailableModels] = useState<ModelInfo[]>([]);
  const [availableMmprojModels, setAvailableMmprojModels] = useState<ModelInfo[]>([]);
  const [availableVocoderModels, setAvailableVocoderModels] = useState<ModelInfo[]>([]);
  const [availableLoraModels, setAvailableLoraModels] = useState<ModelInfo[]>([]);
  const [selectedGrammar, setSelectedGrammar] = useState<string | null>(null);
  const [availableGrammars] = useState<string[]>(['json', 'json_arr', 'list', 'arithmetic', 'c', 'chess', 'english', 'japanese']);
  
  // Internal state
  const [contextHandle, setContextHandle] = useState<number>(-1);
  const [isModelInitialized, setIsModelInitialized] = useState<boolean>(false);
  const [isVocoderInitialized, setIsVocoderInitialized] = useState<boolean>(false);
  const chatMessagesRef = useRef<HTMLDivElement>(null);
  

  // Initialize model
  const initializeModel = async () => {
    try {
      console.log('Initializing model with modelPath:', modelPath);
      console.log('Initializing model with mmprojModelPath:', mmprojModelPath);
      
      // Resolve model paths using Filesystem API
      const resolvedModelPath = await resolveModelPath(modelPath);
      const resolvedMmprojModelPath = mmprojModelPath ? await resolveModelPath(mmprojModelPath) : '';
      
      console.log('Resolved model path:', resolvedModelPath);
      console.log('Resolved mmproj model path:', resolvedMmprojModelPath);
      
      const result = await LlamaMobileCapacitorPlugin.initContext({
        modelPath: resolvedModelPath,
        nCtx: nCtx,
        nGpuLayers: 99,//nGpuLayers,
        nThreads: nThreads,
        embedding: enableEmbedding,
        poolingType: 0,
        embdNormalize: 1
      });
      
      console.log('Model init result:', result);
      console.log('Context handle returned:', result.contextHandle);
      
      if (result.contextHandle && result.contextHandle !== 0) {
        setContextHandle(result.contextHandle);
        setIsModelInitialized(true);
        console.log('Model initialized successfully:', result.contextHandle);
        console.log('modelPath after initialization:', modelPath);
        console.log('mmprojModelPath after initialization:', mmprojModelPath);
      } else {
        console.error('Model initialization failed: invalid context handle');
        alert('Model initialization failed: Invalid context handle returned');
        return;
      }
      
      // Automatically initialize multimodal if MMProj model is selected
      if (resolvedMmprojModelPath) {
        try {
          console.log('Initializing multimodal with mmprojPath:', resolvedMmprojModelPath);
          console.log('Current modelPath during multimodal init:', modelPath);
          const multimodalResult = await LlamaMobileCapacitorPlugin.initMultimodal({
            contextHandle: result.contextHandle,
            mmprojPath: resolvedMmprojModelPath,
            useGpu: nGpuLayers > 0
          });
          
          console.log('Multimodal init result:', multimodalResult);
          
          if (multimodalResult.success) {
            setIsMultimodalEnabled(true);
            console.log('Multimodal initialized successfully');
            console.log('modelPath after multimodal init:', modelPath);
          } else {
            console.error('Multimodal initialization failed:', multimodalResult);
            alert('Multimodal initialization failed. Please check the MMProj model path.');
          }
        } catch (error) {
          console.error('Error initializing multimodal:', error);
          // Don't block model initialization if multimodal fails
        }
      }
      
      // Automatically initialize vocoder if Vocoder model is selected
      if (vocoderModelPath) {
        try {
          console.log('Initializing vocoder with vocoderPath:', vocoderModelPath);
          const resolvedVocoderModelPath = await resolveModelPath(vocoderModelPath);
          console.log('Resolved vocoder model path:', resolvedVocoderModelPath);
          
          const vocoderResult = await LlamaMobileCapacitorPlugin.initVocoder({
            contextHandle: result.contextHandle,
            vocoderModelPath: resolvedVocoderModelPath
          });
          
          console.log('Vocoder init result:', vocoderResult);
          
          if (vocoderResult.success) {
            setIsVocoderInitialized(true);
            console.log('Vocoder initialized successfully');
          } else {
            console.error('Vocoder initialization failed:', vocoderResult);
            alert('Vocoder initialization failed. Please check the Vocoder model path.');
          }
        } catch (error) {
          console.error('Error initializing vocoder:', error);
          // Don't block model initialization if vocoder fails
        }
      }
    } catch (error) {
      console.error('Error initializing model:', error);
      alert('Error initializing model: ' + (error as Error).message);
    }
  };

  const unloadModel = async () => {
    console.log('Unload model button clicked');
    console.log('Current state - contextHandle:', contextHandle, 'isModelInitialized:', isModelInitialized);
    
    if (!contextHandle || contextHandle === 0) {
      console.warn('No valid context handle to unload. contextHandle:', contextHandle);
      alert('No model loaded to unload');
      return;
    }
    
    try {
      // Release multimodal if enabled
      if (isMultimodalEnabled) {
        try {
          console.log('Attempting to release multimodal with contextHandle:', contextHandle);
          await LlamaMobileCapacitorPlugin.releaseMultimodal({ contextHandle });
          console.log('Multimodal released successfully');
          setIsMultimodalEnabled(false);
        } catch (error) {
          console.error('Error releasing multimodal:', error);
          // Continue anyway - don't block unloading
        }
      }
      
      // Release vocoder if initialized
      try {
        console.log('Checking if vocoder is enabled...');
        const vocoderResult = await LlamaMobileCapacitorPlugin.isVocoderEnabled({ contextHandle });
        console.log('Vocoder enabled:', vocoderResult.enabled);
        if (vocoderResult.enabled) {
          console.log('Releasing vocoder...');
          await LlamaMobileCapacitorPlugin.releaseVocoder({ contextHandle });
          console.log('Vocoder released successfully');
          setIsVocoderInitialized(false);
        }
      } catch (error) {
        console.error('Error checking/releasing vocoder:', error);
        // Continue anyway - don't block unloading
      }
      
      // Release the main context
      console.log('Releasing main context with contextHandle:', contextHandle);
      await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
      console.log('Main context released successfully');
      
      // Update UI state
      setContextHandle(0);
      setIsModelInitialized(false);
      setIsMultimodalEnabled(false);
      setIsVocoderInitialized(false);
      console.log('Model unloaded successfully, UI state updated');
      alert('Model unloaded successfully');
    } catch (error) {
      console.error('Error unloading model:', error);
      console.error('Error details:', JSON.stringify(error));
      alert('Error unloading model: ' + (error as Error).message);
    }
  };
  
  // Resolve model path for different platforms
  const resolveModelPath = async (modelPath: string): Promise<string> => {
    try {
      // Check if we're on a native platform
      if (typeof window !== 'undefined' && window.Capacitor) {
        console.log('Resolving model path for native platform:', modelPath);
        
        // For native platforms, use the Filesystem API to get the URI
        // Model files are stored in the public/models directory, which gets bundled into the app
        // On native platforms, the public directory is bundled into the app's assets
        // We'll use Directory.Data for writable storage, but for bundled files, we need a different approach
        // For now, return the path as-is, assuming the plugin handles asset paths correctly
        console.log('Returning model path for native platform:', modelPath);
        return modelPath;
      } else {
        // For web platform, return the relative path
        console.log('Resolving model path for web platform:', modelPath);
        return `models/${modelPath}`;
      }
    } catch (error) {
      console.error('Error resolving model path:', error);
      // Fallback to the original path if resolution fails
      return modelPath;
    }
  };
  
  // Send message
  // Send message
  const sendMessage = async () => {
    if (!inputMessage.trim()) return;
    if (!isModelInitialized) {
      alert('Please initialize the model first');
      return;
    }
    
    const userMessage = inputMessage;
    setInputMessage('');
    
    // Create the updated messages array with the new user message
    const updatedMessages: Message[] = [
      ...messages,
      {
        role: 'user',
        content: userMessage
      }
    ];
    
    // Update the state
    setMessages(updatedMessages);
    setIsGenerating(true);
    setGeneratedText('');
    
    // Scroll to bottom
    setTimeout(scrollToBottom, 100);
    
    try {
      // Generate response using OpenAI compatible format
      console.log('Generating response with OpenAI compatible format...');
      
      // Create OpenAI JSON format
      const openAIJSON = JSON.stringify({
        messages: [
          {
            role: 'system',
            content: 'You are a helpful assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone.'
          },
          ...updatedMessages.map(msg => ({
            role: msg.role,
            content: msg.content
          }))
        ]
      });
      
      console.log('OpenAI JSON:', openAIJSON);
      
      // Generate response using OpenAI compatible API
      const result = await LlamaMobileCapacitorPlugin.generateOpenAICompletion({
        contextHandle: contextHandle,
        openAIJSON: openAIJSON,
        stopSequences: ["<|im_end|>"]
      });
      
      console.log('Response result:', result);
      console.log('Raw response text from plugin:', result.text);
      console.log('Response text length:', result.text.length);
      
      // Parse the response like in iOS SDK Example
      let assistantResponse = result.text;
      
      // Clean up response by removing ending tags and stop sequences
      console.log('Before cleaning - response text:', assistantResponse);
      assistantResponse = assistantResponse.replace(/<\|im_end\|>/g, '');
      assistantResponse = assistantResponse.replace(/<\|endoftext\|>/g, '');
      
      // Trim whitespace
      let jsonString = assistantResponse.trim();
      console.log('After cleaning - jsonString:', jsonString);
      console.log('Cleaned jsonString length:', jsonString.length);
      console.log('First 100 characters:', jsonString.substring(0, 100));
      console.log('Starts with {:', jsonString.startsWith('{'));
      
      // Try simple JSON parsing to extract the response content
      if (jsonString) {
        try {
          // First try the format used by chat_example.cpp (text field in choices)
          console.log('Attempting to parse JSON with choices.text format...');
          const responseWithTextChoices = JSON.parse(jsonString);
          console.log('Parsed responseWithTextChoices:', responseWithTextChoices);
          if (responseWithTextChoices.choices && responseWithTextChoices.choices.length > 0) {
            if (responseWithTextChoices.choices[0].text) {
              assistantResponse = responseWithTextChoices.choices[0].text.trim();
              console.log('Successfully parsed JSON with choices.text');
              console.log('Extracted content:', assistantResponse);
            }
          }
        } catch (error) {
          console.log('First JSON parsing attempt failed:', error);
          // Try standard OpenAI response format
          try {
            console.log('Attempting to parse standard OpenAI response format...');
            const openAIResponse = JSON.parse(jsonString);
            console.log('Parsed openAIResponse:', openAIResponse);
            if (openAIResponse.choices && openAIResponse.choices.length > 0) {
              const lastChoice = openAIResponse.choices[openAIResponse.choices.length - 1];
              if (lastChoice.message && lastChoice.message.role === 'assistant') {
                if (lastChoice.message.content) {
                  assistantResponse = lastChoice.message.content.trim();
                  console.log('Successfully parsed standard OpenAI response');
                  console.log('Extracted content:', assistantResponse);
                }
              }
            }
          } catch (error) {
            console.log('Second JSON parsing attempt failed:', error);
            // Try parsing as single message
            try {
              console.log('Attempting to parse single message format...');
              const message = JSON.parse(jsonString);
              console.log('Parsed message:', message);
              if (message.content) {
                assistantResponse = message.content.trim();
                console.log('Successfully parsed single message format');
                console.log('Extracted content:', assistantResponse);
              }
            } catch (error) {
              console.log('All JSON parsing attempts failed:', error);
              console.log('Using raw text as fallback');
              console.log('Raw text content:', jsonString);
              // Keep the original cleaned text
              assistantResponse = jsonString;
            }
          }
        }
      } else {
        console.log('Empty jsonString after cleaning');
      }
      console.log('Final assistant response:', assistantResponse);
      
      // Add assistant message to chat
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: assistantResponse
      }]);
      
      // Scroll to bottom
      setTimeout(scrollToBottom, 100);
      
    } catch (error) {
      console.error('Error generating response:', error);
      alert('Error generating response: ' + (error as Error).message);
      
      // Add error message to chat
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: 'I apologize, but I encountered an error generating a response. Please try again.'
      }]);
      
      // Scroll to bottom
      setTimeout(scrollToBottom, 100);
    } finally {
      setIsGenerating(false);
      setGeneratedText('');
    }
  };
  
  // Generate embeddings
  const generateEmbeddings = async () => {
    console.log('Generate embeddings button clicked');
    console.log('Current state - isModelInitialized:', isModelInitialized, 'contextHandle:', contextHandle);
    console.log('Embedding text:', embeddingText);
    
    if (!isModelInitialized) {
      console.warn('Model not initialized, cannot generate embeddings');
      alert('Please initialize the model first');
      return;
    }
    
    if (!contextHandle || contextHandle === 0) {
      console.warn('No valid context handle for embeddings');
      alert('Invalid model context');
      return;
    }
    
    try {
      console.log('Calling generateEmbeddings with contextHandle:', contextHandle);
      console.log('Text for embedding:', embeddingText);
      
      const startTime = Date.now();
      const result = await LlamaMobileCapacitorPlugin.generateEmbeddings({ 
        contextHandle: contextHandle, 
        text: embeddingText 
      });
      const endTime = Date.now();
      
      console.log('Embedding generation completed in:', endTime - startTime, 'ms');
      console.log('Raw embedding result:', result);
      console.log('Embedding array length:', result.embedding?.length || 0);
      console.log('First few values:', result.embedding?.slice(0, 5) || []);
      
      if (!result.embedding || result.embedding.length === 0) {
        console.error('Empty embedding returned!');
        console.error('Model path:', modelPath);
        console.error('Embedding enabled:', enableEmbedding);
        alert('Empty embedding returned. Please check if the model supports embeddings.');
      } else {
        setEmbeddings(result.embedding);
        console.log('Embeddings generated successfully:', result.embedding.length, 'dimensions');
        alert(`Embeddings generated successfully! ${result.embedding.length} dimensions`);
      }
    } catch (error) {
      console.error('Error generating embeddings:', error);
      console.error('Error details:', JSON.stringify(error));
      alert('Error generating embeddings: ' + (error as Error).message);
    }
  };
  
  // Generate audio
  const generateAudio = async () => {
    if (!isModelInitialized || !isVocoderInitialized) {
      alert('Please initialize both model and vocoder first');
      return;
    }
    
    setAudioSamples([]);
    setAudioFilePath('');
    
    try {
      const result = await LlamaMobileCapacitorPlugin.generateAudioFromText({
        contextHandle: contextHandle,
        text: ttsText
      });
      
      console.log('Audio generated successfully:', result.audio.length, 'samples');
      setAudioSamples(result.audio);
      
      // Automatically save to WAV file
      const fileName = 'tts_output_latest.wav';
      const saveResult = await LlamaMobileCapacitorPlugin.saveAudioToWav({
        contextHandle: contextHandle,
        filePath: fileName,
        audioData: result.audio,
        sampleRate: 24000
      });
      
      if (saveResult.success) {
        setAudioFilePath(fileName);
        console.log('Audio saved successfully to:', fileName);
        alert(`Audio generated and saved successfully! ${result.audio.length} samples generated.`);
      } else {
        console.error('Failed to save audio automatically');
        alert(`Audio generated (${result.audio.length} samples) but failed to save automatically.`);
      }
    } catch (error) {
      console.error('Error generating audio:', error);
      alert('Error generating audio: ' + (error as Error).message);
    }
  };
  
  // Play audio from samples using native audio playback
  const playAudio = async () => {
    if (audioSamples.length === 0) {
      alert('No audio samples to play. Please generate audio first.');
      return;
    }
    
    try {
      setIsPlaying(true);
      
      const result = await LlamaMobileCapacitorPlugin.playAudio({
        audioData: audioSamples,
        sampleRate: 24000
      });
      
      if (result.success) {
        console.log('Audio playback started successfully');
        
        // Set a timeout to reset playing state (estimated duration)
        const durationSeconds = audioSamples.length / 24000;
        setTimeout(() => {
          setIsPlaying(false);
          console.log('Audio playback completed');
        }, durationSeconds * 1000 + 500); // Add 500ms buffer
      } else {
        console.error('Failed to play audio');
        setIsPlaying(false);
        alert('Failed to play audio.');
      }
    } catch (error) {
      console.error('Error playing audio:', error);
      setIsPlaying(false);
      alert('Error playing audio: ' + (error as Error).message);
    }
  };
  
  // Apply LoRA adapter
  const applyLora = async () => {
    if (!isModelInitialized) {
      alert('Please initialize the model first');
      return;
    }
    
    try {
      // Resolve LoRA model path
      const resolvedLoraPath = await resolveModelPath(loraPath);
      console.log('Resolved LoRA model path:', resolvedLoraPath);
      
      const result = await LlamaMobileCapacitorPlugin.applyLoraAdapters({
        contextHandle: contextHandle,
        adapters: [{
          path: resolvedLoraPath,
          scale: loraScale
        }]
      });
      
      if (result.success) {
        console.log('LoRA adapter applied successfully');
        alert('LoRA adapter applied successfully!');
      } else {
        console.error('Failed to apply LoRA adapter');
        alert('Failed to apply LoRA adapter');
      }
    } catch (error) {
      console.error('Error applying LoRA adapter:', error);
      alert('Error applying LoRA adapter: ' + (error as Error).message);
    }
  };
  
  // Remove LoRA adapter
  const removeLora = async () => {
    if (!isModelInitialized) {
      alert('Please initialize the model first');
      return;
    }
    
    try {
      await LlamaMobileCapacitorPlugin.removeLoraAdapters({
        contextHandle: contextHandle
      });
      
      console.log('LoRA adapter removed successfully');
      alert('LoRA adapter removed successfully!');
    } catch (error) {
      console.error('Error removing LoRA adapter:', error);
      alert('Error removing LoRA adapter: ' + (error as Error).message);
    }
  };
  
  // Select image
  const selectImage = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    
    input.onchange = async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) {
        console.log('Image selected:', file.name);
        
        // Read file as data URL for preview
        const reader = new FileReader();
        reader.onload = async (event) => {
          const dataUrl = event.target?.result as string;
          setSelectedImage(dataUrl);
          
          // For native platforms, pass the full data URL (including prefix)
          // This allows Swift to detect the image format properly
          if (window.Capacitor) {
            console.log('Data URL length:', dataUrl.length);
            console.log('Data URL prefix:', dataUrl.split(',')[0]);
            setSelectedImagePath(dataUrl);
          } else {
            // On web, just use the filename
            setSelectedImagePath(file.name);
          }
        };
        reader.readAsDataURL(file);
      }
    };
    
    input.click();
  };
  
  // Generate multimodal completion
  const generateMultimodalCompletion = async () => {
    if (!isModelInitialized) {
      alert('Please initialize the model first');
      return;
    }
    
    if (!isMultimodalEnabled) {
      alert('Please initialize multimodal first');
      return;
    }
    
    if (!selectedImagePath) {
      alert('Please select an image first');
      return;
    }
    
    if (!multimodalText.trim()) {
      alert('Please enter a text prompt');
      return;
    }
    
    setMultimodalResult('');
    
    try {
      const result = await LlamaMobileCapacitorPlugin.generateCompletion({
        contextHandle: contextHandle,
        params: {
          prompt: multimodalText,
          maxTokens: 200,
          temperature: 0.7,
          topK: 40,
          topP: 0.9,
          mediaPaths: [selectedImagePath]
        }
      });
      
      setMultimodalResult(result.text);
    } catch (error) {
      console.error('Error generating multimodal completion:', error);
      setMultimodalResult('Error: ' + (error as Error).message);
    }
  };
  
  // Scroll to bottom of chat
  const scrollToBottom = () => {
    if (chatMessagesRef.current) {
      chatMessagesRef.current.scrollTop = chatMessagesRef.current.scrollHeight;
    }
  };
  
  // Scan for available models
  const scanForModels = async () => {
    try {
      console.log('Scanning for models...');
      
      // Model categories for all platforms
      let mainModels: ModelInfo[] = [];
      
      // Try platform detection
      let platform = 'Web';
      try {
        if (typeof window !== 'undefined' && window.Capacitor) {
          platform = window.Capacitor.getPlatform();
          console.log('Platform detected:', platform);
        }
      } catch (error) {
        console.error('Error detecting platform:', error);
        platform = 'Web';
      }
      
      // Try to use listModels method from the plugin if available
      try {
        console.log('Attempting to use LlamaMobileCapacitorPlugin.listModels()');
        const result = await LlamaMobileCapacitorPlugin.listModels();
        console.log('listModels result:', result);
        
        if (result.models && result.models.length > 0) {
          console.log('Found models via listModels:', result.models.length);
          mainModels = result.models.map((model: any) => ({
            name: model.name || model.path.split('/').pop(),
            path: model.path
          }));
        } else {
          console.log('listModels returned no models, using default models');
          // Fallback to default models
          const defaultModels: ModelInfo[] = [
            { name: 'SmolVLM-256M-Instruct-Q8_0.gguf', path: 'SmolVLM-256M-Instruct-Q8_0.gguf' },
            { name: 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf', path: 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf' },
            { name: 'fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf', path: 'fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf' },
            { name: 'Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf', path: 'Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf' },
            { name: 'Qwen3-4B-Q4_K_M.gguf', path: 'Qwen3-4B-Q4_K_M.gguf' },
            { name: 'Qwen3-4B-Q5_K_M.gguf', path: 'Qwen3-4B-Q5_K_M.gguf' },
            { name: 'OuteTTS-0.2-500M-Q6_K.gguf', path: 'OuteTTS-0.2-500M-Q6_K.gguf' },
            { name: 'SmolLM-360M-Instruct.Q6_K.gguf', path: 'SmolLM-360M-Instruct.Q6_K.gguf' },
            { name: 'WavTokenizer-Large-75-F16.gguf', path: 'WavTokenizer-Large-75-F16.gguf' },
            { name: 'Qwen3-Embedding-0.6B-Q8_0.gguf', path: 'Qwen3-Embedding-0.6B-Q8_0.gguf' }
          ];
          mainModels = defaultModels;
        }
      } catch (error) {
        console.log('listModels method not available, using default models:', error);
        // Fallback to default models
        const defaultModels: ModelInfo[] = [
          { name: 'SmolVLM-256M-Instruct-Q8_0.gguf', path: 'SmolVLM-256M-Instruct-Q8_0.gguf' },
          { name: 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf', path: 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf' },
          { name: 'fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf', path: 'fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf' },
          { name: 'Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf', path: 'Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf' },
          { name: 'Qwen3-4B-Q4_K_M.gguf', path: 'Qwen3-4B-Q4_K_M.gguf' },
          { name: 'Qwen3-4B-Q5_K_M.gguf', path: 'Qwen3-4B-Q5_K_M.gguf' },
          { name: 'OuteTTS-0.2-500M-Q6_K.gguf', path: 'OuteTTS-0.2-500M-Q6_K.gguf' },
          { name: 'SmolLM-360M-Instruct.Q6_K.gguf', path: 'SmolLM-360M-Instruct.Q6_K.gguf' },
          { name: 'WavTokenizer-Large-75-F16.gguf', path: 'WavTokenizer-Large-75-F16.gguf' },
          { name: 'Qwen3-Embedding-0.6B-Q8_0.gguf', path: 'Qwen3-Embedding-0.6B-Q8_0.gguf' }
        ];
        mainModels = defaultModels;
      }
      
      console.log(`${platform} models configured:`);
      console.log('All models:', mainModels);

      // Add "Empty" option for all model types
      const emptyOption: ModelInfo = { name: 'Empty', path: '' };
      
      // Set main models for the main dropdown
      console.log('Setting availableModels:', [emptyOption, ...mainModels]);
      setAvailableModels([emptyOption, ...mainModels]);
      
      // Set MMProj models (filter for mmproj models)
      const mmprojModels = mainModels.filter(model => 
        model.name.toLowerCase().includes('mmproj')
      );
      console.log('Setting availableMmprojModels:', [emptyOption, ...mmprojModels]);
      setAvailableMmprojModels([emptyOption, ...mmprojModels]);
      
      // Set vocoder models (filter for vocoder/tts models)
      const vocoderModels = mainModels.filter(model => 
        model.name.toLowerCase().includes('vocoder') ||
        model.name.toLowerCase().includes('tts') ||
        model.name.toLowerCase().includes('outetts') ||
        model.name.toLowerCase().includes('wavtokenizer')
      );
      console.log('Setting availableVocoderModels:', [emptyOption, ...vocoderModels]);
      setAvailableVocoderModels([emptyOption, ...vocoderModels]);
      
      // Set LoRA models (filter for lora models)
      const loraModels = mainModels.filter(model => 
        model.name.toLowerCase().includes('lora')
      );
      console.log('Setting availableLoraModels:', [emptyOption, ...loraModels]);
      setAvailableLoraModels([emptyOption, ...loraModels]);
      
      console.log('Models scanned successfully:');
      console.log('Main models found:', mainModels.length);
      console.log('MMProj models found:', mmprojModels.length);
      console.log('Vocoder models found:', vocoderModels.length);
      console.log('LoRA models found:', loraModels.length);
    } catch (error) {
      console.error('Error scanning for models:', error);
      
      // Fallback to empty options if scanning fails completely
      const emptyOption: ModelInfo = { name: 'Empty', path: '' };
      setAvailableModels([emptyOption]);
      setAvailableMmprojModels([emptyOption]);
      setAvailableVocoderModels([emptyOption]);
      setAvailableLoraModels([emptyOption]);
      
      console.log('Fallback to empty model options due to error');
    }
  };

  // Lifecycle
  // Scan for models when app loads
  useEffect(() => {
    console.log('App mounted');
    scanForModels();
  }, []);

  // Track modelPath changes
  useEffect(() => {
    console.log('modelPath changed:', modelPath);
    // Save model path to localStorage when it changes
    localStorage.setItem('modelPath', modelPath);
    console.log('Saved modelPath to localStorage:', modelPath);
  }, [modelPath]);

  // Track mmprojModelPath changes
  useEffect(() => {
    console.log('mmprojModelPath changed:', mmprojModelPath);
    // Save MMProj model path to localStorage when it changes
    localStorage.setItem('mmprojModelPath', mmprojModelPath);
    console.log('Saved mmprojModelPath to localStorage:', mmprojModelPath);
  }, [mmprojModelPath]);

  // Track availableModels changes
  useEffect(() => {
    console.log('availableModels changed:', availableModels);
  }, [availableModels]);

  // Track availableMmprojModels changes
  useEffect(() => {
    console.log('availableMmprojModels changed:', availableMmprojModels);
  }, [availableMmprojModels]);
  
  // Download model from Hugging Face
  const downloadModel = async () => {
    try {
      setIsDownloading(true);
      setDownloadProgress(0);
      setDownloadStatus('Starting download...');
      setDownloadError('');

      // Add progress listener
      const progressListener = await LlamaMobileCapacitorPlugin.addListener(
        'progress',
        (data: { progress: number }) => {
          const progress = data.progress;
          setDownloadProgress(progress);
          setDownloadStatus(`Downloading... ${(progress * 100).toFixed(0)}%`);
        }
      );

      // Generate local path
      const localPath = `${hfFilename}`;

      // Start download
      const result = await LlamaMobileCapacitorPlugin.downloadHfFile({
        repoId: hfRepoId,
        filename: hfFilename,
        destinationPath: localPath,
        bearerToken: hfBearerToken,
        offline: false
      });

      // Remove progress listener
      await progressListener.remove();

      if (result.success) {
        setDownloadStatus('Download completed!');
        setDownloadProgress(1);
        alert(`Model downloaded successfully to: ${result.localPath}`);
        
        // Rescan for models to include the newly downloaded one
        await scanForModels();
      } else {
        setDownloadError(result.errorMessage || 'Unknown error');
        setDownloadStatus('Download failed');
        alert(`Download failed: ${result.errorMessage || 'Unknown error'}`);
      }
    } catch (error) {
      console.error('Error downloading model:', error);
      setDownloadError(`Error: ${(error as Error).message}`);
      setDownloadStatus('Download failed');
      alert(`Error downloading model: ${(error as Error).message}`);
    } finally {
      setIsDownloading(false);
    }
  };

  // Cleanup model context when component unmounts
  useEffect(() => {
    return () => {
      if (contextHandle !== -1 && contextHandle !== 0) {
        LlamaMobileCapacitorPlugin.releaseContext({
          contextHandle: contextHandle
        }).then(() => {
          console.log('Model context released');
        }).catch((error: any) => {
          console.error('Error releasing context:', error);
        });
      }
    };
  }, [contextHandle]);
  
  return (
    <div className="app-container">
      <header className="app-header">
        <h1>llama_mobile Capacitor React Example</h1>
      </header>
      <main className="app-content">
        <div className="tab-content">
          {/* Chat Tab */}
          {activeTab === 'chat' && (
            <div className="tab-panel">
              <Chat
                messages={messages}
                inputMessage={inputMessage}
                setInputMessage={setInputMessage}
                sendMessage={sendMessage}
                isModelInitialized={isModelInitialized}
                isGenerating={isGenerating}
                generatedText={generatedText}
                streaming={streaming}
                setStreaming={setStreaming}
                jsonResponse={jsonResponse}
                setJsonResponse={setJsonResponse}
              />
            </div>
          )}
          
          {/* Embed Tab */}
          {activeTab === 'embed' && (
            <div className="tab-panel">
              <Embed
                embeddingText={embeddingText}
                setEmbeddingText={setEmbeddingText}
                generateEmbeddings={generateEmbeddings}
                embeddings={embeddings}
                isModelInitialized={isModelInitialized}
              />
            </div>
          )}
          
          {/* Image Tab */}
          {activeTab === 'image' && (
            <div className="tab-panel">
              <Image
                selectedImage={selectedImage}
                selectedImagePath={selectedImagePath}
                multimodalText={multimodalText}
                multimodalResult={multimodalResult}
                setMultimodalText={setMultimodalText}
                selectImage={selectImage}
                generateMultimodalCompletion={generateMultimodalCompletion}
                isModelInitialized={isModelInitialized}
                isMultimodalEnabled={isMultimodalEnabled}
              />
            </div>
          )}
          
          {/* TTS Tab */}
          {activeTab === 'tts' && (
            <div className="tab-panel">
              <TTS
                ttsText={ttsText}
                setTtsText={setTtsText}
                generateAudio={generateAudio}
                playAudio={playAudio}
                audioSamples={audioSamples}
                audioFilePath={audioFilePath}
                isPlaying={isPlaying}
                isModelInitialized={isModelInitialized}
                isVocoderInitialized={isVocoderInitialized}
              />
            </div>
          )}
          
          {/* More Tab */}
          {activeTab === 'more' && (
            <div className="tab-panel">
              <More
                // Model configuration
                modelPath={modelPath}
                setModelPath={setModelPath}
                mmprojModelPath={mmprojModelPath}
                setMmprojModelPath={setMmprojModelPath}
                vocoderModelPath={vocoderModelPath}
                setVocoderModelPath={setVocoderModelPath}
                loraPath={loraPath}
                setLoraPath={setLoraPath}
                selectedGrammar={selectedGrammar}
                setSelectedGrammar={setSelectedGrammar}
                enableEmbedding={enableEmbedding}
                setEnableEmbedding={setEnableEmbedding}
                nGpuLayers={nGpuLayers}
                setNGpuLayers={setNGpuLayers}
                nThreads={nThreads}
                setNThreads={setNThreads}
                nCtx={nCtx}
                setNCtx={setNCtx}
                loraScale={loraScale}
                setLoraScale={setLoraScale}
                
                // New switches
                customTemplate={customTemplate}
                setCustomTemplate={setCustomTemplate}
                chatMode={chatMode}
                setChatMode={setChatMode}
                
                // Download settings
                hfRepoId={hfRepoId}
                setHfRepoId={setHfRepoId}
                hfFilename={hfFilename}
                setHfFilename={setHfFilename}
                hfBearerToken={hfBearerToken}
                setHfBearerToken={setHfBearerToken}
                
                // Status
                availableModels={availableModels}
                availableMmprojModels={availableMmprojModels}
                availableVocoderModels={availableVocoderModels}
                availableLoraModels={availableLoraModels}
                availableGrammars={availableGrammars}
                isModelInitialized={isModelInitialized}
                isDownloading={isDownloading}
                downloadProgress={downloadProgress}
                downloadStatus={downloadStatus}
                downloadError={downloadError}
                
                // Actions
                initializeModel={initializeModel}
                unloadModel={unloadModel}
                applyLora={applyLora}
                removeLora={removeLora}
                downloadModel={downloadModel}
              />
            </div>
          )}
        </div>
        
        {/* Bottom Navigation */}
        <div className="tabs">
          <button 
            className={`tab-button ${activeTab === 'chat' ? 'active' : ''}`}
            onClick={() => setActiveTab('chat')}
          >
            <span className="tab-icon">💬</span>
            <span>Chat</span>
          </button>
          <button 
            className={`tab-button ${activeTab === 'embed' ? 'active' : ''}`}
            onClick={() => setActiveTab('embed')}
          >
            <span className="tab-icon">📝</span>
            <span>Embed</span>
          </button>
          <button 
            className={`tab-button ${activeTab === 'image' ? 'active' : ''}`}
            onClick={() => setActiveTab('image')}
          >
            <span className="tab-icon">📷</span>
            <span>Image</span>
          </button>
          <button 
            className={`tab-button ${activeTab === 'tts' ? 'active' : ''}`}
            onClick={() => setActiveTab('tts')}
          >
            <span className="tab-icon">🔊</span>
            <span>TTS</span>
          </button>
          <button 
            className={`tab-button ${activeTab === 'more' ? 'active' : ''}`}
            onClick={() => setActiveTab('more')}
          >
            <span className="tab-icon">⚙️</span>
            <span>More</span>
          </button>
        </div>
      </main>
    </div>
  );
}

export default App;
