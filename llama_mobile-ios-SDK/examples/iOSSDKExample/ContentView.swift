import SwiftUI
import LlamaMobileSDK

struct ContentView: View {
    @State private var modelPath = ""
    @State private var systemPrompt = "You are a helpful and polite AI assistant. Please provide clear and relevant responses to user queries."
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
            
            Section(header: Text("System Prompt")) {
                TextEditor(text: $systemPrompt)
                    .frame(minHeight: 100)
                    .placeholder(when: systemPrompt.isEmpty) { Text("Enter system prompt").foregroundColor(.gray) }
            }
            
            Section(header: Text("User Prompt")) {
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
                        
                        Button(action: { generateResponse() }) {
                            HStack { 
                                Spacer()
                                Text("Generate Response")
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
                systemPrompt: systemPrompt,
                chatTemplate: "",
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
    
    private func generateResponse() {
        isLoading = true
        hasError = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let result = llamaMobile.generateResponse(userMessage: prompt, maxTokens: 128) else {
                DispatchQueue.main.async {
                    isLoading = false
                    hasError = true
                    completionResult = "Failed to generate response."
                }
                return
            }
            
            DispatchQueue.main.async {
                isLoading = false
                completionResult = result
                print("Generation complete.")
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