#!/usr/bin/env bash
# Prepares GitHub release assets from dist/nazzel.apk: update.json for the in-app updater, plus the
# engine.py update signed with .secrets/engine-signing.pem. Publishes only with --publish.
#   tools/release.sh "release notes in Arabic" [--publish]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO=Zaky1m/nazzel
NOTES="${1:?release notes required}"
PUBLISH="${2:-}"
VERSION=$(grep -E '^version:' "$ROOT/pubspec.yaml" | sed -E 's/version: ([0-9.]+)\+([0-9]+)/\1/')
BUILD=$(grep -E '^version:' "$ROOT/pubspec.yaml" | sed -E 's/version: ([0-9.]+)\+([0-9]+)/\2/')
ENGINE=$(grep -E '^ENGINE_VERSION = ' "$ROOT/android/app/src/main/python/engine.py" | cut -d'"' -f2)
OUT="$ROOT/dist/release"
/bin/rm -rf "$OUT" && mkdir -p "$OUT"
cp "$ROOT/dist/nazzel.apk" "$OUT/nazzel.apk"
cp "$ROOT/android/app/src/main/python/engine.py" "$OUT/engine.py"
APK_SHA=$(sha256sum "$OUT/nazzel.apk" | cut -d' ' -f1)
ENGINE_SHA=$(sha256sum "$OUT/engine.py" | cut -d' ' -f1)
python3 - "$OUT" "$VERSION" "$BUILD" "$APK_SHA" "$(stat -c %s "$OUT/nazzel.apk")" "$NOTES" "$REPO" "$ENGINE" "$ENGINE_SHA" <<'PY'
import json, sys
out, version, build, sha, size, notes, repo, engine, engine_sha = sys.argv[1:]
json.dump({"version": version, "build": int(build), "sha256": sha, "size": int(size), "notes": notes,
           "apk": f"https://github.com/{repo}/releases/download/v{version}/nazzel.apk"},
          open(f"{out}/update.json", "w"), ensure_ascii=False)
# Compact and key-ordered: the signature covers these exact bytes.
open(f"{out}/engine.json", "w").write(json.dumps(
    {"version": engine, "min_build": int(build), "sha256": engine_sha}, separators=(",", ":"), sort_keys=True))
PY
openssl pkeyutl -sign -inkey "$ROOT/.secrets/engine-signing.pem" -rawin -in "$OUT/engine.json" -out "$OUT/engine.json.sig"
echo "release v$VERSION (build $BUILD, engine $ENGINE) prepared in $OUT"
ls -la "$OUT"
if [ "$PUBLISH" = "--publish" ]; then
  gh release create "v$VERSION" "$OUT"/* --repo "$REPO" --title "نزّل $VERSION" --notes "$NOTES"
fi
