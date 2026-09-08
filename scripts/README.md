# llama_mobile build scripts

This repo vendors **llama.cpp** (as plain files under `lib/llama.cpp-master`, no nested
git repo) and wraps it with `lib/llama_mobile_*.cpp` into a mobile inference SDK that is
then packaged for **iOS**, **Android**, **Flutter**, and **Capacitor**.

This README documents the **canonical build sequence** to follow after updating the
vendored `lib/llama.cpp-master` sources, and how the generated SDKs are consumed (e.g. by
the aiNotes Flutter app).

---

## 1. Repository layout (what matters)

| Path | Purpose |
|---|---|
| `lib/llama.cpp-master/` | Vendored llama.cpp. Updated by replacing these files; tracked normally (no nested `.git`). |
| `lib/llama_mobile_*.cpp|.h` | llama_mobile wrappers on top of llama.cpp (`common_params`, `llama_*` APIs). **When llama.cpp is bumped, these are what need porting.** |
| `lib/llama_mobile_version.h` | Single version source of truth (`LLAMA_MOBILE_VERSION_STRING`). |
| `scripts/config.env` | Central configuration (NDK path, Xcode path, build types, GPU flags, Flutter path…). |
| `llama_mobile-ios/` | iOS native output (`.xcframework` + static libs) — `build-ios-framework.sh`. |
| `llama_mobile-ios-SDK/` | iOS SDK (Swift package / pod wrapping the framework) — `build-ios-SDK.sh`. |
| `llama_mobile-android/` | Android native static libs per ABI — `build-android-lib.sh`. |
| `llama_mobile-android-SDK/` | Android SDK (Java/Kotlin bindings) — `build-android-SDK.sh`. |
| `llama_mobile-flutter-SDK/` | Flutter plugin (source) — `build-flutter-SDK.sh`. |
| `llama_mobile-capacitor-plugin/` | Capacitor plugin — `build-capacitor-plugin.sh`. |
| `output/` | Centralized copies of the SDKs for distribution. |

Version bumping: `scripts/update_version.sh` reads `lib/llama_mobile_version.h` and stamps
the pubspec/podspec/gradle versions of all SDKs.

---

## 2. Prerequisites

- **Xcode** with iOS SDK (set `XCODE_PATH` in `config.env`).
- **CMake ≥ 3.19** (`brew install cmake`).
- **Android NDK** (set `NDK_PATH` in `config.env`; the current machine uses
  `29.0.14206865`). `ANDROID_HOME` is auto-detected.
- **Flutter** (set `FLUTTER_SDK_PATH` in `config.env`, e.g. `/Users/…/Documents/flutter`).
- **Vulkan (Android GPU, optional):** headers + `glslc` must be discoverable by CMake. On
  macOS with Homebrew, `brew install vulkan-headers shaderc glslang spirv-tools
  spirv-headers` provides them. See section 5 for the exact flags needed when the NDK
  toolchain restricts CMake's find-paths.
- **OpenCL (Android, optional):** enabled with `--opencl` / `GGML_OPENCL=ON`; the current
  scripts default it OFF.

---

## 3. Canonical build sequence

Run these in order from the repo root (`llama_mobile/`). Steps 1 and 2 are independent and
can run in parallel; everything else depends on their outputs.

```bash
# 0) Sanity-check the core C++ library compiles against the vendored llama.cpp
bash scripts/build-lib.sh
#    Output: lib/build/output/  (quickest signal that wrapper porting is complete)

# 1) iOS native framework (device + simulator, Metal)
bash scripts/build-ios-framework.sh
#    Output: llama_mobile-ios/llama_mobile.xcframework (+ static libs)
#    Slices: ios-arm64 (device) + ios-arm64_x86_64-simulator (universal simulator).
#    Only the device slice is required to build/test on real iPhones.

# 2) Android native static libraries (per ABI; GPU backends included)
bash scripts/build-android-lib.sh            # see §5 for Vulkan flags on this Mac
#    Output: llama_mobile-android/libs/static/{arm64-v8a,x86_64}/*.a

# 3) iOS SDK (Swift package wrapping the xcframework)
bash scripts/build-ios-SDK.sh
#    Output: llama_mobile-ios-SDK/ + output/llama_mobile-iOS-SDK/

# 4) Android SDK (Java/Kotlin bindings around the .a libs)
bash scripts/build-android-SDK.sh
#    Output: llama_mobile-android-SDK/ + output/llama_mobile-android-SDK/

# 5) Flutter plugin SDK (consumed by aiNotes via a path dependency)
bash scripts/build-flutter-SDK.sh
#    Output: llama_mobile-flutter-SDK/ + output/llama_mobile-flutter-SDK/

# 6) Capacitor plugin (web devs)
bash scripts/build-capacitor-plugin.sh
#    Output: llama_mobile-capacitor-plugin/

# Optional
bash scripts/update_version.sh      # stamp new version from lib/llama_mobile_version.h
bash scripts/build-macos-lib.sh     # macOS host static lib (output/mac_libs)
```

