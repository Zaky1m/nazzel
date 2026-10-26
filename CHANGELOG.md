# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

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
