# CLAUDE.md

Guidance for AI agents and contributors working on this repository.

## What this is

Nazzel is an Android app that saves videos and audio from social sites. A
Flutter interface talks over a method channel to Kotlin, which runs downloads
in a foreground service and hosts Python (Chaquopy) for yt-dlp.

## Read before you change anything

1. `docs/SPEC.md`: product behaviour, the source of truth
2. `docs/DECISIONS.md`: why things are the way they are. Append to it when you
   make a non-obvious choice
3. `CLAUDE.local.md`, if present: notes for one machine. Never committed

## Commands

```bash
dart format lib test && flutter analyze && flutter test
python -m pytest tests/python
tools/fetch-qjs.sh && flutter build apk --release --target-platform android-arm64
```

## Rules

- Kotlin owns all download state (SQLite). Flutter reads it and asks Kotlin to change it
- Python is called by method name from Kotlin, so classes it touches must stay public and unshrunk
- Every public function in `engine.py` returns JSON and never raises
- Raise `ENGINE_VERSION` whenever `engine.py` changes
- Nothing in RAM that must survive a restart; temporary states expire within 24 hours
- Comments are English, short, and say why, not what
- No secrets, signing keys or personal data in code, tests, docs or commits

## Commits

Small commits, one reason each, imperative mood. Run the checks above first.
