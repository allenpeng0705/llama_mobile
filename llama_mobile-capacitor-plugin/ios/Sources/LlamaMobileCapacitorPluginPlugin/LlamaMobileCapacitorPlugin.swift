import Foundation
import llama_mobile
import UIKit
import AVFoundation

// Global callback context holders
private var progressCallbackContext: ((Float) -> Void)? = nil
private var tokenCallbackContext: ((String) -> Bool)? = nil

// Track freed context handles to prevent double free
private var freedContextHandles: Set<Int64> = []

// Track model paths to prevent early deallocation
private var modelPaths: [Int64: UnsafeMutablePointer<CChar>] = [:]
private var mmprojPaths: [Int64: UnsafeMutablePointer<CChar>] = [:]
private var vocoderPaths: [Int64: UnsafeMutablePointer<CChar>] = [:]


// C-compatible callback functions
private func cProgressCallback(progress: Float) -> Void {
    progressCallbackContext?(progress)
}

private func cTokenCallback(token: UnsafePointer<CChar>?) -> Bool {
    guard let token = token else { return true }
    let tokenString = String(cString: token)
    return tokenCallbackContext?(tokenString) ?? true
}

@objc public class LlamaMobileCapacitorPlugin: NSObject {
    // Helper method to resolve model paths
    private func resolveModelPath(_ path: String) -> String {
        print("[Swift] resolveModelPath called with: '\(path)'")
        
        var filePath = path
        
        // Handle file:// URLs from Camera plugin
        if path.hasPrefix("file://") {
            if let url = URL(string: path) {
                filePath = url.path
                print("[Swift] Converted file:// URL to path: '\(filePath)'")
            }
        }
        
        // If path is already an absolute path, return it as is
        if FileManager.default.fileExists(atPath: filePath) {
            print("[Swift] Found as absolute path: '\(filePath)'")
            return filePath
        }
        
        // Try to find the file in the app bundle
        if let bundlePath = Bundle.main.path(forResource: filePath, ofType: nil) {
            print("[Swift] Found in app bundle: '\(bundlePath)'")
            return bundlePath
        }
        
        // Try to find the file in the models directory within the app bundle
        if let bundlePath = Bundle.main.path(forResource: filePath, ofType: nil, inDirectory: "models") {
            print("[Swift] Found in app bundle models directory: '\(bundlePath)'")
            return bundlePath
        }
        
        // Try to find the file in the app's documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("[Swift] Documents directory: \(documentsDirectory.path)")
            let documentsPath = documentsDirectory.appendingPathComponent(filePath).path
            print("[Swift] Checking documents path: \(documentsPath)")
            if FileManager.default.fileExists(atPath: documentsPath) {
                print("[Swift] Found in documents directory: '\(documentsPath)'")
                return documentsPath
            }
        }
        
        // Try to find the file in the app's temporary directory
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryPath = temporaryDirectory.appendingPathComponent(filePath).path
        print("[Swift] Checking temporary path: \(temporaryPath)")
        if FileManager.default.fileExists(atPath: temporaryPath) {
            print("[Swift] Found in temporary directory: '\(temporaryPath)'")
            return temporaryPath
        }
        
