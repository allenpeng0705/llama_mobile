import Foundation
import Capacitor

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
        CAPPluginMethod(name: "generateAudioFromText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeech", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeechSync", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeechStream", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateSpeechStreamForLongText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveAudioToWav", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "playAudio", returnType: CAPPluginReturnPromise),
        
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
        
        // Chat
        CAPPluginMethod(name: "setChatTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getModelChatTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "formatChatMessages", returnType: CAPPluginReturnPromise)
    ]
    
    private var contexts: [Int: LlamaMobile] = [:]
    private var nextContextHandle: Int = 1
    
    private func getNextContextHandle() -> Int {
        let handle = nextContextHandle
        nextContextHandle += 1
        return handle
    }
    
    // MARK: - Initialization
    
    @objc func initContext(_ call: CAPPluginCall) {
        guard let modelPath = call.getString("modelPath") else {
            call.reject("modelPath is required")
            return
        }
        
        let nCtx = call.getInt("nCtx") ?? 2048
        let nGpuLayers = call.getInt("nGpuLayers") ?? 0
        let nThreads = call.getInt("nThreads") ?? 4
        let embedding = call.getBool("embedding") ?? false
        let poolingType = call.getInt("poolingType") ?? 0
        let embdNormalize = call.getInt("embdNormalize") ?? 1
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let llamaMobile = try LlamaMobile(
                    modelPath: modelPath,
                    nCtx: Int32(nCtx),
                    nGpuLayers: Int32(nGpuLayers),
                    nThreads: Int32(nThreads),
                    embedding: embedding,
                    poolingType: Int32(poolingType),
                    embdNormalize: Int32(embdNormalize)
                )
                
                DispatchQueue.main.async {
                    let contextHandle = self.getNextContextHandle()
                    self.contexts[contextHandle] = llamaMobile
                    call.resolve(["contextHandle": contextHandle])
                }
            } catch {
                DispatchQueue.main.async {
                    call.reject("Failed to initialize context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func releaseContext(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            llamaMobile.releaseContext()
            DispatchQueue.main.async {
                self.contexts.removeValue(forKey: contextHandle)
                call.resolve()
            }
        }
    }
    
    // MARK: - Completion
    
    @objc func generateCompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let params = call.getObject("params"),
              let prompt = params["prompt"] as? String else {
            call.reject("contextHandle and params.prompt are required")
            return
        }
        
        let maxTokens = (params["maxTokens"] as? Int) ?? 128
        let temperature = (params["temperature"] as? Double) ?? 0.8
        let mediaPaths = (params["mediaPaths"] as? [String]) ?? []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var processedMediaPaths: [String] = []
            for mediaPath in mediaPaths {
                if mediaPath.hasPrefix("data:image/") || mediaPath.count > 1000 {
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
                temperature: temperature
            )
            
            let result = llamaMobile.generateCompletion(with: completionParams)
            
            DispatchQueue.main.async {
                if let result = result {
                    call.resolve([
                        "text": result.text,
                        "tokensGenerated": result.tokensGenerated,
                        "tokensEvaluated": result.tokensEvaluated,
                        "truncated": result.truncated,
                        "stoppedEos": result.stoppedEos,
                        "stoppedWord": result.stoppedWord,
                        "stoppedLimit": result.stoppedLimit
                    ])
                } else {
                    call.reject("Failed to generate completion")
                }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = llamaMobile.generateOpenAICompletion(with: openAIJSON)
            
            DispatchQueue.main.async {
                if let result = result {
                    call.resolve([
                        "text": result.text,
                        "tokensGenerated": result.tokensGenerated,
                        "tokensEvaluated": result.tokensEvaluated,
                        "truncated": result.truncated,
                        "stoppedEos": result.stoppedEos,
                        "stoppedWord": result.stoppedWord,
                        "stoppedLimit": result.stoppedLimit
                    ])
                } else {
                    call.reject("Failed to generate OpenAI completion")
                }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let grammar = llamaMobile.loadGrammar(from: filePath)
            
            DispatchQueue.main.async {
                if let grammar = grammar {
                    call.resolve(["grammar": grammar])
                } else {
                    call.reject("Failed to load grammar file")
                }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = llamaMobile.initVocoder(vocoderModelPath: vocoderModelPath)
            
            DispatchQueue.main.async {
                call.resolve(["success": success])
            }
        }
    }
    
    @objc func releaseVocoder(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            llamaMobile.releaseVocoder()
            DispatchQueue.main.async {
                call.resolve()
            }
        }
    }
    
    @objc func isVocoderEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let enabled = llamaMobile.isVocoderEnabled()
        call.resolve(["enabled": enabled])
    }
    
    @objc func getTTSType(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let type = llamaMobile.getTTSType()
        call.resolve(["type": type.rawValue])
    }
    
    @objc func generateAudioFromText(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let speakerJson = call.getString("speakerJson") ?? "{\"speaker\": \"default\"}"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let audioSamples = llamaMobile.generateAudioFromText(text: text, speakerJson: speakerJson)
            
            DispatchQueue.main.async {
                if let audioSamples = audioSamples {
                    call.resolve(["audio": audioSamples])
                } else {
                    call.reject("Failed to generate audio from text")
                }
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
        let method = call.getString("method") ?? "best"
        let speakerJson = call.getString("speakerJson") ?? "{\"speaker\": \"default\"}"
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                let result = await llamaMobile.generateSpeech(
                    text: text,
                    options: options,
                    progressHandler: { progress in
                        DispatchQueue.main.async {
                            self.notifyListeners("progress", data: ["progress": progress])
                        }
                    }
                )
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let speechResult):
                        call.resolve([
                            "audio": speechResult.audioSamples,
                            "sampleRate": speechResult.sampleRate,
                            "duration": speechResult.duration,
                            "methodUsed": speechResult.methodUsed
                        ])
                    case .failure(let error):
                        call.reject("Failed to generate speech: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @objc func generateSpeechSync(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        let method = call.getString("method") ?? "best"
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = llamaMobile.generateSpeechSync(
                text: text,
                options: options
            )
            
            DispatchQueue.main.async {
                switch result {
                case .success(let speechResult):
                    call.resolve([
                        "audio": speechResult.audioSamples,
                        "sampleRate": speechResult.sampleRate,
                        "duration": speechResult.duration,
                        "methodUsed": speechResult.methodUsed
                    ])
                case .failure(let error):
                    call.reject("Failed to generate speech sync: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func generateSpeechStream(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        let method = call.getString("method") ?? "best"
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                let result = await llamaMobile.generateSpeech(
                    text: text,
                    options: options,
                    progressHandler: { progress in
                        DispatchQueue.main.async {
                            self.notifyListeners("progress", data: ["progress": progress])
                        }
                    }
                )
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let speechResult):
                        let audioChunk = speechResult.audioSamples
                        self.notifyListeners("audioChunk", data: ["audio": audioChunk])
                        
                        call.resolve([
                            "sampleRate": speechResult.sampleRate,
                            "duration": speechResult.duration,
                            "methodUsed": speechResult.methodUsed
                        ])
                    case .failure(let error):
                        call.reject("Failed to generate speech stream: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @objc func generateSpeechStreamForLongText(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        let method = call.getString("method") ?? "best"
        
        var options = LlamaMobile.TTSOptions()
        options.sampleRate = sampleRate
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                let result = await llamaMobile.generateSpeechStreamForLongText(
                    text: text,
                    options: options,
                    progressHandler: { progress in
                        DispatchQueue.main.async {
                            self.notifyListeners("progress", data: ["progress": progress])
                        }
                    },
                    audioChunkHandler: { audioChunk in
                        DispatchQueue.main.async {
                            self.notifyListeners("audioChunk", data: ["audio": audioChunk])
                        }
                    }
                )
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let metadata):
                        call.resolve([
                            "sampleRate": metadata.sampleRate,
                            "duration": metadata.duration,
                            "methodUsed": metadata.methodUsed
                        ])
                    case .failure(let error):
                        call.reject("Failed to generate speech stream: \(error.localizedDescription)")
                    }
                }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = llamaMobile.saveAudioToWav(filePath: filePath, audioData: audioData, sampleRate: Int32(sampleRate))
            
            DispatchQueue.main.async {
                call.resolve(["success": success])
            }
        }
    }
    
    @objc func playAudio(_ call: CAPPluginCall) {
        guard let audioData = call.getArray("audioData", Float.self) else {
            call.reject("audioData is required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.playAudioSamples(audioData: audioData, sampleRate: Int32(sampleRate))
            
            DispatchQueue.main.async {
                call.resolve(["success": success])
            }
        }
    }
    
    private func playAudioSamples(audioData: [Float], sampleRate: Int32) -> Bool {
        return false
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = llamaMobile.initMultimodal(mmprojPath: mmprojPath, useGpu: useGpu)
            
            DispatchQueue.main.async {
                call.resolve(["success": success])
            }
        }
    }
    
    @objc func releaseMultimodal(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            llamaMobile.releaseMultimodal()
            DispatchQueue.main.async {
                call.resolve()
            }
        }
    }
    
    @objc func isMultimodalEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let enabled = llamaMobile.isMultimodalEnabled()
        call.resolve(["enabled": enabled])
    }
    
    @objc func supportsVision(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let supported = llamaMobile.supportsVision()
        call.resolve(["supported": supported])
    }
    
    @objc func supportsAudio(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let supported = llamaMobile.supportsAudio()
        call.resolve(["supported": supported])
    }
    
    // MARK: - LoRA
    
    @objc func applyLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let adapters = call.getArray("adapters") as? [[String: Any]] else {
            call.reject("contextHandle and adapters are required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var loraAdapters: [LlamaMobile.LoraAdapter] = []
            for adapter in adapters {
                if let path = adapter["path"] as? String {
                    let scale = (adapter["scale"] as? Double) ?? 1.0
                    loraAdapters.append(LlamaMobile.LoraAdapter(path: path, scale: Float(scale)))
                }
            }
            
            let success = llamaMobile.applyLoraAdapters(loraAdapters)
            
            DispatchQueue.main.async {
                call.resolve(["success": success])
            }
        }
    }
    
    @objc func removeLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            llamaMobile.removeLoraAdapters()
            DispatchQueue.main.async {
                call.resolve()
            }
        }
    }
    
    @objc func getLoadedLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let adapters = llamaMobile.getLoadedLoraAdapters()
        let adapterDicts = adapters?.map { adapter -> [String: Any] in
            return ["path": adapter.path, "scale": adapter.scale]
        } ?? []
        
        call.resolve(["adapters": adapterDicts])
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = llamaMobile.generateResponse(userMessage: userMessage, maxTokens: Int32(maxTokens))
            
            DispatchQueue.main.async {
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
        
        let active = llamaMobile.isConversationActive()
        call.resolve(["active": active])
    }
    
    // MARK: - Embeddings
    
    @objc func generateEmbeddings(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let embeddings = llamaMobile.generateEmbeddings(for: text)
            
            DispatchQueue.main.async {
                if let embeddings = embeddings {
                    call.resolve(["embedding": embeddings])
                } else {
                    call.reject("Failed to generate embeddings")
                }
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
        
        let tokens = llamaMobile.tokenize(text: text)
        let tokenInts = tokens?.map { Int($0) } ?? []
        
        call.resolve(["tokens": tokenInts])
    }
    
    @objc func detokenize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle],
              let tokens = call.getArray("tokens", Int.self) else {
            call.reject("contextHandle and tokens are required")
            return
        }
        
        let tokenInt32s = tokens.map { Int32($0) }
        let text = llamaMobile.detokenize(tokens: tokenInt32s)
        
        call.resolve(["text": text ?? ""])
    }
    
    // MARK: - Model Info
    
    @objc func getContextWindowSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let size = llamaMobile.getContextWindowSize()
        call.resolve(["size": Int(size)])
    }
    
    @objc func getEmbeddingDimension(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let dimension = llamaMobile.getEmbeddingDimension()
        call.resolve(["dimension": Int(dimension)])
    }
    
    @objc func getModelDescription(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let description = llamaMobile.getModelDescription()
        call.resolve(["description": description ?? ""])
    }
    
    @objc func getModelSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let size = llamaMobile.getModelSize()
        call.resolve(["size": size])
    }
    
    @objc func getModelParametersCount(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let llamaMobile = contexts[contextHandle] else {
            call.reject("contextHandle is required")
            return
        }
        
        let count = llamaMobile.getModelParametersCount()
        call.resolve(["count": count])
    }
    
    
    
    // MARK: - Download
    
    @objc func downloadModel(_ call: CAPPluginCall) {
        guard let url = call.getString("url"),
              let localPath = call.getString("localPath") else {
            call.reject("url and localPath are required")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let params = LlamaMobile.DownloadParams(
                url: url,
                localPath: localPath,
                progressCallback: { progress in
                    DispatchQueue.main.async {
                        self.notifyListeners("downloadProgress", data: ["progress": progress])
                    }
                }
            )
            
            let result = LlamaMobile.download(with: params)
            
            DispatchQueue.main.async {
                call.resolve([
                    "success": result.success,
                    "localPath": result.localPath ?? "",
                    "errorMessage": result.errorMessage ?? ""
                ])
            }
        }
    }
    
    @objc func downloadHfFile(_ call: CAPPluginCall) {
        guard let repoId = call.getString("repoId"),
              let filename = call.getString("filename"),
              let localPath = call.getString("localPath") else {
            call.reject("repoId, filename, and localPath are required")
            return
        }
        
        let bearerToken = call.getString("bearerToken")
        let offline = call.getBool("offline", false)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let params = LlamaMobile.HuggingFaceDownloadParams(
                repoID: repoId,
                filename: filename,
                destinationPath: localPath,
                bearerToken: bearerToken,
                offline: offline,
                progressCallback: { progress in
                    DispatchQueue.main.async {
                        self.notifyListeners("downloadProgress", data: ["progress": progress])
                    }
                }
            )
            
            let result = LlamaMobile.downloadHuggingFaceFile(with: params)
            
            DispatchQueue.main.async {
                call.resolve([
                    "success": result.success,
                    "localPath": result.localPath ?? "",
                    "errorMessage": result.errorMessage ?? ""
                ])
            }
        }
    }
    
    // MARK: - Chat
    
    @objc func setChatTemplate(_ call: CAPPluginCall) {
        call.resolve()
    }
    
    @objc func getModelChatTemplate(_ call: CAPPluginCall) {
        call.resolve(["template": ""])
    }
    
    @objc func formatChatMessages(_ call: CAPPluginCall) {
        call.resolve(["formattedPrompt": ""])
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
