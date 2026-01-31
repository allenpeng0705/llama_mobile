//
//  ContentView.swift
//  iOSSDKExample

import SwiftUI
import AVFoundation

// Main application state
class AppState: ObservableObject {
    @Published var isModelLoaded = false
    @Published var modelPath = ""
    @Published var availableModels: [(name: String, path: String)] = []
    @Published var errorMessage: String?
    
    // Additional model paths for multimodal and TTS
    @Published var mmprojModelPath = ""
    @Published var availableMmprojModels: [(name: String, path: String)] = []
    
    @Published var vocoderModelPath = ""
    @Published var availableVocoderModels: [(name: String, path: String)] = []
    
    // LoRA model support
    @Published var loraModelPath = ""
    @Published var availableLoRAModels: [(name: String, path: String)] = []
    
    // Feature flags
    @Published var enableEmbedding = false
    
    // Chat configuration
    @Published var systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone.Please think simple and not reply too many content in <think> </think>, it will truncate the reply simply."
    
    // Feature switches
    @Published var useStreaming = false
    @Published var useCustomTemplate = false
    @Published var useChatMode = true
    @Published var useJsonResponse = true
    
    // Qwen3 chat template - using proper Jinja format
    let qwen3Template = "{%- for message in messages -%}\n" +
                       "  {{- '<|im_start|>' + message.role + '\n' + message.content + '<|im_end|>\n' -}}\n" +
                       "{%- endfor -%}\n" +
                       "{%- if add_generation_prompt -%}\n" +
                       "  {{- '<|im_start|>assistant\n' -}}\n" +
                       "{%- endif -%}"
    
    // LlamaMobile instance - optional since it requires a model path to initialize
    @Published var llamaMobile: LlamaMobile? = nil
    
    

}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            TabView {
                // Chat Tab
                ChatView(appState: appState)
                    .tabItem {
                        Image(systemName: "ellipses.bubble.fill")
                        Text("Chat")
                    }
                    .tag(0)
                
                // Tokenization Tab
                TokenizationTestView(appState: appState)
                    .tabItem {
                        Image(systemName: "number.circle.fill")
                        Text("Tokenize")
                    }
                    .tag(1)
                
                // Embedding Tab
                EmbeddingTestView(appState: appState)
                    .tabItem {
                        Image(systemName: "text.bubble.fill")
                        Text("Embed")
                    }
                    .tag(1)
                
                // LoRA Tab
                LoRATestView(appState: appState)
                    .tabItem {
                        Image(systemName: "gearshape.2.fill")
                        Text("LoRA")
                    }
                    .tag(2)
                
                // Image Tab
                MultimodalTestView(appState: appState)
                    .tabItem {
                        Image(systemName: "camera.badge.ellipsis")
                        Text("Image")
                    }
                    .tag(3)
                

                
                // TTS Tab
                TTSTestView(appState: appState)
                    .tabItem {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("TTS")
                    }
                    .tag(5)
                
                // More Tab
                SettingsView(appState: appState)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("More")
                    }
                    .tag(6)
            }
            .accentColor(.blue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .onAppear {
            // Scan all model files in the models folder
            if let modelsPath = Bundle.main.path(forResource: "models", ofType: nil) {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: modelsPath)
                    
                    // Populate main models (GGUF format)
                    let ggufFiles = files.filter { $0.hasSuffix(".gguf") }
                    appState.availableModels = ggufFiles.map { fileName in
                        (name: fileName, path: modelsPath + "/" + fileName)
                    }
                    
                    // Set default model path if any models are found
                    if let firstModel = appState.availableModels.first {
                        appState.modelPath = firstModel.path
                    }
                    
                    // Populate mmproj models (for multimodal) - show all models plus "Empty" option
                    appState.availableMmprojModels = [
                        (name: "Empty", path: "")
                    ] + appState.availableModels
                    
                    // Set default mmproj model path to "Empty"
                    appState.mmprojModelPath = ""
                    
                    // Populate vocoder models (for TTS) - show all models plus "Empty" option
                    appState.availableVocoderModels = [
                        (name: "Empty", path: "")
                    ] + appState.availableModels
                    
                    // Set default vocoder model path to "Empty"
                    appState.vocoderModelPath = ""
                    
                    // Populate LoRA models - show all models plus "Empty" option
                    appState.availableLoRAModels = [
                        (name: "Empty", path: "")
                    ] + appState.availableModels
                    
                    // Set default LoRA model path to "Empty"
                    appState.loraModelPath = ""
                    
                    
                } catch {
                    print("Error listing models: \(error)")
                }
            }
        }
    }
}

// Message model with proper Identifiable conformance
struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: String
    var text: String
    var thought: String? = nil
}