        // If not found, return the original path
        print("[Swift] File not found in any location, returning original path: '\(path)'")
        return path
    }
    // MARK: - Initialization
    
    /// Configure Metal paths before model initialization
    private func configureMetalPaths() {
        // Get the framework bundle
        let frameworkBundle = Bundle(for: type(of: self))
        let frameworkPath = frameworkBundle.bundlePath
        
        // Log the paths for debugging
        print("[Swift] Framework bundle path: \(frameworkPath)")
        print("[Swift] Framework bundle resources path: \(frameworkBundle.resourcePath ?? "nil")")
        
        // Get the app bundle
        let appBundle = Bundle.main
        print("[Swift] App bundle path: \(appBundle.bundlePath)")
        print("[Swift] App bundle resources path: \(appBundle.resourcePath ?? "nil")")
        
        // Check if metallib files exist
        if let resourcePath = appBundle.resourcePath {
            let metallibPath = resourcePath.appending("/ggml-llama.metallib")
            let metallibSimPath = resourcePath.appending("/ggml-llama-sim.metallib")
            print("[Swift] Checking metallib path: \(metallibPath)")
            print("[Swift] Checking metallib-sim path: \(metallibSimPath)")
            print("[Swift] Metallib exists: \(FileManager.default.fileExists(atPath: metallibPath))")
            print("[Swift] Metallib-sim exists: \(FileManager.default.fileExists(atPath: metallibSimPath))")
        }
    }
    
    @objc public func initContext(modelPath: String, nCtx: Int32 = 2048, nGpuLayers: Int32 = 0, nThreads: Int32 = 4, embedding: Bool = false, poolingType: Int32 = 0, embdNormalize: Int32 = 1, chatTemplate: String? = nil) -> Int64 {
        print("[Swift] initContext called with:")
        print("[Swift] modelPath:", modelPath)
        print("[Swift] nCtx:", nCtx)
        print("[Swift] nGpuLayers:", nGpuLayers)
        print("[Swift] nThreads:", nThreads)
        print("[Swift] embedding:", embedding)
        print("[Swift] poolingType:", poolingType)
        print("[Swift] embdNormalize:", embdNormalize)
        print("[Swift] chatTemplate:", chatTemplate ?? "nil")
        
        // Configure Metal paths before initialization
        configureMetalPaths()
        
        var params = llama_mobile_init_params_c_t()
        memset(&params, 0, MemoryLayout<llama_mobile_init_params_c_t>.size)
        
        params.n_ctx = nCtx
        params.n_batch = 512 // Set reasonable default
        params.n_ubatch = 512 // Set reasonable default
        params.n_gpu_layers = nGpuLayers
        params.n_threads = nThreads
        params.use_mmap = true // Enable memory mapping for faster loading
        params.use_mlock = false // Don't lock memory
        params.embedding = embedding
        params.pooling_type = poolingType
        params.embd_normalize = embdNormalize
        params.flash_attn = false // Disable flash attention for compatibility
        
        let resolvedPath = resolveModelPath(modelPath)
        print("[Swift] Resolved model path:", resolvedPath)
        print("[Swift] File exists:", FileManager.default.fileExists(atPath: resolvedPath))
        
        // Create a persistent C string that will live for the duration of the context
        let modelPathCString = resolvedPath.cString(using: .utf8)
        if let modelPathCString = modelPathCString {
            // Make a copy of the C string
            let modelPathCopy = UnsafeMutablePointer<Int8>.allocate(capacity: modelPathCString.count)
            modelPathCopy.initialize(from: modelPathCString, count: modelPathCString.count)
            
            params.model_path = UnsafePointer(modelPathCopy)
            
            // Handle chat template if provided
            var chatTemplateCString: UnsafeMutablePointer<CChar>? = nil
            if let template = chatTemplate {
                chatTemplateCString = UnsafeMutablePointer<CChar>.allocate(capacity: template.utf8.count + 1)
                template.withCString { source in
                    chatTemplateCString?.update(from: source, count: template.utf8.count + 1)
                }
                params.chat_template = UnsafePointer(chatTemplateCString)
                print("[Swift] Using custom chat template from initialization")
            }
            
            print("[Swift] Calling llama_mobile_init_context_c...")
            let context = llama_mobile_init_context_c(&params)
            print("[Swift] llama_mobile_init_context_c returned:", context)
            
            let handle = unsafeBitCast(context, to: Int64.self)
            
            // Store the model path copy to prevent deallocation
            if handle != 0 {
                modelPaths[handle] = modelPathCopy
                print("[Swift] Stored model path for handle:", handle)
            } else {
                // Deallocate if context creation failed
                modelPathCopy.deallocate()
                if let cString = chatTemplateCString {
                    cString.deallocate()
                }
                print("[Swift] Deallocated resources for failed context")
            }
            
            print("[Swift] Returning context handle:", handle)
            return handle
        } else {
            print("[Swift] Error: Failed to convert model path to C string")
            return 0
        }
    }
    
    @objc public func releaseContext(contextHandle: Int64) {
        print("[Swift] releaseContext called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] releaseContext called with zero handle - skipping")
            return
        }
        if freedContextHandles.contains(contextHandle) {
            print("[Swift] releaseContext called with already freed handle - skipping")
            return
        }
        
        // Clean up mmproj path if it exists
        if let mmprojPathCopy = mmprojPaths[contextHandle] {
            mmprojPathCopy.deallocate()
            mmprojPaths.removeValue(forKey: contextHandle)
            print("[Swift] Deallocated mmproj path for contextHandle: \(contextHandle)")
        }
        
        // Clean up vocoder path if it exists
        if let vocoderPathCopy = vocoderPaths[contextHandle] {
            vocoderPathCopy.deallocate()
            vocoderPaths.removeValue(forKey: contextHandle)
            print("[Swift] Deallocated vocoder path for contextHandle: \(contextHandle)")
        }
        
        // Clean up model path if it exists
        if let modelPathCopy = modelPaths[contextHandle] {
            modelPathCopy.deallocate()
            modelPaths.removeValue(forKey: contextHandle)
            print("[Swift] Deallocated model path for contextHandle: \(contextHandle)")
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        llama_mobile_free_context_c(context)
        freedContextHandles.insert(contextHandle)
        print("[Swift] Context handle \(contextHandle) freed and added to tracking set")
    }
    
    // MARK: - Completion
    
    @objc public func generateCompletion(contextHandle: Int64, prompt: String, maxTokens: Int32 = 128, temperature: Double = 0.8, mediaPaths: [String] = []) -> [String: Any] {
        if contextHandle == 0 {
            print("[Swift] generateCompletion called with zero handle - returning empty result")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        var params = llama_mobile_completion_params_c_t()
        memset(&params, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
        
        params.prompt = prompt.withCString { $0 }
        params.n_predict = maxTokens
        params.temperature = temperature
        
        var result = llama_mobile_completion_result_c_t()
        let status: Int32
        
        if !mediaPaths.isEmpty {
            // Check if multimodal is enabled
            if !llama_mobile_is_multimodal_enabled_c(context) {
                print("[Swift] Error: Multimodal is not enabled but media paths are provided")
                return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
            }
            
            print("[Swift] Processing \(mediaPaths.count) media path(s) for multimodal completion")
            
            // Convert media paths to C array
            let mediaCount = mediaPaths.count
            let mediaPathsC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: mediaCount)
            
            // Array to store C strings that need to be freed
            var mediaStringsToFree: [UnsafeMutablePointer<CChar>] = []
            defer {
                // Free all allocated C strings for media paths
                for cString in mediaStringsToFree {
                    cString.deallocate()
                }
                // Free the media paths array
                mediaPathsC.deallocate()
            }
            
            for (index, path) in mediaPaths.enumerated() {
                // Resolve media path
                let resolvedMediaPath = resolveModelPath(path)
                print("[Swift] Resolved media path \(index): '\(resolvedMediaPath)'")
                print("[Swift] File exists: \(FileManager.default.fileExists(atPath: resolvedMediaPath))")
                
                if FileManager.default.fileExists(atPath: resolvedMediaPath) {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: resolvedMediaPath) {
                        if let fileSize = attrs[.size] as? UInt64 {
                            print("[Swift] File size: \(fileSize) bytes")
                        }
                    }
                }
                
                // Allocate permanent C string for resolved media path
                let mediaCString = UnsafeMutablePointer<CChar>.allocate(capacity: resolvedMediaPath.utf8.count + 1)
                resolvedMediaPath.withCString { source in
                    mediaCString.update(from: source, count: resolvedMediaPath.utf8.count + 1)
                }
                mediaStringsToFree.append(mediaCString)
                mediaPathsC[index] = UnsafePointer(mediaCString)
            }
            
            print("[Swift] Calling llama_mobile_multimodal_completion_c...")
            status = llama_mobile_multimodal_completion_c(context, &params, mediaPathsC, Int32(mediaCount), &result)
            print("[Swift] llama_mobile_multimodal_completion_c returned status: \(status)")
        } else {
            status = llama_mobile_completion_c(context, &params, &result)
        }
        
        if status != 0 {
            print("[Swift] Error: Completion failed with status \(status)")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        let text = result.text != nil ? String(cString: result.text!) : ""
        print("[Swift] Generated text length: \(text.count) characters")
        print("[Swift] Generated text preview: \(text.prefix(100))")
        
        return [
            "text": text,
            "tokensGenerated": result.tokens_predicted,
            "tokensEvaluated": result.tokens_evaluated,
            "truncated": result.truncated,
            "stoppedEos": result.stopped_eos,
            "stoppedWord": result.stopped_word,
            "stoppedLimit": result.stopped_limit,
            "stoppingWord": result.stopping_word != nil ? String(cString: result.stopping_word!) : nil
        ]
    }
    
    @objc public func stopCompletion(contextHandle: Int64) {
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        llama_mobile_stop_completion_c(context)
    }
    
    @objc public func generateOpenAICompletion(contextHandle: Int64, openAIJSON: String, grammar: String? = nil, stopSequences: [String]? = nil) -> [String: Any] {
        print("[Swift] ========== generateOpenAICompletion START ==========")
        print("[Swift] Context handle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] ERROR: generateOpenAICompletion called with zero handle - returning empty result")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        print("[Swift] OpenAI JSON length: \(openAIJSON.count) characters")
        print("[Swift] OpenAI JSON content: \(openAIJSON)")
        
        guard let jsonData = openAIJSON.data(using: .utf8) else {
            print("[Swift] ERROR: Failed to convert OpenAI JSON string to data")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let root = jsonObject as? [String: Any], let messages = root["messages"] as? [[String: Any]] else {
                print("[Swift] ERROR: Invalid OpenAI JSON format - missing 'messages' field")
                return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
            }
            
            print("[Swift] Parsed \(messages.count) messages from OpenAI JSON")
            
            for (index, message) in messages.enumerated() {
                if let role = message["role"] as? String, let content = message["content"] as? String {
                    print("[Swift] Message \(index): role='\(role)', content='\(content)'")
                }
            }
            
            var params = llama_mobile_completion_params_c_t()
            memset(&params, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
            
            params.n_predict = 256
            params.temperature = 0.7
            params.top_k = 40
            params.top_p = 0.95
            params.min_p = 0.05
            params.penalty_last_n = 64
            params.penalty_repeat = 1.0
            params.use_json_response = true // Enable JSON response for chat messages
            
            print("[Swift] Completion params: n_predict=\(params.n_predict), temperature=\(params.temperature), top_k=\(params.top_k), top_p=\(params.top_p)")
            
            if let grammar = grammar, !grammar.isEmpty {
                print("[Swift] Using grammar for OpenAI completion")
                print("[Swift] Grammar preview: \(grammar.prefix(100))...")
                let grammarCString = UnsafeMutablePointer<CChar>.allocate(capacity: grammar.utf8.count + 1)
                grammar.withCString { source in
                    grammarCString.update(from: source, count: grammar.utf8.count + 1)
                }
                params.grammar = UnsafePointer(grammarCString)

                defer {
                    grammarCString.deallocate()
                }
            } else {
                print("[Swift] No grammar specified for generation")
            }
            
            // Convert messages to llama_mobile_chat_message_c structs
            print("[Swift] Converting chat messages to structured format")
            
            var chatMessages: [llama_mobile_chat_message_c] = []
            var roleCStrings: [UnsafeMutablePointer<CChar>] = []
            var contentCStrings: [UnsafeMutablePointer<CChar>] = []
            var stopStringsToFree: [UnsafeMutablePointer<CChar>] = []
            
            for message in messages {
                if let role = message["role"] as? String, let content = message["content"] as? String {
                    // Create C strings for role and content
                    let roleCString = UnsafeMutablePointer<CChar>.allocate(capacity: role.utf8.count + 1)
                    role.withCString { source in
                        roleCString.update(from: source, count: role.utf8.count + 1)
                    }
                    
                    let contentCString = UnsafeMutablePointer<CChar>.allocate(capacity: content.utf8.count + 1)
                    content.withCString { source in
                        contentCString.update(from: source, count: content.utf8.count + 1)
                    }
                    
                    // Create chat message struct
                    var chatMessage = llama_mobile_chat_message_c()
                    chatMessage.role = UnsafePointer(roleCString)
                    chatMessage.content = UnsafePointer(contentCString)
                    
                    chatMessages.append(chatMessage)
                    roleCStrings.append(roleCString)
                    contentCStrings.append(contentCString)
                }
            }
            
            // Set chat messages in params
            if !chatMessages.isEmpty {
                params.chat_message_count = Int32(chatMessages.count)
                params.chat_messages = chatMessages.withUnsafeBufferPointer { $0.baseAddress }
                print("[Swift] Passed \(chatMessages.count) structured chat messages")
            }
            
            // Set empty prompt since we're using chat messages
            params.prompt = "".withCString { $0 }
            
            // Add chat message C strings to cleanup list
            for cString in roleCStrings {
                stopStringsToFree.append(cString)
            }
            for cString in contentCStrings {
                stopStringsToFree.append(cString)
            }
            

            
            let stopSequencesToUse = stopSequences ?? ["<|im_end|>"]
            let stopSequencesCount = stopSequencesToUse.count
            let stopSequencesC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: stopSequencesCount)
            
            print("[Swift] Using stop sequences: \(stopSequencesToUse)")
            
            for (index, stopSequence) in stopSequencesToUse.enumerated() {
                let stopCString = UnsafeMutablePointer<CChar>.allocate(capacity: stopSequence.utf8.count + 1)
                stopSequence.withCString { source in
                    stopCString.update(from: source, count: stopSequence.utf8.count + 1)
                }
                stopStringsToFree.append(stopCString)
                stopSequencesC[index] = UnsafePointer(stopCString)
            }
            
            params.stop_sequences = stopSequencesC
            params.stop_sequence_count = Int32(stopSequencesCount)
            
            // Add cleanup for all C strings
            defer {
                // Free stop sequence C strings
                for cString in stopStringsToFree {
                    cString.deallocate()
                }
                stopSequencesC.deallocate()
            }
            
            var result = llama_mobile_completion_result_c_t()
            print("[Swift] Calling llama_mobile_completion_c...")
            let status = llama_mobile_completion_c(context, &params, &result)
            
            print("[Swift] Completion C API status: \(status)")
            
            if status != 0 {
                print("[Swift] ERROR: OpenAI completion failed with status \(status)")
                return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
            }
            
            let text = result.text != nil ? String(cString: result.text!) : ""
            print("[Swift] Generated OpenAI response length: \(text.count) characters")
            print("[Swift] Generated response preview: \(text.prefix(200))")
            print("[Swift] Generated response full: \(text)")
            
            print("[Swift] Tokens evaluated: \(result.tokens_evaluated)")
            print("[Swift] Tokens generated: \(result.tokens_predicted)")
            print("[Swift] Generation stopped because:")
            print("[Swift]   - End of sequence: \(result.stopped_eos)")
            print("[Swift]   - Stop word: \(result.stopped_word)")
            print("[Swift]   - Token limit: \(result.stopped_limit)")
            
            let stoppingWord = result.stopping_word != nil ? String(cString: result.stopping_word!) : nil
            if let stoppingWord = stoppingWord {
                print("[Swift] Stopping word: '\(stoppingWord)'")
            }
            
            // When use_json_response is true, result.text contains the JSON response
            // We should use it directly instead of wrapping it
            var cleanedText = text
            for stopSequence in stopSequencesToUse {
                cleanedText = cleanedText.replacingOccurrences(of: stopSequence, with: "")
            }
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("[Swift] Cleaned text length: \(cleanedText.count) characters")
            print("[Swift] Cleaned text preview: \(cleanedText.prefix(200))")
            
            // Check if the response is already valid JSON
            if let jsonData = cleanedText.data(using: .utf8),
               let _ = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                print("[Swift] Using built-in JSON response directly")
            } else {
                // Fallback to manual wrapping if JSON is invalid
                print("[Swift] Built-in JSON response is invalid, falling back to manual wrapping")
                let wrappedResponse: [String: Any] = [
                    "id": "chatcmpl-" + UUID().uuidString,
                    "object": "chat.completion",
                    "created": Int(Date.timeIntervalSinceReferenceDate * 1000),
                    "model": "llama.cpp",
                    "choices": [
                        [
                            "index": 0,
                            "message": [
                                "role": "assistant",
                                "content": cleanedText
                            ],
                            "finish_reason": "stop"
                        ]
                    ],
                    "usage": [
                        "prompt_tokens": result.tokens_evaluated,
                        "completion_tokens": result.tokens_predicted,
                        "total_tokens": result.tokens_evaluated + result.tokens_predicted
                    ]
                ]
                
                if let wrappedJsonData = try? JSONSerialization.data(withJSONObject: wrappedResponse, options: []),
                   let wrappedJsonString = String(data: wrappedJsonData, encoding: .utf8) {
                    cleanedText = wrappedJsonString
                    print("[Swift] Successfully wrapped response in JSON format")
                }
            }
            
            print("[Swift] Final response length: \(cleanedText.count) characters")
            print("[Swift] ========== generateOpenAICompletion END ==========")
            
            return [
                "text": cleanedText,
                "tokensGenerated": result.tokens_predicted,
                "tokensEvaluated": result.tokens_evaluated,
                "truncated": result.truncated,
                "stoppedEos": result.stopped_eos,
                "stoppedWord": result.stopped_word,
                "stoppedLimit": result.stopped_limit,
                "stoppingWord": stoppingWord
            ]
        } catch {
            print("[Swift] ERROR parsing OpenAI JSON: \(error)")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
    }
    
    // MARK: - TTS
    
    @objc public func initVocoder(contextHandle: Int64, vocoderModelPath: String) -> [String: Any] {
        print("[Swift] initVocoder called with contextHandle: \(contextHandle), vocoderModelPath: '\(vocoderModelPath)'")
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        let resolvedPath = resolveModelPath(vocoderModelPath)
        print("[Swift] Resolved vocoder path: '\(resolvedPath)'")
        
        // Create a persistent C string
        let pathCString = resolvedPath.cString(using: .utf8)
        guard let pathCString = pathCString else {
            print("[Swift] Error: Failed to convert vocoder path to C string")
            return ["success": false, "modelType": -1]
        }
        
        // Allocate memory for the string (including null terminator)
        let pathCopy = UnsafeMutableRawPointer.allocate(byteCount: pathCString.count + 1, alignment: MemoryLayout<CChar>.alignment)
        
        // Copy the string data
        pathCopy.copyMemory(from: pathCString, byteCount: pathCString.count)
        
        // Add null terminator
        pathCopy.advanced(by: pathCString.count).storeBytes(of: CChar(0), as: CChar.self)
        
        // Store the C string in the dictionary
        let mutablePtr = pathCopy.assumingMemoryBound(to: CChar.self)
        vocoderPaths[contextHandle] = mutablePtr
        
        print("[Swift] Calling llama_mobile_init_vocoder_c with persistent C string")
        let result = llama_mobile_init_vocoder_c(context, mutablePtr)
        let success = result == 0
        print("[Swift] llama_mobile_init_vocoder_c returned: \(result), success: \(success)")
        
        var modelType = -1
        if success {
            modelType = Int(llama_mobile_get_tts_type_c(context))
            print("[Swift] TTS model type: \(modelType)")
        }
        
        return ["success": success, "modelType": modelType]
    }
    
    @objc public func releaseVocoder(contextHandle: Int64) {
        print("[Swift] releaseVocoder called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] releaseVocoder called with zero handle - skipping")
            return
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        // Free the persistent C string
        if let vocoderPath = vocoderPaths[contextHandle] {
            print("[Swift] Freeing vocoder path C string")
            vocoderPath.deallocate()
            vocoderPaths.removeValue(forKey: contextHandle)
        }
        
        llama_mobile_release_vocoder_c(context)
        print("[Swift] Vocoder released successfully")
    }
    
    @objc public func isVocoderEnabled(contextHandle: Int64) -> Bool {
        if contextHandle == 0 {
            print("[Swift] isVocoderEnabled called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_is_vocoder_enabled_c(context)
    }
    
    @objc public func getTTSType(contextHandle: Int64) -> Int {
        if contextHandle == 0 {
            print("[Swift] getTTSType called with zero handle - returning -1")
            return -1
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return Int(llama_mobile_get_tts_type_c(context))
    }
    
    @objc public func getAudioGuideTokens(contextHandle: Int64, text: String) -> [Int32] {
        if contextHandle == 0 {
            print("[Swift] getAudioGuideTokens called with zero handle - returning empty array")
            return []
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        return text.withCString { textC in
            let cResult = llama_mobile_get_audio_guide_tokens_c(context, textC)
            defer { llama_mobile_free_token_array_c(cResult) }
            
            guard let tokens = cResult.tokens else {
                print("[Swift] getAudioGuideTokens: no tokens returned")
                return []
            }
            
            let tokenArray = Array(UnsafeBufferPointer(start: tokens, count: Int(cResult.count)))
            print("[Swift] getAudioGuideTokens: returned \(tokenArray.count) tokens")
            return tokenArray
        }
    }
    
    @objc public func getFormattedAudioCompletion(contextHandle: Int64, speakerJson: String, textToSpeak: String) -> String? {
        if contextHandle == 0 {
            print("[Swift] getFormattedAudioCompletion called with zero handle - returning nil")
            return nil
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        return speakerJson.withCString { speakerJsonC in
            textToSpeak.withCString { textToSpeakC in
                let cString = llama_mobile_get_formatted_audio_completion_c(
                    context,
                    speakerJsonC,
                    textToSpeakC
                )
                
                guard let cString = cString else {
                    print("[Swift] getFormattedAudioCompletion: no string returned")
                    return nil
                }
                
                defer { llama_mobile_free_string_c(cString) }
                let result = String(cString: cString)
                print("[Swift] getFormattedAudioCompletion: returned '\(result)'")
                return result
            }
        }
    }
    
    @objc public func decodeAudioTokens(contextHandle: Int64, tokens: [Int32]) -> [Float] {
        if contextHandle == 0 {
            print("[Swift] decodeAudioTokens called with zero handle - returning empty array")
            return []
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        return tokens.withUnsafeBufferPointer { buffer in
            let cResult = llama_mobile_decode_audio_tokens_c(context, buffer.baseAddress, Int32(buffer.count))
            defer { llama_mobile_free_float_array_c(cResult) }
            
            guard let values = cResult.values else {
                print("[Swift] decodeAudioTokens: no values returned")
                return []
            }
            
            let sampleArray = Array(UnsafeBufferPointer(start: values, count: Int(cResult.count)))
            print("[Swift] decodeAudioTokens: returned \(sampleArray.count) audio samples")
            return sampleArray
        }
    }
    
    @objc public func saveAudioToWav(contextHandle: Int64, filePath: String, audioData: [Float], sampleRate: Int32 = 24000) -> Bool {
        if contextHandle == 0 {
            print("[Swift] saveAudioToWav called with zero handle - returning false")
            return false
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        // Use temporary directory for file storage
        let tempDir = NSTemporaryDirectory()
        let fullPath = tempDir + filePath
        
        print("[Swift] saveAudioToWav: full path = '\(fullPath)'")
        
        return audioData.withUnsafeBufferPointer { buffer in
            fullPath.withCString { filePathC in
                let result = llama_mobile_save_audio_to_wav_c(context, filePathC, buffer.baseAddress, Int32(buffer.count), sampleRate)
                print("[Swift] saveAudioToWav: result = \(result)")
                return result
            }
        }
    }
    
    @objc public func generateAudioFromText(contextHandle: Int64, text: String, speakerJson: String = "{\"speaker\": \"default\"}") -> [Float] {
        print("[Swift] generateAudioFromText called with contextHandle: \(contextHandle), text: '\(text)'")
        
        if contextHandle == 0 {
            print("[Swift] generateAudioFromText called with zero handle - returning empty array")
            return []
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        // Try the direct approach first (getAudioGuideTokens)
        let audioTokens = getAudioGuideTokens(contextHandle: contextHandle, text: text)
        
        if !audioTokens.isEmpty {
            print("[Swift] generateAudioFromText: using direct approach with \(audioTokens.count) tokens")
            let audioSamples = decodeAudioTokens(contextHandle: contextHandle, tokens: audioTokens)
            if !audioSamples.isEmpty {
                return audioSamples
            }
        }
        
        // If direct approach fails, use text completion approach (for models without vocoder tokenizer)
        print("[Swift] generateAudioFromText: direct approach failed, trying text completion approach")
        
        // Get formatted audio completion
        guard let formattedPrompt = getFormattedAudioCompletion(contextHandle: contextHandle, speakerJson: speakerJson, textToSpeak: text) else {
            print("[Swift] generateAudioFromText: failed to get formatted audio completion")
            return []
        }
        
        print("[Swift] generateAudioFromText: formatted prompt: '\(formattedPrompt)'")
        
        // Generate audio content using text completion
        let completionResult = generateCompletion(
            contextHandle: contextHandle,
            prompt: formattedPrompt,
            maxTokens: 200,
            temperature: 0.8
        )
        
        guard let completionText = completionResult["text"] as? String, !completionText.isEmpty else {
            print("[Swift] generateAudioFromText: no completion text generated")
            return []
        }
        
        print("[Swift] generateAudioFromText: completion text: '\(completionText)'")
        
        // Tokenize the completion
        let tokens = tokenize(contextHandle: contextHandle, text: completionText)
        
        if tokens.isEmpty {
            print("[Swift] generateAudioFromText: no tokens generated from completion")
            return []
        }
        
        print("[Swift] generateAudioFromText: tokenized completion into \(tokens.count) tokens")
        
        // Filter audio tokens (151672-155772 range)
        let audioStartToken = 151672
        let audioEndToken = 151668 // <|audio_end|>
        var filteredAudioTokens: [Int32] = []
        
        for token in tokens {
            if token == audioEndToken {
                print("[Swift] generateAudioFromText: found audio end token, stopping")
                break
            }
            
            if token >= audioStartToken && token <= 155772 {
                filteredAudioTokens.append(token)
            }
        }
        
        print("[Swift] generateAudioFromText: filtered to \(filteredAudioTokens.count) audio tokens")
        
        if filteredAudioTokens.isEmpty {
            print("[Swift] generateAudioFromText: no audio tokens found in filtered result")
            return []
        }
        
        // Decode audio tokens to samples
        let audioSamples = decodeAudioTokens(contextHandle: contextHandle, tokens: filteredAudioTokens)
        
        print("[Swift] generateAudioFromText: generated \(audioSamples.count) audio samples")
        return audioSamples
    }
    
    @objc public func playAudio(audioData: [Float], sampleRate: Int32 = 24000) -> Bool {
        print("[Swift] playAudio called with \(audioData.count) samples at \(sampleRate) Hz")
        
        guard !audioData.isEmpty else {
            print("[Swift] playAudio: no audio data provided")
            return false
        }
        
        do {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Configure audio format
            let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!
            
            // Create buffer
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioData.count))!
            buffer.frameLength = buffer.frameCapacity
            
            // Copy samples to buffer
            if let floatBuffer = buffer.floatChannelData?[0] {
                for (index, sample) in audioData.enumerated() {
                    floatBuffer[index] = sample
                }
            } else {
                print("[Swift] playAudio: failed to create audio buffer")
                return false
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
                print("[Swift] playAudio: audio playback completed")
                
                // Clean up
                audioEngine.stop()
                do {
                    try audioSession.setActive(false)
                } catch {
                    print("[Swift] playAudio: error deactivating audio session: \(error)")
                }
            }
            
            print("[Swift] playAudio: audio playback started successfully")
            return true
        } catch {
            print("[Swift] playAudio: error playing audio: \(error)")
            
            // Clean up
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false)
            } catch {
                print("[Swift] playAudio: error deactivating audio session: \(error)")
            }
            
            return false
        }
    }
    
    // MARK: - Multimodal
    
    @objc public func initMultimodal(contextHandle: Int64, mmprojPath: String, useGpu: Bool = true) -> Bool {
        print("[Swift] initMultimodal called with:")
        print("[Swift]   contextHandle: \(contextHandle)")
        print("[Swift]   mmprojPath: '\(mmprojPath)'")
        print("[Swift]   useGpu: \(useGpu)")
        
        if contextHandle == 0 {
            print("[Swift] initMultimodal called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        let resolvedPath = resolveModelPath(mmprojPath)
        print("[Swift]   Resolved mmprojPath: '\(resolvedPath)'")
        print("[Swift]   File exists: \(FileManager.default.fileExists(atPath: resolvedPath))")
        
        // Create persistent C string copy
        let mmprojPathCString = resolvedPath.cString(using: .utf8)
        if let mmprojPathCString = mmprojPathCString {
            // Make a copy of the C string
            let mmprojPathCopy = UnsafeMutablePointer<Int8>.allocate(capacity: mmprojPathCString.count)
            mmprojPathCopy.initialize(from: mmprojPathCString, count: mmprojPathCString.count)
            
            // Store the copy to prevent deallocation
            mmprojPaths[contextHandle] = mmprojPathCopy
            
            // Call the native function with the persistent pointer
            let success = llama_mobile_init_multimodal_c(context, UnsafePointer(mmprojPathCopy), useGpu) == 0
            print("[Swift]   initMultimodal result: \(success)")
            return success
        } else {
            print("[Swift] Error: Failed to convert mmproj path to C string")
            return false
        }
    }
    
    @objc public func releaseMultimodal(contextHandle: Int64) {
        print("[Swift] releaseMultimodal called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] releaseMultimodal called with zero handle - skipping")
            return
        }
        
        // Deallocate mmproj path if it exists
        if let mmprojPathCopy = mmprojPaths[contextHandle] {
            mmprojPathCopy.deallocate()
            mmprojPaths.removeValue(forKey: contextHandle)
            print("[Swift] Deallocated mmproj path for contextHandle: \(contextHandle)")
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        llama_mobile_release_multimodal_c(context)
        print("[Swift] Multimodal released for contextHandle: \(contextHandle)")
    }
    
    @objc public func isMultimodalEnabled(contextHandle: Int64) -> Bool {
        if contextHandle == 0 {
            print("[Swift] isMultimodalEnabled called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_is_multimodal_enabled_c(context)
    }
    
    @objc public func supportsVision(contextHandle: Int64) -> Bool {
        if contextHandle == 0 {
            print("[Swift] supportsVision called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_supports_vision_c(context)
    }
    
    @objc public func supportsAudio(contextHandle: Int64) -> Bool {
        if contextHandle == 0 {
            print("[Swift] supportsAudio called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_supports_audio_c(context)
    }
    
    // MARK: - LoRA
    
    @objc public func applyLoraAdapters(contextHandle: Int64, adapters: [[String: Any]]) -> Bool {
        if contextHandle == 0 {
            print("[Swift] applyLoraAdapters called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        print("[Swift] applyLoraAdapters called with \(adapters.count) adapter(s)")
        
        // Create C array of llama_mobile_lora_adapter_c_t structs
        let adapterCount = adapters.count
        let adaptersArray = UnsafeMutablePointer<llama_mobile_lora_adapter_c_t>.allocate(capacity: adapterCount)
        
        // Array to store C strings that need to be freed
        var pathStringsToFree: [UnsafeMutablePointer<CChar>] = []
        
        for (index, adapter) in adapters.enumerated() {
            guard let path = adapter["path"] as? String else {
                print("[Swift] Error: Adapter at index \(index) missing 'path' field")
                continue
            }
            
            let scale = (adapter["scale"] as? Float) ?? 1.0
            
            // Resolve the model path
            let resolvedPath = resolveModelPath(path)
            print("[Swift] Adapter \(index): path='\(resolvedPath)', scale=\(scale)")
            
            // Create persistent C string for path
            let pathCString = resolvedPath.cString(using: .utf8)
            if let pathCString = pathCString {
                // Allocate memory for the string (including null terminator)
                let pathCopy = UnsafeMutableRawPointer.allocate(byteCount: pathCString.count + 1, alignment: MemoryLayout<CChar>.alignment)
                
                // Copy the string data
                pathCopy.copyMemory(from: pathCString, byteCount: pathCString.count)
                
                // Add null terminator
                pathCopy.advanced(by: pathCString.count).storeBytes(of: CChar(0), as: CChar.self)
                
                // Store the mutable pointer for later deallocation
                let mutablePtr = pathCopy.assumingMemoryBound(to: CChar.self)
                pathStringsToFree.append(mutablePtr)
                
                // Set up adapter struct - use UnsafeRawPointer to bridge the types
                adaptersArray[index].path = UnsafeRawPointer(mutablePtr).assumingMemoryBound(to: CChar.self)
                adaptersArray[index].scale = scale
            } else {
                print("[Swift] Error: Failed to convert path to C string for adapter \(index)")
            }
        }
        
        // Create the llama_mobile_lora_adapters_c_t struct
        let loraAdapters = UnsafeMutablePointer<llama_mobile_lora_adapters_c_t>.allocate(capacity: 1)
        loraAdapters.pointee.adapters = adaptersArray
        loraAdapters.pointee.count = Int32(adapterCount)
        
        // Call the native API
        print("[Swift] Calling llama_mobile_apply_lora_adapters_c with \(adapterCount) adapter(s)")
        let result = llama_mobile_apply_lora_adapters_c(context, loraAdapters)
        print("[Swift] llama_mobile_apply_lora_adapters_c returned: \(result)")
        
        // Free allocated memory
        for cString in pathStringsToFree {
            cString.deallocate()
        }
        adaptersArray.deallocate()
        loraAdapters.deallocate()
        
        return result == 0
    }
    
    @objc public func removeLoraAdapters(contextHandle: Int64) {
        if contextHandle == 0 {
            print("[Swift] removeLoraAdapters called with zero handle - skipping")
            return
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        llama_mobile_remove_lora_adapters_c(context)
    }
    
    // MARK: - Conversation
    
    @objc public func generateResponse(contextHandle: Int64, userMessage: String, maxTokens: Int32) -> [String: Any] {
        if contextHandle == 0 {
            print("[Swift] generateResponse called with zero handle - returning empty result")
            return ["text": "", "timeToFirstToken": 0, "totalTime": 0, "tokensGenerated": 0]
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        var params = llama_mobile_completion_params_c_t()
        memset(&params, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
        
        params.prompt = userMessage.withCString { $0 }
        params.n_predict = maxTokens
        params.temperature = 0.8
        
        var result = llama_mobile_completion_result_c_t()
        let status = llama_mobile_completion_c(context, &params, &result)
        
        if status != 0 {
            return ["text": "", "timeToFirstToken": 0, "totalTime": 0, "tokensGenerated": 0]
        }
        
        let text = result.text != nil ? String(cString: result.text!) : ""
        
        // Clean up response
        var cleanedText = text
        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return [
            "text": cleanedText,
            "timeToFirstToken": 0, // C API doesn't provide this directly
            "totalTime": 0, // C API doesn't provide this directly
            "tokensGenerated": Int(result.tokens_predicted)
        ]
    }
    
    @objc public func clearConversation(contextHandle: Int64) {
        if contextHandle == 0 {
            print("[Swift] clearConversation called with zero handle - skipping")
            return
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        llama_mobile_clear_conversation_c(context)
    }
    
    @objc public func isConversationActive(contextHandle: Int64) -> Bool {
        if contextHandle == 0 {
            print("[Swift] isConversationActive called with zero handle - returning false")
            return false
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_is_conversation_active_c(context)
    }
    
    // MARK: - Embeddings
    
    @objc public func generateEmbeddings(contextHandle: Int64, text: String) -> [Float] {
        if contextHandle == 0 {
            print("[Swift] generateEmbeddings called with zero handle - returning empty array")
            return []
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        let embeddingResult = llama_mobile_embedding_c(context, text.withCString { $0 })
        
        if embeddingResult.values == nil || embeddingResult.count <= 0 {
            return []
        }
        
        defer {
            llama_mobile_free_float_array_c(embeddingResult)
        }
        
        var result: [Float] = []
        for i in 0..<Int(embeddingResult.count) {
            result.append(embeddingResult.values![i])
        }
        
        return result
    }
    
    // MARK: - Tokenization
    
    @objc public func tokenize(contextHandle: Int64, text: String) -> [Int32] {
        if contextHandle == 0 {
            print("[Swift] tokenize called with zero handle - returning empty array")
            return []
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        let tokenResult = llama_mobile_tokenize_c(context, text.withCString { $0 })
        
        if tokenResult.tokens == nil || tokenResult.count <= 0 {
            return []
        }
        
        defer {
            llama_mobile_free_token_array_c(tokenResult)
        }
        
        var result: [Int32] = []
        for i in 0..<Int(tokenResult.count) {
            result.append(tokenResult.tokens![i])
        }
        
        return result
    }
    
    @objc public func detokenize(contextHandle: Int64, tokens: [Int32]) -> String {
        if contextHandle == 0 {
            print("[Swift] detokenize called with zero handle - returning empty string")
            return ""
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        let tokensPointer = UnsafeMutablePointer<Int32>.allocate(capacity: tokens.count)
        defer {
            tokensPointer.deallocate()
        }
        
        for (i, token) in tokens.enumerated() {
            tokensPointer[i] = token
        }
        
        let text = llama_mobile_detokenize_c(context, tokensPointer, Int32(tokens.count))
        
        if text == nil {
            return ""
        }
        
        defer {
            llama_mobile_free_string_c(text)
        }
        
        return String(cString: text!)
    }
    
    // MARK: - Model Info
    
    @objc public func getContextWindowSize(contextHandle: Int64) -> Int32 {
        if contextHandle == 0 {
            print("[Swift] getContextWindowSize called with zero handle - returning 0")
            return 0
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_get_n_ctx_c(context)
    }
    
    @objc public func getEmbeddingDimension(contextHandle: Int64) -> Int32 {
        if contextHandle == 0 {
            print("[Swift] getEmbeddingDimension called with zero handle - returning 0")
            return 0
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_get_n_embd_c(context)
    }
    
    @objc public func getModelDescription(contextHandle: Int64) -> String {
        if contextHandle == 0 {
            print("[Swift] getModelDescription called with zero handle - returning empty string")
            return ""
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        let description = llama_mobile_get_model_desc_c(context)
        return description != nil ? String(cString: description!) : ""
    }
    
    @objc public func getModelSize(contextHandle: Int64) -> Int64 {
        if contextHandle == 0 {
            print("[Swift] getModelSize called with zero handle - returning 0")
            return 0
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_get_model_size_c(context)
    }
    
    @objc public func getModelParametersCount(contextHandle: Int64) -> Int64 {
        if contextHandle == 0 {
            print("[Swift] getModelParametersCount called with zero handle - returning 0")
            return 0
        }
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        return llama_mobile_get_model_params_c(context)
    }
    
    @objc public func listFiles(directoryPath: String) -> [String: [String]] {
        print("[Swift] listFiles called with directoryPath: '\(directoryPath)'")
        
        var result: [String: [String]] = [:]
        
        // Resolve the directory path using the existing resolveModelPath method
        let resolvedPath = resolveModelPath(directoryPath)
        print("[Swift] Resolved directory path: '\(resolvedPath)'")
        
        // Check if directory exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: resolvedPath) {
            print("[Swift] Directory does not exist")
            result["error"] = ["Directory does not exist"]
            return result
        }
        
        do {
            // Get all files in the directory
            let files = try fileManager.contentsOfDirectory(atPath: resolvedPath)
            print("[Swift] Found \(files.count) items in directory")
            
            // Filter for model files
            let modelFiles = files.filter { $0.lowercased().hasSuffix(".gguf") || $0.lowercased().hasSuffix(".bin") }
            print("[Swift] Found \(modelFiles.count) model files")
            
            result["files"] = files
            result["modelFiles"] = modelFiles
        } catch {
            print("[Swift] Error listing files: \(error)")
            result["error"] = [error.localizedDescription]
        }
        
        return result
    }
    
    @objc public func listModels() -> [String: [String]] {
        print("[Swift] listModels called")
        
        var result: [String: [String]] = [:]
        var allModelFiles: [String] = []
        
        // Scan multiple directories
        let directoriesToScan: [String] = ["", "models", "../models"]
        
        for directory in directoriesToScan {
            let resolvedPath = resolveModelPath(directory)
            print("[Swift] Scanning directory: '\(resolvedPath)'")
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: resolvedPath) {
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: resolvedPath)
                    let modelFiles = files.filter { $0.lowercased().hasSuffix(".gguf") || $0.lowercased().hasSuffix(".bin") }
                    print("[Swift] Directory '\(directory)' has \(modelFiles.count) model files")
                    
                    allModelFiles.append(contentsOf: modelFiles)
                } catch {
                    print("[Swift] Error scanning directory '\(directory)': \(error)")
                }
            }
        }
        
        // Remove duplicates and sort
        let uniqueModelFiles = Array(Set(allModelFiles)).sorted()
        print("[Swift] Total unique model files: \(uniqueModelFiles.count)")
        
        result["modelFiles"] = uniqueModelFiles
        
        return result
    }
    
    // MARK: - LoRA
    
    @objc public func getLoadedLoraAdapters(contextHandle: Int64) -> [[String: Any]] {
        if contextHandle == 0 {
            print("[Swift] getLoadedLoraAdapters called with zero handle - returning empty array")
            return []
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        let adaptersResult = llama_mobile_get_loaded_lora_adapters_c(context)
        defer {
            // Create a mutable pointer to pass to the free function
            var resultCopy = adaptersResult
            llama_mobile_free_lora_adapters_c(&resultCopy)
        }
        
        var result: [[String: Any]] = []
        
        if let adapters = adaptersResult.adapters {
            for i in 0..<Int(adaptersResult.count) {
                let adapter = adapters[i]
                let path = adapter.path != nil ? String(cString: adapter.path!) : ""
                result.append([
                    "path": path,
                    "scale": adapter.scale
                ])
            }
        }
        
        print("[Swift] getLoadedLoraAdapters: returned \(result.count) adapter(s)")
        return result
    }
    
    // MARK: - Download
    
    @objc public func downloadModel(url: String, localPath: String) -> [String: Any] {
        print("[Swift] downloadModel called with URL: '\(url)', localPath: '\(localPath)'")
        
        // This would typically use llama_mobile_download_model_c
        // For now, return a placeholder
        return [
            "success": false,
            "localPath": localPath,
            "errorMessage": "Not implemented"
        ]
    }
    
    @objc public func downloadHfFile(repoId: String, filename: String, localPath: String) -> [String: Any] {
        print("[Swift] downloadHfFile called with repoId: '\(repoId)', filename: '\(filename)', localPath: '\(localPath)'")
        
        // This would typically use llama_mobile_download_hf_file_c
        // For now, return a placeholder
        return [
            "success": false,
            "localPath": localPath,
            "errorMessage": "Not implemented"
        ]
    }
    
    // MARK: - Grammar
    
    @objc public func getJsonGrammar() -> String {
        print("[Swift] getJsonGrammar called")
        
        // Get JSON grammar from the framework
        if let grammarPath = Bundle.main.path(forResource: "json", ofType: "gbnf", inDirectory: "grammars") {
            do {
                let grammar = try String(contentsOfFile: grammarPath)
                return grammar
            } catch {
                print("[Swift] Error reading JSON grammar: \(error)")
            }
        }
        
        // Fallback to default JSON grammar
        return "# JSON grammar\nroot ::= object\nobject ::= { members }\nmembers ::= member (, member)* | \nmember ::= string : value\narray ::= [ elements ]\nelements ::= value (, value)* | \nvalue ::= string | number | object | array | true | false | null\nstring ::= \" [^\" ]* \"\nnumber ::= [0-9]+"
    }
    
    @objc public func getArithmeticGrammar() -> String {
        print("[Swift] getArithmeticGrammar called")
        
        // Get arithmetic grammar from the framework
        if let grammarPath = Bundle.main.path(forResource: "arithmetic", ofType: "gbnf", inDirectory: "grammars") {
            do {
                let grammar = try String(contentsOfFile: grammarPath)
                return grammar
            } catch {
                print("[Swift] Error reading arithmetic grammar: \(error)")
            }
        }
        
        // Fallback to default arithmetic grammar
        return """
        # Arithmetic grammar
        root ::= sum
        sum ::= product (('+' | '-') product)*
        product ::= term (('*' | '/') term)*
        term ::= NUMBER | '(' sum ')'
        NUMBER ::= [0-9]+ ('.' [0-9]+)?
        """
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @objc public func getCGrammar() -> String {
        print("[Swift] getCGrammar called")
        
        // Get C grammar from the framework
        if let grammarPath = Bundle.main.path(forResource: "c", ofType: "gbnf", inDirectory: "grammars") {
            do {
                let grammar = try String(contentsOfFile: grammarPath)
                return grammar
            } catch {
                print("[Swift] Error reading C grammar: \(error)")
            }
        }
        
        // Fallback to simple C grammar
        return "# Simple C grammar\nroot ::= function\nfunction ::= type identifier '(' parameters ')' '{' body '}'\ntype ::= 'int' | 'void' | 'char' | 'float' | 'double'\nparameters ::= parameter (',' parameter)* | void\nparameter ::= type identifier\nbody ::= statement*\nstatement ::= declaration | assignment | if_statement | return_statement | '{' body '}'\ndeclaration ::= type identifier ';'\nassignment ::= identifier '=' expression ';'\nif_statement ::= 'if' '(' condition ')' statement ('else' statement)?\nreturn_statement ::= 'return' expression? ';'\nexpression ::= term (('+' | '-') term)*\nterm ::= factor (('*' | '/') factor)*\nfactor ::= NUMBER | identifier | '(' expression ')'\ncondition ::= expression ('==' | '!=' | '<' | '>' | '<=' | '>=') expression\nidentifier ::= [a-zA-Z_][a-zA-Z0-9_]*\nNUMBER ::= [0-9]+"
    }
    
    // MARK: - Chat Template
    
    @objc public func setChatTemplate(contextHandle: Int64, chatTemplate: String) -> Bool {
        print("[Swift] setChatTemplate called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] setChatTemplate called with zero handle - returning false")
            return false
        }
        
        // This function is not implemented in the current llama_mobile version
        print("[Swift] setChatTemplate: function not implemented")
        return false
    }
    
    
    @objc public func formatChatMessages(contextHandle: Int64, messagesJson: String, chatTemplate: String? = nil) -> [String: Any] {
        print("[Swift] formatChatMessages called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] formatChatMessages called with zero handle - returning empty result")
            return ["formattedPrompt": ""]
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        // Parse messages JSON
        guard let jsonData = messagesJson.data(using: .utf8) else {
            print("[Swift] Error: Invalid JSON string")
            return ["formattedPrompt": ""]
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let messages = jsonObject as? [[String: Any]] else {
                print("[Swift] Error: Invalid messages format")
                return ["formattedPrompt": ""]
            }
            
            // Get the built-in chat template from the model, or use the provided template or default
            let modelChatTemplate = getModelChatTemplate(contextHandle: contextHandle)
            let templateToUse = chatTemplate ?? modelChatTemplate ?? "{{role}}:\n{{content}}\n\n"
            
            print("[Swift] Using chat template: \(templateToUse)")
            
            // Create a formatted prompt from messages using the chat template
            var formattedPrompt = ""
            for message in messages {
                if let role = message["role"] as? String, let content = message["content"] as? String {
                    var messageTemplate = templateToUse
                    messageTemplate = messageTemplate.replacingOccurrences(of: "{{role}}", with: role)
                    messageTemplate = messageTemplate.replacingOccurrences(of: "{{content}}", with: content)
                    formattedPrompt += messageTemplate
                }
            }
            
            // Add the assistant prompt suffix based on the chat template
            // This extracts the assistant turn format by replacing role with 'assistant' and removing content placeholder
            var assistantTurnTemplate = templateToUse
            assistantTurnTemplate = assistantTurnTemplate.replacingOccurrences(of: "{{role}}", with: "assistant")
            
            // Find the position of the content placeholder and only keep the part before it
            if let contentPlaceholderRange = assistantTurnTemplate.range(of: "{{content}}") {
                // Only keep the part before the content placeholder
                assistantTurnTemplate = String(assistantTurnTemplate[..<contentPlaceholderRange.lowerBound])
            }
            
            // Trim whitespace and add newline
            assistantTurnTemplate = assistantTurnTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            formattedPrompt += assistantTurnTemplate + "\n"
            
            print("[Swift] formatChatMessages: returned prompt length = \(formattedPrompt.count)")
            return ["formattedPrompt": formattedPrompt]
            
        } catch {
            print("[Swift] Error parsing messages JSON: \(error)")
            return ["formattedPrompt": ""]
        }
    }
    
    // MARK: - Enhanced Completion
    
    @objc public func generateCompletionWithParams(contextHandle: Int64, params: [String: Any]) -> [String: Any] {
        print("[Swift] generateCompletionWithParams called with contextHandle: \(contextHandle)")
        
        if contextHandle == 0 {
            print("[Swift] generateCompletionWithParams called with zero handle - returning empty result")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        let context = unsafeBitCast(contextHandle, to: llama_mobile_context_handle_t.self)
        
        var cParams = llama_mobile_completion_params_c_t()
        memset(&cParams, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
        
        // Set parameters from dictionary
        if let prompt = params["prompt"] as? String {
            cParams.prompt = prompt.withCString { $0 }
        }
        
        if let maxTokens = params["maxTokens"] as? Int {
            cParams.n_predict = Int32(maxTokens)
        } else {
            cParams.n_predict = 128
        }
        
        if let temperature = params["temperature"] as? Double {
            cParams.temperature = temperature
        }
        
        if let topK = params["topK"] as? Int {
            cParams.top_k = Int32(topK)
        }
        
        if let topP = params["topP"] as? Double {
            cParams.top_p = topP
        }
        
        if let minP = params["minP"] as? Double {
            cParams.min_p = minP
        }
        
        if let penaltyRepeat = params["penaltyRepeat"] as? Double {
            cParams.penalty_repeat = penaltyRepeat
        }
        
        if let penaltyFreq = params["penaltyFreq"] as? Double {
            cParams.penalty_freq = penaltyFreq
        }
        
        if let penaltyPresent = params["penaltyPresent"] as? Double {
            cParams.penalty_present = penaltyPresent
        }
        
        if let useJsonResponse = params["useJsonResponse"] as? Bool {
            cParams.use_json_response = useJsonResponse
        }
        
        // Handle stop sequences
        if let stopSequences = params["stopSequences"] as? [String], !stopSequences.isEmpty {
            let stopSequenceCount = stopSequences.count
            let stopSequencesC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: stopSequenceCount)
            var stopStringsToFree: [UnsafeMutablePointer<CChar>] = []
            
            defer {
                for cString in stopStringsToFree {
                    cString.deallocate()
                }
                stopSequencesC.deallocate()
            }
            
            for (index, sequence) in stopSequences.enumerated() {
                let stopCString = UnsafeMutablePointer<CChar>.allocate(capacity: sequence.utf8.count + 1)
                sequence.withCString { source in
                    stopCString.update(from: source, count: sequence.utf8.count + 1)
                }
                stopStringsToFree.append(stopCString)
                stopSequencesC[index] = UnsafePointer(stopCString)
            }
            
            cParams.stop_sequences = stopSequencesC
            cParams.stop_sequence_count = Int32(stopSequenceCount)
        }
        
        // Generate completion
        var result = llama_mobile_completion_result_c_t()
        let status = llama_mobile_completion_c(context, &cParams, &result)
        
        if status != 0 {
            print("[Swift] Error: Completion failed with status \(status)")
            return ["text": "", "tokensGenerated": 0, "tokensEvaluated": 0, "truncated": false, "stoppedEos": false, "stoppedWord": false, "stoppedLimit": false]
        }
        
        let text = result.text != nil ? String(cString: result.text!) : ""
        print("[Swift] Generated text length: \(text.count) characters")
        
        // Clean up response by removing ending tags and stop sequences
        var cleanedText = text
        if let stopSequences = params["stopSequences"] as? [String] {
            for stopSequence in stopSequences {
                cleanedText = cleanedText.replacingOccurrences(of: stopSequence, with: "")
            }
        }
        cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|", with: "")
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Wrap plain text in JSON if needed
        if let useJsonResponse = params["useJsonResponse"] as? Bool, useJsonResponse, !cleanedText.hasPrefix("{") {
            print("[Swift] Expected JSON response but got plain text, wrapping in JSON format")
            let wrappedResponse: [String: Any] = [
                "id": "chatcmpl-" + UUID().uuidString,
                "object": "chat.completion",
                "created": Int(Date.timeIntervalSinceReferenceDate * 1000),
                "model": "llama.cpp",
                "choices": [
                    [
                        "index": 0,
                        "message": ["role": "assistant", "content": cleanedText],
                        "finish_reason": "stop"
                    ]
                ],
                "usage": [
                    "prompt_tokens": result.tokens_evaluated,
                    "completion_tokens": result.tokens_predicted,
                    "total_tokens": result.tokens_evaluated + result.tokens_predicted
                ]
            ]
            if let wrappedJsonData = try? JSONSerialization.data(withJSONObject: wrappedResponse, options: .prettyPrinted),
               let wrappedJsonString = String(data: wrappedJsonData, encoding: .utf8) {
                cleanedText = wrappedJsonString
            }
        }
        
        return [
            "text": cleanedText,
            "tokensGenerated": result.tokens_predicted,
            "tokensEvaluated": result.tokens_evaluated,
            "truncated": result.truncated,
            "stoppedEos": result.stopped_eos,
            "stoppedWord": result.stopped_word,
            "stoppedLimit": result.stopped_limit,
            "stoppingWord": result.stopping_word != nil ? String(cString: result.stopping_word!) : nil
        ]
    }
}
