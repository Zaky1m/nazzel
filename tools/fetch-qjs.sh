#!/usr/bin/env bash
# Fetches the official QuickJS-NG static aarch64 binary that yt-dlp uses to solve YouTube challenges,
# verifies its SHA-256 against the release digest, and places it where Gradle packages it as libqjs.so.
set -euo pipefail
VERSION=v0.17.0
SHA256=3372133484edf50a69f3c67903af41206d22a061e930e3cfb63269272ef56d2e
DEST="$(cd "$(dirname "$0")/.." && pwd)/android/app/src/main/jniLibs/arm64-v8a/libqjs.so"
mkdir -p "$(dirname "$DEST")"
if [ -f "$DEST" ] && [ "$(sha256sum "$DEST" | cut -d' ' -f1)" = "$SHA256" ]; then exit 0; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/qjs" "https://github.com/quickjs-ng/quickjs/releases/download/$VERSION/qjs-linux-aarch64"
echo "$SHA256  $TMP/qjs" | sha256sum -c - >/dev/null
install -m 755 "$TMP/qjs" "$DEST"
echo "qjs $VERSION ready at $DEST"
