# Decisions

Short records of choices that are not obvious from the code.

## Download on the phone, not on a server

**Context.** Platforms block data-centre addresses far more than home and
mobile connections; YouTube and TikTok refused the build server outright.
**Decision.** yt-dlp runs inside the app. **Why.** Each phone has its own
address, so no cookies are needed for public posts, a block affects one person
only, and there is no server bandwidth to pay for.

## Chaquopy and Python 3.13 instead of youtubedl-android

**Context.** youtubedl-android bundles Python 3.8, while current yt-dlp needs
3.10 or later. **Decision.** Chaquopy with Python 3.13. **Why.** yt-dlp can
update itself without breaking, and 3.13 is the first version with Android
wheels of curl_cffi.

## curl_cffi 0.16.4b1 with cffi 1.17.1

**Context.** yt-dlp accepts curl_cffi below 0.17, and 0.16.4b1 is the only
such version with an Android wheel. It declares `cffi>=2.0`, but only 1.17.1
has an Android build. **Decision.** Install both pinned, without dependency
resolution. **Why.** An impersonated request works with this pair; revisit
when yt-dlp accepts 0.17 or cffi 2 ships for Android.

## No ffmpeg

**Decision.** Download separate streams and combine them with `MediaMuxer`.
**Why.** ffmpeg adds tens of megabytes. The cost is that AV1 and VP9 streams
are not offered and audio is saved as M4A, not MP3.

## QuickJS-NG for YouTube

**Context.** YouTube's player challenges need a JavaScript runtime.
**Decision.** Ship the official static `qjs` build for aarch64 as
`libqjs.so`, fetched by `tools/fetch-qjs.sh` and checked against its SHA-256.
**Why.** It runs on Android as is, is about 2 MB, and yt-dlp supports it.
Android only allows executing files from the app's native library folder, so
native libraries are extracted at install time.

## SQLite in the native layer

**Decision.** Kotlin owns the download database; Flutter only reads it.
**Why.** The download service keeps running with the interface closed, so it
must be the single writer.

## Minimum Android 10

**Decision.** API 29. **Why.** Saving to the gallery through MediaStore
without a storage permission starts there.

## R8 disabled

**Context.** Shrinking renamed the progress callback that Python calls by
name, and every download failed. **Decision.** No minification. **Why.** The
saving is small next to the Python runtime, and reflection from Python makes
keep rules easy to get wrong.

## Signed engine updates and GitHub releases

**Decision.** Releases on this repository carry the APK, `update.json`,
`engine.py`, `engine.json` and its Ed25519 signature. **Why.** Most fixes
are in the download logic and take kilobytes instead of a full APK. Signing
means a compromised download path cannot run code in the app.

## Spotify through YouTube search

**Decision.** Read names from Spotify's public embed page and download from
YouTube. **Why.** Spotify audio is protected; this needs no account, key or
third-party service.

## No song recognition

Recognition needs a fingerprint database of millions of songs, which only
online services have. A local-only feature is not possible, so it was left out.
