// llama_mobile SDK version definition
// This file is used by both corelib (C++) and iOS SDK (Swift)

#pragma once

// Semantic version for llama_mobile SDK
#define LLAMA_MOBILE_VERSION_MAJOR 1
#define LLAMA_MOBILE_VERSION_MINOR 2
#define LLAMA_MOBILE_VERSION_PATCH 3

// Version string
#define LLAMA_MOBILE_VERSION_STRING "1.2.3"

// Version integer (for comparison)
#define LLAMA_MOBILE_VERSION (LLAMA_MOBILE_VERSION_MAJOR * 10000 + LLAMA_MOBILE_VERSION_MINOR * 100 + LLAMA_MOBILE_VERSION_PATCH)

// C++ namespace for version information
#ifdef __cplusplus
namespace llama_mobile {
    namespace version {
        static constexpr int major = LLAMA_MOBILE_VERSION_MAJOR;
        static constexpr int minor = LLAMA_MOBILE_VERSION_MINOR;
        static constexpr int patch = LLAMA_MOBILE_VERSION_PATCH;
        static constexpr const char* string = LLAMA_MOBILE_VERSION_STRING;
        static constexpr int value = LLAMA_MOBILE_VERSION;
    }
}
#endif
