//
//  ContentView.swift
//  LlamaMobileSwiftUIExample
//

import SwiftUI
import AVFoundation
import llama_mobile

struct ContentView: View {
    @State private var selectedModel: String = ""
    @State private var models: [String] = []
    @State private var isInitialized: Bool = false
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isGenerating: Bool = false
    @State private var isConversationMode: Bool = false
    @State private var embeddingText: String = ""
    @State private var embeddingResult: String = ""
    @State private var isEmbedding: Bool = false
    @State private var isMultimodal: Bool = false
    @State private var multimodalText: String = ""
    @State private var imagePath: String = ""
    @State private var projectionPath: String = ""
    @State private var ttsText: String = ""
    @State private var vocoderPath: String = ""
    @State private var isTTSEnabled: Bool = false
    @State private var isTTSSpeaking: Bool = false
    
    @State private var llamaContext: llama_mobile_context_handle_t? = nil
    private let audioEngine = AVAudioEngine()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model Selection")) {
                    Picker("Select Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) {
                            Text($0.split(separator: "/").last ?? "Unknown")
                        }
                    }
                    Button("Initialize Model") {
                        initializeModel()
                    }
                    .disabled(isInitialized || selectedModel.isEmpty)
                    Text("Status: \(isInitialized ? "Initialized" : "Not Initialized")")
                }
                
                Section(header: Text("Text Generation")) {
                    TextField("Enter prompt", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                    Toggle("Conversation Mode", isOn: $isConversationMode)
                    Button("Generate") {
                        generateText()
                    }
                    .disabled(!isInitialized || inputText.isEmpty || isGenerating)
                    Text("Output:")
                    Text(outputText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Section(header: Text("Embeddings")) {
                    TextField("Enter text for embedding", text: $embeddingText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...3)
                    Button("Generate Embedding") {
                        generateEmbedding()
                    }
                    .disabled(!isInitialized || embeddingText.isEmpty || isEmbedding)
                    Text("Embedding Result:")
                    Text(embeddingResult)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .lineLimit(5)
                }
                
                Section(header: Text("Multimodal")) {
                    Toggle("Enable Multimodal", isOn: $isMultimodal)
                    TextField("Multimodal Text", text: $multimodalText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...3)
                        .disabled(!isMultimodal)
                    TextField("Image Path", text: $imagePath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!isMultimodal)
                    TextField("Projection Path", text: $projectionPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!isMultimodal)
                    Button("Generate Multimodal") {
                        generateMultimodal()
                    }
                    .disabled(!isMultimodal || !isInitialized || multimodalText.isEmpty || imagePath.isEmpty || projectionPath.isEmpty)
                }
                
                Section(header: Text("Text-to-Speech")) {
                    Toggle("Enable TTS", isOn: $isTTSEnabled)
                    TextField("Vocoder Model Path", text: $vocoderPath, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!isTTSEnabled)
                    TextField("Enter text for TTS", text: $ttsText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...3)
                        .disabled(!isTTSEnabled)
                    Button("Speak") {
                        speakText()
                    }
                    .disabled(!isTTSEnabled || ttsText.isEmpty || isTTSSpeaking || (llamaContext != nil && !llama_mobile_is_vocoder_enabled_c(llamaContext!) && vocoderPath.isEmpty))
                }
            }
            .navigationTitle("Llama Mobile SwiftUI Example")
        }
        .onAppear {
            scanModels()
        }
    }
    
    private func scanModels() {
        // Scan the models directory from the original iOSSDKExample
        let modelsDir = "/Users/shileipeng/Documents/mygithub/llama_mobile/examples/iOSSDKExample/models"
        if FileManager.default.fileExists(atPath: modelsDir) {
            scanDirectory(modelsDir)
        }
    }
    
    private func scanDirectory(_ path: String) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            for item in contents {
                let fullPath = URL(fileURLWithPath: path).appendingPathComponent(item).path
                if item.hasSuffix(".gguf") {
                    models.append(fullPath)
                } else if let fileAttrs = try? FileManager.default.attributesOfItem(atPath: fullPath), let type = fileAttrs[.type] as? FileAttributeType, type == .typeDirectory {
                    scanDirectory(fullPath)
                }
            }
        } catch {
            print("Error scanning directory: \(error)")
        }
    }
    
    private func initializeModel() {
        Task {
            await MainActor.run {
                isGenerating = true
            }
            
            // Free existing context if it exists
            await MainActor.run {
                if let context = llamaContext {
                    llama_mobile_free_context_c(context)
                    llamaContext = nil
                }
            }
            
            // Initialize with default parameters
            var initParams = llama_mobile_init_params_c_t()
            // Convert string to C string pointer
            selectedModel.withCString { cString in
                initParams.model_path = cString
            }
            initParams.n_ctx = 2048
            initParams.n_batch = 512
            initParams.n_ubatch = 512
            initParams.n_gpu_layers = 0
            initParams.n_threads = 4
            initParams.use_mmap = true
            initParams.use_mlock = false
            initParams.embedding = false
            initParams.pooling_type = 0
            initParams.embd_normalize = 0
            initParams.flash_attn = false
            initParams.chat_template = nil
            initParams.cache_type_k = nil
            initParams.cache_type_v = nil
            initParams.progress_callback = nil
            
            llamaContext = llama_mobile_init_context_c(&initParams)
            
            await MainActor.run {
                isInitialized = llamaContext != nil
                if !isInitialized {
                    outputText = "Failed to initialize model"
                }
                isGenerating = false
            }
        }
    }
    
    private func generateText() {
        Task {
            await MainActor.run {
                isGenerating = true
                outputText = ""
            }
            
            guard let context = llamaContext else {
                DispatchQueue.main.async {
                    self.outputText = "Model not initialized"
                    self.isGenerating = false
                }
                return
            }
            
            // Token callback functionality has been removed from the completion parameters struct
            // We'll use the final result instead
            
            // Set up completion parameters
            var completionParams = llama_mobile_completion_params_c_t()
            // Convert string to C string pointer
            inputText.withCString { cString in
                completionParams.prompt = cString
            }
            completionParams.n_predict = 1024
            completionParams.n_threads = 4
            completionParams.seed = -1
            completionParams.temperature = 0.7
            completionParams.top_k = 40
            completionParams.top_p = 0.9
            completionParams.min_p = 0.05
            completionParams.typical_p = 1.0
            completionParams.penalty_last_n = 64
            completionParams.penalty_repeat = 1.1
            completionParams.penalty_freq = 0.0
            completionParams.penalty_present = 0.0
            completionParams.mirostat = 0
            completionParams.mirostat_tau = 5.0
            completionParams.mirostat_eta = 0.1
            completionParams.ignore_eos = false
            completionParams.n_probs = 0
            completionParams.stop_sequences = nil
            completionParams.stop_sequence_count = 0
            completionParams.grammar = nil
            
            // Generate completion
            var completionResult = llama_mobile_completion_result_c_t()
            let completionStatus = llama_mobile_completion_c(context, &completionParams, &completionResult)
            
            if completionStatus != 0 {
                DispatchQueue.main.async {
                    self.outputText = "Failed to generate completion"
                }
            } else if let text = completionResult.text {
                DispatchQueue.main.async {
                    self.outputText = String(cString: text)
                }
            }
            
            // Free the completion result
            llama_mobile_free_completion_result_members_c(&completionResult)
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func generateEmbedding() {
        Task {
            await MainActor.run {
                isEmbedding = true
            }
            
            guard let context = llamaContext else {
                DispatchQueue.main.async {
                    self.embeddingResult = "Model not initialized"
                    self.isEmbedding = false
                }
                return
            }
            
            // Convert string to C string pointer
            let embeddingResultPtr = embeddingText.withCString { cString in
                return llama_mobile_embedding_c(context, cString)
            }
            defer { llama_mobile_free_float_array_c(embeddingResultPtr) }
            
            if embeddingResultPtr.count > 0, let values = embeddingResultPtr.values {
                // Convert the float array to Swift array
                let embeddingArray = Array(UnsafeBufferPointer(start: values, count: Int(embeddingResultPtr.count)))
                DispatchQueue.main.async {
                    self.embeddingResult = "[\(embeddingArray.map { String(format: "%.6f", $0) }.joined(separator: ", "))]"
                    self.isEmbedding = false
                }
            } else {
                DispatchQueue.main.async {
                    self.embeddingResult = "Failed to generate embedding"
                    self.isEmbedding = false
                }
            }
        }
    }
    
    private func generateMultimodal() {
        Task {
            await MainActor.run {
                isGenerating = true
                outputText = ""
            }
            
            guard let context = llamaContext else {
                DispatchQueue.main.async {
                    self.outputText = "Model not initialized"
                    self.isGenerating = false
                }
                return
            }
            
            // Initialize multimodal with the projection path
            let mmInitResult = projectionPath.withCString { cString in
                return llama_mobile_init_multimodal_c(context, cString, false)
            }
            if mmInitResult != 0 {
                DispatchQueue.main.async {
                    self.outputText = "Failed to initialize multimodal"
                    self.isGenerating = false
                }
                return
            }
            
            // Token callback functionality has been removed from the completion parameters struct
            // We'll use the final result instead
            
            // Set up completion parameters
            var completionParams = llama_mobile_completion_params_c_t()
            // Convert string to C string pointer
            multimodalText.withCString { cString in
                completionParams.prompt = cString
            }
            completionParams.n_predict = 1024
            completionParams.n_threads = 4
            completionParams.seed = -1
            completionParams.temperature = 0.7
            completionParams.top_k = 40
            completionParams.top_p = 0.9
            completionParams.min_p = 0.05
            completionParams.typical_p = 1.0
            completionParams.penalty_last_n = 64
            completionParams.penalty_repeat = 1.1
            completionParams.penalty_freq = 0.0
            completionParams.penalty_present = 0.0
            completionParams.mirostat = 0
            completionParams.mirostat_tau = 5.0
            completionParams.mirostat_eta = 0.1
            completionParams.ignore_eos = false
            completionParams.n_probs = 0
            completionParams.stop_sequences = nil
            completionParams.stop_sequence_count = 0
            completionParams.grammar = nil
            
            // Create media paths array with C string pointers
            let mediaPathsPtr = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 1)
            defer { mediaPathsPtr.deallocate() }
            imagePath.withCString { cString in
                mediaPathsPtr[0] = cString
            }
            
            // Generate multimodal completion
            var completionResult = llama_mobile_completion_result_c_t()
            let completionStatus = llama_mobile_multimodal_completion_c(
                context,
                &completionParams,
                mediaPathsPtr,
                1,
                &completionResult
            )
            
            if completionStatus != 0 {
                DispatchQueue.main.async {
                    self.outputText = "Failed to generate multimodal completion"
                }
            } else if let text = completionResult.text {
                DispatchQueue.main.async {
                    self.outputText = String(cString: text)
                }
            }
            
            // Free the completion result
            llama_mobile_free_completion_result_members_c(&completionResult)
            
            await MainActor.run {
                self.isGenerating = false
            }
        }
    }
    
    private func speakText() {
        Task {
            await MainActor.run {
                isTTSSpeaking = true
            }
            
            guard let context = llamaContext else {
                DispatchQueue.main.async {
                    self.outputText = "Model not initialized"
                    self.isTTSSpeaking = false
                }
                return
            }
            
            // Step 1: Initialize vocoder if not already enabled
            let isVocoderEnabled = llama_mobile_is_vocoder_enabled_c(context)
            if !isVocoderEnabled {
                let vocoderSuccess = vocoderPath.withCString { cString in
                    return llama_mobile_init_vocoder_c(context, cString)
                }
                if vocoderSuccess != 0 {
                    DispatchQueue.main.async {
                        self.outputText = "Failed to initialize vocoder"
                        self.isTTSSpeaking = false
                    }
                    return
                }
            }
            
            // Step 2: Get audio guide tokens for the text
            let audioTokensPtr = ttsText.withCString { cString in
                return llama_mobile_get_audio_guide_tokens_c(context, cString)
            }
            defer { llama_mobile_free_token_array_c(audioTokensPtr) }
            
            if audioTokensPtr.count <= 0 || audioTokensPtr.tokens == nil {
                DispatchQueue.main.async {
                    self.outputText = "Failed to get audio guide tokens"
                    self.isTTSSpeaking = false
                }
                return
            }
            
            // Convert token array to Swift array (unused variable removed)
            
            // Step 3: Decode audio tokens to get audio samples
            let audioSamplesPtr = llama_mobile_decode_audio_tokens_c(context, audioTokensPtr.tokens, audioTokensPtr.count)
            defer { llama_mobile_free_float_array_c(audioSamplesPtr) }
            
            if audioSamplesPtr.count <= 0 || audioSamplesPtr.values == nil {
                DispatchQueue.main.async {
                    self.outputText = "Failed to decode audio tokens"
                    self.isTTSSpeaking = false
                }
                return
            }
            
            // Convert float array to Swift array
            let audioSamples = Array(UnsafeBufferPointer(start: audioSamplesPtr.values, count: Int(audioSamplesPtr.count)))
            
            // Step 4: Play the audio samples using AVFoundation
            await playAudioSamples(samples: audioSamples)
            
            DispatchQueue.main.async {
                self.outputText = "Generated and played TTS audio with \(audioSamples.count) samples"
            }
            
            await MainActor.run {
                self.isTTSSpeaking = false
            }
        }
    }
    
    private func playAudioSamples(samples: [Float]) async {
        do {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Stop and reset audio engine if it's running
            audioEngine.stop()
            audioEngine.reset()
            
            // Create audio format (24kHz is common for TTS)
            let sampleRate: Double = 24000
            let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            
            // Create audio buffer
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(samples.count))!
            audioBuffer.frameLength = AVAudioFrameCount(samples.count)
            
            // Copy samples to audio buffer
            let floatBuffer = audioBuffer.floatChannelData![0]
            for i in 0..<samples.count {
                floatBuffer[i] = samples[i]
            }
            
            // Create and connect audio player node
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            
            // Start audio engine
            try audioEngine.start()
            
            // Play audio with async/await
            playerNode.play()
            await playerNode.scheduleBuffer(audioBuffer)
            
            // Wait for playback to complete
            let totalDuration = Double(samples.count) / sampleRate
            try await Task.sleep(nanoseconds: UInt64(totalDuration * 1_000_000_000))
            
            // Clean up
            audioEngine.stop()
            audioEngine.detach(playerNode)
            
        } catch {
            DispatchQueue.main.async {
                self.outputText = "Error playing audio: \(error.localizedDescription)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}