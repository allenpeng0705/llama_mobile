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
    @Published var systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone."
    
    // LlamaMobile instance - optional since it requires a model path to initialize
    @Published var llamaMobile: LlamaMobile? = nil
    
    // Grammar support
    @Published var selectedGrammar: String? = nil
    @Published var availableGrammars: [String] = []
    
    // Load grammar content from available locations
    func loadGrammarContent(grammarName: String) -> String? {
        // First priority: the absolute path where we copied the grammar files
        let absolutePath = "/Users/shileipeng/Documents/mygithub/llama_mobile/examples/iOSSDKExample/iOSSDKExample/grammars/\(grammarName).gbnf"
        
        if FileManager.default.fileExists(atPath: absolutePath) {
            print("[DEBUG] ✓ Found grammar file at absolute path: \(absolutePath)")
            
            do {
                let content = try String(contentsOf: URL(fileURLWithPath: absolutePath), encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar content for: \(grammarName)")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file at \(absolutePath): \(error)")
            }
        } else {
            print("[DEBUG] ✗ Grammar file not found at absolute path: \(absolutePath)")
        }
        
        // Second priority: main app bundle
        let mainBundle = Bundle.main
        
        // Try directly in main bundle
        if let fileURL = mainBundle.url(forResource: grammarName, withExtension: "gbnf") {
            print("[DEBUG] ✓ Found grammar file directly in main app bundle: \(fileURL.path)")
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar content")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file: \(error)")
            }
        }
        
        // Try in grammars subdirectory of main bundle
        if let fileURL = mainBundle.url(forResource: grammarName, withExtension: "gbnf", subdirectory: "grammars") {
            print("[DEBUG] ✓ Found grammar file in main app bundle grammars subdirectory: \(fileURL.path)")
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar content")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file: \(error)")
            }
        }
        
        // Third priority: framework bundle - try direct access to embedded framework
        print("[DEBUG] Main bundle path: \(Bundle.main.bundlePath)")
        
        // Try 1: Find framework bundle directly in the app's Frameworks directory
        let frameworkURL = mainBundle.bundleURL.appendingPathComponent("Frameworks/llama_mobile.framework")
        print("[DEBUG] Direct framework URL: \(frameworkURL.path)")
        
        let frameworkExists = FileManager.default.fileExists(atPath: frameworkURL.path)
        print("[DEBUG] Framework exists at direct path: \(frameworkExists)")
        
        if frameworkExists {
            // Check if this is a valid bundle
            if let frameworkBundle = Bundle(url: frameworkURL) {
                print("[DEBUG] Created framework bundle from URL successfully")
                
                // List framework bundle contents
                do {
                    let frameworkContents = try FileManager.default.contentsOfDirectory(atPath: frameworkBundle.bundlePath)
                    print("[DEBUG] Framework bundle contents: \(frameworkContents)")
                    
                    // Check for grammars directory
                    let grammarsURL = frameworkBundle.bundleURL.appendingPathComponent("grammars")
                    print("[DEBUG] Framework grammars URL: \(grammarsURL.path)")
                    
                    let grammarsExists = FileManager.default.fileExists(atPath: grammarsURL.path)
                    print("[DEBUG] Framework grammars directory exists: \(grammarsExists)")
                    
                    if grammarsExists {
                        let grammarFiles = try FileManager.default.contentsOfDirectory(atPath: grammarsURL.path)
                        print("[DEBUG] Framework grammar files: \(grammarFiles)")
                        
                        // Try to find the specific grammar file
                        let grammarFilePath = grammarsURL.appendingPathComponent("\(grammarName).gbnf")
                        print("[DEBUG] Specific grammar file path: \(grammarFilePath.path)")
                        
                        let grammarFileExists = FileManager.default.fileExists(atPath: grammarFilePath.path)
                        print("[DEBUG] Specific grammar file exists: \(grammarFileExists)")
                        
                        if grammarFileExists {
                            // Try to read the file
                            do {
                                let content = try String(contentsOf: grammarFilePath, encoding: .utf8)
                                print("[DEBUG] ✓ Successfully loaded grammar from direct framework path")
                                return content
                            } catch {
                                print("[ERROR] ✗ Failed to read grammar file: \(error)")
                            }
                        }
                    }
                } catch {
                    print("[ERROR] ✗ Failed to access framework bundle: \(error)")
                }
            } else {
            print("[ERROR] ✗ Failed to create bundle from framework URL")
        }
        }
        
        // Try 2: Fallback to Bundle(for:) method
        print("[DEBUG] Trying fallback: Bundle(for: LlamaMobile.self)")
        let fallbackFrameworkBundle = Bundle(for: LlamaMobile.self)
        print("[DEBUG] Fallback framework bundle path: \(fallbackFrameworkBundle.bundlePath)")
        
        // Try 2: Fallback to Bundle(for:) method - continued
        // Try with Bundle API on the fallback bundle
        if let fileURL = fallbackFrameworkBundle.url(forResource: grammarName, withExtension: "gbnf", subdirectory: "grammars") {
            print("[DEBUG] ✓ Found grammar file using fallback Bundle API: \(fileURL.path)")
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar content from fallback bundle")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file from fallback bundle: \(error)")
            }
        } else {
            print("[DEBUG] ✗ Grammar file not found using fallback Bundle API")
        }
        
        // Try direct file path access on the fallback bundle
        let directGrammarPath = fallbackFrameworkBundle.bundlePath + "/grammars/\(grammarName).gbnf"
        print("[DEBUG] Trying direct file path on fallback bundle: \(directGrammarPath)")
        
        if FileManager.default.fileExists(atPath: directGrammarPath) {
            print("[DEBUG] ✓ Found grammar file using direct path on fallback bundle: \(directGrammarPath)")
            
            do {
                let content = try String(contentsOf: URL(fileURLWithPath: directGrammarPath), encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar content using direct path on fallback bundle")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file using direct path on fallback bundle: \(error)")
            }
        } else {
            print("[DEBUG] ✗ Grammar file not found using direct path on fallback bundle")
        }
        

        
        print("[ERROR] ✗ Could not find grammar file in any location: \(grammarName).gbnf")
        return nil
    }
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
                    
                    // Load available grammar files
                    appState.availableGrammars = ["json", "json_arr", "list", "arithmetic", "c", "chess", "english", "japanese"]
                    // Set default grammar to nil (Empty)
                    appState.selectedGrammar = nil
                    
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
            // Create chat messages from conversation history
            var chatMessages: [LlamaMobile.ChatMessage] = []
            
            // Add system message
            chatMessages.append(LlamaMobile.ChatMessage(role: "system", content: appState.systemPrompt))
            
            // Add all conversation messages
            for message in messages {
                chatMessages.append(LlamaMobile.ChatMessage(role: message.role, content: message.text))
            }
            
            // Use the selected grammar from appState if available
            let selectedGrammar = appState.selectedGrammar
            var grammarContent: String? = nil
            
            // Load grammar content if a grammar is selected
            if let selectedGrammarName = selectedGrammar {
                print("[DEBUG] Attempting to load grammar: \(selectedGrammarName)")
                grammarContent = appState.loadGrammarContent(grammarName: selectedGrammarName)
                
                if grammarContent != nil {
                    print("[DEBUG] ✓ Grammar will be used for generation: \(selectedGrammarName)")
                } else {
                    print("[DEBUG] ✗ Grammar not loaded, generation will proceed without grammar constraints")
                    grammarContent = nil // Ensure grammar is nil if not loaded
                }
            } else {
                print("[DEBUG] No grammar selected, generation will proceed without grammar constraints")
                grammarContent = nil // Explicitly clear grammar when none selected
            }
            
            // Format chat messages into a prompt string like chat_example.cpp does
            var formattedPrompt = ""
            for message in chatMessages {
                formattedPrompt += "\(message.role): \(message.content)\n"
            }
            formattedPrompt += "Assistant: "
            
            // Create completion parameters with formatted prompt
            var params = LlamaMobile.CompletionParams(
                prompt: formattedPrompt
            )
            params.maxTokens = 256
            params.temperature = 0.7
            params.topK = 40
            params.topP = 0.9
            params.minP = 0.1
            params.penaltyLastN = 64
            params.penaltyRepeat = 1.0
            params.penaltyFreq = 0.0
            params.penaltyPresent = 0.0
            params.grammar = grammarContent

            // Set comprehensive stop sequences exactly matching chat_example.cpp
            params.stopSequences = [
                "\n\n", "<|im_end|>", "<|endoftext|>",
                "\nUser:", "User:", "\n\tUser:", "\tUser:",
                "\nAssistant:", "Assistant:", "\n\tAssistant:", "\tAssistant:",
                "\nHuman:", "Human:", "\nSystem:", "System:",
                "\nBot:", "Bot:", "\nAI:", "AI:",
                "\nuser:", "user:", "\n\tuser:", "\tuser:",
                "\nassistant:", "assistant:", "\n\tassistant:", "\tassistant:"
            ]

            // Clear chat messages since we're formatting them manually
            params.chatMessages = []

            // Enable JSON response format
            params.useJsonResponse = true
            
            // Log detailed LLM input parameters for debugging
            print("\n==================================================")
            print("[LLM INPUT DETAILS]")
            print("==================================================")
            print("Formatted Prompt (first 100 chars): \(formattedPrompt.prefix(100))...")
            print("Prompt Length: \(formattedPrompt.count) characters")
            print("Max Tokens: \(params.maxTokens)")
            print("Temperature: \(params.temperature)")
            print("Top K: \(params.topK)")
            print("Top P: \(params.topP)")
            print("Min P: \(params.minP)")
            print("Penalty Repeat: \(params.penaltyRepeat)")
            print("Stop Sequences Count: \(params.stopSequences.count)")
            print("Stop Sequences (exact representation with escaped newlines/tabs):")
            for (index, sequence) in params.stopSequences.enumerated() {
                let escapedSequence = sequence
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\t", with: "\\t")
                print("  \(index): '\(escapedSequence)'")
            }
            print("JSON Response Enabled: \(params.useJsonResponse)")
            print("Chat Messages Count: \(params.chatMessages.count)")
            print("Grammar Enabled: \(params.grammar != nil)")
            if let grammar = params.grammar {
                print("Grammar Content: \(grammar)")
            } else {
                print("Grammar Content: nil")
            }
            print("==================================================")
            
            if let result = appState.llamaMobile?.generateCompletion(with: params) {
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
                    // Log complete raw response from LLM (no parsing)
                    print("\n" + String(repeating: "=", count: 50))
                    print("[RAW MODEL RESPONSE] START (length: \(result.text.count) characters)")
                    print(result.text)
                    print("[RAW MODEL RESPONSE] END")
                    print(String(repeating: "=", count: 50) + "\n")
                    
                    // Parse the JSON response from LLM
                    do {
                        // Clean up response by removing ending tags and stop sequences
                        var cleanedText = result.text
                        
                        // Remove ending tags and stop sequences
                        cleanedText = cleanedText.replacingOccurrences(of: "<|im_end|>", with: "")
                        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
                        
                        // Remove stop sequences that might still be present
                        for stopSeq in params.stopSequences {
                            cleanedText = cleanedText.replacingOccurrences(of: stopSeq, with: "")
                        }
                        
                        // Trim whitespace
                        var jsonString = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("[DEBUG] Cleaned Model Response: \(jsonString)")
                        
                        // Fix malformed JSON like chat_example.cpp does
                        var fixedJSON = jsonString
                        
                        // Fix duplicate model fields by removing the empty one
                        let emptyModelPattern = #""model""\s*:\s*""\s*,"#
                        if let emptyModelRange = fixedJSON.range(of: emptyModelPattern, options: .regularExpression) {
                            fixedJSON.removeSubrange(emptyModelRange)
                        }
                        
                        // Fix extra closing bracket before usage field
                        let extraBracketPattern = #"}\s*")\s*,("#
                        if let extraBracketRange = fixedJSON.range(of: extraBracketPattern, options: .regularExpression) {
                            fixedJSON.replaceSubrange(extraBracketRange, with: "},")
                        }
                        
                        // Extract valid JSON from response (from first '{' to last '}')
                        if let firstBrace = fixedJSON.firstIndex(of: "{"),
                           let lastBrace = fixedJSON.lastIndex(of: "}") {
                            let extractedJSON = String(fixedJSON[firstBrace...lastBrace])
                            print("[DEBUG] Extracted and fixed JSON from response: \(extractedJSON)")
                            jsonString = extractedJSON
                        }
                        
                        guard let data = jsonString.data(using: .utf8) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON data"))
                        }
                        
                        // Try parsing as standard OpenAI response format
                        let decoder = JSONDecoder()
                        
                        // First try the format used by chat_example.cpp (text field in choices)
                        do {
                            // Try parsing as choices with text field
                            struct ResponseWithTextChoices: Codable {
                                let choices: [ChoiceWithText]
                            }
                            
                            struct ChoiceWithText: Codable {
                                let text: String
                            }
                            
                            let response = try decoder.decode(ResponseWithTextChoices.self, from: data)
                            print("[DEBUG] Successfully parsed as choices with text format")
                            
                            // Extract the assistant message content
                            if let assistantContent = response.choices.last?.text {
                                // Clean the assistant content by removing stop sequences like chat_example.cpp
                                var cleanedAssistantContent = assistantContent
                                for stopSeq in params.stopSequences {
                                    cleanedAssistantContent = cleanedAssistantContent.replacingOccurrences(of: stopSeq, with: "")
                                }
                                // Trim any remaining whitespace
                                cleanedAssistantContent = cleanedAssistantContent.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                print("[DEBUG] Extracted assistant response: \(assistantContent)")
                                print("[DEBUG] Cleaned assistant response (after removing stop sequences): \(cleanedAssistantContent)")
                                self.messages.append(Message(role: "assistant", text: cleanedAssistantContent))
                                return
                            } else {
                                print("[DEBUG] No text found in choices")
                            }
                        } catch {
                            print("[DEBUG] Failed to parse as choices with text: \(error)")
                            
                            // Try standard OpenAI response with choices array as fallback
                            do {
                                let response = try decoder.decode(OpenAIResponse.self, from: data)
                                print("[DEBUG] Successfully parsed as OpenAI Response Format")
                                
                                // Extract the assistant message content
                                if let assistantMessage = response.choices.last?.message,
                                   assistantMessage.role == "assistant" {
                                    // Clean the assistant content by removing stop sequences like chat_example.cpp
                                    var cleanedAssistantContent = assistantMessage.content
                                    for stopSeq in params.stopSequences {
                                        cleanedAssistantContent = cleanedAssistantContent.replacingOccurrences(of: stopSeq, with: "")
                                    }
                                    // Trim any remaining whitespace
                                    cleanedAssistantContent = cleanedAssistantContent.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    print("[DEBUG] Extracted assistant response: \(assistantMessage.content)")
                                    print("[DEBUG] Cleaned assistant response (after removing stop sequences): \(cleanedAssistantContent)")
                                    self.messages.append(Message(role: assistantMessage.role, text: cleanedAssistantContent))
                                    return
                                } else {
                                    print("[DEBUG] No assistant message found in response")
                                }
                            } catch {
                                print("[DEBUG] Failed to parse as standard OpenAI Response: \(error)")
                                
                                // Try parsing as single message object as fallback
                                do {
                                    let message = try decoder.decode(OpenAIMessage.self, from: data)
                                    print("[DEBUG] Successfully parsed as single OpenAI Message")
                                    
                                    // Clean the message content by removing stop sequences like chat_example.cpp
                                    var cleanedMessageContent = message.content
                                    for stopSeq in params.stopSequences {
                                        cleanedMessageContent = cleanedMessageContent.replacingOccurrences(of: stopSeq, with: "")
                                    }
                                    // Trim any remaining whitespace
                                    cleanedMessageContent = cleanedMessageContent.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    print("[DEBUG] Using parsed message: \(message.content)")
                                    print("[DEBUG] Cleaned message (after removing stop sequences): \(cleanedMessageContent)")
                                    self.messages.append(Message(role: message.role, text: cleanedMessageContent))
                                    return
                                } catch {
                                    print("[DEBUG] Failed to parse as single OpenAI Message: \(error)")
                                }
                            }
                        }
                        
                        // Try a simplified fallback - extract content directly from JSON string
                        if jsonString.contains("content") {
                            // Use regex to extract content field value
                            let contentPattern = #""content"\s*:\s*"([^"]+)"#
                            if let contentRange = jsonString.range(of: contentPattern, options: .regularExpression) {
                                let contentMatch = String(jsonString[contentRange])
                                if let valueStart = contentMatch.range(of: ": \""), 
                                   let valueEnd = contentMatch.range(of: "\"", options: [], range: valueStart.upperBound..<contentMatch.endIndex) {
                                    let assistantContent = String(contentMatch[valueStart.upperBound..<valueEnd.lowerBound])
                                    print("[DEBUG] Extracted assistant content via regex fallback: \(assistantContent)")
                                    self.messages.append(Message(role: "assistant", text: assistantContent))
                                    return
                                }
                            }
                        }
                        
                        // Last resort: use cleaned raw text
                        print("[DEBUG] Using cleaned raw text as final fallback: \(cleanedText)")
                        self.messages.append(Message(role: "assistant", text: cleanedText))
                        
                    } catch {
                        print("[DEBUG] Error parsing LLM response: \(error.localizedDescription)")
                        // Fallback to cleaned text if parsing fails
                        var cleanedText = result.text
                        cleanedText = cleanedText.replacingOccurrences(of: "<|im_end|>", with: "")
                        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
                        
                        // Remove stop sequences
                        for stopSeq in params.stopSequences {
                            cleanedText = cleanedText.replacingOccurrences(of: stopSeq, with: "")
                        }
                        
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
    
    // Define OpenAI message structure for proper JSON encoding/decoding
    struct OpenAIMessage: Codable {
        let role: String
        let content: String
    }
    
    // Define OpenAI request structure
    struct OpenAIRequest: Codable {
        let model: String
        let messages: [OpenAIMessage]
        let temperature: Double
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
        
        // Add all conversation messages
        for message in messages {
            messagesArray.append(OpenAIMessage(
                role: message.role,
                content: message.text
            ))
        }
        
        // Create complete OpenAI request format
        let openAIRequest = OpenAIRequest(
            model: "gpt-4o",
            messages: messagesArray,
            temperature: 0.7
        )
        
        // Convert to JSON string using JSONEncoder
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let jsonData = try encoder.encode(openAIRequest)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Log the full OpenAI format input being sent to LLM
                print("[DEBUG] OpenAI Format Input: \(jsonString)")
                return jsonString
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
        
        // Fallback to complete JSON format if encoding fails
        var fallbackBuilder = "{\"model\": \"gpt-4o\", \"messages\": ["
        
        // Add system message to fallback
        let escapedSystemContent = appState.systemPrompt.replacingOccurrences(of: "\"", with: "\\\"")
        fallbackBuilder.append("{\"role\": \"system\", \"content\": \"\(escapedSystemContent)\"}")
        
        // Add conversation history to fallback
        for (index, message) in messages.enumerated() {
            fallbackBuilder.append(",")
            let escapedContent = message.text.replacingOccurrences(of: "\"", with: "\\\"")
            fallbackBuilder.append("{\"role\": \"\(message.role)\", \"content\": \"\(escapedContent)\"}")
        }
        
        // Complete fallback JSON
        fallbackBuilder.append("], \"temperature\": 0.7}")
        
        print("[DEBUG] OpenAI Format Input (Fallback): \(fallbackBuilder)")
        return fallbackBuilder
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
                    
                    // Grammar picker - always show picker with "Empty" option
                    Picker("Select Grammar", selection: $appState.selectedGrammar) {
                        Text("Empty").tag(nil as String?)
                        ForEach(appState.availableGrammars, id: \.self) {
                            Text($0).tag($0 as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(appState.isModelLoaded)
                    
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
                    Toggle("Enable Embedding", isOn: $appState.enableEmbedding)
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
        
        // Configure model with proper embedding support
        var initParams = LlamaMobile.InitParams(modelPath: appState.modelPath)
        initParams.nCtx = Int32(nCtx)
        initParams.nGpuLayers = Int32(nGpuLayers)
        initParams.nThreads = Int32(nThreads)
        initParams.embedding = appState.enableEmbedding
        initParams.poolingType = 0 // Mean pooling
        initParams.embdNormalize = 1 // Normalize embeddings
        
        // Increase batch sizes for TTS support (to handle large audio token batches)
        initParams.nBatch = 1024 // Increase from default 512
        initParams.nUBatch = 1024 // Increase from default 512 - must be >= number of audio tokens
        
        appState.llamaMobile = LlamaMobile(with: initParams)
        
        if appState.llamaMobile != nil {
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
    @State private var audioSamples: [Float]? = nil
    @State private var sampleRate: Int = 24000 // Default sample rate for TTS models
    
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
                    appState.llamaMobile?.isVocoderEnabled() == false || 
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
    }
    
    func generateSpeech() {
        guard !text.isEmpty, appState.llamaMobile?.isVocoderEnabled() == true else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        
        Task {
            await performTTS(for: trimmedText)
        }
    }
    
    func performTTS(for text: String) async {
        defer { DispatchQueue.main.async { self.isGenerating = false } }
        
        DispatchQueue.main.async {
            self.ttsResult = "Generating audio from text..."
        }
        
        // Get the llama mobile instance
        guard let llamaMobile = appState.llamaMobile else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ LlamaMobile instance not available"
            }
            return
        }
        
        // Debug step 0: Check TTS model type and vocoder status
        DispatchQueue.main.async {
            let ttsType = llamaMobile.getTTSType()
            let vocoderEnabled = llamaMobile.isVocoderEnabled()
            self.ttsResult = "Step 0: TTS Type - \(ttsType), Vocoder Enabled - \(vocoderEnabled)"
        }
        
        // Check if vocoder is enabled
        guard llamaMobile.isVocoderEnabled() else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ Vocoder is not enabled. Please check the vocoder model path."
            }
            return
        }
        
        // Check TTS model type
        let ttsType = llamaMobile.getTTSType()
        let isKnownTTSModel = ttsType != .unknown
        
        DispatchQueue.main.async {
            self.ttsResult = "TTS Model Info: Type - \(ttsType), Known - \(isKnownTTSModel)"
        }
        
        // Debug step 1: Try using the built-in generateAudioFromText method if we have a proper TTS model
        if isKnownTTSModel {
            DispatchQueue.main.async {
                self.ttsResult = "Step 1: Using built-in generateAudioFromText method..."
            }
            
            // Try the built-in TTS method first
            if let samples = llamaMobile.generateAudioFromText(text: text) {
                DispatchQueue.main.async {
                    // Save audio to WAV file automatically (fixed name for overwriting)
                    let tempDir = NSTemporaryDirectory()
                    let tempFileName = "tts_output_latest.wav"
                    let tempFilePath = tempDir.appending(tempFileName)
                    
                    // Save using the new API
                    let saveSuccess = llamaMobile.saveAudioToWav(filePath: tempFilePath, audioData: samples, sampleRate: Int32(sampleRate))
                    
                    self.audioSamples = samples
                    
                    if saveSuccess {
                        self.ttsResult = "✅ TTS generation completed successfully.\n"
                        self.ttsResult += "   - Generated \(samples.count) audio samples at \(sampleRate) Hz\n"
                        self.ttsResult += "   - Audio saved to: \(tempFilePath)"
                    } else {
                        self.ttsResult = "⚠️ TTS generation completed but failed to save audio to file.\n"
                        self.ttsResult += "   - Generated \(samples.count) audio samples at \(sampleRate) Hz"
                    }
                }
                return
            }
        }
        
        // If built-in method fails or we don't have a proper TTS model, implement custom workflow
        DispatchQueue.main.async {
            self.ttsResult = "Using custom TTS workflow: formatting + completion + audio decoding..."
        }
        
        // Debug step 2: Try to format text for TTS
        DispatchQueue.main.async {
            self.ttsResult = "Step 2: Formatting text for TTS..."
        }
        
        guard let formattedPrompt = llamaMobile.getFormattedAudioCompletion(speakerJson: "{\"speaker\": \"default\"}", textToSpeak: text) else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ Failed at Step 2: Cannot format text for TTS. Check if your model supports TTS formatting."
            }
            return
        }
        
        // Debug: Check what's in the formatted prompt
        print("[DEBUG] Formatted Prompt: \(formattedPrompt)")
        print("[DEBUG] Formatted Prompt Length: \(formattedPrompt.count)")
        
        // If formatted prompt contains audio template markers, we should only tokenize the completion result
        // This prevents generating audio from the template content
        let useOnlyCompletion = formattedPrompt.contains("<|audio_start|") || formattedPrompt.contains("<|text_start|")
        print("[DEBUG] useOnlyCompletion: \(useOnlyCompletion)")
        
        // Debug step 3: Generate audio content using text completion
        DispatchQueue.main.async {
            self.ttsResult = "Step 3: Generating audio content using text completion..."
        }
        
        // Get guide tokens - note: the built-in method passes formattedPrompt, not original text
        print("[DEBUG] Getting audio guide tokens using formatted prompt...")
        if let guideTokens = llamaMobile.getAudioGuideTokens(textToSpeak: formattedPrompt) {
            print("[DEBUG] Setting guide tokens: \(guideTokens.count) tokens")
            llamaMobile.setGuideTokens(tokens: guideTokens)
        } else {
            print("[DEBUG] Failed to get guide tokens, proceeding without...")
        }
        
        // Generate audio content using text completion
        var completionParams = LlamaMobile.CompletionParams(prompt: formattedPrompt)
        completionParams.maxTokens = 200 // Generate appropriate audio content
        completionParams.temperature = 0.0 // Deterministic output
        completionParams.ignoreEos = true // Don't stop at end-of-sequence
        
        guard let completionResult = llamaMobile.generateCompletion(with: completionParams) else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ Failed at Step 3: Cannot generate audio content via text completion."
            }
            return
        }
        
        // Debug: Print actual text content
        print("[DEBUG] Formatted Prompt Content:")
        print("\"\(formattedPrompt)\"")
        print("[DEBUG] Completion Result Content:")
        print("\"\(completionResult.text)\"")
        
        // Combine prompt and completion for full audio tokens - or just use completion if prompt contains template markers
        let contentToTokenize: String
        if useOnlyCompletion {
            // If prompt contains template markers, only use the completion result (prevents audio from template)
            contentToTokenize = completionResult.text
            print("[DEBUG] Using only completion result for tokenization (skipping template)")
        } else {
            // Otherwise combine both
            contentToTokenize = formattedPrompt + completionResult.text
            print("[DEBUG] Combining prompt and completion for tokenization")
        }
        
        print("[DEBUG] Final Content to Tokenize:")
        print("\"\(contentToTokenize)\"")
        
        // Debug step 4: Tokenize the audio content
        DispatchQueue.main.async {
            self.ttsResult = "Step 4: Tokenizing audio content..."
        }
        
        // Tokenize the audio content
        guard let tokens = llamaMobile.tokenize(text: contentToTokenize) else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ Failed at Step 4: Cannot tokenize audio content."
            }
            return
        }
        
        // Debug: Show first few tokens and their values
        print("[DEBUG] Total tokens generated: \(tokens.count)")
        print("[DEBUG] First 10 tokens: \(tokens.prefix(10))")
        print("[DEBUG] Last 10 tokens: \(tokens.suffix(10))")
        
        // Check if formatted prompt itself contains audio tokens
        if let promptTokens = llamaMobile.tokenize(text: formattedPrompt) {
            print("[DEBUG] Prompt tokens count: \(promptTokens.count)")
            print("[DEBUG] Prompt first 10 tokens: \(promptTokens.prefix(10))")
        }
        
        // Debug step 4.5: Filter audio tokens (following C++ example)
        DispatchQueue.main.async {
            self.ttsResult = "Step 4.5: Filtering audio tokens..."
        }
        
        // Filter tokens to only include audio tokens (151672-155772) and look for end token
        var audioTokens: [Int32] = []
        let audioStartToken = 151672
        let audioEndToken = 151668 // <|audio_end|>
        
        // Debug: Track token filtering
        var nonAudioTokens = 0
        
        for token in tokens {
            // Check if token is in audio range
            if token >= 151672 && token <= 155772 {
                audioTokens.append(token)
            } else {
                nonAudioTokens += 1
            }
            
            // Check for end token
            if token == audioEndToken {
                print("Found audio end token")
                break
            }
        }
        
        print("[DEBUG] Generated \(audioTokens.count) audio tokens (skipped non-audio: \(nonAudioTokens))")
        
        if audioTokens.isEmpty {
            DispatchQueue.main.async {
                self.ttsResult = "❌ No audio tokens found in the generated content."
            }
            return
        }
        
        // Debug step 5: Try to decode audio tokens
        DispatchQueue.main.async {
            self.ttsResult = "Step 5: Decoding audio tokens to samples..."
        }
        
        guard let samples = llamaMobile.decodeAudioTokens(tokens: audioTokens) else {
            DispatchQueue.main.async {
                self.ttsResult = "❌ Failed at Step 5: Cannot decode audio tokens. Check vocoder model."
            }
            return
        }
        
        // Success! All steps completed
        DispatchQueue.main.async {
            // Save audio to WAV file automatically (fixed name for overwriting)
            let tempDir = NSTemporaryDirectory()
            let tempFileName = "tts_output_latest.wav"
            let tempFilePath = tempDir.appending(tempFileName)
            
            // Save using the new API
            let saveSuccess = llamaMobile.saveAudioToWav(filePath: tempFilePath, audioData: samples, sampleRate: Int32(sampleRate))
            
            self.audioSamples = samples
            
            if saveSuccess {
                self.ttsResult = "✅ TTS generation completed successfully.\n"
                self.ttsResult += "   - Generated \(samples.count) audio samples at \(sampleRate) Hz\n"
                self.ttsResult += "   - Audio saved to: \(tempFilePath)"
            } else {
                self.ttsResult = "⚠️ TTS generation completed but failed to save audio to file.\n"
                self.ttsResult += "   - Generated \(samples.count) audio samples at \(sampleRate) Hz"
            }
        }
    }
    
    func playAudio() {
        guard let samples = audioSamples else { return }
        
        isPlaying = true
        
        Task {
            do {
                // Set up audio session
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true)
                
                // Configure audio format
                let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!
                
                // Create buffer
                let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(samples.count))!
                buffer.frameLength = buffer.frameCapacity
                
                // Copy samples to buffer
                if let floatBuffer = buffer.floatChannelData?[0] {
                    for (index, sample) in samples.enumerated() {
                        floatBuffer[index] = sample
                    }
                } else {
                    throw NSError(domain: "TTSError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
                }
                
                // Configure audio engine
                let audioEngine = AVAudioEngine()
                let playerNode = AVAudioPlayerNode()
                
                // Attach player node to engine
                audioEngine.attach(playerNode)
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
                
                // Start engine
                try audioEngine.start()
                
                // Play the audio
                playerNode.play()
                playerNode.scheduleBuffer(buffer) { 
                    DispatchQueue.main.async {
                        self.isPlaying = false
                        self.ttsResult += "\n✅ Audio playback completed."
                    }
                    
                    // Clean up
                    audioEngine.stop()
                    do {
                        try audioSession.setActive(false)
                    } catch {
                        print("Error deactivating audio session: \(error)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.ttsResult += "\n❌ Error playing audio: \(error.localizedDescription)"
                }
                
                // Clean up
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setActive(false)
                } catch {
                    print("Error deactivating audio session: \(error)")
                }
            }
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
            
            Section(header: Text("Apply LoRA Adapter")) {
                Button(action: applyLoRA) {
                    HStack {
                        Spacer()
                        Text(isProcessing ? "Applying LoRA..." : "Apply LoRA")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(appState.loraModelPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.isModelLoaded || isProcessing)
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
