# Contributing

Please read `docs/SPEC.md` first: it is the reference for how the app behaves,
and changes to it start with an issue.

## Build and test

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
pip install -r tests/python/requirements.txt
python -m pytest tests/python
```

Building the APK is described in [docs/building.md](docs/building.md).

## Where things live

| Path | Contents |
|---|---|
| `lib/` | Flutter interface |
| `android/app/src/main/kotlin/` | Download service, database, saving, remuxing, updates |
| `android/app/src/main/python/engine.py` | Download logic around yt-dlp |
| `android/app/src/main/python/loader.py` | Chooses the bundled or a signed updated engine |
| `tests/python/` | Engine tests that run without a phone |

## Rules

- Comments in English, short, explaining why
- User-facing text stays in `lib/core/strings.dart` and the Kotlin strings it mirrors
- Any change to `engine.py` raises `ENGINE_VERSION`, or signed updates will not reach phones
- No secrets, personal data or server details in code, tests, docs or commits

## Commits

Small commits with one reason each, in the imperative mood ("Add playlist selection").
