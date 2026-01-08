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

## Current Status: 92% Complete 🚀

All core features have been implemented and the app is in the testing & polish phase.

## Features Implemented

### Authentication ✅
- Email/Password registration and login
- Google Sign-In (OAuth)
- Password reset functionality
- Session persistence
- Secure token management

### User Profile ✅
- Profile CRUD operations
- Profile picture upload (Cloud Storage)
- User preferences (currency, notifications)
- Edit profile page

### Group Management ✅
- Create groups (trip, home, couple, other)
- Group list with balances
- Member management (add/remove)
- Group settings and editing
- Real-time updates

### Expense Management ✅
- Add expenses with description, amount, date, category
- Four split strategies:
  - Equal split
  - Exact amounts
  - Percentage-based
  - Shares/ratio-based
- Multi-payer support
- Receipt image attachment
- Expense categories (food, transport, accommodation, etc.)
- Expense list and detail views

### Settlements ✅
- View who owes whom
- Record payments between users
- Payment method selection (Cash, UPI, Bank Transfer)
- Settlement history
- Biometric verification for amounts > ₹5,000

### Debt Simplification ✅
- Algorithm to minimize transactions
- "Show Me the Math" feature
- Visual explanation of simplified debts
- Toggle per group

### Expense Chat ✅
- Text messages per expense
- Image attachments
- Voice notes (record/playback)
- Real-time updates
- System messages for changes

### Notifications ✅
- Push notifications via FCM
- In-app notification center
- Notification preferences
- Activity feed with timeline
- Deep linking from notifications

### Offline Support ✅
- Firestore offline persistence
- Local queue for offline operations (Hive)
- Sync conflict resolution
- Connectivity monitoring
- Offline indicator UI

### Core Services ✅
- LoggingService - Structured logging with levels
- AnalyticsService - Firebase Analytics
- ConnectivityService - Network monitoring
- OfflineQueueManager - Offline operation queue
- SyncService - Firestore sync
- AudioService - Voice recording/playback

## Project Structure

```
flutter_app/
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── lib/
│   ├── main.dart           # App entry point
│   ├── app/
│   │   ├── app.dart        # Main app widget
│   │   └── routes.dart     # GoRouter navigation
│   ├── core/
│   │   ├── config/         # App & theme configuration
│   │   ├── constants/      # App constants
│   │   ├── di/             # Dependency injection (GetIt)
│   │   ├── errors/         # Exceptions, failures, error messages
│   │   ├── models/         # Core models (offline operations)
│   │   ├── services/       # Core services (6 services)
│   │   ├── utils/          # Utility functions
│   │   └── widgets/        # Reusable widgets
│   └── features/
│       ├── auth/           # Authentication feature
│       │   ├── data/       # DataSources, Models, Repositories
│       │   ├── domain/     # Entities, Repositories, UseCases
│       │   └── presentation/ # BLoC, Pages
│       ├── profile/        # User profile feature
│       ├── groups/         # Group management feature
│       ├── expenses/       # Expenses & chat feature
│       ├── settlements/    # Settlements feature
│       ├── notifications/  # Notifications feature
│       └── dashboard/      # Dashboard feature
├── test/                   # Test files
└── pubspec.yaml           # Dependencies
```

## Tech Stack

- **Flutter**: 3.24+
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage, FCM)
- **Local Storage**: Hive, SharedPreferences
- **Architecture**: Clean Architecture

## Dependencies

### Core
- `flutter_bloc` - State management
- `go_router` - Navigation
- `get_it` - Dependency injection
- `dartz` - Functional programming (Either type)
- `equatable` - Value equality

### Firebase
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `firebase_messaging`
- `firebase_analytics`

### Storage
- `hive` & `hive_flutter` - Local storage
- `shared_preferences` - Simple key-value storage
- `path_provider` - File system paths

### UI
- `flutter_svg` - SVG support
- `cached_network_image` - Image caching
- `image_picker` - Camera/gallery access
- `intl` - Internationalization

### Audio
- `record` - Audio recording
- `audioplayers` - Audio playback
- `permission_handler` - Permission management

### Utilities
- `connectivity_plus` - Network connectivity
- `uuid` - Unique IDs
- `timeago` - Relative time formatting

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

2. **Configure Firebase** (if not already done)
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=YOUR_PROJECT_ID
   ```

3. **iOS Setup**
   ```bash
   cd ios && pod install && cd ..
   ```

4. **Run on iOS Simulator**
   ```bash
   flutter run -d ios
   ```

5. **Run on Android Emulator**
   ```bash
   flutter run -d android
   ```

## Development Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Build release (iOS)
flutter build ios --release

# Build release (Android)
flutter build apk --release
flutter build appbundle --release
```

## Build for Release

### iOS
```bash
flutter build ios --release
```

### Android
```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Architecture

The app follows **Clean Architecture** with three layers:

1. **Presentation Layer** - UI, BLoC, Widgets
2. **Domain Layer** - Entities, Repositories (interfaces), Use Cases
3. **Data Layer** - Models, DataSources, Repository Implementations

### State Management

Using **BLoC pattern** with:
- Events - User actions
- States - UI states
- BLoC - Business logic

### Dependency Injection

Using **GetIt** for service locator pattern:
- All services registered in `injection_container.dart`
- Lazy initialization for performance
- Easy mocking for tests

## Code Style

- Follow Dart style guide
- Use `dart format` for formatting
- Run `flutter analyze` before commits
- Write tests for business logic

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Library](https://bloclibrary.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [Firebase Flutter](https://firebase.google.com/docs/flutter/setup)

## Next Steps

### Sprint 8: Testing & Quality
- Unit tests (80% coverage target)
- Widget tests
- Integration tests
- Performance optimization

### Sprint 9: Launch
- Beta testing
- Store submissions
- Production monitoring

## License

This project is part of the What's My Share application. See the root LICENSE file for details.

---

*Last Updated: January 9, 2026*