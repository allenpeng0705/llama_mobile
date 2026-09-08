#!/bin/bash
# check-gpu-artifacts.sh — verifies GPU support is actually packaged in the
# shipped artifacts:
#   iOS  : Metal backend compiled into the llama_mobile xcframework
#          (GGML_METAL, embedded MSL) and synced to every consumer copy.
#   Android: libggml-vulkan.a (real Vulkan code + SPIR-V shaders) present for
#          arm64-v8a and x86_64 in the SDK and each consumer (system
#          libvulkan.so is linked by the SDK CMake).
# Exit 0 when everything is present; prints one line per check.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

say() { printf '%-70s %s\n' "$1" "$2"; }

# ---------------------------------------------------------------- iOS / Metal
IOS_SRC="$ROOT/llama_mobile-ios/shared/llama_mobile.xcframework"
IOS_COPIES=(
    "$ROOT/llama_mobile-ios-SDK/llama_mobile.xcframework"
    "$ROOT/llama_mobile-flutter-SDK/ios/LlamaMobile/llama_mobile.xcframework"
    "$ROOT/llama_mobile-capacitor-plugin/ios/Libraries/llama_mobile.xcframework"
)
# Native Metal symbols the device slice must export (set by GGML_METAL=ON).
METAL_SYMBOLS=(_ggml_metal_init)
# Embedded-metal marker compiled into the binary when LLAMA_METAL_EMBED_LIBRARY.
for slice in ios-arm64 ios-arm64_x86_64-simulator; do
    bin="$IOS_SRC/$slice/llama_mobile.framework/llama_mobile"
    if [ ! -f "$bin" ]; then
        say "iOS $slice slice present" "MISSING"; fail=1; continue
    fi
    ok=1
    for s in "${METAL_SYMBOLS[@]}"; do
        nm -gU "$bin" 2>/dev/null | grep -q "T $s" || ok=0
    done
    if [ "$ok" = 1 ]; then
        say "iOS $slice: Metal backend compiled ($(nm -gU "$bin" 2>/dev/null | grep -cE "T _ggml_metal_init|T __Z.*metal" ) metal syms)" "OK"
    else
        say "iOS $slice: Metal backend compiled" "MISSING"; fail=1
    fi
    # Embedded MSL library (string marker from ggml-metal-embed-* objects).
    if strings "$bin" 2>/dev/null | grep -qiE "default.metallib|ggml_metal_library_init"; then
        say "iOS $slice: embedded Metal shader library" "OK"
    else
        say "iOS $slice: embedded Metal shader library" "NOT FOUND (check LLAMA_METAL_EMBED_LIBRARY)"; fail=1
    fi
done

# Every consumer copy must be byte-identical to the source xcframework.
for dst in "${IOS_COPIES[@]}"; do
    a="$(md5 -q "$IOS_SRC/ios-arm64/llama_mobile.framework/llama_mobile" 2>/dev/null)"
    b="$(md5 -q "$dst/ios-arm64/llama_mobile.framework/llama_mobile" 2>/dev/null)"
    if [ -n "$a" ] && [ "$a" = "$b" ]; then
        say "iOS consumer synced: ${dst#$ROOT/}" "OK"
    else
        say "iOS consumer synced: ${dst#$ROOT/}" "STALE/DIFFERS"; fail=1
    fi
done

# ------------------------------------------------------------- Android / Vulkan
AND_LIB="$ROOT/llama_mobile-android-SDK/src/main/jniLibs"
AND_COPIES=(
    "$ROOT/llama_mobile-flutter-SDK/android/src/main/jniLibs"
    "$ROOT/llama_mobile-capacitor-plugin/android/libs"
)
for abi in arm64-v8a x86_64; do
    lib="$AND_LIB/$abi/libggml-vulkan.a"
    if [ ! -f "$lib" ]; then
        say "Android $abi: libggml-vulkan.a present" "MISSING"; fail=1; continue
    fi
    n_syms=$(nm "$lib" 2>/dev/null | grep -cE "ggml_vk_")
    n_spv=$(nm "$lib" 2>/dev/null | grep -cE "spv_|_spv$")
    if [ "$n_syms" -gt 50 ] && [ "$n_spv" -gt 10 ]; then
        say "Android $abi: libggml-vulkan.a real backend ($n_syms ggml_vk_ syms, $n_spv SPIR-V arrays)" "OK"
    else
        say "Android $abi: libggml-vulkan.a real backend" "STUB/INCOMPLETE"; fail=1
    fi
done

# Consumer copies of libggml-vulkan.a must exist per ABI.
for dst in "${AND_COPIES[@]}"; do
    for abi in arm64-v8a x86_64; do
        if [ -f "$dst/$abi/libggml-vulkan.a" ]; then
            say "Android consumer has Vulkan lib: ${dst#$ROOT/} ($abi)" "OK"
        else
            say "Android consumer has Vulkan lib: ${dst#$ROOT/} ($abi)" "MISSING"; fail=1
        fi
    done
done

# CMake links the system Vulkan runtime only when the static lib exists.
for cmake in \
    "$ROOT/llama_mobile-android-SDK/src/main/cpp/CMakeLists.txt" \
    "$ROOT/llama_mobile-flutter-SDK/android/src/main/cpp/CMakeLists.txt" \
    "$ROOT/llama_mobile-capacitor-plugin/android/src/main/cpp/CMakeLists.txt"; do
    if grep -q "libggml-vulkan.a" "$cmake" 2>/dev/null && grep -q "find_library(vulkan-lib vulkan)" "$cmake" 2>/dev/null; then
        say "CMake Vulkan link logic: ${cmake#$ROOT/}" "OK"
    else
        say "CMake Vulkan link logic: ${cmake#$ROOT/}" "MISSING"; fail=1
    fi
done

echo
if [ "$fail" = 0 ]; then
    echo "GPU packaging audit: ALL OK"
else
    echo "GPU packaging audit: FAILURES (see above)"
fi
exit "$fail"
