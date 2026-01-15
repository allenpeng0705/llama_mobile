//
//  ContentView.swift
//  iOSSDKExample
//

import SwiftUI

// Main application state
class AppState: ObservableObject {
    @Published var isModelLoaded = false
    @Published var modelPath = ""
    @Published var availableModels: [(name: String, path: String)] = []
    @Published var errorMessage: String?
    
    // Feature flags
    @Published var enableChatting = true
    @Published var enableEmbedding = false
    @Published var enableMultimodal = false
    @Published var enableTTS = false
    
    // Chat configuration
    @Published var systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone."
    
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
                
                // Grammar Tab
                GrammarTestView(appState: appState)
                    .tabItem {
                        Image(systemName: "textformat.fill")
                        Text("Grammar")
                    }
                    .tag(4)
                
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
            // Scan all .gguf files in the models folder and populate availableModels
            if let modelsPath = Bundle.main.path(forResource: "models", ofType: nil) {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: modelsPath)
                    let ggufFiles = files.filter { $0.hasSuffix(".gguf") }
                    
                    // Populate availableModels with name and full path
                    appState.availableModels = ggufFiles.map { fileName in
                        (name: fileName, path: modelsPath + "/" + fileName)
                    }
                    
                    // Set default model path if any models are found
                    if let firstModel = appState.availableModels.first {
                        appState.modelPath = firstModel.path
                    }
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
    let text: String
}

