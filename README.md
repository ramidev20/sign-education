# EduBridge (sign_education)

EduBridge learning platform built with Flutter.

## Requirements

- Flutter SDK (stable)
- Git
- One of:
  - Android Studio (recommended) + Android SDK (for Android builds/emulator)
  - Xcode (macOS only, for iOS builds/simulator)
  - Windows / macOS / Linux desktop toolchain (optional, for desktop builds)

## Install Flutter

Follow the official Flutter install guide for your OS:

- Flutter install docs: https://docs.flutter.dev/get-started/install

After installing Flutter, verify your setup:

```bash
flutter --version
flutter doctor
```

Fix anything `flutter doctor` reports (Android SDK licenses, missing toolchains, etc.).

### Windows notes (common issues)

- Make sure `C:\flutter\bin` (or your Flutter install path) is on your `PATH`.
- Enable Developer Mode in Windows if you plan to run desktop apps.
- Android Studio → **SDK Manager**: install **Android SDK Platform** + **Build-Tools** + **Platform-Tools**.
- Accept Android licenses:

```bash
flutter doctor --android-licenses
```

## Get the project

Clone and enter the project:

```bash
git clone <YOUR_REPO_URL>
cd sign-education
```

Install dependencies:

```bash
flutter pub get
```

## Environment / configuration

### Supabase

This project currently initializes Supabase in `lib/main.dart` using a hardcoded `url` and `anonKey`.

- If you are using your own Supabase project, update:
  - `Supabase.initialize(url: ..., anonKey: ...)` in `lib/main.dart`

### Sentry (optional)

Sentry is enabled only if `SENTRY_DSN` is provided at build/run time.

Run with Sentry:

```bash
flutter run --dart-define=SENTRY_DSN=YOUR_DSN_HERE
```

Run without Sentry (default):

```bash
flutter run
```

## Run the app

### 1) Start an emulator or connect a device

List devices:

```bash
flutter devices
```

If you don’t have a device connected, create/start an emulator:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

### 2) Run

```bash
flutter run
```

Run a specific device:

```bash
flutter run -d <device_id>
```

## Build releases

### Android

APK:

```bash
flutter build apk --release
```

App Bundle (Play Store):

```bash
flutter build appbundle --release
```

Outputs are under `build/app/outputs/`.

### iOS (macOS only)

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to sign and archive.

## Project scripts / structure

- App source code lives in `lib/`.
- Assets are declared in `pubspec.yaml` and live under `assets/`.
- Misc docs and screenshots are stored in `docs/`.

## Troubleshooting

### Clean and rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### “SDK not found” / Android build issues

Re-run and follow fixes:

```bash
flutter doctor -v
```

### Dependency resolution issues

```bash
flutter pub get -v
flutter pub outdated
```
