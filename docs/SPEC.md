# Nazzel specification

This file describes what the app does. It is the reference for behaviour; code
that disagrees with it is a bug, and changes to it start as an issue.

## Purpose

Save videos and audio from social and video sites to the phone, from the
system share menu or from a pasted link. All work happens on the phone: there
is no server, account or tracking.

## Getting a link in

- Share menu. Sharing text that contains a link to Nazzel opens a sheet on
  top of the app it came from. The sheet shows the video, its qualities and a
  download button, then closes. The user does not leave the other app
- Quick mode. With "Ask for quality when sharing" turned off, sharing
  queues the best quality at once and shows a short confirmation
- Paste field. The home screen has a full-width field with one button
  inside it: paste when empty, clear when filled
- Clipboard. When the app gains focus and the clipboard holds a link it
  has not seen yet, the field is filled and the preview starts. Each clipboard
  entry is read once, because Android shows a notice on every read
- The first `http` or `https` link in the text is used; anything else is
  rejected with a message

## Preview and quality

- A single video shows its thumbnail, title, site, duration and the size of
  the selected quality when the site reports it
- Qualities are named by the short side of the picture (a vertical 1080×1920
  video is 1080p) and include only what the phone can finish: single files,
  or H.264/HEVC video plus AAC audio that it can combine. AV1 and VP9 streams
  are skipped
- "Audio only" appears when the site offers a separate audio stream
- The default choice follows the saved default quality and never goes above it

## Playlists, albums and multi-video posts

- Up to 200 items are listed with checkboxes, all selected at first
- One quality applies to the whole list ("Best", 1080p, 720p, 480p or audio).
  Each item later picks its nearest quality that is not higher
- Every item becomes its own download, processed in list order, grouped under
  the list title with a progress count and a "Cancel all" button
- Audio-only sites (SoundCloud and similar) offer only audio

## Downloading

- One download runs at a time in a foreground service with a progress
  notification and a cancel action; it keeps going when the app is closed
- Separate video and audio streams are downloaded one after the other and
  combined into MP4 with Android's `MediaMuxer`, without re-encoding.
  HLS downloads, which arrive as MPEG-TS, are remuxed into MP4 the same way
- Files are saved through MediaStore to `Download/Nazzel`, video and audio
  alike, unless the user picks another folder in Settings. No storage
  permission is needed
- YouTube: the bundled QuickJS-NG runs yt-dlp's challenge solver. When a
  stream answers HTTP 403, other YouTube clients are tried in turn
- Sites that check the TLS fingerprint get a browser fingerprint through
  curl_cffi
- If extraction fails because a site changed, the downloader updates itself
  once and retries

## Errors

Failures are shown in plain words (private or login required, missing,
unsupported link, no connection, site changed, merge failed, could not save,
interrupted). A failed download keeps a short technical note with links and
file paths removed, which can be copied from the list and disappears with the
item. A preview that fails shows the same kind of note under the message.

## No logs

The app writes no log files and keeps no engine output. Versions before 1.3.0
saved a diagnostics file in `Download/Nazzel`; 1.3.0 deletes those files and
the database tables behind them on first start.

## State

| Kind | What | Kept |
|---|---|---|
| Temporary | Queued, failed or cancelled downloads and their partial files | 24 hours |
| Permanent | Finished downloads and the saved files | Until the user deletes them |

Download state lives in SQLite owned by the native layer, because the service
runs while the user interface is closed. A download that was running when the
process died is marked as failed and can be retried.

## Updates

- Downloader. Once a day yt-dlp is updated from its GitHub releases after
  checking the published SHA-256
- Engine. `engine.py` (the app's own download logic) is updated from this
  repository's latest release when a newer copy is published. It is used only
  if its Ed25519 signature matches the key built into the app, its SHA-256
  matches, and it does not require a newer app build. Anything else falls back
  to the bundled copy
- App. Once a day the app reads `update.json` from the latest release. A
  newer build is reported in Settings, next to the version number. The app does
  not download or install it; the install permission is not requested

- Store build. When built with `NAZZEL_STORE=1` none of the above runs: no
  downloaded code, no yt-dlp update, no app update check, and YouTube links
  are refused. See [PLAY.md](PLAY.md)

## Settings

Default quality, ask for quality when sharing, save location (any folder, chosen with the system picker),
temporary file lifetime (read only), statistics (downloads so far, files kept
and their size), and a short note about privacy and rights.

## Interface

Arabic, right to left. Light theme in white and blue, dark theme in navy, both
following the system. Fixed English text (units, quality labels) is shown in
small capitals; names, links and numbers are not changed.

## Out of scope

Logging in or cookies, trimming, MP3 conversion, iOS.
