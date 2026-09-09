#!/bin/bash
# Runs the v2 Android instrumented (LlamaEngineTests) suite on a connected
# device/emulator, pushing the test model into the test app's external dir
# first (reinstalls wipe it). Usage: scripts/android-run-instrumented.sh
set -e
SDK_DIR="$(cd "$(dirname "$0")/.." && pwd)/llama_mobile-android-SDK"
MODEL="$SDK_DIR/../models/SmolLM-360M-Instruct.Q6_K.gguf"
EMBEDDING="$SDK_DIR/../models/Qwen3-Embedding-0.6B-Q8_0.gguf"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
adb shell mkdir -p /sdcard/Android/data/com.llamamobile.test/files
adb push "$MODEL" /sdcard/Android/data/com.llamamobile.test/files/ >/dev/null
# Embedding model powers the embed tests; push when present.
if [ -f "$EMBEDDING" ]; then
    adb push "$EMBEDDING" /sdcard/Android/data/com.llamamobile.test/files/ >/dev/null
fi
# Vision + TTS fixtures for the multimodal/TTS instrumented tests.
for f in SmolVLM-256M-Instruct-Q8_0.gguf mmproj-SmolVLM-256M-Instruct-Q8_0.gguf img/image.jpg OuteTTS-0.2-500M-Q6_K.gguf WavTokenizer-Large-75-F16.gguf; do
    src="$SDK_DIR/../models/$f"
    [ -f "$src" ] && adb push "$src" /sdcard/Android/data/com.llamamobile.test/files/$(basename "$f") >/dev/null
done
cd "$SDK_DIR"
./gradlew connectedDebugAndroidTest "$@"
