# Building Nazzel

**English** · [العربية](building.ar.md)

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44 (stable) |
| JDK | 21, a full JDK with `javac` |
| Android SDK | Platform 36 and build tools 36 |
| Python | 3.13 on the build machine, as `python3.13` or set in `NAZZEL_BUILD_PYTHON` |

Chaquopy compiles the app's Python code with a build machine Python of the
same minor version, which is why 3.13 is needed. The Gradle build installs the
Python packages for Android by itself.

A release build uses about 2 GB of memory for Gradle.

## Debug build

```bash
tools/fetch-qjs.sh                 # downloads QuickJS-NG and checks its SHA-256
flutter build apk --debug --target-platform android-arm64
```

## Release build

Release APKs are signed with a key that never leaves the maintainer's machine.
To sign your own build, create `.secrets/key.properties`:

```properties
storeFile=nazzel.jks
storePassword=change-me
keyAlias=nazzel
keyPassword=change-me
```

and put the keystore next to it (`.secrets/nazzel.jks`). Then:

```bash
tools/fetch-qjs.sh
flutter build apk --release --target-platform android-arm64
```

An APK signed with a different key cannot update an installed copy of the
official app; Android asks to uninstall first.

## Publishing a release

1. Raise `version` in `pubspec.yaml`, and `ENGINE_VERSION` in `engine.py` if it changed
2. Add the changes to `CHANGELOG.md`
3. Build the release APK into `dist/nazzel.apk`
4. Run `tools/release.sh "notes" --publish`

The script writes `update.json` for the in-app updater, signs `engine.json`
with `.secrets/engine-signing.pem`, and creates the GitHub release with all
assets.