Each script keeps timestamped backups under `scripts/sdk_backup/` (older ones pruned), and
the `output/` directory mirrors the latest SDKs.

---

## 4. After bumping `lib/llama.cpp-master` — wrapper port checklist

`lib/llama_mobile_*.cpp` compile against the llama.cpp public/common API, which changes
between versions. The last bump (older ggml 0.9.7-era llama.cpp → llama.cpp 0.4.0-dev /
ggml 0.23) required these mappings — check for them first next time:

| Old llama.cpp | New llama.cpp (0.4.0-dev) | Where it was fixed |
|---|---|---|
| `params.use_mmap` / `params.use_mlock` (bools) | `params.load_mode` enum (`LLAMA_LOAD_MODE_MMAP/MLOCK/MMAP_MLOCK/NONE/AUTO`); flags → mode mapping | `llama_mobile_ffi.cpp` (init path), logs in `llama_mobile_loader.cpp` |
| `params.sampling.grammar = std::string` | `params.sampling.grammar = common_grammar(COMMON_GRAMMAR_TYPE_USER, str)`; `common_grammar` has `empty()`, no `clear()` | `llama_mobile_ffi.cpp`, `llama_mobile_completion.cpp`, `llama_mobile_context.cpp` |
| `common_download_model(...)` (removed) | `common_download_file_single(url, path, opts)` returning HTTP status (200–299 or 304 = success); pass a no-op `common_download_callback` to suppress the console progress bar | `llama_mobile_ffi.cpp` (both download entry points) |
| `common_chat_msgs_parse_oaicompat(nlohmann::json)` | parsers now take `common_json`; `common_json::parse(str)`; `inputs.json_schema` is now a `std::string` | `llama_mobile_chat.cpp` |
| `params.vocoder` sub-struct (removed from `common_params`; `-mv`, `--tts-use-guide-tokens` args gone) | only `params.tts_speaker_file` remains; mobile TTS runtime is `llama_mobile_context` — the legacy `tts_main` uses local defaults | `llama_mobile_tts.cpp` |
| `mtmd_helper_bitmap_init_from_{buf,file}(ctx, …)` returning raw `mtmd_bitmap*` | helpers return `mtmd_helper_bitmap_wrapper {bitmap, video_ctx}` and take `(placeholder, mtmd_helper_init_opt)`; `mtmd::bitmap` now owns the pointer | `llama_mobile_multimodal.cpp` |
| `mtmd_decode_use_non_causal(ctx)` | `mtmd_decode_use_non_causal(ctx, chunk)` (`nullptr` = default image chunk) | `llama_mobile_multimodal.cpp` |

After porting, `bash scripts/build-lib.sh` is the fast compile gate before the SDK chain.

---

## 5. Android + Vulkan on this Mac (llama.cpp master)

`build-android-lib.sh` enables `GGML_VULKAN=ON` by default, but llama.cpp master's
`ggml-vulkan` CMake now does `find_package(Vulkan COMPONENTS glslc REQUIRED)` and
`find_package(SPIRV-Headers CONFIG REQUIRED)`. Under the **NDK toolchain**, CMake roots
package/library searches into the NDK, so host Homebrew packages are invisible unless you:

1. export `VULKAN_SDK=/opt/homebrew` (Homebrew installs Vulkan headers + glslc there), and
2. tell CMake the prefix and allow host package lookup:

```bash
# make sure the script forwards extra CMake defines (see scripts/build-android-lib.sh,
# it appends $LLAMA_MOBILE_EXTRA_CMAKE_FLAGS to the configure line)
export VULKAN_SDK=/opt/homebrew
export CMAKE_PREFIX_PATH=/opt/homebrew
LLAMA_MOBILE_EXTRA_CMAKE_FLAGS="-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH" \
  bash scripts/build-android-lib.sh
```

