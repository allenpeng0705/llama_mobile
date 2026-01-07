import Foundation
import llama_mobile_c
import LlamaMobileSDK

// Test structure for tracking results
struct TestResult {
    let name: String
    let passed: Bool
    let details: String?
}

// Test suite for iOS SDK functionality
class LlamaMobileSDKTests {
    private let llamaMobile = LlamaMobile()
    private var contextHandle: llama_mobile_context_handle_c_t?
    private var testResults: [TestResult] = []
    
    // Model path - this should be adjusted based on your test environment
    private let modelPath: String
    
    init() {
        // Determine model path - default to /tmp/model.gguf if not found in command line
        if CommandLine.arguments.count > 1 {
            modelPath = CommandLine.arguments[1]
        } else {
            // Try to find a model in the models directory
            let currentDir = FileManager.default.currentDirectoryPath
            let modelsDir = URL(fileURLWithPath: currentDir).appendingPathComponent("../../models").path
            
            if let modelFiles = try? FileManager.default.contentsOfDirectory(atPath: modelsDir) {
                let ggufFiles = modelFiles.filter { $0.hasSuffix(".gguf") }
                if let firstModel = ggufFiles.first {
                    modelPath = URL(fileURLWithPath: modelsDir).appendingPathComponent(firstModel).path
                    print("Using found model: \(modelPath)")
                } else {
                    modelPath = "/tmp/model.gguf"
                    print("No model found in models directory, using default path: \(modelPath)")
                }
            } else {
                modelPath = "/tmp/model.gguf"
                print("No models directory found, using default path: \(modelPath)")
            }
        }
    }
    
    func runAllTests() {
        print("\n" + String(repeating: "=", count: 60))
        print("         LLAMA MOBILE iOS SDK TEST SUITE")
        print(String(repeating: "=", count: 60))
        
        // Run individual tests
        testGrammarLoading()
        testModelInitialization()
        
        if contextHandle != nil {
            testCompletionGeneration()
            testCompletionWithGrammar()
            testTokenization()
            // Cleanup
            testModelRelease()
        }
        
        // Generate test report
        generateReport()
    }
    
    private func testGrammarLoading() {
        print("\n--- Testing Grammar Loading ---")
        
        let grammars: [LlamaMobile.GrammarName] = [.json, .arithmetic, .list]
        var allGrammarsLoaded = true
        var loadedGrammars: [String] = []
        var failedGrammars: [String] = []
        
        for grammarName in grammars {
            if let grammarContent = llamaMobile.grammarContent(for: grammarName) {
                print("✓ Successfully loaded \(grammarName.rawValue).gbnf")
                loadedGrammars.append(grammarName.rawValue)
            } else {
                print("✗ Failed to load \(grammarName.rawValue).gbnf")
                failedGrammars.append(grammarName.rawValue)
                allGrammarsLoaded = false
            }
        }
        
        let details = "Loaded: \(loadedGrammars.joined(", ")), Failed: \(failedGrammars.joined(", "))"
        testResults.append(TestResult(name: "Grammar Loading", passed: allGrammarsLoaded, details: details))
    }
    
    private func testModelInitialization() {
        print("\n--- Testing Model Initialization ---")
        
        guard FileManager.default.fileExists(atPath: modelPath) else {
            print("✗ Model file not found at path: \(modelPath)")
            testResults.append(TestResult(name: "Model Initialization", passed: false, details: "Model file not found"))
            return
        }
        
        print("Using model path: \(modelPath)")
        
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            nGpuLayers: 4, // Adjust based on your hardware
            nThreads: 4
        )
        
