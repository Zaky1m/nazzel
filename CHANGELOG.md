# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

## [1.2.2] - 2026-10-27

### Changed

- The download button of a playlist stays pinned at the bottom of the screen
- The update check button is gone; the version number sits at the end of Settings
- One delete-all button instead of one per playlist

## [1.2.1] - 2026-10-27

### Changed

- The app no longer installs updates itself. Settings only reports when a newer version exists, and the install permission is gone

## [1.2.0] - 2026-10-27

### Added

- Choose the folder where downloads are saved
- Delete all finished, failed or canceled downloads at once, and per playlist
- Update check button in the Settings footer, replacing the updates card

### Changed

- Settings are grouped into sections, and the version number sits at the bottom

### Fixed

- Canceling a download that had not reported progress yet did nothing until it started

## [1.1.0] - 2026-10-26

### Added

- Quality sheet over the sharing app, and a quick mode that downloads the best quality directly
- Playlists, albums and multi-video posts with item selection and grouped progress
- Spotify tracks, albums and playlists, downloaded as audio through YouTube search
- Audio-only sites such as SoundCloud, and HLS downloads remuxed into MP4
- YouTube challenge solving with QuickJS-NG, and browser TLS fingerprints with curl_cffi
- Clipboard detection and a single paste or clear button inside the link field
- In-app updates from GitHub releases, and signed updates for the download engine
- Download log for the last 100 downloads, with save, share and clear
- Statistics in Settings

### Fixed

- Downloads failed because shrinking renamed the progress callback
- Vertical videos were labelled by their long side

## [1.0.0] - 2026-10-26

### Added

- Download from the share menu or a pasted link, with preview and quality choice
- Background downloads with a progress notification, saved to the gallery
- Download list with play, share, delete and retry
