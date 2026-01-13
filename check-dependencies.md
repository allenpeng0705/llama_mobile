# Dependency Analysis: minija and nlohmann

## Current State

### minija
- **CMakeLists.txt references it**: Line 296, 304, 312 include `${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/minja`
- **But directory doesn't exist**: `ls -la /Users/shileipeng/Documents/mygithub/llama_mobile/lib/llama_cpp/` shows no `minija` directory
- **No code references found**: `grep "minija"` across the entire codebase found no usage

### nlohmann
- **Exists in source code**: `/Users/shileipeng/Documents/mygithub/llama_mobile/lib/llama_cpp/nlohmann/`
- **Used in multiple files**: 
  - `llama_mobile_ffi.cpp` (line 5)
  - `llama_mobile_chat.cpp` (line 3)
  - `llama_mobile_context.cpp` (line 3)
  - `llama_cpp/peg-parser.h` (line 3)
- **Code references use full path**: `#include "llama_cpp/nlohmann/json.hpp"`

## Flutter SDK Comparison

The Flutter SDK has:
- Top-level `Headers/nlohmann/` directory
- Nested `Headers/llama_cpp/nlohmann/` directory

This appears to be **redundant** since the code only needs access to one location.

## Recommended Approach

### For minija
- **Remove references**: Since the directory doesn't exist and no code uses it, we should remove references from CMakeLists.txt
- **No need to add**: It's likely a leftover dependency that was removed from the source code

### For nlohmann
- **Keep as-is**: Our current structure with `nlohmann` inside `llama_cpp/` is sufficient
- **Code references match**: All `#include` statements use `llama_cpp/nlohmann/` path
- **No need for duplication**: Unlike the Flutter SDK, we don't need both top-level and nested directories

## Conclusion

1. **minija**: Not needed, should remove CMake references
2. **nlohmann**: Keep in `llama_cpp/` directory (our current setup is correct)

Our current build approach is better organized and avoids unnecessary duplication compared to the Flutter SDK's structure.