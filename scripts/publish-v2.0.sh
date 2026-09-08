#!/bin/bash
# v2.0 registry publish helpers (owner-run; requires credentials in env).
# Dry-run by default — run with PUBLISH=1 to actually push.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLISH="${PUBLISH:-0}"

echo "== CocoaPods (llama_mobile) =="
(cd "$ROOT/llama_mobile-ios-SDK" && pod lib lint llama_mobile.podspec --allow-warnings)
if [ "$PUBLISH" = "1" ]; then
  (cd "$ROOT/llama_mobile-ios-SDK" && pod trunk push llama_mobile.podspec --allow-warnings)
else
  echo "(dry-run: use PUBLISH=1 to push)"
fi

echo "== pub.dev (llama_mobile_flutter_sdk) =="
(cd "$ROOT/llama_mobile-flutter-SDK" && flutter pub publish --dry-run)
if [ "$PUBLISH" = "1" ]; then
  (cd "$ROOT/llama_mobile-flutter-SDK" && flutter pub publish -f)
else
  echo "(dry-run: use PUBLISH=1 to push)"
fi

echo "== npm (llama-mobile-capacitor-plugin) =="
(cd "$ROOT/llama_mobile-capacitor-plugin" && npm publish --dry-run)
if [ "$PUBLISH" = "1" ]; then
  (cd "$ROOT/llama_mobile-capacitor-plugin" && npm publish)
else
  echo "(dry-run: use PUBLISH=1 to push)"
fi

echo "== Maven Central (llama_mobile-android-SDK) =="
echo "Local validation (no credentials needed):"
(cd "$ROOT/llama_mobile-android-SDK" && ./gradlew publishToMavenLocal)
echo "Remote push: configure mavenCentral credentials (SONATYPE_USERNAME/PASSWORD) and run:"
echo "  cd $ROOT/llama_mobile-android-SDK && ./gradlew publishMavenPublicationToSonatypeRepository"

echo "== Tag =="
echo "v1.x tag exists at $(git -C "$ROOT" rev-list -n1 v1.x)"
echo "After publishing, tag v2.0.0:  git -C "$ROOT" tag v2.0.0 && git -C "$ROOT" push origin v2.0.0"
