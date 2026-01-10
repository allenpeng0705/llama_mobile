//
//  TestLlamaMobile.swift
//  Test file for LlamaMobile Swift wrapper
//

import llama_mobile

// Create a comprehensive test to demonstrate the simplified Swift wrapper API
func testLlamaMobile() {
    // Test basic initialization
    if let llama = LlamaMobile(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 4, nThreads: 2) {
        print("✅ Successfully initialized LlamaMobile context")
        
        // Test tokenization
        if let tokens = llama.tokenize(text: "Hello, world!") {
            print("✅ Successfully tokenized text: \(tokens)")
            
            // Test detokenization
            if let text = llama.detokenize(tokens: tokens) {
                print("✅ Successfully detokenized tokens: \(text)")
            }
        }
        
        // Test simple completion with simplified API
        if let result = llama.generateCompletion(prompt: "Hello, world!", maxTokens: 50, temperature: 0.7) {
            print("✅ Successfully generated completion: \(result.text)")
        }
        
        // Test completion with CompletionParams struct
        var completionParams = LlamaMobile.CompletionParams(prompt: "Explain quantum computing in simple terms")
        completionParams.maxTokens = 150
        completionParams.temperature = 0.6
        if let result = llama.generateCompletion(with: completionParams) {
            print("✅ Successfully generated completion with params struct: \(result.text)")
        }
        
        // Test convenience initializers for CompletionParams
        let creativeParams = LlamaMobile.CompletionParams(creativePrompt: "Write a short poem about the moon")
        if let creativeResult = llama.generateCompletion(with: creativeParams) {
            print("✅ Successfully generated creative completion: \(creativeResult.text)")
        }
        
        let factualParams = LlamaMobile.CompletionParams(factualPrompt: "What is the capital of France?")
        if let factualResult = llama.generateCompletion(with: factualParams) {
            print("✅ Successfully generated factual completion: \(factualResult.text)")
        }
        
        // Test conversation with streaming
        print("Testing conversation with streaming...")
        if let streamResult = llama.generateResponse(userMessage: "What is AI?", maxTokens: 100, tokenCallback: { token in
            print("🔄 Streaming token: \(token)")
            return true // Continue streaming
        }) {
            print("✅ Successfully generated streaming conversation response: \(streamResult.text)")
        }
        
        // Test LoRA adapters
        let loraAdapter = LlamaMobile.LoraAdapter(path: "/path/to/lora.gguf", scale: 1.0)
        if llama.applyLoraAdapters([loraAdapter]) {
            print("✅ Successfully applied LoRA adapter")
            llama.removeLoraAdapters()
        }
        
        // Test TTS functionality
        if llama.initVocoder(vocoderModelPath: "/path/to/vocoder.gguf") {
            print("✅ Successfully initialized vocoder")
            
            let ttsType = llama.getTTSType()
            print("✅ TTS type: \(ttsType)")
            
            // Test the new simplified TTS method
            if let audioSamples = llama.generateAudioFromText(text: "Hello, this is a test of the text to speech functionality.") {
                print("✅ Successfully generated audio samples: \(audioSamples.count) samples")
            }
            
            llama.releaseVocoder()
        }
        
        // Test multimodal functionality with unified API
        if llama.initMultimodal(mmprojPath: "/path/to/mmproj.bin") {
            print("✅ Successfully initialized multimodal")
            print("✅ Supports vision: \(llama.supportsVision())")
            print("✅ Supports audio: \(llama.supportsAudio())")
            
            // Test unified completion API with media
            let multimodalParams = LlamaMobile.CompletionParams(
                multimodalPrompt: "What is in this image?",
                mediaPaths: ["/path/to/image.jpg"]
            )
            if let multimodalResult = llama.generateCompletion(with: multimodalParams) {
                print("✅ Successfully generated multimodal completion: \(multimodalResult.text)")
            }
            
            llama.releaseMultimodal()
        }
        
        // Test model info
        print("✅ Context window size: \(llama.getContextWindowSize())")
        print("✅ Embedding dimension: \(llama.getEmbeddingDimension())")
        
        if let desc = llama.getModelDescription() {
            print("✅ Model description: \(desc)")
        }
        
        print("✅ Model size: \(llama.getModelSize()) bytes")
        print("✅ Model parameters: \(llama.getModelParametersCount())")
        
    } else {
        print("❌ Failed to initialize LlamaMobile context")
    }
}

// Main entry point
@main
struct TestMain {
    static func main() {
        testLlamaMobile()
    }
}