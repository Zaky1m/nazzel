# How Nazzel works

**English** · [العربية](how-it-works.ar.md)

Nazzel has three layers that run inside the app:

| Layer | Language | Job |
|---|---|---|
| Interface | Dart (Flutter) | Screens, the share sheet, settings |
| Platform | Kotlin | Download service, SQLite, saving to the gallery, remuxing, updates |
| Engine | Python (Chaquopy) | Reads links and downloads streams with yt-dlp |

## From a shared link to a saved file

1. Another app shares text. `ShareEntry` takes the first link and opens the
   quality sheet over that app, or queues the best quality in quick mode
2. The engine asks yt-dlp for the formats and returns only the ones the phone
   can finish: a single file, or H.264/HEVC video with AAC audio
3. The choice is stored in SQLite and the foreground service starts. It runs
   one download at a time and survives the interface being closed
4. Separate video and audio streams are downloaded one after the other.
   Android's `MediaMuxer` combines them into MP4 without re-encoding; HLS
   downloads, which arrive as MPEG-TS, are rewritten into MP4 the same way
5. The file is saved through MediaStore, so no storage permission is needed

## Sites that resist downloaders

- YouTube asks the player to solve JavaScript challenges. The app ships
  QuickJS-NG, a 2 MB JavaScript engine, and yt-dlp's solver scripts. When a
  stream still answers HTTP 403, other YouTube clients are tried
- TikTok, Dailymotion and others check the TLS fingerprint of the
  connection. curl_cffi presents a real browser fingerprint
- Spotify streams are protected. Nazzel reads the track names from
  Spotify's public embed page and downloads the audio from YouTube

## Staying up to date

Sites change often, so two things update on their own and the app only reports new versions:

| What | Size | Source | Check |
|---|---|---|---|
| yt-dlp | About 3 MB | yt-dlp's GitHub releases | Published SHA-256 |
| `engine.py` | Tens of KB | This repository's latest release | Ed25519 signature and SHA-256 |

The app itself is never installed by Nazzel; Settings shows when a newer release exists.

A signed engine update is used only if it does not need a newer app; a broken
one falls back to the copy inside the APK.

## When something fails

Every download writes its full log: yt-dlp's verbose output, each step the
app took and any exception. The last 100 are kept. Settings can save or share
the log, which shows the exact reason a site refused a download.
