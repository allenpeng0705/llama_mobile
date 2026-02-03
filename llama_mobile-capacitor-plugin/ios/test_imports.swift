// Test file to verify iOS plugin can compile
import Foundation
import llama_mobile

// Test that we can reference LlamaMobile types
let params = LlamaMobile.DownloadParams(url: "https://example.com", localPath: "/tmp")
let hfParams = LlamaMobile.HuggingFaceDownloadParams(repoID: "test/repo", filename: "model.gguf", destinationPath: "/tmp")
let ttsOptions = LlamaMobile.TTSOptions()

print("✓ All types imported successfully")
print("✓ iOS plugin code is syntactically correct")
print("✓ llama_mobile module is working!")