# Publishing on Google Play

The app is built so that a Google Play version can exist beside the one on
GitHub. This page lists what differs, what Play asks for, and what is still a
risk.

## The two builds

| | GitHub APK | Play bundle (`NAZZEL_STORE=1`) |
|---|---|---|
| Sites | all supported sites | no YouTube |
| Downloader updates | yt-dlp and signed `engine.py` from GitHub, daily | none; updates come only through Play |
| App update notice | shown in Settings | none |
| Output | `flutter build apk` | `flutter build appbundle` |

Play does not allow an app to fetch executable code from outside Play, and
Python code is that, because it can call Android APIs directly. The store build
therefore never loads downloaded code. The cost is that a site change can break
a site until a new version is published on Play.

Build it with `NAZZEL_STORE=1 flutter build appbundle --release`.

## What the bundle already satisfies

- Target API 36, 64-bit only (`arm64-v8a`)
- Every native library, including the Python and curl_cffi modules, is aligned
  to 16 KB pages
- No install-packages permission, no storage permission, no background location
  or other sensitive permission; saving uses MediaStore or a folder the user
  picks
- No backup of app data (`allowBackup=false` and extraction rules that exclude
  everything), cleartext traffic off
- No logs, no analytics, no ads, no accounts
- The privacy policy is in `docs/PRIVACY.md` and `docs/PRIVACY.ar.md`

## What you do in the Play Console

1. Create the app, and enroll in Play App Signing. The key in `.secrets/` then
   becomes the upload key. An APK signed by it will not update an install that
   came from Play, because Play signs with its own key
2. Privacy policy URL: the public page of `docs/PRIVACY.md` on GitHub
3. Data safety form: collects no data, shares no data, no data is encrypted
   in transit by us because we send none; the user can delete data by deleting
   downloads or uninstalling
4. Foreground service declaration for `dataSync`: "Downloads the video or audio
   the user chose and saves it to the device; the user starts every download and
   sees a notification with a cancel action." Record a short screen video of a
   download with its notification
5. Content rating questionnaire: no user-generated content hosted by the app,
   no violence or other categories of its own; the app opens third-party sites'
   media only when the user asks
6. App access: no login, nothing to provide to reviewers. Give them one public
   link from a supported site to try
7. Target audience: 18 and over, not designed for children
8. Ads: none. News, health, finance: no

## Store listing text

Title: Nazzel

Short description: Save public videos and audio from the links you share, with
a quality choice.

Full description: Share a link from another app, pick a quality, and Nazzel
saves the video or audio to your gallery. It works from the share menu without
leaving the app you were in, downloads playlists with per-item progress, keeps
working in the background and stores nothing about you. Download only content
you have the right to save.

## Risks that remain

- Google's policies allow an app to fetch media only when the user has the right
  to it, and several sites state in their terms that downloads are not allowed.
  Play reviewers sometimes reject or remove "video downloader" apps for that
  reason, with or without YouTube support. Approval cannot be promised
- If rejected, the GitHub APK stays the main way to install
- A listing that names a site or brand, or implies affiliation with one, is
  rejected. The text above names none
