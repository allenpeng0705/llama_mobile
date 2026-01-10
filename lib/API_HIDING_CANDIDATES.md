# API Candidates for Hiding

This document identifies potential API candidates that should be moved from the public `llama_mobile_api.h` to the private `llama_mobile_private.h` header file.

## Criteria for Hiding APIs

An API should be considered for hiding if it meets one or more of the following criteria:
- It's an internal implementation detail that users don't need to know about
- It exposes internal data structures or implementation details
- It's only used within the library itself
- It's likely to change in future versions and shouldn't be part of the stable public API
- It's a helper function that supports public APIs but doesn't need to be exposed directly

## Candidate APIs

### 1. Internal Context Structure

**Current Status**: The `llama_mobile_context_private` struct is already in the private header, which is correct.

**Reason**: Exposing internal context structure would break encapsulation and make the API more fragile to changes.

### 2. Internal Initialization Functions

**Current Status**: `llama_mobile_init_internal` is already in the private header.

**Reason**: Internal initialization functions handle low-level details that users don't need to manage directly.

### 3. Token Processing Functions

**Candidate**: None - The public tokenization functions (`llama_mobile_tokenize`, `llama_mobile_detokenize`) are essential for users.

### 4. Internal Helper Functions

**Candidate**: Functions like `convert_init_params`, `convert_completion_params` that are already marked as `static` in implementation files.

**Status**: Already hidden as `static` functions - no need to move to private header.

**Reason**: These helper functions are only used within the same translation unit and don't need to be exposed publicly.

### 5. Multimodal Internal Functions

**Current Status**: Functions like `llama_mobile_init_multimodal` are public, which is correct.

**Reason**: Multimodal functionality is a core feature that users need to access directly.

### 6. FFI Layer Functions

**Candidate**: Functions with `_c` suffix like `llama_mobile_init_context_c`, `llama_mobile_completion_c`.

**Status**: These are already marked with `LLAMA_MOBILE_FFI_EXPORT` and are intended for FFI use.

**Recommendation**: Keep as public FFI APIs since they're needed for language bindings.

### 7. Grammar Support Functions

**Candidate**: Internal grammar functions like `llama_mobile_init_grammar`, `llama_mobile_free_grammar`.

**Status**: These are already in the private header, which is correct.

**Reason**: Grammar implementation details should be hidden from users.

### 8. Sampling Functions

**Candidate**: Internal sampling functions like `llama_mobile_sample_next_token`.

**Status**: Already in the private header, which is correct.

**Reason**: Sampling algorithms are implementation details that shouldn't be exposed publicly.

## Additional Recommendations

### 1. Keep Public Core API Functions

The following core functions should remain public:
- `llama_mobile_init` / `llama_mobile_init_simple` - Essential for initialization
- `llama_mobile_free` - Essential for cleanup
- `llama_mobile_completion` / `llama_mobile_completion_simple` - Essential for generation
- `llama_mobile_tokenize` / `llama_mobile_detokenize` - Essential for text processing
- `llama_mobile_embedding` - Essential for embedding generation
- `llama_mobile_apply_lora_adapters` / `llama_mobile_remove_lora_adapters` - Essential for LoRA support
- `llama_mobile_init_multimodal` / `llama_mobile_release_multimodal` - Essential for multimodal support

### 2. Consider Hiding Advanced Configuration Functions

Functions that control low-level configuration might be candidates for hiding or deprecation in favor of simpler APIs:
- Functions that expose internal buffer management
- Functions that require deep knowledge of the model architecture
- Functions that are only useful for debugging

### 3. Maintain Backward Compatibility

If hiding an API that was previously public:
1. Mark it as deprecated first with appropriate comments
2. Provide migration paths for users
3. Wait for a major version release before removing it completely

## Conclusion

The current API organization is generally good, with most internal functions already properly hidden:
- Core user-facing APIs are public
- Internal implementation details are either in the private header or marked as `static`
- FFI layer is properly separated with its own export macros

The main improvements would be to ensure any remaining internal implementation functions are moved to the private header and marked with `LLAMA_MOBILE_PRIVATE` visibility macro.