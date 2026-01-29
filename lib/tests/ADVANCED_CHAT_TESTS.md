# Advanced Chat Features Test Suite

## Overview
This document describes the comprehensive test suite for advanced chat features added to llama_mobile.

## Test Files

### 1. `/lib/tests/test_advanced_chat.cpp`
**Purpose**: Unit tests for advanced chat features using the C++ API directly.

**Test Scenarios**:
1. **Basic Chat Messages with Built-in Template**
   - Tests basic chat message formatting using the model's built-in template
   - Verifies that prompt tokens > 1 (indicating proper formatting)

2. **JSON Schema Parameter**
   - Tests the `json_schema` parameter for structured output
   - Verifies that the parameter is accepted without errors

3. **Tools Parameter**
   - Tests the `tools` parameter for function calling
   - Verifies that tool definitions are properly handled

4. **Tool Choice Parameter**
   - Tests the `tool_choice` parameter for selecting specific tools
   - Verifies that tool selection works correctly

5. **Parallel Tool Calls Parameter**
   - Tests the `parallel_tool_calls` parameter for concurrent tool execution
   - Verifies that parallel tool calls are enabled

6. **JSON Escaping in Chat Messages**
   - Tests proper escaping of special characters in chat messages
   - Verifies that quotes, newlines, and other special characters are handled

7. **Enable Chat Template = false**
   - Tests disabling chat templates
   - Verifies that chat templates can be disabled

8. **Custom Jinja Template**
   - Tests applying a custom Jinja template
   - Verifies that custom templates work correctly

9. **Multiple Advanced Parameters Together**
   - Tests using multiple advanced parameters simultaneously
   - Verifies that parameters work together without conflicts

10. **Empty Chat Messages**
    - Tests direct prompt usage when chat messages are empty
    - Verifies fallback to direct prompt works

**Usage**:
```bash
cd /Users/shileipeng/Documents/mygithub/llama_mobile/lib/build
./output/test_advanced_chat <model_path>
```

### 2. `/examples/cpp/main_advanced_chat.cpp`
**Purpose**: Example code demonstrating advanced chat features using the FFI API.

**Examples**:
1. **Basic Chat with Messages**
   - Simple chat with system and user messages
   - Demonstrates basic chat functionality

2. **Chat with JSON Schema**
   - Structured output with JSON schema
   - Demonstrates how to enforce JSON format

3. **Chat with Tools**
   - Function calling with tool definitions
   - Demonstrates how to provide tools to the model

4. **Chat with Tool Choice**
   - Selecting specific tools for function calling
   - Demonstrates tool selection control

5. **Chat with Parallel Tool Calls**
   - Concurrent tool execution
   - Demonstrates parallel tool calling

6. **Multi-turn Conversation**
   - Maintaining conversation history
   - Demonstrates multi-turn dialogue

**Usage**:
```bash
cd /Users/shileipeng/Documents/mygithub/llama_mobile/examples/cpp
./build.sh
./output/llama_mobile_advanced_chat <model_path>
```

## Key Features Tested

### 1. **Template Format Auto-Detection**
- Tests automatic detection of Jinja vs legacy templates
- Verifies that `{{` and `{%` markers are recognized
- Ensures built-in templates are assumed to be Jinja

### 2. **Advanced Parameters**
- **json_schema**: Structured output constraints
- **tools**: Function calling capabilities
- **tool_choice**: Tool selection strategy
- **parallel_tool_calls**: Concurrent tool execution

### 3. **Robustness Features**
- **JSON Escaping**: Proper handling of special characters
- **Exception Handling**: Graceful fallback on errors
- **Parameter Validation**: Clear warnings for invalid usage

### 4. **Backward Compatibility**
- **use_jinja**: Kept in params for CLI tools
- **enable_chat_template**: New parameter for FFI
- **Legacy Templates**: Support for old-style templates

## Test Execution

### Running All Tests
```bash
cd /Users/shileipeng/Documents/mygithub/llama_mobile/lib/build
./output/test_advanced_chat <model_path>
```

### Running Examples
```bash
cd /Users/shileipeng/Documents/mygithub/llama_mobile/examples/cpp
./build.sh
./output/llama_mobile_advanced_chat <model_path>
```

## Expected Output

### Test Results
- **PASSED**: Test completed successfully
- **FAILED**: Test encountered an error
- **Details**: Additional information about test result

### Summary Report
```
SUMMARY:
----------------------------------------------------------------------
Test                                          Status     Details
----------------------------------------------------------------------
Basic Chat Messages                           PASSED     Chat messages formatted correctly
JSON Schema Parameter                       PASSED     JSON schema parameter accepted
Tools Parameter                              PASSED     Tools parameter accepted
...
----------------------------------------------------------------------
Total Tests                                 10
Tests Passed                                10
Tests Failed                                0
```

## Code Changes Summary

### Corelib Changes
1. **Helper Functions** (`llama_mobile_completion.cpp`):
   - `is_jinja_template()`: Detects Jinja template format
   - `has_advanced_parameters()`: Checks for advanced parameter usage

2. **Auto-Detection Logic** (`loadPrompt()`):
   - Automatic template format detection
   - Smart parameter usage based on template support
   - Clear logging for debugging

3. **Enhanced Warnings**:
   - Legacy template limitations
   - No template available scenarios
   - No chat messages scenarios

### FFI Changes
1. **New Parameters** (`llama_mobile_ffi.h`):
   - `enable_chat_template`: Added to init params

2. **Parameter Mapping** (`llama_mobile_ffi.cpp`):
   - `enable_chat_template`: Passed from FFI to corelib

### Test Infrastructure
1. **New Test Executable** (`test_advanced_chat.cpp`):
   - 10 comprehensive test scenarios
   - Detailed test reporting
   - Clear pass/fail indicators

2. **New Example Code** (`main_advanced_chat.cpp`):
   - 6 practical examples
   - FFI API usage
   - Real-world scenarios

3. **Build System Updates**:
   - Updated `tests/CMakeLists.txt`
   - Updated `examples/cpp/CMakeLists.txt`
   - Added Metal framework linking

## Build Status
✅ All tests compiled successfully
✅ All examples compiled successfully
✅ Build system updated correctly

## Next Steps
1. Run tests with various models to verify compatibility
2. Add more edge case tests as needed
3. Update documentation with test results
4. Consider adding performance benchmarks
