# What's My Share - Flutter App

A bill-splitting mobile application built with Flutter for **iOS and Android platforms only**.

## Current Status: 98% Complete ✅

All core features and testing are complete. Ready for beta testing and store submission.

## Supported Platforms

| Platform | Supported |
|----------|-----------|
| iOS | ✅ Yes |
| Android | ✅ Yes |
| Web | ❌ No |
| macOS | ❌ No |
| Linux | ❌ No |
| Windows | ❌ No |

---

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
| Service | Purpose |
|---------|---------|
| LoggingService | Structured logging with levels |
| AnalyticsService | Firebase Analytics integration |
| ConnectivityService | Network state monitoring |
| OfflineQueueManager | Offline operation queue with retry |
| SyncService | Firestore sync operations |
| AudioService | Voice note recording/playback |

---

## Project Structure

```
flutter_app/
├── lib/                         # 85 source files
│   ├── main.dart               # App entry point
│   ├── firebase_options.dart   # Firebase configuration
│   ├── app/                    # App configuration (2 files)
│   │   ├── app.dart           # Main app widget with providers
│   │   └── routes.dart        # GoRouter navigation setup
│   ├── core/                   # Core utilities (21 files)
│   │   ├── config/            # App & theme configuration
│   │   ├── constants/         # App-wide constants
│   │   ├── di/                # Dependency injection (GetIt)
│   │   ├── errors/            # Custom exceptions & failures
│   │   ├── models/            # Core models (OfflineOperation)
│   │   ├── services/          # 6 core services
│   │   ├── utils/             # Utility functions (currency)
│   │   └── widgets/           # Shared widgets
│   └── features/              # Feature modules (62 files)
│       ├── auth/              # Authentication (15 files)
│       ├── profile/           # User profile (9 files)
│       ├── groups/            # Group management (10 files)
│       ├── expenses/          # Expenses & chat (15 files)
│       ├── settlements/       # Settlements (10 files)
│       ├── notifications/     # Notifications (10 files)
│       └── dashboard/         # Dashboard (1 file)
└── test/                       # 45+ test files
    ├── unit/                  # 26 unit test files
    ├── widget/                # 15 widget test files
    └── integration/           # 4 integration test files
```

---

## Tech Stack

- **Flutter**: 3.24+
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage, FCM, Analytics)
- **Local Storage**: Hive, SharedPreferences
- **Architecture**: Clean Architecture

---

## Testing

### Test Summary

**Total Tests: 1,382 passing** 🎉

| Category | Files | Tests |
|----------|-------|-------|
| Unit Tests | 26 | ~900 |
| Widget Tests | 15 | ~440 |
| Integration Tests | 4 | 41 |

### Test Organization

```
test/
├── unit/                    # Unit tests
│   ├── core/               # Services, utils, errors, config
│   │   ├── config/
│   │   ├── errors/
│   │   ├── models/
│   │   ├── services/
│   │   └── utils/
│   └── features/           # BLoCs, models, usecases
│       ├── auth/
│       ├── expenses/
│       ├── groups/
│       ├── notifications/
│       ├── profile/
│       └── settlements/
├── widget/                  # Widget tests
│   ├── core/widgets/
│   └── features/           # All page widgets
└── integration/            # Integration tests (mock Firebase)
    ├── test_helper.dart    # Firebase mock setup
    ├── auth_flow_test.dart
    ├── group_flow_test.dart
    ├── expense_flow_test.dart
    └── settlement_flow_test.dart
```

### Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/features/auth/presentation/bloc/auth_bloc_test.dart

# Run tests matching pattern
flutter test --name "should sign in"

# Run integration tests (uses mock Firebase - no emulators needed)
flutter test test/integration/ --tags integration

