import XCTest
@testable import LlamaMobileCapacitorPlugin

/// v2 conformance tests for the Capacitor iOS plugin (M7).
/// Model-backed tests skip unless a GGUF is reachable on the test host.
final class LlamaMobileCapacitorPluginTests: XCTestCase {

    private var modelPath: String {
        if let p = ProcessInfo.processInfo.environment["LLAMA_MOBILE_TEST_MODEL"],
           FileManager.default.fileExists(atPath: p) { return p }
        return "/dev/null/missing.gguf"
    }

    func testPluginRegisteredName() {
        // identifier/jsName must match the TS registerPlugin('LlamaMobile').
        XCTAssertEqual(LlamaMobileCapacitorPlugin().identifier, "LlamaMobile")
        XCTAssertEqual(LlamaMobileCapacitorPlugin().jsName, "LlamaMobile")
    }
}