// Chat View
struct ChatView: View {
    @ObservedObject var appState: AppState
    @State private var message = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var jsonGrammar: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
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
                            MessageBubble(message: message)
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
            // JSON grammar loading removed - method no longer exists
        }
    }
    

    
    
    func sendMessage() {
        guard !message.isEmpty else { return }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        messages.append(Message(role: "user", text: trimmedMessage))
        message = ""
        isLoading = true
        
        Task {
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
            // Build conversation history for proper chat flow
            let fullPrompt = buildConversationHistory()
            
            let params = LlamaMobile.CompletionParams(
                prompt: fullPrompt,
                maxTokens: 256,
                temperature: 0.7,
                topK: 40,
                topP: 0.9,
                minP: 0.1,
                penaltyLastN: 64,
                penaltyRepeat: 1.0,
                penaltyFreq: 0.0,
                penaltyPresent: 0.0,
                grammar: jsonGrammar
            )
            
            if let result = appState.llamaMobile?.generateCompletion(with: params) {
                DispatchQueue.main.async {
                    // Log raw response from LLM
                    print("[DEBUG] Raw LLM response: \(result.text)")
                    
                    // Parse the JSON response from LLM
                    do {
                        // Clean up response by removing ending tags only, keep think content
                    var cleanedText = result.text
                    
                    // Remove ending tags
                    cleanedText = cleanedText.replacingOccurrences(of: "<|im_end|>", with: "")
                    cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
                    
                    // Trim whitespace
                    let jsonString = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("[DEBUG] Cleaned JSON string: \(jsonString)")
                        
                        guard let data = jsonString.data(using: .utf8) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON data"))
                        }
                        
                        // Try parsing as standard OpenAI response first (with choices array)
                        do {
                            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                            print("[DEBUG] Successfully parsed as OpenAIResponse: \(response)")
                            if let assistantMessage = response.choices.last?.message, assistantMessage.role == "assistant" {
                                self.messages.append(Message(role: assistantMessage.role, text: assistantMessage.content))
                                return
                            }
                        } catch {
                            print("[DEBUG] Failed to parse as OpenAIResponse: \(error)")
                            // If standard format fails, try parsing as array of messages
                            do {
                                let messages = try JSONDecoder().decode([OpenAIMessage].self, from: data)
                                print("[DEBUG] Successfully parsed as [OpenAIMessage]: \(messages)")
                                if let assistantMessage = messages.last(where: { $0.role == "assistant" }) {
                                    self.messages.append(Message(role: assistantMessage.role, text: assistantMessage.content))
                                    return
                                }
                            } catch {
                                print("[DEBUG] Failed to parse as [OpenAIMessage]: \(error)")
                                // If array parsing fails, try single message
                                do {
                                    let singleMessage = try JSONDecoder().decode(OpenAIMessage.self, from: data)
                                    print("[DEBUG] Successfully parsed as single OpenAIMessage: \(singleMessage)")
                                    if singleMessage.role == "assistant" {
                                        self.messages.append(Message(role: singleMessage.role, text: singleMessage.content))
                                        return
                                    }
                                } catch {
                                    print("[DEBUG] Failed to parse as single OpenAIMessage: \(error)")
                                    // All JSON parsing attempts failed, try to extract assistant content using regex
                                    if let assistantContent = extractAssistantContent(from: cleanedText) {
                                        print("[DEBUG] Successfully extracted assistant content via regex: \(assistantContent)")
                                        self.messages.append(Message(role: "assistant", text: assistantContent))
                                        return
                                    }
                                    // Last resort: use cleaned raw text
                                    print("[DEBUG] Using cleaned raw text as fallback")
                                    self.messages.append(Message(role: "assistant", text: cleanedText))
                                    return
                                }
                            }
                        }
                        
                        // Fallback if parsing succeeds but no assistant message found
                        self.messages.append(Message(role: "assistant", text: cleanedText))
                        
                    } catch {
                        print("[DEBUG] Error parsing LLM response: \(error.localizedDescription)")
                        // Fallback to cleaned text if parsing fails (keep think content)
                        var cleanedText = result.text
                        cleanedText = cleanedText.replacingOccurrences(of: "<|im_end|>", with: "")
                        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
                        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("[DEBUG] Error fallback - cleaned text: \(cleanedText)")
                        
                        // Try to extract assistant content using regex
                        if let assistantContent = extractAssistantContent(from: cleanedText) {
                            print("[DEBUG] Error fallback - regex extracted content: \(assistantContent)")
                            self.messages.append(Message(role: "assistant", text: assistantContent))
                            return
                        }
                        
                        // Last resort: use cleaned raw text
                        print("[DEBUG] Error fallback - using raw cleaned text")
                        self.messages.append(Message(role: "assistant", text: cleanedText))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.appState.errorMessage = "Failed to generate response"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.appState.errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    // Define OpenAI message structure for proper JSON encoding/decoding
    struct OpenAIMessage: Codable {
        let role: String
        let content: String
    }
    
    // Define OpenAI standard response structure (choices array format)
    struct OpenAIResponse: Codable {
        let choices: [OpenAIChoice]
    }
    
    struct OpenAIChoice: Codable {
        let message: OpenAIMessage
    }
    
    // Extract assistant content from malformed JSON using regex
    private func extractAssistantContent(from text: String) -> String? {
        // Try multiple patterns to extract meaningful content
        
        // Pattern 1: Find assistant role with content field
        let assistantPattern = #"role"\s*:\s*"assistant"[^}]*"content"\s*:\s*"([^"]+)"#
        
        // Pattern 2: Find any role with content or input field (handles incorrect user role from LLM)
        let anyContentPattern = #"(content|input)"\s*:\s*"([^"]+)"#
        
        // First try to find assistant content
        if let range = text.range(of: assistantPattern, options: .regularExpression) {
            let match = String(text[range])
            
            // Extract content from the matched string
            let contentPattern = #""content"\s*:\s*"([^"]+)"#
            if let contentRange = match.range(of: contentPattern, options: .regularExpression) {
                let contentMatch = String(match[contentRange])
                
                // Remove "content": " prefix and trailing "
                if let startIndex = contentMatch.range(of: ": \"")?.upperBound,
                   let endIndex = contentMatch.range(of: "\"", options: [], range: startIndex..<contentMatch.endIndex)?.lowerBound {
                    return String(contentMatch[startIndex..<endIndex])
                }
            }
        }
        
        // If assistant content not found, try to find any content or input field
        if let range = text.range(of: anyContentPattern, options: .regularExpression) {
            let match = String(text[range])
            
            // Extract value from the matched string
            let valuePattern = #"\s*:\s*"([^"]+)"#
            if let valueRange = match.range(of: valuePattern, options: .regularExpression) {
                let valueMatch = String(match[valueRange])
                
                // Remove : " prefix and trailing "
                if let startIndex = valueMatch.range(of: ": \"")?.upperBound,
                   let endIndex = valueMatch.range(of: "\"", options: [], range: startIndex..<valueMatch.endIndex)?.lowerBound {
                    return String(valueMatch[startIndex..<endIndex])
                }
            }
        }
        
        return nil
    }
    
    func buildConversationHistory() -> String {
        // Create messages array following OpenAI format
        var messagesArray: [OpenAIMessage] = []
        
        // Add system message
        messagesArray.append(OpenAIMessage(
            role: "system",
            content: appState.systemPrompt
        ))
        
        // Add only the last 10 conversation rounds
        let recentMessages = Array(messages.suffix(20)) // 10 rounds = 20 messages (user + assistant)
        
        // Add user/assistant messages
        for message in recentMessages {
            messagesArray.append(OpenAIMessage(
                role: message.role,
                content: message.text
            ))
        }
        
        // Convert to JSON string using JSONEncoder
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let jsonData = try encoder.encode(messagesArray)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Log the full prompt being sent to LLM
                print("[DEBUG] Prompt sent to LLM: \(jsonString)")
                return jsonString
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
        
        // Fallback to minimal JSON format if encoding fails
        let escapedContent = appState.systemPrompt.replacingOccurrences(of: "\"", with: "\\\"")
        let fallbackPrompt = "[{\"role\":\"system\",\"content\":\"\(escapedContent)\"}]"
        print("[DEBUG] Using fallback prompt: \(fallbackPrompt)")
        return fallbackPrompt
    }
}

// Message Bubble View Component
struct MessageBubble: View {
    let message: Message
    
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
                VStack(alignment: .leading) {
                    Text("Llama")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    Text(message.text)
                        .padding(12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
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
    @State private var nGpuLayers = 4
    @State private var nThreads = 4
    @State private var nCtx = 2048
    
    var body: some View {
        Form {
                Section(header: Text("Model Configuration")) {
                    if appState.availableModels.isEmpty {
                        Text("No models found in the bundle")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        Picker("Select Model", selection: $appState.modelPath) {
                            ForEach(appState.availableModels, id: \.path) {
                                Text($0.name)
                                    .tag($0.path)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(appState.isModelLoaded)
                    }
                    
                    HStack {
                        Text("GPU Layers")
                        Spacer()
                        Stepper(value: $nGpuLayers, in: 0...16, step: 1) {
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
                
                Section(header: Text("Feature Configuration")) {
                    Toggle("Enable Chatting", isOn: $appState.enableChatting)
                    Toggle("Enable Embedding", isOn: $appState.enableEmbedding)
                    Toggle("Enable Multimodal", isOn: $appState.enableMultimodal)
                    Toggle("Enable TTS", isOn: $appState.enableTTS)
                }
                
                Section(header: Text("Chat Configuration")) {
                    TextEditor(text: $appState.systemPrompt)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(appState.isModelLoaded)
                    
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
    }
    
    func loadModel() {
        guard !appState.modelPath.isEmpty, FileManager.default.fileExists(atPath: appState.modelPath) else {
            appState.errorMessage = "Please provide a valid model path"
            return
        }
        
        appState.errorMessage = nil
        
        // Use the public initializer instead of private initialize method
        appState.llamaMobile = LlamaMobile(
            modelPath: appState.modelPath,
            nCtx: Int32(nCtx),
            nGpuLayers: Int32(nGpuLayers),
            nThreads: Int32(nThreads)
        )
        
        if appState.llamaMobile != nil {
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
}

// Embedding Test View
struct EmbeddingTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = ""
    @State private var embeddingResult = ""
    @State private var isGenerating = false
    
    var body: some View {
        Form {
            Section(header: Text("Input Text")) {
                TextField("Enter text to generate embedding...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                    .disabled(!appState.enableEmbedding || !appState.isModelLoaded || isGenerating)
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
    @State private var vocoderPath: String? = nil
    @State private var availableVocoderFiles: [(name: String, path: String)] = []
    @State private var isGenerating = false
    @State private var isPlaying = false
    @State private var ttsResult = ""
    @State private var audioSamples: [Float]? = nil
    @State private var sampleRate: Int = 24000 // Default sample rate for TTS models
    
    var body: some View {
        Form {
            Section(header: Text("Text Input")) {
                TextField("Enter text to convert to speech...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...8)
                    .disabled(!appState.enableTTS || !appState.isModelLoaded || isGenerating)
            }
            
            Section(header: Text("Vocoder Model")) {
                if availableVocoderFiles.isEmpty {
                    Text("No vocoder files found in models folder")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    Picker("Select Vocoder", selection: $vocoderPath) {
                        ForEach(availableVocoderFiles, id: \.path) {
                            Text($0.name)
                                .tag(Optional($0.path))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!appState.enableTTS || !appState.isModelLoaded)
                }
            }
            
            Section {
                Button(action: generateSpeech) {
                    HStack {
                        Spacer()
                        Text(isGenerating ? "Generating Speech..." : "Generate Speech")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                    vocoderPath == nil || 
                    !appState.enableTTS || 
                    !appState.isModelLoaded || 
                    isGenerating
                )
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
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
        .onAppear {
            scanVocoderFiles()
        }
    }
    
    func scanVocoderFiles() {
        if let modelsPath = Bundle.main.path(forResource: "models", ofType: nil) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: modelsPath)
                let vocoderFiles = files.filter { $0.hasSuffix(".bin") }
                
                availableVocoderFiles = vocoderFiles.map { fileName in
                    (name: fileName, path: modelsPath + "/" + fileName)
                }
                
                // Set default vocoder path if any files are found
                if let firstVocoder = availableVocoderFiles.first {
                    vocoderPath = firstVocoder.path
                }
            } catch {
                print("Error listing vocoder files: \(error)")
            }
        }
    }
    
    func generateSpeech() {
        guard !text.isEmpty, let vocoderPath = vocoderPath else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        
        Task {
            await performTTS(for: trimmedText, vocoderPath: vocoderPath)
        }
    }
    
    func performTTS(for text: String, vocoderPath: String) async {
        defer { DispatchQueue.main.async { self.isGenerating = false } }
        
        do {
            // Vocoder checks removed - methods no longer exist
            
            // Format text for TTS
            guard let formattedText = appState.llamaMobile?.getFormattedAudioCompletion(speakerJson: "{}", textToSpeak: text) else {
                DispatchQueue.main.async {
                    self.ttsResult = "Failed to format text for TTS"
                }
                return
            }
            
            // Generate completion with formatted text
            let params = LlamaMobile.CompletionParams(
                prompt: formattedText,
                maxTokens: 500, // Longer for TTS tokens
                temperature: 0.0, // Low temperature for TTS
                topK: 0,
                topP: 0.0
            )
            
            if let result = appState.llamaMobile?.generateCompletion(with: params) {
                // Extract audio tokens from the result
                // Note: The actual implementation might need to parse the result differently
                // depending on the model's output format
                
                // For simplicity, we'll just show the result for now
                DispatchQueue.main.async {
                    self.ttsResult = "TTS generation completed successfully"
                }
                
                // In a real implementation, you would:
                // 1. Extract the audio tokens from the result
                // 2. Decode them with decodeAudioTokens
                // 3. Store the samples for playback
                
                // For demonstration purposes, we'll simulate this step
                DispatchQueue.main.async {
                    self.audioSamples = Array(repeating: 0.0, count: 10000) // Empty samples array
                    self.ttsResult += "\n\nNote: Audio token extraction and decoding would happen here."
                }
            } else {
                DispatchQueue.main.async {
                    self.ttsResult = "Failed to generate TTS tokens"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.ttsResult = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func playAudio() {
        guard let samples = audioSamples else { return }
        
        isPlaying = true
        
        // In a real implementation, you would use AVAudioEngine to play back the audio samples
        // For demonstration purposes, we'll just simulate playback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isPlaying = false
            self.ttsResult += "\n\nNote: Audio playback would happen here with AVAudioEngine."
        }
    }
}

// Tokenization Test View
struct TokenizationTestView: View {
    @ObservedObject var appState: AppState
    @State private var text = "Hello world"
    @State private var tokens: [Int32] = []
    @State private var detokenizedText = ""
    @State private var isProcessing = false
    
    var body: some View {
        Form {
            Section(header: Text("Text Input")) {
                TextField("Enter text to tokenize...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .disabled(!appState.isModelLoaded || isProcessing)
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
        
        do {
            if let tokenized = appState.llamaMobile?.tokenize(text: text) {
                DispatchQueue.main.async {
                    self.tokens = tokenized
                    self.detokenizedText = ""
                }
            } else {
                DispatchQueue.main.async {
                    self.appState.errorMessage = "Failed to tokenize text"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.appState.errorMessage = "Error tokenizing text: \(error.localizedDescription)"
            }
        }
    }
    
    func performDetokenization(for tokens: [Int32]) async {
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        do {
            if let detokenized = appState.llamaMobile?.detokenize(tokens: tokens) {
                DispatchQueue.main.async {
                    self.detokenizedText = detokenized
                }
            } else {
                DispatchQueue.main.async {
                    self.appState.errorMessage = "Failed to detokenize tokens"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.appState.errorMessage = "Error detokenizing tokens: \(error.localizedDescription)"
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
    @State private var loraPath = ""
    @State private var scale: Float = 1.0
    @State private var isProcessing = false
    @State private var loraApplied = false
    
    var body: some View {
        Form {
            Section(header: Text("LoRA Adapter Configuration")) {
                TextField("LoRA Adapter Path", text: $loraPath)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!appState.isModelLoaded || isProcessing)
                
                TextField("LoRA Scale", value: $scale, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .disabled(!appState.isModelLoaded || isProcessing)
            }
            
            Section(header: Text("Apply LoRA Adapter")) {
                Button(action: applyLoRA) {
                    HStack {
                        Spacer()
                        Text(isProcessing ? "Applying LoRA..." : "Apply LoRA")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(loraPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.isModelLoaded || isProcessing)
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
        guard !loraPath.isEmpty else { return }
        
        let trimmedPath = loraPath.trimmingCharacters(in: .whitespacesAndNewlines)
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
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        do {
            let loraAdapter = LlamaMobile.LoraAdapter(path: path, scale: scale)
            if appState.llamaMobile?.applyLoraAdapters([loraAdapter]) ?? false {
                DispatchQueue.main.async {
                    self.loraApplied = true
                }
            } else {
                DispatchQueue.main.async {
                    appState.errorMessage = "Failed to apply LoRA adapter"
                }
            }
        } catch {
            DispatchQueue.main.async {
                appState.errorMessage = "Error applying LoRA adapter: \(error.localizedDescription)"
            }
        }
    }
    
    func performRemoveLoRA() async {
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        do {
            appState.llamaMobile?.removeLoraAdapters()
            DispatchQueue.main.async {
                self.loraApplied = false
            }
        } catch {
            DispatchQueue.main.async {
                appState.errorMessage = "Error removing LoRA adapter: \(error.localizedDescription)"
            }
        }
    }
}

// Grammar Test View
struct GrammarTestView: View {
    @ObservedObject var appState: AppState
    @State private var grammarName = "json"
    @State private var grammarContent = ""
    @State private var prompt = "Generate a JSON object with name, age, and city fields"
    @State private var result = ""
    @State private var isLoading = false
    
    let availableGrammars = ["json", "json_arr", "list", "arithmetic", "c", "chess", "english", "japanese"]
    
    var body: some View {
        Form {
            // Grammar Selection
            Section(header: Text("Grammar Configuration")) {
                Picker("Grammar", selection: $grammarName) {
                    ForEach(availableGrammars, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                
                Button("Get Grammar Content") {
                    Task {
                        await getGrammarContent()
                    }
                }
                
                if !grammarContent.isEmpty {
                    Section(header: Text("Grammar Content")) {
                        Text(grammarContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxHeight: 100)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(8)
                            .scrollContentBackground(.hidden)
                    }
                }
            }
            
            // Generate with Grammar
            Section(header: Text("Generate with Grammar")) {
                TextField("Enter prompt...", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                
                Button(action: generateWithGrammar) {
                    Text(isLoading ? "Generating..." : "Generate")
                }
                .disabled(isLoading)
            }
            
            // Result
            if !result.isEmpty {
                Section(header: Text("Result")) {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(8)
                        .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Grammar Test")
    }
    
    func getGrammarContent() async {
        Task {
            do {
                // Grammar content loading removed - method no longer exists
                await MainActor.run {
                    // Grammar content loading removed - no content variable anymore
                }
            } catch {
                await MainActor.run {
                    self.grammarContent = "Error getting grammar content: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func generateWithGrammar() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await MainActor.run {
                self.isLoading = true
                self.result = ""
            }
            
            do {
                defer {
                    Task {
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                }
                
                // Grammar content loading removed - method no longer exists
                
                let params = LlamaMobile.CompletionParams(
                    prompt: prompt,
                    maxTokens: 512,
                    temperature: 0.7,
                    topK: 40,
                    topP: 0.95,
                    minP: 0.05,
                    grammar: grammarContent
                )
                
                let generated = try await appState.llamaMobile?.generateCompletion(with: params)
                
                await MainActor.run {
                    self.result = generated?.text ?? "Generation failed"
                }
            } catch {
                await MainActor.run {
                    self.result = "Error: \(error.localizedDescription)"
                }
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
    @State private var mmprojPath: String? = nil
    @State private var availableMmprojFiles: [(name: String, path: String)] = []
    @State private var completionResult = ""
    @State private var isGenerating = false
    @State private var isMultimodalInitialized = false
    
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
                .disabled(!appState.enableMultimodal || !appState.isModelLoaded)
            }
            
            Section(header: Text("MMProj File")) {
                if availableMmprojFiles.isEmpty {
                    Text("No mmproj files found in models folder")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    Picker("Select MMProj", selection: $mmprojPath) {
                        ForEach(availableMmprojFiles, id: \.path) {
                            Text($0.name)
                                .tag(Optional($0.path))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!appState.enableMultimodal || !appState.isModelLoaded)
                }
            }
            
            Section(header: Text("Text Input")) {
                TextField("Enter text prompt...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                    .disabled(!appState.enableMultimodal || !appState.isModelLoaded || isGenerating)
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
                    mmprojPath == nil || 
                    !appState.enableMultimodal || 
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
        .onAppear {
            scanMmprojFiles()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage, selectedImagePath: $selectedImagePath)
        }
    }
    
    func scanMmprojFiles() {
        if let modelsPath = Bundle.main.path(forResource: "models", ofType: nil) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: modelsPath)
                let mmprojFiles = files.filter { $0.hasSuffix(".mmproj") }
                
                availableMmprojFiles = mmprojFiles.map { fileName in
                    (name: fileName, path: modelsPath + "/" + fileName)
                }
                
                // Set default mmproj path if any files are found
                if let firstMmproj = availableMmprojFiles.first {
                    mmprojPath = firstMmproj.path
                }
            } catch {
                print("Error listing mmproj files: \(error)")
            }
        }
    }
    
    func selectImage() {
        isImagePickerPresented = true // Trigger sheet
    }
    
    func generateCompletion() {
        guard !text.isEmpty, let imagePath = selectedImagePath, let mmprojPath = mmprojPath else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        
        Task {
            await performMultimodalCompletion(for: trimmedText, imagePath: imagePath, mmprojPath: mmprojPath)
        }
    }
    
    func performMultimodalCompletion(for text: String, imagePath: String, mmprojPath: String) async {
        defer {
            DispatchQueue.main.async {
                self.isGenerating = false
            }
        }
        
        do {
            // Initialize multimodal if not already initialized
            if let llamaMobile = appState.llamaMobile, !llamaMobile.isMultimodalEnabled() {
                let success = llamaMobile.initMultimodal(mmprojPath: mmprojPath, useGpu: true)
                if !success {
                    DispatchQueue.main.async {
                        self.completionResult = "Failed to initialize multimodal"
                    }
                    return
                }
            }
            
            var params = LlamaMobile.CompletionParams(
                prompt: text,
                maxTokens: 200,
                temperature: 0.7,
                topK: 40,
                topP: 0.9
            )
            params.mediaPaths = [imagePath]
            
            if let result = appState.llamaMobile?.generateCompletion(with: params) {
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

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
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
