import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(LlamaMobilePlugin)
public class LlamaMobilePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LlamaMobilePlugin"
    public let jsName = "LlamaMobile"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "multimodalCompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopCompletion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "tokenize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "detokenize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateEmbeddings", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "applyLoraAdapters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeLoraAdapters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "initMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isMultimodalEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateResponse", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearConversation", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getGrammarContent", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "release", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = LlamaMobile()

    @objc func initialize(_ call: CAPPluginCall) {
        guard let params = call.getObject("params") else {
            call.reject("Missing params")
            return
        }
        
        let result = implementation.initialize(params)
        call.resolve([
            "success": result
        ])
    }
    
    @objc func generate(_ call: CAPPluginCall) {
        guard let params = call.getObject("params") else {
            call.reject("Missing params")
            return
        }
        
        if let result = implementation.generate(params) {
            call.resolve(result)
        } else {
            call.reject("Generation failed")
        }
    }
    
    @objc func multimodalCompletion(_ call: CAPPluginCall) {
        guard let params = call.getObject("params"),
              let mediaPaths = call.getArray("mediaPaths") as? [String] else {
            call.reject("Missing params or mediaPaths")
            return
        }
        
        if let result = implementation.multimodalCompletion(params, mediaPaths: mediaPaths) {
            call.resolve(result)
        } else {
            call.reject("Generation failed")
        }
    }
    
    @objc func stopCompletion(_ call: CAPPluginCall) {
        implementation.stopCompletion()
        call.resolve()
    }
    
    @objc func tokenize(_ call: CAPPluginCall) {
        guard let text = call.getString("text") else {
            call.reject("Missing text")
            return
        }
        
        if let tokens = implementation.tokenize(text) {
            call.resolve([
                "tokens": tokens
            ])
        } else {
            call.reject("Tokenization failed")
        }
    }
    
    @objc func detokenize(_ call: CAPPluginCall) {
        guard let tokens = call.getArray("tokens") as? [Int] else {
            call.reject("Missing tokens")
            return
        }
        
        if let text = implementation.detokenize(tokens) {
            call.resolve([
                "text": text
            ])
        } else {
            call.reject("Detokenization failed")
        }
    }
    
    @objc func generateEmbeddings(_ call: CAPPluginCall) {
        guard let text = call.getString("text") else {
            call.reject("Missing text")
            return
        }
        
        if let embeddings = implementation.generateEmbeddings(text) {
            call.resolve([
                "embeddings": embeddings
            ])
        } else {
            call.reject("Embedding generation failed")
        }
    }
    
    @objc func applyLoraAdapters(_ call: CAPPluginCall) {
        guard let adapters = call.getArray("adapters") as? [[String: Any]] else {
            call.reject("Missing adapters")
            return
        }
        
        let success = implementation.applyLoraAdapters(adapters)
        call.resolve([
            "success": success
        ])
    }
    
    @objc func removeLoraAdapters(_ call: CAPPluginCall) {
        implementation.removeLoraAdapters()
        call.resolve()
    }
    
    @objc func initMultimodal(_ call: CAPPluginCall) {
        guard let mmprojPath = call.getString("mmprojPath"),
              let useGpu = call.getBool("useGpu") else {
            call.reject("Missing mmprojPath or useGpu")
            return
        }
        
        let success = implementation.initMultimodal(mmprojPath, useGpu: useGpu)
        call.resolve([
            "success": success
        ])
    }
    
    @objc func isMultimodalEnabled(_ call: CAPPluginCall) {
        let isEnabled = implementation.isMultimodalEnabled()
        call.resolve([
            "enabled": isEnabled
        ])
    }
    
    @objc func releaseMultimodal(_ call: CAPPluginCall) {
        implementation.releaseMultimodal()
        call.resolve()
    }
    
    @objc func generateResponse(_ call: CAPPluginCall) {
        guard let userMessage = call.getString("userMessage"),
              let maxTokens = call.getInt("maxTokens") else {
            call.reject("Missing userMessage or maxTokens")
            return
        }
        
        if let result = implementation.generateResponse(userMessage, maxTokens: maxTokens) {
            call.resolve(result)
        } else {
            call.reject("Response generation failed")
        }
    }
    
    @objc func clearConversation(_ call: CAPPluginCall) {
        implementation.clearConversation()
        call.resolve()
    }
    
    @objc func getGrammarContent(_ call: CAPPluginCall) {
        guard let grammarName = call.getString("grammarName") else {
            call.reject("Missing grammarName")
            return
        }
        
        if let content = implementation.getGrammarContent(grammarName) {
            call.resolve([
                "content": content
            ])
        } else {
            call.reject("Grammar not found")
        }
    }
    
    @objc func release(_ call: CAPPluginCall) {
        implementation.release()
        call.resolve()
    }
}