// Chat View
struct ChatView: View {
    @ObservedObject var appState: AppState
    @State private var message = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Feature Switches
            if appState.isModelLoaded {
                VStack(spacing: 0) {
                    // Streaming Toggle
                    HStack {
                        Text("Streaming:")
                        Toggle(isOn: $appState.useStreaming) {}
                            .tint(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
                    .border(Color.gray.opacity(0.2), width: 0.5)
                    
                    // JSON Response Toggle
                    HStack {
                        Text("JSON Response:")
                        Toggle(isOn: $appState.useJsonResponse) {}
                            .tint(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
                    .border(Color.gray.opacity(0.2), width: 0.5)
                }
            }
            
            if !appState.isModelLoaded {
                VStack(spacing: 20) {
                    Image(systemName: "brain.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    Text("Model Not Loaded")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Please load a model in the Settings tab first.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, useJsonResponse: appState.useJsonResponse)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                        
                        // Placeholder to ensure last message is visible
                        Color.clear
                            .frame(height: 20)
                            .id("bottom")
                    }
                    .background(Color(.systemGroupedBackground))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: messages) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isLoading) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Input area
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $message, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: isLoading ? "hourglass.circle.fill" : "paperplane.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
                .border(.gray.opacity(0.2), width: 1)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Llama Mobile SDK")
        .onTapGesture {
            // Hide keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
        }
    }
    
    
    func sendMessage() {
        guard !message.isEmpty else { return }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        messages.append(Message(role: "user", text: trimmedMessage))
        message = ""
        isLoading = true
        
        Task {
            // Generate response based on selected API approach
            await generateResponse(for: trimmedMessage)
        }
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    
    func generateResponse(for prompt: String) async {
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        do {
            // Create completion parameters based on Chat switch
            var params: LlamaMobile.CompletionParams
            
            if appState.useChatMode {
                // Chat mode: use chatMessages with history
                print("[INFO] Using Chat mode with message history")
                
                // Create chat messages from conversation history
                var chatMessages: [LlamaMobile.ChatMessage] = []
                
                // Add system message
                chatMessages.append(LlamaMobile.ChatMessage(role: "system", content: appState.systemPrompt))
                
                // Add all conversation messages
                for message in messages {
                    chatMessages.append(LlamaMobile.ChatMessage(role: message.role, content: message.text))
                }
                
                // Debug: Log chat messages
                print("[DEBUG] Total chat messages: \(chatMessages.count)")
                for (index, msg) in chatMessages.enumerated() {
                    print("[DEBUG] Message \(index): role=\(msg.role), content=\(msg.content.prefix(50))...")
                }
                
                // Create completion parameters with structured chat messages
                params = LlamaMobile.CompletionParams(chatMessages: chatMessages)
                params.useJsonResponse = appState.useJsonResponse
            } else {
                // Direct prompt mode: use prompt only
                print("[INFO] Using Direct Prompt mode")
                print("[DEBUG] Prompt content: \(prompt)")
                print("[DEBUG] System prompt: \(appState.systemPrompt)")
                
                // Create completion parameters with direct prompt
                // System prompt is set when initializing the model
                params = LlamaMobile.CompletionParams(prompt: prompt)
                /*
                 if !appState.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                 let fullPrompt = "\(appState.systemPrompt)\n\(prompt)"
                 params = LlamaMobile.CompletionParams(prompt: prompt)
                 } else {
                 params = LlamaMobile.CompletionParams(prompt: prompt)
                 }
                 */
            }
            
            // Set common parameters
            params.maxTokens = 4096
            params.temperature = 0.7
            params.topK = 40
            params.topP = 0.9
            params.minP = 0.1
            params.penaltyLastN = 64
            params.penaltyRepeat = 1.0
            params.penaltyFreq = 0.0
            params.penaltyPresent = 0.0
            params.stopSequences = ["<|im_end|>"]
            params.useJsonResponse = appState.useJsonResponse
            
            // Log detailed LLM input parameters for debugging
            print("\n==================================================")
            print("[LLM INPUT DETAILS]")
            print("==================================================")
            print("Mode: \(appState.useChatMode ? "Chat" : "Direct Prompt")")
            print("Streaming: \(appState.useStreaming)")
            print("Template: \(appState.useCustomTemplate ? "Custom Qwen3" : "Built-in")")
            print("JSON Response: \(appState.useJsonResponse)")
            print("Max Tokens: \(params.maxTokens)")
            print("Temperature: \(params.temperature)")
            print("Top K: \(params.topK)")
            print("Top P: \(params.topP)")
            print("Min P: \(params.minP)")
            print("Penalty Repeat: \(params.penaltyRepeat)")
            print("Stop Sequences: \(params.stopSequences)")
            print("==================================================")
            
            // Generate completion based on Streaming switch
            if appState.useStreaming {
                // Use streaming generation
                print("[INFO] Using streaming generation")
                
                // Create a variable to accumulate the response
                var accumulatedResponse = ""
                var isFirstToken = true
                
                // Set up token callback for streaming
                params.tokenCallback = { token in
                    DispatchQueue.main.async {
                        if isFirstToken {
                            // Add initial assistant message
                            self.messages.append(Message(role: "assistant", text: ""))
                            isFirstToken = false
                        }
                        
                        // Update the last message with the new token
                        if var lastMessage = self.messages.last, lastMessage.role == "assistant" {
                            lastMessage.text += token
                            self.messages[self.messages.count - 1] = lastMessage
                        }
                    }
                    accumulatedResponse += token
                    return true // Continue streaming
                }
                
                // Generate completion with streaming
                let result = await Task.detached {
                    appState.llamaMobile?.generateCompletion(with: params)
                }.value
                
                if let result = result {
                    print("[INFO] Streaming completed successfully")
                } else {
                    print("[ERROR] Streaming generation failed")
                    DispatchQueue.main.async {
                        self.appState.errorMessage = "Failed to generate response"
                    }
                }
            } else {
                // Use normal generation
                print("[INFO] Using normal generation")
                
                // Generate completion without streaming
                let result = await Task.detached {
                    appState.llamaMobile?.generateCompletion(with: params)
                }.value
                
                if let result = result {
                    DispatchQueue.main.async {
                        // Log stop sequence detection results from completion result
                        print("\n[STOP SEQUENCE DETAILS]")
                        print("Stopped due to EOS: \(result.stoppedEos)")
                        print("Stopped due to stop sequence: \(result.stoppedWord)")
                        print("Stopped due to max tokens: \(result.stoppedLimit)")
                        if let stoppingWord = result.stoppingWord {
                            print("Stopping word detected: \(stoppingWord)")
                        } else {
                            print("No stopping word detected")
                        }
                        // Log complete raw response from LLM
                        print("\n" + String(repeating: "=", count: 50))
                        print("[RAW MODEL RESPONSE] START (length: \(result.text.count) characters)")
                        print(result.text)
                        print("[RAW MODEL RESPONSE] END")
                        print(String(repeating: "=", count: 50) + "\n")
                        
                        // Clean response by removing ending tags and stop sequences
                        var cleanedText = result.text
                        
                        // Remove ending tags and stop sequences
                        cleanedText = cleanedText.replacingOccurrences(of: "<|im_end|>", with: "")
                        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
                        
                        // Remove stop sequences that might still be present
                        for stopSeq in params.stopSequences {
                            cleanedText = cleanedText.replacingOccurrences(of: stopSeq, with: "")
                        }
                        
                        // Trim whitespace
                        let assistantResponse = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Parse response to extract thought and reply if JSON response is enabled
                        var finalText = assistantResponse
                        var messageThought: String? = nil
                        
                        if appState.useJsonResponse {
                            (finalText, messageThought) = parseResponseForThoughtAndReply(assistantResponse)
                        }
                        
                        // Always append the message to UI
                        print("[DEBUG] Final assistant response: \(finalText)")
                        print("[DEBUG] Extracted thought: \(messageThought ?? "nil")")
                        print("[DEBUG] Current messages count before append: \(self.messages.count)")
                        self.messages.append(Message(role: "assistant", text: finalText, thought: messageThought))
                        print("[DEBUG] Current messages count after append: \(self.messages.count)")
                        print("[DEBUG] Last message: \(self.messages.last?.text ?? "nil")")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.appState.errorMessage = "Failed to generate response"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                // Log complete error information
                print("\n" + String(repeating: "=", count: 50))
                print("[GENERATION ERROR] START")
                print("Error: \(error)")
                print("Error description: \(error.localizedDescription)")
                print("[GENERATION ERROR] END")
                print(String(repeating: "=", count: 50) + "\n")
                
                self.appState.errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
// Parse response to extract thought (between <think> tags) and reply (after </think>)
func parseResponseForThoughtAndReply(_ response: String) -> (String, String?) {
    // First, extract "choices[0]['text']" field content from the JSON response
    var textContent = response
    
    // Try to parse as JSON and extract the "choices[0]['text']" field
    if let data = response.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let choices = json["choices"] as? [[String: Any]],
       let firstChoice = choices.first,
       let extractedText = firstChoice["text"] as? String {
        textContent = extractedText
    }
    
    var thought: String? = nil
    var reply = textContent
    
    // Extract thought if found using simple string operations
    let openingTag = "<think>"
    let closingTag = "</think>"
    
    if let openRange = textContent.range(of: openingTag),
       let closeRange = textContent.range(of: closingTag, options: [], range: openRange.upperBound..<textContent.endIndex) {
        // Extract thought content between tags
        let thoughtRange = openRange.upperBound..<closeRange.lowerBound
        thought = String(textContent[thoughtRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract reply content after closing tag
        let replyRange = closeRange.upperBound..<textContent.endIndex
        reply = String(textContent[replyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    return (reply, thought)
} 

// Message Bubble View Component
struct MessageBubble: View {
    let message: Message
    let useJsonResponse: Bool
    @State private var isShowingThought = false
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    Text(message.text)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Llama")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(message.text)
                        .padding(12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    
                    // Thought button if thought exists and JSON response is enabled
                    if useJsonResponse && message.thought != nil {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Tap action - toggle thought visibility
                                isShowingThought.toggle()
                            }) {
                                Text("Thought")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Thought popup
                        if isShowingThought, let thought = message.thought {
                            ZStack {
                                Text(thought)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .zIndex(1)
                            }
                            .frame(maxWidth: 200)
                            .position(x: 150, y: 30)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
    }
}

// Settings View
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var nGpuLayers = 99
    @State private var nThreads = 4
    @State private var nCtx = 4096
    
    // Download progress variables
    @State private var isDownloading = false
    @State private var downloadProgress = 0.0
    @State private var downloadStatus = ""
    @State private var downloadSpeed = ""
    @State private var downloadSize = ""
    @State private var downloadError: String? = nil
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Model Configuration")) {
                    if appState.availableModels.isEmpty {
                        Text("No models found in the bundle")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        Picker("Select Main Model", selection: $appState.modelPath) {
                            ForEach(appState.availableModels, id: \.path) {
                                Text($0.name)
                                    .tag($0.path)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(appState.isModelLoaded)
                    }
                    
                    // Multimodal (mmproj) model picker - always show picker with "Empty" option
                    Picker("Select MMProj Model", selection: $appState.mmprojModelPath) {
                        ForEach(appState.availableMmprojModels, id: \.path) {
                            Text($0.name)
                                .tag($0.path)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(appState.isModelLoaded)
                    
                    // TTS (vocoder) model picker - always show picker with "Empty" option
                    Picker("Select Vocoder Model", selection: $appState.vocoderModelPath) {
                        ForEach(appState.availableVocoderModels, id: \.path) {
                            Text($0.name)
                                .tag($0.path)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(appState.isModelLoaded)
                    
                    // LoRA model picker - always show picker with "Empty" option
                    Picker("Select LoRA Model", selection: $appState.loraModelPath) {
                        ForEach(appState.availableLoRAModels, id: \.path) {
                            Text($0.name)
                                .tag($0.path)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(appState.isModelLoaded)
                    
                    .disabled(appState.isModelLoaded)
                    
                    // Template Toggle
                    HStack {
                        Text("Custom Template:")
                        Spacer()
                        Toggle(isOn: $appState.useCustomTemplate) {}
                            .tint(.blue)
                    }
                    .disabled(appState.isModelLoaded)
                    
                    Text("Note: Template changes require reloading the model")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("GPU Layers")
                        Spacer()
                        Stepper(value: $nGpuLayers, in: 0...99, step: 1) {
                            Text("\(nGpuLayers)")
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .disabled(appState.isModelLoaded)
                    
                    HStack {
                        Text("Threads")
                        Spacer()
                        Stepper(value: $nThreads, in: 1...8, step: 1) {
                            Text("\(nThreads)")
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .disabled(appState.isModelLoaded)
                    
                    HStack {
                        Text("Context Size")
                        Spacer()
                        Stepper(value: $nCtx, in: 512...4096, step: 512) {
                            Text("\(nCtx)")
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                    .disabled(appState.isModelLoaded)
                }
                
                Section(header: Text("Model Actions")) {
                    Button(action: loadModel) {
                        HStack {
                            Spacer()
                            Text("Load Model")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .disabled(appState.isModelLoaded)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: unloadModel) {
                        HStack {
                            Spacer()
                            Text("Unload Model")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .disabled(!appState.isModelLoaded)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                Section(header: Text("Model Download")) {
                    Button(action: downloadFromHuggingFace) {
                        HStack {
                            Spacer()
                            Text("Download Model from HF")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: downloadFromURL) {
                        HStack {
                            Spacer()
                            Text("Download from URL")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                Section(header: Text("Feature Configuration")) {
                    Toggle("Enable Embedding", isOn: $appState.enableEmbedding)
                }
                
                Section(header: Text("Chat Configuration")) {
                    TextEditor(text: $appState.systemPrompt)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(appState.isModelLoaded)
                    
                    // Chat Mode Toggle
                    HStack {
                        Text("Chat Mode:")
                        Spacer()
                        Toggle(isOn: $appState.useChatMode) {}
                            .tint(.blue)
                    }
                    .disabled(appState.isModelLoaded)
                    
                    Text("Note: Chat mode changes require reloading the model")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Note: System prompt changes require reloading the model")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if appState.isModelLoaded {
                    Section(header: Text("Model Status")) {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text("Loaded")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Multimodal")
                            Spacer()
                            Text(appState.llamaMobile?.isMultimodalEnabled() ?? false ? "Yes" : "No")
                        }
                        
                        HStack {
                            Text("Vision Support")
                            Spacer()
                            Text(appState.llamaMobile?.supportsVision() ?? false ? "Yes" : "No")
                        }
                        
                        HStack {
                            Text("Audio Support")
                            Spacer()
                            Text(appState.llamaMobile?.supportsAudio() ?? false ? "Yes" : "No")
                        }
                    }
                }
                
                if let errorMessage = appState.errorMessage {
                    Section(header: Text("Error")) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            
            // Download progress popup
            if isDownloading {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("Downloading Model")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ProgressView(value: downloadProgress, total: 1.0)
                            .frame(width: 300)
                            .tint(.blue)
                        
                        Text(String(format: "%.1f%%", downloadProgress * 100))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(downloadStatus)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        if !downloadSize.isEmpty {
                            Text(downloadSize)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        if !downloadSpeed.isEmpty {
                            Text(downloadSpeed)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
            
            // Download error popup
            if let error = downloadError {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("Download Error")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            downloadError = nil
                        }) {
                            Text("OK")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    func loadModel() {
        guard !appState.modelPath.isEmpty, FileManager.default.fileExists(atPath: appState.modelPath) else {
            appState.errorMessage = "Please provide a valid model path"
            return
        }
        
        appState.errorMessage = nil
        
        // Configure model with proper embedding support
        var initParams = LlamaMobile.InitParams(modelPath: appState.modelPath)
        initParams.nCtx = Int32(nCtx)
        initParams.nGpuLayers = Int32(nGpuLayers)
        initParams.nThreads = Int32(nThreads)
        initParams.embedding = appState.enableEmbedding
        initParams.poolingType = 0 // Mean pooling
        initParams.embdNormalize = 1 // Normalize embeddings
        initParams.systemPrompt = appState.systemPrompt
        
        // Set custom chat template if Template switch is on
        if appState.useCustomTemplate {
            initParams.chatTemplate = appState.qwen3Template
            print("[INFO] Using custom Qwen3 chat template")
        } else {
            print("[INFO] Using model's built-in chat template")
        }
        
        // Increase batch sizes for TTS support (to handle large audio token batches)
        initParams.nBatch = 1024 // Increase from default 512
        initParams.nUBatch = 1024 // Increase from default 512 - must be >= number of audio tokens
        
        // Enable flash attention for faster GPU performance
        initParams.flashAttention = true
        
        appState.llamaMobile = LlamaMobile(with: initParams)
        
        if let llamaMobile = appState.llamaMobile {
            // Initialize multimodal if mmproj path is provided
            if !appState.mmprojModelPath.isEmpty && FileManager.default.fileExists(atPath: appState.mmprojModelPath) {
                let success = appState.llamaMobile?.initMultimodal(mmprojPath: appState.mmprojModelPath, useGpu: nGpuLayers > 0)
                print("Multimodal initialization: \(success ?? false)")
            }
            
            // Initialize vocoder if vocoder path is provided
            if !appState.vocoderModelPath.isEmpty && FileManager.default.fileExists(atPath: appState.vocoderModelPath) {
                let success = appState.llamaMobile?.initVocoder(vocoderModelPath: appState.vocoderModelPath)
                print("Vocoder initialization: \(success ?? false)")
            }
            
            DispatchQueue.main.async {
                self.appState.isModelLoaded = true
                self.appState.errorMessage = nil
            }
        } else {
            DispatchQueue.main.async {
                self.appState.errorMessage = "Failed to load model. Please check the path and try again."
            }
        }
    }
    
    func unloadModel() {
        // Reset model loaded state
        DispatchQueue.main.async {
            self.appState.isModelLoaded = false
        }
    }
    
    func downloadFromHuggingFace() {
        // Set up download parameters
        let repoID = "microsoft/Phi-3-mini-4k-instruct-gguf"
        let filename = "Phi-3-mini-4k-instruct-q4.gguf"
        let bearerToken = "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"
        
        // Get models directory
        guard let modelsDir = getModelsDirectory() else {
            downloadError = "Failed to get models directory"
            return
        }
        
        // Start download
        startDownload(repoID: repoID, filename: filename, destinationPath: modelsDir, bearerToken: bearerToken, isHuggingFace: true)
    }
    
    func downloadFromURL() {
        // Set up download parameters
        let url = "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
        let filename = "Phi-3-mini-4k-instruct-q4.gguf"
        let bearerToken = "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"
        
        // Get models directory
        guard let modelsDir = getModelsDirectory() else {
            downloadError = "Failed to get models directory"
            return
        }
        
        // Start download
        startDownload(repoID: url, filename: filename, destinationPath: modelsDir, bearerToken: bearerToken, isHuggingFace: false)
    }
    
    func getModelsDirectory() -> String? {
        // Get documents directory
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // Create models directory if it doesn't exist
        let modelsDir = documentsDir.appendingPathComponent("models").path
        
        if !FileManager.default.fileExists(atPath: modelsDir) {
            do {
                try FileManager.default.createDirectory(atPath: modelsDir, withIntermediateDirectories: true)
            } catch {
                print("Error creating models directory: \(error)")
                return nil
            }
        }
        
        return modelsDir
    }
    
    func startDownload(repoID: String, filename: String, destinationPath: String, bearerToken: String, isHuggingFace: Bool) {
        // Reset download state
        downloadProgress = 0.0
        downloadStatus = "Preparing download..."
        downloadSpeed = ""
        downloadSize = ""
        downloadError = nil
        isDownloading = true
        
        // Create local path for the downloaded file
        let localPath = destinationPath + "/" + filename
        
        // Set up progress callback
        let progressCallback: (Float) -> Void = { [ self] progress in
            DispatchQueue.main.async {
                self.downloadProgress = Double(progress)
                self.downloadStatus = "Downloading..."
            }
        }
        
        // Start download in a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Create download parameters
            let params = LlamaMobile.DownloadParams(
                url: repoID,
                localPath: localPath,
                password: bearerToken,
                progressCallback: progressCallback
            )
            
            // Create a temporary LlamaMobile instance to call the download method
            //let tempLlamaMobile = LlamaMobile(modelPath: "")
            let result = appState.llamaMobile?.download(with: params)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isDownloading = false
                
                if result?.success != nil {
                    // Download successful, update available models
                    self.updateAvailableModels()
                } else {
                    // Download failed
                    self.downloadError = result?.errorMessage ?? "Unknown error"
                }
            }
        }
    }
    
    func updateAvailableModels() {
        // Get models directory
        guard let modelsDir = getModelsDirectory() else {
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: modelsDir)
            
            // Populate main models (GGUF format)
            let ggufFiles = files.filter { $0.hasSuffix(".gguf") }
            appState.availableModels = ggufFiles.map { fileName in
                (name: fileName, path: modelsDir + "/" + fileName)
            }
            
            // Set default model path if any models are found
            if let firstModel = appState.availableModels.first {
                appState.modelPath = firstModel.path
            }
            
            // Populate mmproj models (for multimodal) - show all models plus "Empty" option
            appState.availableMmprojModels = [
                (name: "Empty", path: "")
            ] + appState.availableModels
            
            // Set default mmproj model path to "Empty"
            appState.mmprojModelPath = ""
            
            // Populate vocoder models (for TTS) - show all models plus "Empty" option
            appState.availableVocoderModels = [
                (name: "Empty", path: "")
            ] + appState.availableModels
            
            // Set default vocoder model path to "Empty"
            appState.vocoderModelPath = ""
            
            // Populate LoRA models - show all models plus "Empty" option
            appState.availableLoRAModels = [
                (name: "Empty", path: "")
            ] + appState.availableModels
            
            // Set default LoRA model path to "Empty"
            appState.loraModelPath = ""
        } catch {
            print("Error listing models: \(error)")
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024.0 && unitIndex < 3 {
            size /= 1024.0
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", size, units[unitIndex])
    }
}

// Embedding Test View
struct EmbeddingTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = ""
    @State private var embeddingResult = ""
    @State private var isGenerating = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Input Text")) {
                TextField("Enter text to generate embedding...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                    .disabled(isGenerating)
                    .focused($isTextFieldFocused)
            }
            Section {
                Button(action: generateEmbedding) {
                    HStack {
                        Spacer()
                        Text(isGenerating ? "Generating Embedding..." : "Generate Embedding")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.enableEmbedding || !appState.isModelLoaded || isGenerating)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            
            Section(header: Text("Embedding Result")) {
                Text(embeddingResult.isEmpty ? "Embedding will appear here" : embeddingResult)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(nil)
                    .foregroundColor(embeddingResult.isEmpty ? .gray : .primary)
            }
        }
        .navigationTitle("Embedding Test")
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    func generateEmbedding() {
        guard !text.isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        
        Task {
            await performEmbedding(for: trimmedText)
        }
    }
    
    func performEmbedding(for text: String) async {
        defer {
            DispatchQueue.main.async {
                self.isGenerating = false
            }
        }
        
        do {
            if let embedding = appState.llamaMobile?.generateEmbeddings(for: text) {
                DispatchQueue.main.async {
                    self.embeddingResult = formatEmbeddingResult(embedding)
                }
            } else {
                DispatchQueue.main.async {
                    self.embeddingResult = "Failed to generate embedding"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.embeddingResult = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func formatEmbeddingResult(_ embedding: [Float]) -> String {
        let truncatedEmbedding = embedding.prefix(20) // Show only first 20 values
        let formattedValues = truncatedEmbedding.map { String(format: "%.6f", $0) }
        var result = "[\(formattedValues.joined(separator: ", "))"
        
        if embedding.count > 20 {
            result += ", ... (and \(embedding.count - 20) more values)"
        }
        
        result += "\n\nEmbedding dimension: \(embedding.count)"
        return result
    }
}

// TTS Test View
struct TTSTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = ""
    @State private var isGenerating = false
    @State private var isPlaying = false
    @State private var ttsResult = ""
    @State private var audioSamples: [Int16]? = nil
    @State private var sampleRate: Int = 24000 // Default sample rate for TTS models
    @State private var progress: Float = 0.0
    @State private var saveToFile = true
    @State private var outputFilePath = ""
    // Audio playback objects (need to be class-level to persist during playback)
    @State private var audioEngine: AVAudioEngine? = nil
    @State private var playerNode: AVAudioPlayerNode? = nil
    @State private var audioSession: AVAudioSession? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Text Input")) {
                TextField("Enter text to convert to speech...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...8)
                    .disabled(!appState.isModelLoaded || isGenerating)
            }
            
            Section(header: Text("Vocoder Model")) {
                if appState.availableVocoderModels.isEmpty {
                    Text("No vocoder files found for TTS")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    Text("Vocoder model loaded: \((appState.vocoderModelPath as NSString).lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Show whether vocoder is enabled
                if appState.llamaMobile?.isVocoderEnabled() == true {
                    Text("Vocoder enabled")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Vocoder not enabled")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Options")) {
                Toggle("Save to File", isOn: $saveToFile)
                    .disabled(isGenerating)
            }
            
            if isGenerating {
                Section(header: Text("Progress")) {
                    ProgressView(value: progress)
                        .padding(.vertical, 8)
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Section {
                Button(action: generateSpeechAsync) {
                    HStack {
                        Spacer()
                        Text(isGenerating ? "Generating Speech..." : "Generate Speech (Async)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                    appState.llamaMobile?.isVocoderEnabled() == false || 
                    !appState.isModelLoaded || 
                    isGenerating
                )
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: generateSpeechSync) {
                    HStack {
                        Spacer()
                        Text(isGenerating ? "Generating Speech..." : "Generate Speech (Sync)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                    appState.llamaMobile?.isVocoderEnabled() == false || 
                    !appState.isModelLoaded || 
                    isGenerating
                )
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                
                Button(action: playAudio) {
                    HStack {
                        Spacer()
                        Text(isPlaying ? "Playing..." : "Play Audio")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(audioSamples == nil || isPlaying)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
            Section(header: Text("TTS Result")) {
                Text(ttsResult.isEmpty ? "TTS status will appear here" : ttsResult)
                    .lineLimit(nil)
                    .foregroundColor(ttsResult.isEmpty ? .gray : .primary)
            }
        }
        .navigationTitle("TTS Test")
    }
    
    func generateSpeechAsync() {
        guard !text.isEmpty, appState.llamaMobile?.isVocoderEnabled() == true else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        progress = 0.0
        
        Task {
            await performTTSAsync(for: trimmedText)
        }
    }
    
    func generateSpeechSync() {
        guard !text.isEmpty, appState.llamaMobile?.isVocoderEnabled() == true else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        progress = 0.0
        
        Task {
            performTTSSync(for: trimmedText)
        }
    }
    
    func performTTSAsync(for text: String) async {
        defer { DispatchQueue.main.async { self.isGenerating = false } }
        
        // Get the llama mobile instance
        guard let llamaMobile = appState.llamaMobile else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ LlamaMobile instance not available"
            }
            return
        }
        
        // Prepare TTS options
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        options.saveToFile = saveToFile
        if saveToFile {
            let tempDir = NSTemporaryDirectory()
            let tempFileName = "tts_output_async.wav"
            options.outputFilePath = tempDir.appending(tempFileName)
        }
        
        // Generate speech using async API
        let result = await llamaMobile.generateSpeech(
            text: text,
            options: options,
            progressHandler: { value in
                DispatchQueue.main.async {
                    self.progress = value
                }
            }
        )
        
        // Handle result
        switch result {
        case .success(let speechResult):
            DispatchQueue.main.async {
                self.audioSamples = speechResult.audioSamples
                self.sampleRate = speechResult.sampleRate
                self.outputFilePath = speechResult.outputFilePath ?? ""
                
                var resultText = "✅ TTS generation completed successfully.\n"
                resultText += "   - Generated \(speechResult.audioSamples.count) audio samples at \(speechResult.sampleRate) Hz\n"
                resultText += "   - Duration: \(String(format: "%.2f", speechResult.duration)) seconds\n"
                resultText += "   - Method used: \(speechResult.methodUsed)"
                
                if let filePath = speechResult.outputFilePath {
                    resultText += "\n   - Audio saved to: \(filePath)"
                }
                
                self.ttsResult = resultText
            }
        case .failure(let error):
            DispatchQueue.main.async {
                self.ttsResult = "❌ Error generating speech: \(error)"
            }
        }
    }
    
    func performTTSSync(for text: String) {
        defer { DispatchQueue.main.async { self.isGenerating = false } }
        
        // Get the llama mobile instance
        guard let llamaMobile = appState.llamaMobile else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ LlamaMobile instance not available"
            }
            return
        }
        
        // Prepare TTS options
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        options.saveToFile = saveToFile
        if saveToFile {
            let tempDir = NSTemporaryDirectory()
            let tempFileName = "tts_output_sync.wav"
            options.outputFilePath = tempDir.appending(tempFileName)
        }
        
        // Generate speech using sync API
        let result = llamaMobile.generateSpeechSync(text: text, options: options)
        
        // Handle result
        switch result {
        case .success(let speechResult):
            DispatchQueue.main.async {
                self.audioSamples = speechResult.audioSamples
                self.sampleRate = speechResult.sampleRate
                self.outputFilePath = speechResult.outputFilePath ?? ""
                
                var resultText = "✅ TTS generation completed successfully.\n"
                resultText += "   - Generated \(speechResult.audioSamples.count) audio samples at \(speechResult.sampleRate) Hz\n"
                resultText += "   - Duration: \(String(format: "%.2f", speechResult.duration)) seconds\n"
                resultText += "   - Method used: \(speechResult.methodUsed)"
                
                if let filePath = speechResult.outputFilePath {
                    resultText += "\n   - Audio saved to: \(filePath)"
                }
                
                self.ttsResult = resultText
            }
        case .failure(let error):
            DispatchQueue.main.async {
                self.ttsResult = "❌ Error generating speech: \(error)"
            }
        }
    }
    
    func playAudio() {
        guard let samples = audioSamples else {
            DispatchQueue.main.async {
                self.ttsResult += "\n❌ No audio samples available for playback."
            }
            return 
        }
        
        isPlaying = true
        
        Task {
            do {
                print("[DEBUG] Starting audio playback with", samples.count, "samples at", sampleRate, "Hz")
                
                // Set up audio session
                let audioSession = AVAudioSession.sharedInstance()
                print("[DEBUG] Setting up audio session")
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                self.audioSession = audioSession
                print("[DEBUG] Audio session active")
                
                // Convert Int16 samples to Float samples (normalized to -1.0 to 1.0)
                print("[DEBUG] Converting Int16 samples to Float")
                let floatSamples = samples.map { Float($0) / Float(Int16.max) }
                print("[DEBUG] Converted", floatSamples.count, "samples")
                
                // Configure audio engine first
                let audioEngine = AVAudioEngine()
                let playerNode = AVAudioPlayerNode()
                self.audioEngine = audioEngine
                self.playerNode = playerNode
                print("[DEBUG] Created audio engine and player node")
                
                // Create mono audio format for our buffer
                let monoFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)! 
                print("[DEBUG] Created mono audio format:", monoFormat)
                
                // Create buffer
                let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: AVAudioFrameCount(floatSamples.count))!
                buffer.frameLength = buffer.frameCapacity
                print("[DEBUG] Created buffer with capacity:", buffer.frameCapacity, "length:", buffer.frameLength, "channels:", monoFormat.channelCount)
                
                // Copy samples to buffer
                if let floatBuffer = buffer.floatChannelData?[0] {
                    print("[DEBUG] Copying samples to buffer")
                    for (index, sample) in floatSamples.enumerated() {
                        floatBuffer[index] = sample
                    }
                    print("[DEBUG] Samples copied successfully")
                } else {
                    print("[DEBUG] Failed to get floatChannelData")
                    throw NSError(domain: "TTSError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
                }
                
                // Attach player node to engine
                audioEngine.attach(playerNode)
                
                // Connect player node to main mixer with explicit mono format
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: monoFormat)
                print("[DEBUG] Attached and connected player node with mono format")
                
                // Start engine
                try audioEngine.start()
                print("[DEBUG] Audio engine started")
                
                // Schedule the buffer first
                print("[DEBUG] Scheduling buffer for playback")
                playerNode.scheduleBuffer(buffer) { 
                    print("[DEBUG] Buffer playback completed")
                    DispatchQueue.main.async {
                        self.isPlaying = false
                        self.ttsResult += "\n✅ Audio playback completed."
                        
                        // Clean up on main thread
                        self.cleanupAudioResources()
                    }
                }
                
                // Then start playback
                print("[DEBUG] Starting player node playback")
                playerNode.play()
                print("[DEBUG] Player node playback started")
            } catch {
                print("[DEBUG] Audio playback error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.ttsResult += "\n❌ Error playing audio: " + error.localizedDescription
                    
                    // Clean up on main thread
                    self.cleanupAudioResources()
                }
            }
        }
    }
    
    private func cleanupAudioResources() {
        // Stop and clean up audio resources
        playerNode?.stop()
        audioEngine?.stop()
        
        // Deactivate audio session
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        // Reset references
        playerNode = nil
        audioEngine = nil
        audioSession = nil
    }
}

// Tokenization Test View
struct TokenizationTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = "Hello world"
    @State private var tokens: [Int32] = []
    @State private var detokenizedText = ""
    @State private var isProcessing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Text Input")) {
                TextField("Enter text to tokenize...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .disabled(!appState.isModelLoaded || isProcessing)
                    .focused($isTextFieldFocused)
            }
            Section(header: Text("Tokenization")) {
                Button(action: tokenizeText) {
                    HStack {
                        Spacer()
                        Text(isProcessing ? "Tokenizing..." : "Tokenize")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.isModelLoaded || isProcessing)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                if !tokens.isEmpty {
                    Button(action: detokenizeTokens) {
                        HStack {
                            Spacer()
                            Text(isProcessing ? "Detokenizing..." : "Detokenize")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .disabled(isProcessing)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            
            if !tokens.isEmpty {
                Section(header: Text("Tokens")) {
                    Text(formatTokens(tokens))
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(nil)
                }
            }
            
            if !detokenizedText.isEmpty {
                Section(header: Text("Detokenized Result")) {
                    Text(detokenizedText)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .navigationTitle("Tokenization Test")
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    func tokenizeText() {
        guard !text.isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isProcessing = true
        
        Task {
            await performTokenization(for: trimmedText)
        }
    }
    
    func detokenizeTokens() {
        guard !tokens.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            await performDetokenization(for: tokens)
        }
    }
    
    func performTokenization(for text: String) async {
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        // Debug logging
        DispatchQueue.main.async {
            print("[TOKENIZE DEBUG] Tokenize button pressed")
            print("[TOKENIZE DEBUG] Text to tokenize: \(text)")
            print("[TOKENIZE DEBUG] Model loaded: \(self.appState.isModelLoaded)")
            print("[TOKENIZE DEBUG] LlamaMobile instance: \(self.appState.llamaMobile != nil ? "Available" : "Nil")")
        }
        
        // Check if llamaMobile is available
        guard let llamaMobile = appState.llamaMobile else {
            DispatchQueue.main.async {
                print("[TOKENIZE ERROR] LlamaMobile instance not available")
                self.appState.errorMessage = "LlamaMobile instance not available"
            }
            return
        }
        

        
        // Try to tokenize text
        if let tokenized = llamaMobile.tokenize(text: text) {
            DispatchQueue.main.async {
                print("[TOKENIZE DEBUG] Tokenization successful, tokens: \(tokenized)")
                self.tokens = tokenized
                self.detokenizedText = ""
                // Clear any previous error messages
                self.appState.errorMessage = nil
            }
        } else {
            DispatchQueue.main.async {
                print("[TOKENIZE ERROR] Tokenization failed")
                self.appState.errorMessage = "Failed to tokenize text"
            }
        }
    }
    
    func performDetokenization(for tokens: [Int32]) async {
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        // Debug logging
        DispatchQueue.main.async {
            print("[DETOKENIZE DEBUG] Detokenize button pressed")
            print("[DETOKENIZE DEBUG] Tokens to detokenize: \(tokens)")
            print("[DETOKENIZE DEBUG] Model loaded: \(self.appState.isModelLoaded)")
            print("[DETOKENIZE DEBUG] LlamaMobile instance: \(self.appState.llamaMobile != nil ? "Available" : "Nil")")
        }
        
        // Check if llamaMobile is available
        guard let llamaMobile = appState.llamaMobile else {
            DispatchQueue.main.async {
                print("[DETOKENIZE ERROR] LlamaMobile instance not available")
                self.appState.errorMessage = "LlamaMobile instance not available"
            }
            return
        }
        
        // Try to detokenize tokens
        if let detokenized = llamaMobile.detokenize(tokens: tokens) {
            DispatchQueue.main.async {
                print("[DETOKENIZE DEBUG] Detokenization successful, result: \(detokenized)")
                self.detokenizedText = detokenized
                // Clear any previous error messages
                self.appState.errorMessage = nil
            }
        } else {
            DispatchQueue.main.async {
                print("[DETOKENIZE ERROR] Detokenization failed")
                self.appState.errorMessage = "Failed to detokenize tokens"
                // Clear detokenized text on failure
                self.detokenizedText = ""
            }
        }
    }
    
    func formatTokens(_ tokens: [Int32]) -> String {
        let tokenStrings = tokens.prefix(20).map { String($0) }
        var result = tokenStrings.joined(separator: ", ")
        
        if tokens.count > 20 {
            result += ", ... (and \(tokens.count - 20) more tokens)"
        }
        
        result += "\n\nTotal tokens: \(tokens.count)"
        return result
    }
}

// LoRA Adapters Test View
struct LoRATestView: View {
    @ObservedObject var appState: AppState
    @State private var scale: Float = 1.0
    @State private var isProcessing = false
    @State private var loraApplied = false
    
    var body: some View {
        Form {
            Section(header: Text("LoRA Adapter Configuration")) {
                TextField("LoRA Adapter Path", text: Binding( 
                    get: { appState.loraModelPath },
                    set: { _ in } // Read-only since we select from settings
                ))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true) // Always disabled, select from Settings
                
                TextField("LoRA Scale", value: $scale, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .disabled(!appState.isModelLoaded || isProcessing)
            }
            
            Section(header: Text("LoRA Actions")) {
                Button(action: applyLoRA) {
                    HStack {
                        Spacer()
                        Text(isProcessing ? "Applying LoRA..." : "Apply LoRA")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(appState.loraModelPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.isModelLoaded || isProcessing || loraApplied)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: removeLoRA) {
                    HStack {
                        Spacer()
                        Text(isProcessing ? "Removing LoRA..." : "Remove LoRA")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(!loraApplied || !appState.isModelLoaded || isProcessing)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            
            Section(header: Text("Status")) {
                Text(loraApplied ? "✅ LoRA adapter applied successfully" : "❌ No LoRA adapter applied")
                    .fontWeight(.medium)
                    .foregroundColor(loraApplied ? .green : .red)
            }
        }
        .navigationTitle("LoRA Adapters Test")
    }
    
    func applyLoRA() {
        guard !appState.loraModelPath.isEmpty else { return }
        
        let trimmedPath = appState.loraModelPath.trimmingCharacters(in: .whitespacesAndNewlines)
        isProcessing = true
        
        Task {
            await performApplyLoRA(path: trimmedPath)
        }
    }
    
    func removeLoRA() {
        isProcessing = true
        
        Task {
            await performRemoveLoRA()
        }
    }
    
    func performApplyLoRA(path: String) async {
        var success = false
        var errorMessage: String?
        
        do {
            let loraAdapter = LlamaMobile.LoraAdapter(path: path, scale: scale)
            success = appState.llamaMobile?.applyLoraAdapters([loraAdapter]) ?? false
            if !success {
                errorMessage = "Failed to apply LoRA adapter"
            }
        } catch {
            errorMessage = "Error applying LoRA adapter: \(error.localizedDescription)"
        }
        
        // Update all UI states in a single main thread dispatch
        DispatchQueue.main.async {
            self.isProcessing = false
            if success {
                self.loraApplied = true
            } else if let errorMessage = errorMessage {
                self.appState.errorMessage = errorMessage
            }
        }
    }
    
    func performRemoveLoRA() async {
        var errorMessage: String?
        
        do {
            appState.llamaMobile?.removeLoraAdapters()
        } catch {
            errorMessage = "Error removing LoRA adapter: \(error.localizedDescription)"
        }
        
        // Update all UI states in a single main thread dispatch
        DispatchQueue.main.async {
            self.isProcessing = false
            self.loraApplied = false
            if let errorMessage = errorMessage {
                self.appState.errorMessage = errorMessage
            }
        }
    }
}



// Multimodal Test View
struct MultimodalTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = ""
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImagePath: String? = nil
    @State private var isImagePickerPresented = false
    @State private var completionResult = ""
    @State private var isGenerating = false
    
    var body: some View {
        Form {
            Section(header: Text("Image Input")) {
                Button(action: selectImage) {
                    HStack {
                        Spacer()
                        if selectedImage != nil {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        } else {
                            Text("Select Image")
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
                .disabled(!appState.isModelLoaded)
            }
            
            Section(header: Text("MMProj Model")) {
                if appState.availableMmprojModels.isEmpty {
                    Text("No mmproj models found for multimodal")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    Text("MMProj model loaded: \((appState.mmprojModelPath as NSString).lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Show whether multimodal is enabled
                if appState.llamaMobile?.isMultimodalEnabled() == true {
                    Text("Multimodal enabled")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Multimodal not enabled")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Text Input")) {
                TextField("Enter text prompt...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                    .disabled(!appState.isModelLoaded || isGenerating)
            }
            
            Section {
                Button(action: generateCompletion) {
                    HStack {
                        Spacer()
                        Text(isGenerating ? "Generating Completion..." : "Generate Completion")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                    selectedImagePath == nil || 
                    appState.llamaMobile?.isMultimodalEnabled() == false || 
                    !appState.isModelLoaded || 
                    isGenerating
                )
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            
            Section(header: Text("Completion Result")) {
                Text(completionResult.isEmpty ? "Completion will appear here" : completionResult)
                    .lineLimit(nil)
                    .foregroundColor(completionResult.isEmpty ? .gray : .primary)
            }
        }
        .navigationTitle("Multimodal Test")
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage, selectedImagePath: $selectedImagePath)
        }
    }
    
    func selectImage() {
        isImagePickerPresented = true // Trigger sheet
    }
    
    func generateCompletion() {
        guard !text.isEmpty, let imagePath = selectedImagePath, appState.llamaMobile?.isMultimodalEnabled() == true else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        
        Task {
            await performMultimodalCompletion(for: trimmedText, imagePath: imagePath)
        }
    }
    
    func performMultimodalCompletion(for text: String, imagePath: String) async {
        defer {
            DispatchQueue.main.async {
                self.isGenerating = false
            }
        }
        
        do {
            
            var params = LlamaMobile.CompletionParams(
                prompt: text,
                maxTokens: 1024,
                temperature: 0.7,
                topK: 40,
                topP: 0.9
            )
            params.mediaPaths = [imagePath]
            
            if let result = await Task.detached { appState.llamaMobile?.generateCompletion(with: params) }.value {
                DispatchQueue.main.async {
                    self.completionResult = result.text
                }
            } else {
                DispatchQueue.main.async {
                    self.completionResult = "Failed to generate multimodal completion"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.completionResult = "Error: \(error.localizedDescription)"
            }
        }
    }
}

// Image Picker Helper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImagePath: String?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                
                // Save image to temporary directory for processing
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let tempDir = NSTemporaryDirectory()
                    let tempPath = tempDir + "selected_image.jpg"
                    do {
                        try imageData.write(to: URL(fileURLWithPath: tempPath))
                        parent.selectedImagePath = tempPath
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.selectedImagePath = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Info View
struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // SDK Info
                Section(header: Text("SDK Information").font(.title2).fontWeight(.bold)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: Llama Mobile SDK")
                        Text("Version: 1.0.0")
                        Text("Platform: iOS")
                        Text("Language: Swift")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Features
                Section(header: Text("Features").font(.title2).fontWeight(.bold)) {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "checkmark.circle.fill", text: "Native Swift Interface")
                        FeatureRow(icon: "brain.circle.fill", text: "LLaMA Model Inference")
                        FeatureRow(icon: "bolt.circle.fill", text: "GPU Acceleration")
                        FeatureRow(icon: "camera.circle.fill", text: "Multimodal Support")
                        FeatureRow(icon: "mic.circle.fill", text: "Audio Processing")
                        FeatureRow(icon: "doc.text.magnifyingglass.fill", text: "Embeddings")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Usage Example
                Section(header: Text("Basic Usage").font(.title2).fontWeight(.bold)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Load a model in the Settings tab")
                        Text("2. Switch to the Chat tab")
                        Text("3. Type your message and send")
                        Text("4. Receive AI-generated response")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Model Requirements
                Section(header: Text("Model Requirements").font(.title2).fontWeight(.bold)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("- GGUF format models only")
                        Text("- Compatible with LLaMA architecture")
                        Text("- Place models in the 'models' folder")
                        Text("- Large models may require GPU acceleration")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Info")
    }
}

// Helper Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
