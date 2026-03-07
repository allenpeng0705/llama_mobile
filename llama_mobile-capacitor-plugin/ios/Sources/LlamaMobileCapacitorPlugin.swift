import Foundation
import AVFoundation
@preconcurrency import Capacitor

@objc(LlamaMobileCapacitorPlugin)
public class LlamaMobileCapacitorPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LlamaMobileCapacitorPlugin"
    public let jsName = "LlamaMobileCapacitorPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        // Initialization
        CAPPluginMethod(name: "initContext", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseContext", returnType: CAPPluginReturnPromise),
        
        // Completion
        CAPPluginMethod(name: "generateCompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateOpenAICompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopCompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadGrammar", returnType: CAPPluginReturnPromise),
        
        // TTS
        CAPPluginMethod(name: "initVocoder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseVocoder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isVocoderEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getTTSType", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeechAsync", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeech", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeechStreamForLongTextAsync", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveAudioToWav", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "playAudio", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "playAudioFromFile", returnType: CAPPluginReturnPromise),
        
        // Multimodal
        CAPPluginMethod(name: "initMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isMultimodalEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "supportsVision", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "supportsAudio", returnType: CAPPluginReturnPromise),
        
        // LoRA
        CAPPluginMethod(name: "applyLoraAdapters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeLoraAdapters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getLoadedLoraAdapters", returnType: CAPPluginReturnPromise),
        
        // Conversation
        CAPPluginMethod(name: "generateResponse", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearConversation", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isConversationActive", returnType: CAPPluginReturnPromise),
        
        // Embeddings
        CAPPluginMethod(name: "generateEmbeddings", returnType: CAPPluginReturnPromise),
        
        // Tokenization
        CAPPluginMethod(name: "tokenize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "detokenize", returnType: CAPPluginReturnPromise),
        
        // Model Info
        CAPPluginMethod(name: "getContextWindowSize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getEmbeddingDimension", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getModelDescription", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getModelSize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getModelParametersCount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listFiles", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listModels", returnType: CAPPluginReturnPromise),
        
        // Download
        CAPPluginMethod(name: "downloadModel", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "downloadHfFile", returnType: CAPPluginReturnPromise),
        
    ]
    
    private var contexts: [Int: LlamaMobile] = [:]
    private var nextContextHandle: Int = 1
    
    // Audio playback properties
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private func getNextContextHandle() -> Int {
        let handle = nextContextHandle
        nextContextHandle += 1
        return handle
    }
    
    // MARK: - Initialization
    
    @objc func initContext(_ call: CAPPluginCall) {
        let modelPath = call.getString("modelPath") ?? ""
        if modelPath.isEmpty {
            call.reject("modelPath is required")
            return
        }
        
        let nCtx = call.getInt("nCtx") ?? 2048
        let nGpuLayers = call.getInt("nGpuLayers") ?? 0
        let nThreads = call.getInt("nThreads") ?? 4
        let nBatch = call.getInt("nBatch") ?? 512
        let nUBatch = call.getInt("nUBatch") ?? 512
        let useMmap = call.getBool("useMmap") ?? true
        let useMlock = call.getBool("useMlock") ?? false
        let embedding = call.getBool("embedding") ?? false
        let poolingType = call.getInt("poolingType") ?? 0
        let embdNormalize = call.getInt("embdNormalize") ?? 0
        let flashAttention = call.getBool("flashAttention") ?? false
        let chatTemplate = call.getString("chatTemplate")
        let systemPrompt = call.getString("systemPrompt")
        let cacheTypeK = call.getString("cacheTypeK")
        let cacheTypeV = call.getString("cacheTypeV")
        let enableChatTemplate = call.getBool("enableChatTemplate") ?? true
        let imageMinTokens = call.getInt("imageMinTokens") ?? -1
        
        // Resolve model path if it's just a filename
        let resolvedModelPath = resolveModelPath(modelPath)
        
        Task {
            do {
                let contextHandle = try await Task.detached {
                    var initParams = LlamaMobile.InitParams(modelPath: resolvedModelPath)
                    initParams.nCtx = Int32(nCtx)
                    initParams.nGpuLayers = Int32(nGpuLayers)
                    initParams.nThreads = Int32(nThreads)
                    initParams.nBatch = Int32(nBatch)
                    initParams.nUBatch = Int32(nUBatch)
                    initParams.useMmap = useMmap
                    initParams.useMlock = useMlock
                    initParams.embedding = embedding
                    initParams.poolingType = Int32(poolingType)
                    initParams.embdNormalize = Int32(embdNormalize)
                    initParams.flashAttention = flashAttention
                    initParams.chatTemplate = chatTemplate
                    initParams.systemPrompt = systemPrompt
                    initParams.cacheTypeK = cacheTypeK
                    initParams.cacheTypeV = cacheTypeV
                    initParams.enableChatTemplate = enableChatTemplate
                    initParams.imageMinTokens = Int32(imageMinTokens)
                    
                    guard let llamaMobile = LlamaMobile(with: initParams) else {
                        throw NSError(domain: "LlamaMobile", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize LlamaMobile context"])
                    }
                    
                    return await MainActor.run {
                        let handle = self.getNextContextHandle()
                        self.contexts[handle] = llamaMobile
                        return handle
                    }
                }.value
                
                call.resolve(["contextHandle": contextHandle])
            } catch {
                call.reject("Failed to initialize context: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper method to resolve model paths
    private func resolveModelPath(_ modelPath: String) -> String {
        // If the path is already absolute, return it as-is
        if modelPath.hasPrefix("/") {
            return modelPath
        }
        
        let fileManager = FileManager.default
        
        // List of common directories to search for models
        var searchDirs: [String] = []
        
        // Get documents directory
        if let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            searchDirs.append(documentsDirectory)
            searchDirs.append(documentsDirectory + "/models")
            searchDirs.append(documentsDirectory + "/Downloads")
            searchDirs.append(documentsDirectory + "/Downloads/models")
        }
        
        // Add app bundle directories for bundled models
        let bundlePath = Bundle.main.bundlePath
        searchDirs.append(bundlePath + "/public/models")
        searchDirs.append(bundlePath + "/models")
        searchDirs.append(bundlePath)
        
        // Search for the model file in common directories
        for dir in searchDirs {
            let fullPath = dir + (dir.hasSuffix("/") ? "" : "/") + modelPath
            if fileManager.fileExists(atPath: fullPath) {
                return fullPath
            }
        }
        
        // If not found, return the original path (will likely fail, but let the error propagate)
        return modelPath
    }
    
    @objc func releaseContext(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            await Task.detached {
                llamaMobile.releaseContext()
            }.value
            
            self.contexts.removeValue(forKey: contextHandle)
            call.resolve()
        }
    }
    
    // MARK: - Completion
    
    @objc func generateCompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let params = call.getObject("params")
        else {
            call.reject("Invalid parameters")
            return
        }
        let prompt = params["prompt"] as? String ?? ""       
        let maxTokens = (params["maxTokens"] as? Int) ?? 128
        let nThreads = (params["nThreads"] as? Int)
        let seed = (params["seed"] as? Int) ?? -1
        let temperature = (params["temperature"] as? Double) ?? 0.8
        let topK = (params["topK"] as? Int) ?? 40
        let topP = (params["topP"] as? Double) ?? 0.95
        let minP = (params["minP"] as? Double) ?? 0.05
        let typicalP = (params["typicalP"] as? Double) ?? 1.0
        let penaltyLastN = (params["penaltyLastN"] as? Int) ?? 64
        let penaltyRepeat = (params["penaltyRepeat"] as? Double) ?? 1.1
        let penaltyFreq = (params["penaltyFreq"] as? Double) ?? 0.0
        let penaltyPresent = (params["penaltyPresent"] as? Double) ?? 0.0
        let mirostat = (params["mirostat"] as? Int) ?? 0
        let mirostatTau = (params["mirostatTau"] as? Double) ?? 5.0
        let mirostatEta = (params["mirostatEta"] as? Double) ?? 0.1
        let ignoreEos = (params["ignoreEos"] as? Bool) ?? false
        let stopSequences = (params["stopSequences"] as? [String]) ?? []
        let grammar = (params["grammar"] as? String) ?? nil
        let mediaPaths = (params["mediaPaths"] as? [String]) ?? []
        let useJsonResponse = (params["useJsonResponse"] as? Bool) ?? true
        let nProbs = (params["nProbs"] as? Int) ?? 0
        let jsonSchema = (params["jsonSchema"] as? String)
        let tools = (params["tools"] as? String)
        let parallelToolCalls = (params["parallelToolCalls"] as? Bool) ?? false
        let toolChoice = (params["toolChoice"] as? String)
        
        Task {
            do {
                let result = try await Task.detached {
                    var processedMediaPaths: [String] = []
                    for mediaPath in mediaPaths {
                        if mediaPath.hasPrefix("data:image/") {
                            if let tempFilePath = self.saveBase64ImageToTempFile(mediaPath) {
                                processedMediaPaths.append(tempFilePath)
                            }
                        } else {
                            processedMediaPaths.append(mediaPath)
                        }
                    }
                    
                    let completionParams = LlamaMobile.CompletionParams(
                        prompt: prompt,
                        maxTokens: Int32(maxTokens),
                        nThreads: nThreads.map { Int32($0) },
                        seed: Int32(seed),
                        temperature: temperature,
                        topK: Int32(topK),
                        topP: topP,
                        minP: minP,
                        typicalP: typicalP,
                        penaltyLastN: Int32(penaltyLastN),
                        penaltyRepeat: penaltyRepeat,
                        penaltyFreq: penaltyFreq,
                        penaltyPresent: penaltyPresent,
                        mirostat: Int32(mirostat),
                        mirostatTau: mirostatTau,
                        mirostatEta: mirostatEta,
                        ignoreEos: ignoreEos,
                        stopSequences: stopSequences,
                        grammar: grammar,
                        mediaPaths: processedMediaPaths,
                        chatMessages: [],
                        useJsonResponse: useJsonResponse,
                        nProbs: Int32(nProbs),
                        jsonSchema: jsonSchema,
                        tools: tools,
                        parallelToolCalls: parallelToolCalls,
                        toolChoice: toolChoice
                    )
                    
                    guard let genResult = llamaMobile.generateCompletion(with: completionParams) else {
                        throw NSError(domain: "LlamaMobile", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate completion"])
                    }
                    return genResult
                }.value
                
                call.resolve([
                    "text": result.text,
                    "tokensGenerated": result.tokensGenerated,
                    "tokensEvaluated": result.tokensEvaluated,
                    "truncated": result.truncated,
                    "stoppedEos": result.stoppedEos,
                    "stoppedWord": result.stoppedWord,
                    "stoppedLimit": result.stoppedLimit
                ])
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }
    
    @objc func generateOpenAICompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let openAIJSON = call.getString("openAIJSON") else {
            call.reject("contextHandle and openAIJSON are required")
            return
        }
        
        Task {
            do {
                let result = try await Task.detached {
                    guard let genResult = llamaMobile.generateOpenAICompletion(with: openAIJSON) else {
                        throw NSError(domain: "LlamaMobile", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate OpenAI completion"])
                    }
                    return genResult
                }.value
                
                call.resolve([
                    "text": result.text,
                    "tokensGenerated": result.tokensGenerated,
                    "tokensEvaluated": result.tokensEvaluated,
                    "truncated": result.truncated,
                    "stoppedEos": result.stoppedEos,
                    "stoppedWord": result.stoppedWord,
                    "stoppedLimit": result.stoppedLimit
                ])
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }
    
    @objc func stopCompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        llamaMobile.stopCompletion()
        call.resolve()
    }
    
    @objc func loadGrammar(_ call: CAPPluginCall) {
        guard let filePath = call.getString("filePath"),
              let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("filePath and contextHandle are required")
            return
        }
        
        Task {
            let grammar = await Task.detached {
                return llamaMobile.loadGrammar(from: filePath)
            }.value
            
            if let grammar = grammar {
                call.resolve(["grammar": grammar])
            } else {
                call.reject("Failed to load grammar file")
            }
        }
    }
    
    // MARK: - TTS
    
    @objc func initVocoder(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let vocoderModelPath = call.getString("vocoderModelPath") else {
            call.reject("contextHandle and vocoderModelPath are required")
            return
        }
        
        Task {
            let success = await Task.detached {
                return llamaMobile.initVocoder(vocoderModelPath: vocoderModelPath)
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    @objc func releaseVocoder(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            await Task.detached {
                llamaMobile.releaseVocoder()
            }.value
            call.resolve()
        }
    }
    
    @objc func isVocoderEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let enabled = await Task.detached {
                return llamaMobile.isVocoderEnabled()
            }.value
            call.resolve(["enabled": enabled])
        }
    }
    
    @objc func getTTSType(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let type = await Task.detached {
                return llamaMobile.getTTSType()
            }.value
            call.resolve(["type": type.rawValue])
        }
    }
    
    @objc func generateSpeechAsync(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        Task {
            let result = await llamaMobile.generateSpeechAsync(
                text: text,
                options: options
            )
            
            switch result {
            case .success(let speechResult):
                // Generate temporary file path
                let tempFileName = "temp_audio_\(UUID().uuidString).wav"
                
                // Convert Int16 audio samples to Float by normalizing to [-1.0, 1.0]
                let floatAudioData = speechResult.audioSamples.map { Float($0) / Float(Int16.max) }
                
                // Use existing saveAudioToWav method internally
                let saveSuccess = await Task.detached {
                    return self.saveAudioToWavInternal(
                        contextHandle: contextHandle,
                        llamaMobile: llamaMobile,
                        filePath: tempFileName,
                        audioData: floatAudioData,
                        sampleRate: speechResult.sampleRate
                    )
                }.value
                
                if saveSuccess {
                    // Resolve with the file path
                    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let tempFilePath = documentsDir.appendingPathComponent(tempFileName).path
                    
                    // Convert TTSMethod to string for JSON serialization
                    let methodUsedString = speechResult.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                    
                    // Round duration to 2 decimal places for better JSON serialization
                    let roundedDuration = Double(round(speechResult.duration * 100) / 100)
                    
                    call.resolve([
                        "audioPath": tempFilePath,
                        "sampleRate": speechResult.sampleRate,
                        "duration": roundedDuration,
                        "methodUsed": methodUsedString
                    ])
                } else {
                    call.reject("Failed to save audio to file")
                }
            case .failure(let error):
                call.reject("Failed to generate speech: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateSpeech(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        Task {
            let result = await Task.detached {
                return llamaMobile.generateSpeech(
                    text: text,
                    options: options
                )
            }.value
            
            switch result {
            case .success(let speechResult):
                // Generate temporary file path
                let tempFileName = "temp_audio_\(UUID().uuidString).wav"
                
                // Convert Int16 audio samples to Float by normalizing to [-1.0, 1.0]
                let floatAudioData = speechResult.audioSamples.map { Float($0) / Float(Int16.max) }
                
                // Use existing saveAudioToWav method internally
                let saveSuccess = await Task.detached {
                    return self.saveAudioToWavInternal(
                        contextHandle: contextHandle,
                        llamaMobile: llamaMobile,
                        filePath: tempFileName,
                        audioData: floatAudioData,
                        sampleRate: speechResult.sampleRate
                    )
                }.value
                
                if saveSuccess {
                    // Resolve with the file path
                    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let tempFilePath = documentsDir.appendingPathComponent(tempFileName).path
                    
                    // Convert TTSMethod to string for JSON serialization
                    let methodUsedString = speechResult.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                    
                    // Round duration to 2 decimal places for better JSON serialization
                    let roundedDuration = Double(round(speechResult.duration * 100) / 100)
                    
                    call.resolve([
                        "audioPath": tempFilePath,
                        "sampleRate": speechResult.sampleRate,
                        "duration": roundedDuration,
                        "methodUsed": methodUsedString
                    ])
                } else {
                    call.reject("Failed to save audio to file")
                }
            case .failure(let error):
                call.reject("Failed to generate speech sync: \(error.localizedDescription)")
            }
        }
    }
    
    // Internal method to save audio to WAV using existing logic
    private func saveAudioToWavInternal(
        contextHandle: Int,
        llamaMobile: LlamaMobile,
        filePath: String,
        audioData: [Float],
        sampleRate: Int
    ) -> Bool {
        // Resolve filePath to app's documents directory
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalPath = documentsDir.appendingPathComponent(filePath).path
        
        // Ensure directory exists
        let fileManager = FileManager.default
        let directory = (finalPath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: directory) {
            do {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
                return false
            }
        }
        
        return llamaMobile.saveAudioToWav(filePath: finalPath, audioData: audioData, sampleRate: Int32(sampleRate))
    }
    
    
    @objc func generateSpeechStreamForLongTextAsync(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        var ttsOptions = LlamaMobile.TTSOptions()
        ttsOptions.sampleRate = sampleRate
        
        Task {
            let result = await llamaMobile.generateSpeechStreamForLongTextAsync(
                text: text,
                options: ttsOptions,
                progressHandler: { progress in
                    self.notifyListeners("progress", data: ["progress": progress])
                },
                audioChunkHandler: { audioChunk in
                    self.notifyListeners("audioChunk", data: ["audio": audioChunk])
                }
            )
            
            switch result {
            case .success(let metadata):
                let methodUsedString = metadata.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                let roundedDuration = Double(round(metadata.duration * 100) / 100)
                
                call.resolve([
                    "sampleRate": metadata.sampleRate,
                    "duration": roundedDuration,
                    "methodUsed": methodUsedString
                ])
            case .failure(let error):
                call.reject("Failed to generate speech stream: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func saveAudioToWav(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let filePath = call.getString("filePath"),
              let audioData = call.getArray("audioData", Float.self) else {
            call.reject("contextHandle, filePath, and audioData are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        Task {
            let success = await Task.detached {
                return self.saveAudioToWavInternal(
                    contextHandle: contextHandle,
                    llamaMobile: llamaMobile,
                    filePath: filePath,
                    audioData: audioData,
                    sampleRate: sampleRate
                )
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    @objc func playAudio(_ call: CAPPluginCall) {
        guard let audioData = call.getArray("audioData", Float.self) else {
            call.reject("audioData is required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        Task {
            let success = await Task.detached {
                return self.playAudioSamples(audioData: audioData, sampleRate: Int32(sampleRate))
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    private func playAudioSamples(audioData: [Float], sampleRate: Int32) -> Bool {
        do {
            // Create audio format
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: 1, interleaved: false)
            guard let audioFormat = audioFormat else {
                print("Failed to create audio format")
                return false
            }
            
            // Create audio buffer
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(audioData.count))
            guard let audioBuffer = audioBuffer else {
                print("Failed to create audio buffer")
                return false
            }
            
            // Copy audio data to buffer
            audioBuffer.frameLength = UInt32(audioData.count)
            let floatBuffer = audioBuffer.floatChannelData?[0]
            for (i, sample) in audioData.enumerated() {
                floatBuffer?[i] = sample
            }
            
            // Stop any existing audio playback
            if let existingPlayerNode = playerNode {
                existingPlayerNode.stop()
            }
            
            if let existingAudioEngine = audioEngine {
                existingAudioEngine.stop()
                existingAudioEngine.reset()
            }
            
            // Create new audio engine and player node
            let newAudioEngine = AVAudioEngine()
            let newPlayerNode = AVAudioPlayerNode()
            
            // Store references
            self.audioEngine = newAudioEngine
            self.playerNode = newPlayerNode
            
            // Attach and connect nodes
            newAudioEngine.attach(newPlayerNode)
            newAudioEngine.connect(newPlayerNode, to: newAudioEngine.mainMixerNode, format: audioFormat)
            
            // Start audio engine
            try newAudioEngine.start()
            
            // Play audio
            newPlayerNode.scheduleBuffer(audioBuffer) {
                // Playback completed
                DispatchQueue.main.async {
                    // Release references after playback
                    self.playerNode = nil
                    self.audioEngine = nil
                }
            }
            
            newPlayerNode.play()
            
            return true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            // Clean up references on error
            self.playerNode = nil
            self.audioEngine = nil
            return false
        }
    }
    
    @objc func playAudioFromFile(_ call: CAPPluginCall) {
        guard let filePath = call.getString("filePath") else {
            call.reject("filePath is required")
            return
        }
        
        Task {
            let success = await Task.detached {
                return self.playAudioFromFilePath(filePath: filePath)
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    private func playAudioFromFilePath(filePath: String) -> Bool {
        do {
            // Stop any existing audio playback
            if let existingPlayerNode = playerNode {
                existingPlayerNode.stop()
            }
            
            if let existingAudioEngine = audioEngine {
                existingAudioEngine.stop()
                existingAudioEngine.reset()
            }
            
            // Create audio player with the file
            let audioURL = URL(fileURLWithPath: filePath)
            let audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            
            // Set up audio session with proper options
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Play audio
            audioPlayer.play()
            
            // Wait for playback to complete
            while audioPlayer.isPlaying {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Deactivate audio session with proper options
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            return true
        } catch {
            print("Error playing audio from file: \(error.localizedDescription)")
            // Clean up references on error
            self.playerNode = nil
            self.audioEngine = nil
            return false
        }
    }
    
    // MARK: - Multimodal
    
    @objc func initMultimodal(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let mmprojPath = call.getString("mmprojPath") else {
            call.reject("contextHandle and mmprojPath are required")
            return
        }
        
        let useGpu = call.getBool("useGpu") ?? true
        
        Task {
            let success = await Task.detached {
                return llamaMobile.initMultimodal(mmprojPath: mmprojPath, useGpu: useGpu)
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    @objc func releaseMultimodal(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            await Task.detached {
                llamaMobile.releaseMultimodal()
            }.value
            call.resolve()
        }
    }
    
    @objc func isMultimodalEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let enabled = await Task.detached {
                return llamaMobile.isMultimodalEnabled()
            }.value
            call.resolve(["enabled": enabled])
        }
    }
    
    @objc func supportsVision(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let supported = await Task.detached {
                return llamaMobile.supportsVision()
            }.value
            call.resolve(["supported": supported])
        }
    }
    
    @objc func supportsAudio(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let supported = await Task.detached {
                return llamaMobile.supportsAudio()
            }.value
            call.resolve(["supported": supported])
        }
    }
    
    // MARK: - LoRA
    
    @objc func applyLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let adapters = call.getArray("adapters") as? [[String: Any]] else {
            call.reject("contextHandle and adapters are required")
            return
        }
        
        Task {
            let success = await Task.detached {
                var loraAdapters: [LlamaMobile.LoraAdapter] = []
                for adapter in adapters {
                    if let path = adapter["path"] as? String {
                        let scale = (adapter["scale"] as? Double) ?? 1.0
                        loraAdapters.append(LlamaMobile.LoraAdapter(path: path, scale: Float(scale)))
                    }
                }
                
                return llamaMobile.applyLoraAdapters(loraAdapters)
            }.value
            
            call.resolve(["success": success])
        }
    }
    
    @objc func removeLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            await Task.detached {
                llamaMobile.removeLoraAdapters()
            }.value
            call.resolve()
        }
    }
    
    @objc func getLoadedLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let adapterDicts = await Task.detached {
                let adapters = llamaMobile.getLoadedLoraAdapters()
                return adapters?.map { adapter -> [String: Any] in
                    return ["path": adapter.path, "scale": adapter.scale]
                } ?? []
            }.value
            
            call.resolve(["adapters": adapterDicts])
        }
    }
    
    // MARK: - Conversation
    
    @objc func generateResponse(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let userMessage = call.getString("userMessage") else {
            call.reject("contextHandle and userMessage are required")
            return
        }
        
        let maxTokens = call.getInt("maxTokens") ?? 128
        let enableStreaming = call.getBool("enableStreaming") ?? false
        
        Task {
            let result = await Task.detached {
                return llamaMobile.generateResponse(
                    userMessage: userMessage,
                    maxTokens: Int32(maxTokens),
                    tokenCallback: enableStreaming ? { token in
                        self.notifyListeners("token", data: ["token": token])
                        return true
                    } : nil
                )
            }.value
            
            if let result = result {
                call.resolve([
                    "text": result.text,
                    "tokensGenerated": result.tokensGenerated
                ])
            } else {
                call.reject("Failed to generate response")
            }
        }
    }
    
    @objc func clearConversation(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        llamaMobile.clearConversation()
        call.resolve()
    }
    
    @objc func isConversationActive(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let active = await Task.detached {
                return llamaMobile.isConversationActive()
            }.value
            call.resolve(["active": active])
        }
    }
    
    // MARK: - Embeddings
    
    @objc func generateEmbeddings(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        Task {
            let embeddings = await Task.detached {
                return llamaMobile.generateEmbeddings(for: text)
            }.value
            
            if let embeddings = embeddings {
                call.resolve(["embedding": embeddings])
            } else {
                call.reject("Failed to generate embeddings")
            }
        }
    }
    
    // MARK: - Tokenization
    
    @objc func tokenize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        Task {
            let tokens = await Task.detached {
                return llamaMobile.tokenize(text: text)
            }.value
            
            let tokenInts = tokens?.map { Int($0) } ?? []
            call.resolve(["tokens": tokenInts])
        }
    }
    
    @objc func detokenize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let tokens = call.getArray("tokens", Int.self) else {
            call.reject("contextHandle and tokens are required")
            return
        }
        
        Task {
            let text = await Task.detached {
                let tokenInt32s = tokens.map { Int32($0) }
                return llamaMobile.detokenize(tokens: tokenInt32s)
            }.value
            
            call.resolve(["text": text ?? ""])
        }
    }
    
    // MARK: - Model Info
    
    @objc func getContextWindowSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let size = await Task.detached {
                return llamaMobile.getContextWindowSize()
            }.value
            call.resolve(["size": Int(size)])
        }
    }
    
    @objc func getEmbeddingDimension(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let dimension = await Task.detached {
                return llamaMobile.getEmbeddingDimension()
            }.value
            call.resolve(["dimension": Int(dimension)])
        }
    }
    
    @objc func getModelDescription(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let description = await Task.detached {
                return llamaMobile.getModelDescription()
            }.value
            call.resolve(["description": description ?? ""])
        }
    }
    
    @objc func getModelSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let size = await Task.detached {
                return llamaMobile.getModelSize()
            }.value
            call.resolve(["size": size])
        }
    }
    
    @objc func getModelParametersCount(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        Task {
            let count = await Task.detached {
                return llamaMobile.getModelParametersCount()
            }.value
            call.resolve(["count": count])
        }
    }
    
    @objc func listFiles(_ call: CAPPluginCall) {
        guard let directory = call.getString("directory") else {
            call.reject("directory is required")
            return
        }
        
        Task {
            let files = await Task.detached {
                var files: [String] = []
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: directory), 
                   let enumerator = fileManager.enumerator(atPath: directory) {
                    while let file = enumerator.nextObject() as? String {
                        files.append(file)
                    }
                }
                return files
            }.value
            
            call.resolve(["files": files])
        }
    }
    
    @objc func listModels(_ call: CAPPluginCall) {
        Task {
            let modelArray = await Task.detached {
                // Define model info struct
                struct ModelInfo {
                    let name: String
                    let path: String
                }
                
                var models: [ModelInfo] = []
                let fileManager = FileManager.default
                
                // Get documents directory
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                // Directories to scan
                var modelDirectories = [
                    documentsDirectory,
                    documentsDirectory + "/models",
                    documentsDirectory + "/Downloads",
                    documentsDirectory + "/Downloads/models"
                ]
                
                // Add app bundle directories for bundled models
                let bundlePath = Bundle.main.bundlePath
                let bundleModelDirectories = [
                    bundlePath + "/public/models",
                    bundlePath + "/models",
                    bundlePath
                ]
                modelDirectories.append(contentsOf: bundleModelDirectories)
                
                // Model file extensions to look for
                let modelExtensions = ["gguf", "safetensors", "bin"]
                
                for directory in modelDirectories {
                    if fileManager.fileExists(atPath: directory), 
                       let enumerator = fileManager.enumerator(atPath: directory) {
                        while let file = enumerator.nextObject() as? String {
                            let fullPath = directory + (directory.hasSuffix("/") ? "" : "/") + file
                            let lowercasedFile = file.lowercased()
                            
                            // Check if file has a model extension
                            for ext in modelExtensions {
                                if lowercasedFile.hasSuffix("." + ext) {
                                    models.append(ModelInfo(name: file, path: fullPath))
                                    break
                                }
                            }
                        }
                    }
                }
                
                // Convert to the expected format
                var modelsResult: [[String: String]] = []
                for model in models {
                    modelsResult.append(["name": model.name, "path": model.path])
                }
                return modelsResult
            }.value
            
            call.resolve(["models": modelArray])
        }
    }
    
    
    
    // MARK: - Download
    
    @objc func downloadModel(_ call: CAPPluginCall) {
        guard let url = call.getString("url"),
              let localPath = call.getString("localPath") else {
            call.reject("url and localPath are required")
            return
        }
        
        Task {
            let result = await Task.detached {
                let params = LlamaMobile.DownloadParams(
                    url: url,
                    localPath: localPath,
                    progressCallback: { progress in
                        self.notifyListeners("progress", data: ["progress": progress])
                    }
                )
                
                return LlamaMobile.download(with: params)
            }.value
            
            call.resolve([
                "success": result.success,
                "localPath": result.localPath,
                "errorMessage": result.errorMessage ?? ""
            ])
        }
    }
    
    @objc func downloadHfFile(_ call: CAPPluginCall) {
        guard let repoId = call.getString("repoId"),
              let filename = call.getString("filename"),
              let localPath = call.getString("destinationPath") else {
            call.reject("repoId, filename, and destinationPath are required")
            return
        }
        
        let bearerToken = call.getString("bearerToken")
        let offline = call.getBool("offline", false)
        
        Task {
            let result = await Task.detached {
                let params = LlamaMobile.HuggingFaceDownloadParams(
                    repoID: repoId,
                    filename: filename,
                    destinationPath: localPath,
                    bearerToken: bearerToken,
                    offline: offline,
                    progressCallback: { progress in
                        self.notifyListeners("progress", data: ["progress": progress])
                    }
                )
                
                return LlamaMobile.downloadHuggingFaceFile(with: params)
            }.value
            
            call.resolve([
                "success": result.success,
                "localPath": result.localPath,
                "errorMessage": result.errorMessage ?? ""
            ])
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func saveBase64ImageToTempFile(_ base64Data: String) -> String? {
        guard base64Data.hasPrefix("data:image/") else {
            return nil
        }
        
        var imageData = base64Data
        
        if let commaIndex = base64Data.firstIndex(of: ",") {
            imageData = String(base64Data[commaIndex...].dropFirst())
        } else {
            return nil
        }
        
        guard let decodedData = Data(base64Encoded: imageData) else {
            return nil
        }
        
        guard let image = UIImage(data: decodedData) else {
            return nil
        }
        
        guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "temp_image_\(UUID().uuidString).jpg"
        let tempFilePath = tempDir.appendingPathComponent(filename)
        
        do {
            try jpegData.write(to: tempFilePath)
            return tempFilePath.path
        } catch {
            return nil
        }
    }
}
