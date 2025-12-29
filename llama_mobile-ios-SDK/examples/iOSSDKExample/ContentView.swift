import SwiftUI
import LlamaMobileSDK

struct ContentView: View {
    @State private var modelPath = ""
    @State private var prompt = "Hello, world!"
    @State private var completionResult = ""
    @State private var isLoading = false
    @State private var hasError = false
    
    private var llamaMobile = LlamaMobile()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Form {
                    Section(header: Text("Model Configuration")) {
                        TextField("Model Path", text: $modelPath)
                            .placeholder(when: modelPath.isEmpty) { Text("Path to your model file").foregroundColor(.gray) }
                    }
                    
                    Section(header: Text("Prompt")) {
                        TextField("Enter prompt", text: $prompt)
                            .placeholder(when: prompt.isEmpty) { Text("Hello, world!").foregroundColor(.gray) }
                    }
                    
                    Section {
                        Button(action: { loadModel() }) {
                            HStack { 
                                Spacer()
                                Text("Load Model")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        .disabled(isLoading)
                        
                        Button(action: { generateCompletion() }) {
                            HStack { 
                                Spacer()
                                Text("Generate Completion")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        .disabled(isLoading || modelPath.isEmpty)
                    }
                }
                
                if isLoading {
                    ProgressView("Processing...")
                        .padding()
                }
                
                if hasError {
                    Text("An error occurred. Please check your inputs.")
                        .foregroundColor(.red)
                        .padding()
                }
                
                if !completionResult.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Result:")
                            .font(.headline)
                        Text(completionResult)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Llama Mobile SDK Example")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
    
    private func loadModel() {
        isLoading = true
        hasError = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let params = LlamaMobile.InitParams(
                modelPath: modelPath,
                nCtx: 2048,
                nGpuLayers: 4,
                progressCallback: { progress in
                    print("Loading progress: \(progress * 100)%")
                }
            )
            
            let success = llamaMobile.initialize(with: params)
            
            DispatchQueue.main.async {
                isLoading = false
                if !success {
                    hasError = true
                    completionResult = "Failed to load model. Please check the model path."
                } else {
                    completionResult = "Model loaded successfully!"
                }
            }
        }
    }
    
    private func generateCompletion() {
        isLoading = true
        hasError = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let params = LlamaMobile.CompletionParams(
                prompt: prompt,
                nPredict: 128,
                temperature: 0.7,
                topK: 40,
                topP: 0.9,
                tokenCallback: { tokenJson in
                    // Process token here if needed
                    print("Token: \(tokenJson)")
                    return true // Continue generation
                }
            )
            
            guard let result = llamaMobile.completion(with: params) else {
                DispatchQueue.main.async {
                    isLoading = false
                    hasError = true
                    completionResult = "Failed to generate completion."
                }
                return
            }
            
            DispatchQueue.main.async {
                isLoading = false
                completionResult = result.text
                print("Generation complete. Tokens predicted: \(result.tokensPredicted)")
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}