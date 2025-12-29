//
//  LlamaMobileTestApp.swift
//  LlamaMobileTestApp
//
//  Created by Your Name on 2025-12-29.
//

import SwiftUI
import LlamaMobileSDK

struct ContentView: View {
    @State private var modelPath = ""
    @State private var vocoderPath = ""
    @State private var prompt = "Hello, how are you?"
    @State private var result = ""
    @State private var isInitialized = false
    @State private var isVocoderInitialized = false
    
    private let llamaMobile = LlamaMobile()
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Model Paths") {
                        TextField("Model Path", text: $modelPath)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        TextField("Vocoder Path", text: $vocoderPath)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    Section("Controls") {
                        Button("Initialize Model") {
                            Task {
                                await initializeModel()
                            }
                        }
                        .disabled(isInitialized)
                        
                        Button("Initialize Vocoder") {
                            Task {
                                await initializeVocoder()
                            }
                        }
                        .disabled(!isInitialized || isVocoderInitialized)
                    }
                    
                    Section("Completion") {
                        TextField("Prompt", text: $prompt, axis: .vertical)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button("Generate Completion") {
                            Task {
                                await generateCompletion()
                            }
                        }
                        .disabled(!isInitialized)
                    }
                    
                    Section("Result") {
                        Text(result)
                    }
                    
                    Section("TTS") {
                        Button("Generate Audio Tokens") {
                            Task {
                                await generateAudio()
                            }
                        }
                        .disabled(!isInitialized || !isVocoderInitialized)
                    }
                }
            }
            .navigationTitle("LlamaMobile SDK Test")
        }
    }
    
    private func initializeModel() async {
        guard !modelPath.isEmpty else {
            result = "Please enter a model path"
            return
        }
        
        let params = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            nBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            progressCallback: { progress in
                print("Initialization progress: \(progress * 100)%")
            }
        )
        
        let success = llamaMobile.initialize(with: params)
        isInitialized = success
        result = success ? "Model initialized successfully" : "Failed to initialize model"
    }
    
    private func initializeVocoder() async {
        guard !vocoderPath.isEmpty else {
            result = "Please enter a vocoder path"
            return
        }
        
        let success = llamaMobile.initializeVocoder(modelPath: vocoderPath)
        isVocoderInitialized = success
        result = success ? "Vocoder initialized successfully" : "Failed to initialize vocoder"
    }
    
    private func generateCompletion() async {
        guard !prompt.isEmpty else {
            result = "Please enter a prompt"
            return
        }
        
        let params = LlamaMobile.CompletionParams(
            prompt: prompt,
            nPredict: 128,
            temperature: 0.8,
            topK: 40,
            topP: 0.9
        )
        
        if let completionResult = llamaMobile.completion(with: params) {
            result = completionResult.text
        } else {
            result = "Failed to generate completion"
        }
    }
    
    private func generateAudio() async {
        guard !prompt.isEmpty else {
            result = "Please enter a prompt"
            return
        }
        
        // Get formatted audio completion
        if let formattedPrompt = llamaMobile.getFormattedAudioCompletion(textToSpeak: prompt) {
            // Generate completion to get audio tokens
            let completionParams = LlamaMobile.CompletionParams(
                prompt: formattedPrompt,
                nPredict: 512,
                temperature: 0.0,
                topK: 0,
                topP: 0.0
            )
            
            if let completionResult = llamaMobile.completion(with: completionParams) {
                // Tokenize the generated text
                if let tokens = llamaMobile.tokenize(text: completionResult.text) {
                    // Decode audio tokens
                    if let audioData = llamaMobile.decodeAudioTokens(tokens: tokens) {
                        result = "Generated audio data with \(audioData.count) samples"
                        print("Audio data sample: \(audioData.prefix(5))...")
                        // Here you would typically play the audio data
                    } else {
                        result = "Failed to decode audio tokens"
                    }
                } else {
                    result = "Failed to tokenize completion result"
                }
            } else {
                result = "Failed to generate audio completion"
            }
        } else {
            result = "Failed to get formatted audio completion"
        }
    }
}

@main
struct LlamaMobileTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