        if llamaMobile.initialize(with: initParams) {
            print("✓ Model initialized successfully")
            // Store context handle for further tests
            if let handle = UnsafeMutableRawPointer(bitPattern: llama_mobile_get_default_context_c()) {
                contextHandle = handle.assumingMemoryBound(to: llama_mobile_context_c_t.self)
            }
            testResults.append(TestResult(name: "Model Initialization", passed: true, details: nil))
        } else {
            print("✗ Model initialization failed")
            testResults.append(TestResult(name: "Model Initialization", passed: false, details: nil))
        }
    }
    
    private func testCompletionGeneration() {
        print("\n--- Testing Completion Generation ---")
        
        let completionParams = LlamaMobile.CompletionParams(
            prompt: "Hello, world!",
            nPredict: 64,
            temperature: 0.8,
            topK: 40,
            topP: 0.9,
            stopSequences: ["\n\n"]
        )
        
        if let result = llamaMobile.completion(with: completionParams) {
            print("✓ Completion generated successfully")
            print("Generated text: \(result.text)")
            print("Tokens predicted: \(result.tokensPredicted)")
            print("Tokens evaluated: \(result.tokensEvaluated)")
            
            testResults.append(TestResult(
                name: "Completion Generation", 
                passed: true, 
                details: "Generated \(result.tokensPredicted) tokens"
            ))
        } else {
            print("✗ Completion generation failed")
            testResults.append(TestResult(name: "Completion Generation", passed: false, details: nil))
        }
    }
    
    private func testCompletionWithGrammar() {
        print("\n--- Testing Completion with Grammar ---")
        
        guard let jsonGrammar = llamaMobile.grammarContent(for: .json) else {
            print("✗ JSON grammar not available for testing")
            testResults.append(TestResult(
                name: "Completion with Grammar", 
                passed: false, 
                details: "JSON grammar not available"
            ))
            return
        }
        
        let completionParams = LlamaMobile.CompletionParams(
            prompt: "Generate a JSON object with name, age, and city fields: ",
            nPredict: 100,
            temperature: 0.7,
            topK: 40,
            topP: 0.9,
            grammar: jsonGrammar
        )
        
        if let result = llamaMobile.completion(with: completionParams) {
            print("✓ JSON completion generated successfully")
            let fullJson = "\(completionParams.prompt)\(result.text)"
            print("Generated JSON: \(fullJson)")
            
            testResults.append(TestResult(
                name: "Completion with Grammar", 
                passed: true, 
                details: "Generated JSON output with grammar constraints"
            ))
        } else {
            print("✗ JSON completion generation failed")
            testResults.append(TestResult(name: "Completion with Grammar", passed: false, details: nil))
        }
    }
    
    private func testTokenization() {
        print("\n--- Testing Tokenization ---")
        
        let testText = "Testing tokenization API in iOS SDK."
        
        // Test tokenization
        let tokens = llama_mobile_tokenize_c(contextHandle, testText, false)
        if tokens.count > 0 {
            print("✓ Tokenization successful")
            print("Text: \(testText)")
            print("Token count: \(tokens.count)")
            print("Tokens: \(tokens)")
            
            // Test detokenization
            let detokenizedText = llama_mobile_detokenize_c(contextHandle, tokens)
            if let detokenized = detokenizedText {
                print("✓ Detokenization successful")
                print("Detokenized: \(detokenized)")
                
                let tokensMatch = detokenized.lowercased().contains(testText.lowercased())
                testResults.append(TestResult(
                    name: "Tokenization/Detokenization", 
                    passed: tokensMatch, 
                    details: tokensMatch ? "Round trip successful" : "Detokenized text doesn't match original"
                ))
                
                llama_mobile_free_string_c(detokenized)
            } else {
                print("✗ Detokenization failed")
                testResults.append(TestResult(name: "Tokenization/Detokenization", passed: false, details: "Detokenization failed"))
            }
        } else {
            print("✗ Tokenization failed")
            testResults.append(TestResult(name: "Tokenization/Detokenization", passed: false, details: "Tokenization failed"))
        }
    }
    
    private func testModelRelease() {
        print("\n--- Testing Model Release ---")
        
        if contextHandle != nil {
            llama_mobile_free_context_c(contextHandle!)
            contextHandle = nil
            print("✓ Model context released successfully")
            testResults.append(TestResult(name: "Model Release", passed: true, details: nil))
        } else {
            print("✗ No context handle to release")
            testResults.append(TestResult(name: "Model Release", passed: false, details: "No context handle available"))
        }
    }
    
    private func generateReport() {
        print("\n" + String(repeating: "=", count: 60))
        print("                TEST RESULTS REPORT")
        print(String(repeating: "=", count: 60))
        
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.passed }.count
        let failedTests = totalTests - passedTests
        
        // Print detailed results
        print("\nDETAILED RESULTS:")
        print("------------------------------------------------------------------------")
        print(String(format: "%-40s %-15s %s", "Test", "Status", "Details"))
        print("------------------------------------------------------------------------")
        
        for result in testResults {
            let status = result.passed ? "PASSED" : "FAILED"
            let details = result.details ?? ""
            print(String(format: "%-40s %-15s %s", result.name, status, details))
        }
        
        print("------------------------------------------------------------------------")
        print(String(format: "%-40s %-15d", "Total Tests", totalTests))
        print(String(format: "%-40s %-15d", "Tests Passed", passedTests))
        print(String(format: "%-40s %-15d", "Tests Failed", failedTests))
        
        // Final summary
        print("\n" + String(repeating: "=", count: 60))
        if failedTests == 0 {
            print("✅ ALL TESTS PASSED!")
        } else {
            print("❌ \(failedTests) OUT OF \(totalTests) TESTS FAILED!")
        }
        print(String(repeating: "=", count: 60))
    }
}

// Run the tests if this file is executed directly
if CommandLine.arguments.first == URL(fileURLWithPath: #file).lastPathComponent {
    let tests = LlamaMobileSDKTests()
    tests.runAllTests()
}
