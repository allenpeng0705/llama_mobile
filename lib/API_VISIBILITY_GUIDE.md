# API Visibility Control Guide for llama_mobile

This guide explains how to control API visibility in the llama_mobile library using export macros and private header files.

## Overview

The llama_mobile library uses a two-tiered approach to API visibility:
1. **Public APIs**: Exposed to users through `llama_mobile_api.h`
2. **Private APIs**: Hidden from users in `llama_mobile_private.h`

## Visibility Macros

### Public API Macro

In `llama_mobile_api.h`, the `LLAMA_MOBILE_API` macro is defined to control visibility of public APIs:

```c
// Platform-specific export macros for shared library builds
#if defined _WIN32 || defined __CYGWIN__
  #ifdef LLAMA_MOBILE_BUILDING_SHARED
    #ifdef __GNUC__
      #define LLAMA_MOBILE_API __attribute__ ((dllexport))
    #else
      #define LLAMA_MOBILE_API __declspec(dllexport)
    #endif
  #else
    #ifdef __GNUC__
      #define LLAMA_MOBILE_API __attribute__ ((dllimport))
    #else
      #define LLAMA_MOBILE_API __declspec(dllimport)
    #endif
  #endif
  #define LLAMA_MOBILE_LOCAL
#elif __GNUC__ >= 4
  #define LLAMA_MOBILE_API __attribute__ ((visibility ("default")))
  #define LLAMA_MOBILE_LOCAL  __attribute__ ((visibility ("hidden")))
#else
  #define LLAMA_MOBILE_API
  #define LLAMA_MOBILE_LOCAL
#endif
```

### Private API Macro

In `llama_mobile_private.h`, the `LLAMA_MOBILE_PRIVATE` macro is defined to hide internal APIs:

```c
// Platform-specific visibility macros for private APIs
#if defined _WIN32 || defined __CYGWIN__
  #define LLAMA_MOBILE_PRIVATE
#elif __GNUC__ >= 4
  #define LLAMA_MOBILE_PRIVATE __attribute__ ((visibility ("hidden")))
#else
  #define LLAMA_MOBILE_PRIVATE
#endif
```

### FFI Export Macro

For FFI-specific APIs, there's also `LLAMA_MOBILE_FFI_EXPORT`:

```c
// FFI-specific export macros
#if defined _WIN32 || defined __CYGWIN__
  #ifdef LLAMA_MOBILE_FFI_BUILDING_DLL
    #ifdef __GNUC__
      #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((dllexport))
    #else
      #define LLAMA_MOBILE_FFI_EXPORT __declspec(dllexport)
    #endif
  #else
    #ifdef __GNUC__
      #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((dllimport))
    #else
      #define LLAMA_MOBILE_FFI_EXPORT __declspec(dllimport)
    #endif
  #endif
  #define LLAMA_MOBILE_FFI_LOCAL
#else
  #if __GNUC__ >= 4
    #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((visibility ("default")))
    #define LLAMA_MOBILE_FFI_LOCAL  __attribute__ ((visibility ("hidden")))
  #else
    #define LLAMA_MOBILE_FFI_EXPORT
    #define LLAMA_MOBILE_FFI_LOCAL
  #endif
#endif
```

## How to Use Visibility Macros

### For Public APIs

Add the `LLAMA_MOBILE_API` macro before the function declaration in `llama_mobile_api.h`:

```c
LLAMA_MOBILE_API llama_mobile_context_t llama_mobile_init(
    const llama_mobile_init_params_t* params);
```

### For Private APIs

Add the `LLAMA_MOBILE_PRIVATE` macro before the function declaration in `llama_mobile_private.h`:

```c
LLAMA_MOBILE_PRIVATE int llama_mobile_init_internal(const char* model_path, struct llama_mobile_context_private** ctx_out);
```

## Header File Organization

### Public Header (`llama_mobile_api.h`)
- Contains only public API declarations
- Uses `LLAMA_MOBILE_API` macro for visibility
- Should be included by external users

### Private Header (`llama_mobile_private.h`)
- Contains internal API declarations and structures
- Uses `LLAMA_MOBILE_PRIVATE` macro for visibility
- Should only be included by library source files
- Includes the public header to reuse public types

## Guidelines for API Visibility

### What to Make Public
- Functions that users need to call
- Opaque handles and public structs
- Enums and constants used by public functions

### What to Make Private
- Internal implementation functions
- Detailed struct definitions (like `llama_mobile_context_private`)
- Helper functions used only within the library
- Platform-specific implementation details

## Example: Moving API from Public to Private

### 1. Remove from Public Header
```c
// From llama_mobile_api.h - remove this
LLAMA_MOBILE_API int llama_mobile_internal_helper(const char* data);
```

### 2. Add to Private Header
```c
// To llama_mobile_private.h - add this
LLAMA_MOBILE_PRIVATE int llama_mobile_internal_helper(const char* data);
```

### 3. Update Implementation
```c
// In the implementation file
LLAMA_MOBILE_PRIVATE int llama_mobile_internal_helper(const char* data) {
    // Implementation
}
```

## Benefits of API Visibility Control

1. **Better Encapsulation**: Users only see what they need
2. **Stable API**: Internal changes don't break users
3. **Smaller Binary**: Hidden symbols can be optimized
4. **Improved Documentation**: Clear separation between public and private APIs
5. **Reduced Name Collisions**: Internal symbols are hidden from users' namespace

## Building with Visibility Control

When building the library, ensure that:
- `LLAMA_MOBILE_BUILDING_SHARED` is defined when building as a shared library
- The private header is only included by library sources, not exposed to users
- All internal APIs use the appropriate visibility macros