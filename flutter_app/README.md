# What's My Share - Flutter App

A bill-splitting mobile application built with Flutter for **iOS and Android platforms only**.

## Supported Platforms

| Platform | Supported |
|----------|-----------|
| iOS | ✅ Yes |
| Android | ✅ Yes |
| Web | ❌ No |
| macOS | ❌ No |
| Linux | ❌ No |
| Windows | ❌ No |

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.5+
- For iOS: macOS with Xcode 15+
- For Android: Android Studio with SDK 34+

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run on iOS Simulator**
   ```bash
   flutter run -d ios
   ```

3. **Run on Android Emulator**
   ```bash
   flutter run -d android
   ```

### Build for Release

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

## Project Structure

```
flutter_app/
├── android/          # Android platform files
├── ios/              # iOS platform files
├── lib/              # Dart source code
│   └── main.dart     # App entry point
├── test/             # Test files
├── pubspec.yaml      # Dependencies
└── README.md         # This file
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

## License

This project is part of the What's My Share application. See the root LICENSE file for details.