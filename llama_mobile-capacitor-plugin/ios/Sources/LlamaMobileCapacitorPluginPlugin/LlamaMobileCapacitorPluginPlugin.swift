import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(LlamaMobileCapacitorPluginPlugin)
public class LlamaMobileCapacitorPluginPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LlamaMobileCapacitorPluginPlugin"
    public let jsName = "LlamaMobileCapacitorPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        // Initialization
        CAPPluginMethod(name: "initContext", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseContext", returnType: CAPPluginReturnPromise),
        
        // Completion
        CAPPluginMethod(name: "generateCompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateOpenAICompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopCompletion", returnType: CAPPluginReturnPromise),
        
        // TTS
        CAPPluginMethod(name: "initVocoder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseVocoder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isVocoderEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getTTSType", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateAudioFromText", returnType: CAPPluginReturnPromise),
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
        
        // Custom methodsDownload
        CAPPluginMethod(name: "downloadModel", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "downloadHfFile", returnType: CAPPluginReturnPromise),
        
        // Grammar
        CAPPluginMethod(name: "getJsonGrammar", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getArithmeticGrammar", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCGrammar", returnType: CAPPluginReturnPromise),
        
        // Chat
        CAPPluginMethod(name: "setChatTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getModelChatTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "formatChatMessages", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = LlamaMobileCapacitorPlugin()

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
        
        let contextHandle = implementation.initContext(
            modelPath: modelPath,
            nCtx: Int32(nCtx),
            nGpuLayers: Int32(nGpuLayers),
            nThreads: Int32(nThreads),
            embedding: embedding,
            poolingType: Int32(poolingType),
            embdNormalize: Int32(embdNormalize)
        )
        
        call.resolve(["contextHandle": contextHandle])
    }
    
    @objc func releaseContext(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.releaseContext(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    // MARK: - Completion
    
    @objc func generateCompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let params = call.getObject("params"),
              let prompt = params["prompt"] as? String else {
            call.reject("contextHandle and params.prompt are required")
            return
        }
        
        let maxTokens = (params["maxTokens"] as? Int) ?? 128
        let temperature = (params["temperature"] as? Double) ?? 0.8
        let mediaPaths = (params["mediaPaths"] as? [String]) ?? []
        
        // Handle base64 image data
        var processedMediaPaths: [String] = []
        for mediaPath in mediaPaths {
            if mediaPath.hasPrefix("data:image/") || mediaPath.count > 1000 {
                // This is base64 data, convert to temporary file
                print("[Swift] Detected base64 image data, converting to temp file...")
                if let tempFilePath = saveBase64ImageToTempFile(mediaPath) {
                    processedMediaPaths.append(tempFilePath)
                    print("[Swift] Successfully converted base64 to temp file: \(tempFilePath)")
                } else {
                    print("[Swift] Error: Failed to save base64 image to temp file - skipping this image")
                }
            } else {
                // This is a file path
                print("[Swift] Using file path directly: \(mediaPath)")
                processedMediaPaths.append(mediaPath)
            }
        }
        
        if processedMediaPaths.isEmpty && !mediaPaths.isEmpty {
            print("[Swift] Warning: All image conversions failed, proceeding without images")
        }
        
        let result = implementation.generateCompletion(
            contextHandle: Int64(contextHandle),
            prompt: prompt,
            maxTokens: Int32(maxTokens),
            temperature: temperature,
            mediaPaths: processedMediaPaths
        )
        
        call.resolve(result)
    }
    
    private func saveBase64ImageToTempFile(_ base64Data: String) -> String? {
        print("[Swift] saveBase64ImageToTempFile called")
        print("[Swift] Input data length: \(base64Data.count) characters")
        
        // Check if this is a data URL
        guard base64Data.hasPrefix("data:image/") else {
            print("[Swift] Error: Input does not start with 'data:image/'")
            print("[Swift] First 100 chars: \(String(base64Data.prefix(100)))")
            return nil
        }
        
        // Extract base64 data
        var imageData = base64Data
        
        if let commaIndex = base64Data.firstIndex(of: ",") {
            let prefix = String(base64Data[..<commaIndex])
            imageData = String(base64Data[commaIndex...].dropFirst())
            print("[Swift] Data URL prefix: \(prefix)")
            print("[Swift] Extracted base64 data length: \(imageData.count) characters")
        } else {
            print("[Swift] Error: No comma found in data URL")
            return nil
        }
        
        // Decode base64 data
        guard let decodedData = Data(base64Encoded: imageData) else {
            print("[Swift] Error: Failed to decode base64 data")
            print("[Swift] First 100 chars of data: \(String(imageData.prefix(100)))")
            return nil
        }
        
        print("[Swift] Decoded data size: \(decodedData.count) bytes")
        
        // Create UIImage from decoded data
        guard let image = UIImage(data: decodedData) else {
            print("[Swift] Error: Could not create UIImage from decoded data - image is corrupted or unsupported format")
            return nil
        }
        
        print("[Swift] Image validation successful - Size: \(image.size.width)x\(image.size.height)")
        
        // Convert image to JPEG format for compatibility with multimodal model
        // Use maximum quality (1.0) to preserve image quality
        guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
            print("[Swift] Error: Failed to convert image to JPEG format")
            return nil
        }
        
        print("[Swift] Converted to JPEG format - Size: \(jpegData.count) bytes")
        
        // Create temporary file with .jpg extension
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "temp_image_\(UUID().uuidString).jpg"
        let tempFilePath = tempDir.appendingPathComponent(filename)
        
        do {
            try jpegData.write(to: tempFilePath)
            print("[Swift] Saved JPEG image to: \(tempFilePath.path)")
            print("[Swift] Final file size: \(jpegData.count) bytes")
            
            // Verify file was written correctly
            if FileManager.default.fileExists(atPath: tempFilePath.path) {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: tempFilePath.path),
                   let fileSize = attrs[.size] as? UInt64 {
                    print("[Swift] Verified file size on disk: \(fileSize) bytes")
                }
            } else {
                print("[Swift] Error: File was not created on disk")
                return nil
            }
            
            return tempFilePath.path
        } catch {
            print("[Swift] Failed to write image to temp file: \(error)")
            return nil
        }
    }
    
    @objc func generateOpenAICompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
            let openAIJSON = call.getString("openAIJSON") else {
            call.reject("contextHandle and openAIJSON are required")
            return
        }
        
        let grammar = call.getString("grammar")
        let stopSequences = call.getArray("stopSequences") as? [String]
        
        let result = implementation.generateOpenAICompletion(
            contextHandle: Int64(contextHandle),
            openAIJSON: openAIJSON,
            grammar: grammar,
            stopSequences: stopSequences
        )
        
        call.resolve(result)
    }
    
    @objc func stopCompletion(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.stopCompletion(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    // MARK: - TTS
    
    @objc func initVocoder(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let vocoderModelPath = call.getString("vocoderModelPath") else {
            call.reject("contextHandle and vocoderModelPath are required")
            return
        }
        
        let result = implementation.initVocoder(
            contextHandle: Int64(contextHandle),
            vocoderModelPath: vocoderModelPath
        )
        
        call.resolve(result)
    }
    
    @objc func releaseVocoder(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.releaseVocoder(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    @objc func isVocoderEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let enabled = implementation.isVocoderEnabled(contextHandle: Int64(contextHandle))
        call.resolve(["enabled": enabled])
    }
    
    @objc func getTTSType(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let type = implementation.getTTSType(contextHandle: Int64(contextHandle))
        call.resolve(["type": type])
    }
    
    @objc func generateAudioFromText(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let speakerJson = call.getString("speakerJson") ?? "{\"speaker\": \"default\"}"
        
        print("[Swift Plugin] generateAudioFromText called with contextHandle: \(contextHandle), text: '\(text)'")
        
        let audioSamples = implementation.generateAudioFromText(
            contextHandle: Int64(contextHandle),
            text: text,
            speakerJson: speakerJson
        )
        
        print("[Swift Plugin] Generated \(audioSamples.count) audio samples")
        call.resolve(["audio": audioSamples])
    }
    
    @objc func saveAudioToWav(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let filePath = call.getString("filePath"),
              let audioData = call.getArray("audioData", Float.self) else {
            call.reject("contextHandle, filePath, and audioData are required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        print("[Swift Plugin] saveAudioToWav called with contextHandle: \(contextHandle), filePath: '\(filePath)', sampleRate: \(sampleRate)")
        
        let success = implementation.saveAudioToWav(
            contextHandle: Int64(contextHandle),
            filePath: filePath,
            audioData: audioData,
            sampleRate: Int32(sampleRate)
        )
        
        print("[Swift Plugin] saveAudioToWav result: \(success)")
        call.resolve(["success": success])
    }
    
    @objc func playAudio(_ call: CAPPluginCall) {
        guard let audioData = call.getArray("audioData", Float.self) else {
            call.reject("audioData is required")
            return
        }
        
        let sampleRate = call.getInt("sampleRate") ?? 24000
        
        print("[Swift Plugin] playAudio called with \(audioData.count) samples at \(sampleRate) Hz")
        
        let success = implementation.playAudio(
            audioData: audioData,
            sampleRate: Int32(sampleRate)
        )
        
        print("[Swift Plugin] playAudio result: \(success)")
        call.resolve(["success": success])
    }
    
    // MARK: - Multimodal
    
    @objc func initMultimodal(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let mmprojPath = call.getString("mmprojPath") else {
            call.reject("contextHandle and mmprojPath are required")
            return
        }
        
        print("[Swift] initMultimodal called with:")
        print("[Swift]   contextHandle: \(contextHandle)")
        print("[Swift]   mmprojPath: '\(mmprojPath)'")
        
        let useGpu = call.getBool("useGpu") ?? true
        let success = implementation.initMultimodal(
            contextHandle: Int64(contextHandle),
            mmprojPath: mmprojPath,
            useGpu: useGpu
        )
        
        call.resolve(["success": success])
    }
    
    @objc func releaseMultimodal(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.releaseMultimodal(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    @objc func isMultimodalEnabled(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let enabled = implementation.isMultimodalEnabled(contextHandle: Int64(contextHandle))
        call.resolve(["enabled": enabled])
    }
    
    @objc func supportsVision(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let supported = implementation.supportsVision(contextHandle: Int64(contextHandle))
        call.resolve(["supported": supported])
    }
    
    @objc func supportsAudio(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let supported = implementation.supportsAudio(contextHandle: Int64(contextHandle))
        call.resolve(["supported": supported])
    }
    
    // MARK: - LoRA
    
    @objc func applyLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let adapters = call.getArray("adapters") as? [[String: Any]] else {
            call.reject("contextHandle and adapters are required")
            return
        }
        
        let success = implementation.applyLoraAdapters(contextHandle: Int64(contextHandle), adapters: adapters)
        call.resolve(["success": success])
    }
    
    @objc func removeLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.removeLoraAdapters(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    @objc func getLoadedLoraAdapters(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let adapters = implementation.getLoadedLoraAdapters(contextHandle: Int64(contextHandle))
        call.resolve(["adapters": adapters])
    }
    
    // MARK: - Conversation
    
    @objc func generateResponse(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let userMessage = call.getString("userMessage"),
              let maxTokens = call.getInt("maxTokens") else {
            call.reject("contextHandle, userMessage, and maxTokens are required")
            return
        }
        
        let result = implementation.generateResponse(
            contextHandle: Int64(contextHandle),
            userMessage: userMessage,
            maxTokens: Int32(maxTokens)
        )
        
        call.resolve(result)
    }
    
    @objc func clearConversation(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        implementation.clearConversation(contextHandle: Int64(contextHandle))
        call.resolve()
    }
    
    @objc func isConversationActive(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let active = implementation.isConversationActive(contextHandle: Int64(contextHandle))
        call.resolve(["active": active])
    }
    
    // MARK: - Embeddings
    
    @objc func generateEmbeddings(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let embedding = implementation.generateEmbeddings(contextHandle: Int64(contextHandle), text: text)
        call.resolve(["embedding": embedding])
    }
    
    // MARK: - Tokenization
    
    @objc func tokenize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let text = call.getString("text") else {
            call.reject("contextHandle and text are required")
            return
        }
        
        let tokens = implementation.tokenize(contextHandle: Int64(contextHandle), text: text)
        call.resolve(["tokens": tokens])
    }
    
    @objc func detokenize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let tokens = call.getArray("tokens") as? [Int32] else {
            call.reject("contextHandle and tokens are required")
            return
        }
        
        let text = implementation.detokenize(contextHandle: Int64(contextHandle), tokens: tokens)
        call.resolve(["text": text])
    }
    
    // MARK: - Model Info
    
    @objc func getContextWindowSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let size = implementation.getContextWindowSize(contextHandle: Int64(contextHandle))
        call.resolve(["size": size])
    }
    
    @objc func getEmbeddingDimension(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let dimension = implementation.getEmbeddingDimension(contextHandle: Int64(contextHandle))
        call.resolve(["dimension": dimension])
    }
    
    @objc func getModelDescription(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let description = implementation.getModelDescription(contextHandle: Int64(contextHandle))
        call.resolve(["description": description])
    }
    
    @objc func getModelSize(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let size = implementation.getModelSize(contextHandle: Int64(contextHandle))
        call.resolve(["size": size])
    }
    
    @objc func getModelParametersCount(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let count = implementation.getModelParametersCount(contextHandle: Int64(contextHandle))
        call.resolve(["count": count])
    }
    
    @objc func listFiles(_ call: CAPPluginCall) {
        guard let directoryPath = call.getString("directoryPath") else {
            call.reject("directoryPath is required")
            return
        }
        
        let result = implementation.listFiles(directoryPath: directoryPath)
        call.resolve(result)
    }
    
    @objc func listModels(_ call: CAPPluginCall) {
        let result = implementation.listModels()
        call.resolve(result)
    }
    
    // MARK: - Download
    
    @objc func downloadModel(_ call: CAPPluginCall) {
        guard let url = call.getString("url"),
              let localPath = call.getString("localPath") else {
            call.reject("url and localPath are required")
            return
        }
        
        let result = implementation.downloadModel(url: url, localPath: localPath)
        call.resolve(result)
    }
    
    @objc func downloadHfFile(_ call: CAPPluginCall) {
        guard let repoId = call.getString("repoId"),
              let filename = call.getString("filename"),
              let localPath = call.getString("localPath") else {
            call.reject("repoId, filename, and localPath are required")
            return
        }
        
        let result = implementation.downloadHfFile(repoId: repoId, filename: filename, localPath: localPath)
        call.resolve(result)
    }
    
    // MARK: - Grammar
    
    @objc func getJsonGrammar(_ call: CAPPluginCall) {
        let grammar = implementation.getJsonGrammar()
        call.resolve(["grammar": grammar])
    }
    
    @objc func getArithmeticGrammar(_ call: CAPPluginCall) {
        let grammar = implementation.getArithmeticGrammar()
        call.resolve(["grammar": grammar])
    }
    
    @objc func getCGrammar(_ call: CAPPluginCall) {
        let grammar = implementation.getCGrammar()
        call.resolve(["grammar": grammar])
    }
    
    // MARK: - Chat
    
    @objc func setChatTemplate(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let chatTemplate = call.getString("chatTemplate") else {
            call.reject("contextHandle and chatTemplate are required")
            return
        }
        
        let success = implementation.setChatTemplate(contextHandle: Int64(contextHandle), chatTemplate: chatTemplate)
        call.resolve(["success": success])
    }
    
    @objc func getModelChatTemplate(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle") else {
            call.reject("contextHandle is required")
            return
        }
        
        let chatTemplate = implementation.getModelChatTemplate(contextHandle: Int64(contextHandle))
        call.resolve(["chatTemplate": chatTemplate ?? ""])
    }
    
    @objc func formatChatMessages(_ call: CAPPluginCall) {
        guard let contextHandle = call.getInt("contextHandle"),
              let messagesJson = call.getString("messagesJson") else {
            call.reject("contextHandle and messagesJson are required")
            return
        }
        
        let chatTemplate = call.getString("chatTemplate")
        
        let result = implementation.formatChatMessages(
            contextHandle: Int64(contextHandle),
            messagesJson: messagesJson,
            chatTemplate: chatTemplate
        )
        
        call.resolve(result)
    }
}