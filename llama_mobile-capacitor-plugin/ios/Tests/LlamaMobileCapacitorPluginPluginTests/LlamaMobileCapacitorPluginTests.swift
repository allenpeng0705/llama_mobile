import XCTest
@testable import LlamaMobileCapacitorPluginPlugin

class LlamaMobileCapacitorPluginTests: XCTestCase {
    // Test initialization and context management
    func testInitContext() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy model path for testing
        let modelPath = "/path/to/dummy/model.gguf"
        let contextHandle = implementation.initContext(modelPath: modelPath, nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        
        // Verify that contextHandle is not -1 (error)
        XCTAssertNotEqual(contextHandle, -1, "initContext should return a valid context handle")
    }
    
    func testReleaseContext() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        // This should not throw an error
        XCTAssertNoThrow(implementation.releaseContext(contextHandle: contextHandle))
    }
    
    // Test tokenization
    func testTokenize() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        let text = "Hello, world!"
        
        let tokens = implementation.tokenize(contextHandle: contextHandle, text: text)
        // Verify that tokens array is not empty
        XCTAssertFalse(tokens.isEmpty, "tokenize should return an array of tokens")
    }
    
    // Test detokenization
    func testDetokenize() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        // Use dummy tokens for testing
        let tokens: [Int32] = [1, 2, 3, 4, 5]
        
        let text = implementation.detokenize(contextHandle: contextHandle, tokens: tokens)
        // Verify that text is not empty
        XCTAssertFalse(text.isEmpty, "detokenize should return a non-empty string")
    }
    
    // Test model info methods
    func testGetContextWindowSize() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let size = implementation.getContextWindowSize(contextHandle: contextHandle)
        // Verify that size is greater than 0
        XCTAssertGreaterThan(size, 0, "getContextWindowSize should return a positive value")
    }
    
    func testGetEmbeddingDimension() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let dimension = implementation.getEmbeddingDimension(contextHandle: contextHandle)
        // Verify that dimension is greater than 0
        XCTAssertGreaterThan(dimension, 0, "getEmbeddingDimension should return a positive value")
    }
    
    // Test conversation methods
    func testIsConversationActive() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let isActive = implementation.isConversationActive(contextHandle: contextHandle)
        // This should return a boolean value
        XCTAssertFalse(isActive, "isConversationActive should return false for a new context")
    }
    
    func testClearConversation() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        // This should not throw an error
        XCTAssertNoThrow(implementation.clearConversation(contextHandle: contextHandle))
    }
    
    // Test TTS methods
    func testIsVocoderEnabled() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let isEnabled = implementation.isVocoderEnabled(contextHandle: contextHandle)
        // This should return false initially
        XCTAssertFalse(isEnabled, "isVocoderEnabled should return false initially")
    }
    
    func testGetTTSType() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let ttsType = implementation.getTTSType(contextHandle: contextHandle)
        // This should return "NONE" initially
        XCTAssertEqual(ttsType, "NONE", "getTTSType should return \"NONE\" initially")
    }
    
    // Test multimodal methods
    func testIsMultimodalEnabled() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let isEnabled = implementation.isMultimodalEnabled(contextHandle: contextHandle)
        // This should return false initially
        XCTAssertFalse(isEnabled, "isMultimodalEnabled should return false initially")
    }
    
    func testSupportsVision() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let supports = implementation.supportsVision(contextHandle: contextHandle)
        // This should return false initially
        XCTAssertFalse(supports, "supportsVision should return false initially")
    }
    
    func testSupportsAudio() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        let supports = implementation.supportsAudio(contextHandle: contextHandle)
        // This should return false initially
        XCTAssertFalse(supports, "supportsAudio should return false initially")
    }
    
    // Test LoRA methods
    func testRemoveLoraAdapters() {
        let implementation = LlamaMobileCapacitorPlugin()
        // Use a dummy context handle for testing
        let contextHandle: Int64 = 1
        
        // This should not throw an error
        XCTAssertNoThrow(implementation.removeLoraAdapters(contextHandle: contextHandle))
    }
}
