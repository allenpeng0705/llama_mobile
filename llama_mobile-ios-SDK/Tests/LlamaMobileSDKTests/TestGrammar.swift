import LlamaMobileSDK

// Test grammar loading
let llamaMobile = LlamaMobile()

// Test that json grammar can be loaded
if let jsonGrammar = llamaMobile.grammarContent(for: .json) {
    print("✓ Successfully loaded json.gbnf grammar")
    print("First 100 chars of json.gbnf:", jsonGrammar.prefix(100))
} else {
    print("✗ Failed to load json.gbnf grammar")
}

// Test other grammars
if let arithmeticGrammar = llamaMobile.grammarContent(for: .arithmetic) {
    print("✓ Successfully loaded arithmetic.gbnf grammar")
} else {
    print("✗ Failed to load arithmetic.gbnf grammar")
}

print("Grammar loading test completed!")