# Run ALL tests including integration
flutter test --tags integration
```

### Mock Firebase Testing

Integration tests use mock packages for fast, isolated testing:
- **firebase_auth_mocks** - Simulates Firebase Auth in-memory
- **fake_cloud_firestore** - Simulates Firestore in-memory

Benefits:
- ✅ No emulator setup required
- ✅ Tests run fast (~3 seconds for 41 tests)
- ✅ Works in any CI/CD environment
- ✅ Isolated and deterministic

### Optional: Firebase Emulator Testing

For real Firebase testing, use the integration test runner:

```bash
# From project root
./scripts/run_integration_tests.sh
```

This script:
- Starts Firebase emulators automatically
- Runs integration tests
- Shuts down emulators after completion

---

## Dependencies

### Core
```yaml
flutter_bloc: ^8.1.6
go_router: ^14.6.3
get_it: ^8.0.3
dartz: ^0.10.1
equatable: ^2.0.7
```

### Firebase
```yaml
firebase_core: ^3.9.0
firebase_auth: ^5.4.1
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.0
firebase_messaging: ^15.2.0
firebase_analytics: ^11.4.0
google_sign_in: ^6.2.2
```

### Storage
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.3.4
path_provider: ^2.1.5
```

### UI
```yaml
flutter_svg: ^2.0.16
cached_network_image: ^3.4.1
image_picker: ^1.1.2
shimmer: ^3.0.0
intl: ^0.19.0
```

### Audio
```yaml
record: ^5.1.2
audioplayers: ^6.1.0
permission_handler: ^11.3.1
```

### Testing
```yaml
flutter_test: sdk
bloc_test: ^9.1.7
mocktail: ^1.0.4
firebase_auth_mocks: ^0.14.1
fake_cloud_firestore: ^3.1.0
```

---

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

---

## Development Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Run all tests
flutter test

# Run integration tests
flutter test test/integration/ --tags integration

# Analyze code
flutter analyze

# Format code
dart format lib/

# Build release (iOS)
flutter build ios --release

# Build release (Android)
flutter build apk --release
flutter build appbundle --release
```

---

## Architecture

The app follows **Clean Architecture** with three layers:

### 1. Presentation Layer
- **Pages**: UI screens
- **BLoC**: Business logic components
- **Widgets**: Reusable UI components

### 2. Domain Layer
- **Entities**: Core business objects
- **Repositories**: Abstract interfaces
- **Use Cases**: Business operations

### 3. Data Layer
- **Models**: Data transfer objects
- **DataSources**: API/Database access
- **Repository Implementations**: Concrete implementations

### State Management

Using **BLoC pattern** with:
- **Events**: User actions/triggers
- **States**: UI states (loading, loaded, error)
- **BLoC**: Business logic processing

### Dependency Injection

Using **GetIt** for service locator pattern:
- All services registered in `injection_container.dart`
- Lazy initialization for performance
- Easy mocking for tests

---

## UI Pages

| Page | Route | Status |
|------|-------|--------|
| Login | `/login` | ✅ Tested |
| Signup | `/signup` | ✅ Tested |
| Forgot Password | `/forgot-password` | ✅ Tested |
| Dashboard | `/` | ✅ Tested |
| Group List | `/groups` | ✅ Tested |
| Group Detail | `/groups/:id` | ✅ Tested |
| Create Group | `/groups/create` | ✅ Tested |
| Expense List | `/groups/:id/expenses` | ✅ Tested |
| Add Expense | `/groups/:id/expenses/add` | ✅ Tested |
| Expense Chat | `/expenses/:id/chat` | ✅ Tested |
| Profile | `/profile` | ✅ Tested |
| Edit Profile | `/profile/edit` | ✅ Tested |
| Notifications | `/notifications` | ✅ Tested |
| Settle Up | `/groups/:id/settle` | ✅ Tested |

---

## Next Steps

### Phase 5: Launch
1. Beta testing via TestFlight / Firebase App Distribution
2. Performance optimization
3. Security audit
4. App Store / Play Store submission

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Library](https://bloclibrary.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [Firebase Flutter](https://firebase.google.com/docs/flutter/setup)

---

## License

This project is part of the What's My Share application. See the root LICENSE file for details.

---

*Last Updated: January 9, 2026*