`glslc`/`glslangValidator` are host binaries (found via `PATH`), the NDK provides
`libvulkan.so` for the target, and headers/configs come from Homebrew.

Without these, the configure step fails with `CMake Error … find_package` in
`ggml/src/ggml-vulkan/CMakeLists.txt`. If you do not need Android GPU, pass
`--no-vulkan` instead.

---

## 6. Consuming the Flutter SDK in aiNotes

aiNotes depends on the freshly built SDK through **path dependencies** in its
`pubspec.yaml` (not pub.dev):

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: ../llama_mobile/llama_mobile-flutter-SDK
  llama_mobile_vd_flutter_sdk:
    path: ../llama_mobile_vector_database/llama_mobile_vd-flutter-SDK   # sibling repo
```

After rebuilding the SDKs:

```bash
cd ../aiNotes
flutter pub get          # re-resolves the path package
# iOS: CocoaPods embeds the .xcframework → run a pod reinstall if pods exist
(cd ios && pod install)
flutter analyze && flutter test
```

The plugin is plain source — Flutter compiles the Android `.a` into an AAR and embeds the
iOS `.xcframework` at app build time, so no manual AAR/xcframework step is needed.

---

## 7. Troubleshooting

- **`build-lib.sh` compile errors after a llama.cpp bump** — almost always the wrapper
  files, not llama.cpp itself. Grep the failing TU for the old symbols listed in §4 and
  port them; do not edit vendored llama.cpp files.
- **llama.cpp tools targets fail to build under the SDK** — llama.cpp's
  `tools/tuning`/example targets reference `${CMAKE_SOURCE_DIR}/ggml/...`, which is only
  valid when llama.cpp is the top-level CMake project. `lib/CMakeLists.txt` therefore
  builds only the `mtmd` library (`LLAMA_BUILD_TOOLS=OFF`, `LLAMA_BUILD_MTMD=ON`). If you
  re-enable `LLAMA_BUILD_TOOLS`, remember to wipe the per-target CMake build dirs first,
  since `option()` won't override a value already cached in an existing build tree.
- **Archive names changed after the llama.cpp bump** — llama.cpp master renamed/split the
  old `common` library (`libcommon.a`) into `libllama-common.a` + `libllama-common-base.a`
  and `mtmd` gained a dependency on `vendor/hash` (`libvendor-hash.a`). The build scripts
  and the Android/Capacitor `CMakeLists.txt` files list these archives explicitly — update
  every hardcoded list (grep for `libcommon`) when bumping. The wrapper CMake links
  `llama-common` (not `common`) and `lib/CMakeLists.txt` also flips
  `LLAMA_BUILD_TOOLS` to OFF (see the llama.cpp tools bullet above).
- **Simulator slice naming / generic-simulator builds** — since llama.cpp bumped, the iOS
  build produces one universal simulator slice (`ios-arm64_x86_64-simulator`) instead of a
  separate `ios-arm64-simulator` folder. `build-ios-SDK.sh` accepts either name now. If you
  only ever run/test on **real devices**, the simulator slice is irrelevant; keep
  `IOS_SIMULATOR_ARCHES="arm64 x86_64"` intact so generic `flutter build ios --simulator`
  and simulator runs keep working. If Xcode reports “Unsupported Swift architecture” for a
  plugin module during a *generic* simulator build, re-run `pod install` after rebuilding
  the framework so CocoaPods regenerates its `*-xcframeworks.sh` slice list.
- **iOS CMake “No CMAKE_C/CXX_COMPILER could be found” with `-GXcode`** — cmake probes the
  compiler by asking `xcodebuild` to build into `~/Library/Developer/Xcode/DerivedData`.
  If that path is not writable (sandboxed CI, permissions), the probe fails. Ensure
  DerivedData is writable, or run the build with the same full-disk access as Xcode.
- **Android configure fails inside `ggml-vulkan`** — see §5 (Vulkan SDK discovery under
  the NDK toolchain).
- **Flutter SDK script cannot find Flutter** — it checks `$PATH`, then common install
  locations. Either put `/…/flutter/bin` on `PATH` or pass it explicitly.
- **CocoaPods still links the old framework after a rebuild** — `flutter clean`, re-run
  `pod install`, and verify `llama_mobile-ios/llama_mobile.xcframework` mtime inside the
  pod checkout.
