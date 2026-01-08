# What's My Share - Development Plan

A comprehensive bill-splitting mobile application built with Flutter and Google Cloud Platform, designed for the Indian market with global scalability in mind. **Supported platforms: iOS and Android only.**

## 📱 App Overview

**What's My Share** is a Splitwise-like application that helps friends and groups split expenses easily. The app supports multiple splitting strategies, offline functionality, and smart debt simplification.

### Key Features

- 👥 **Group Management** - Create groups for trips, home expenses, couples, etc.
- 💰 **Smart Expense Splitting** - Equal, exact, percentage, or ratio-based splits
- 🔄 **Multi-payer Support** - Handle bills paid by multiple people
- 📊 **Debt Simplification** - Minimize transactions with smart algorithms
- 💬 **Expense Chat** - Discuss specific expenses with image and voice attachments
- 📱 **Offline Support** - Full functionality even without internet
- 🔔 **Push Notifications** - Stay updated on expenses and settlements
- 🔒 **Biometric Security** - Extra protection for large settlements
- 🇮🇳 **India-First** - INR support, UPI tracking, optimized for 4G

---

## 🚀 Current Progress: **92% Complete**

### Phase Status

| Phase | Duration | Focus | Status |
|-------|----------|-------|--------|
| **Phase 1: Foundation** | Weeks 1-3 | Setup, Auth, Navigation | ✅ Complete |
| **Phase 2: Core Features** | Weeks 4-8 | Groups, Expenses, Friends | ✅ Complete |
| **Phase 3: Advanced** | Weeks 9-12 | Settlements, Notifications, Chat | ✅ Complete |
| **Phase 4: Polish** | Weeks 13-14 | Offline, Testing, Performance | 🔄 In Progress |
| **Phase 5: Launch** | Weeks 15-16 | Beta, Store Submission | ⏳ Pending |

### Completed Features ✅
- Authentication (Email, Google Sign-In)
- User Profile Management
- Group Management (CRUD, member management)
- Expense Management (all 4 split types)
- Split Calculator Service
- Settlements & Debt Simplification Algorithm
- Notifications & Activity Feed
- Offline Support Infrastructure
- Expense Chat with Image & Voice Notes
- Logging & Analytics Services

### Remaining Work
- Unit tests (80% coverage target)
- Widget & Integration tests
- Performance optimization
- Beta testing
- Store submissions

---

## 📁 Project Structure

```
WhatsMyShare/
├── README.md                    # This file
├── docs/                        # Planning documentation
│   ├── 01-development-environment-setup.md
│   ├── 02-architecture-design.md
│   ├── 03-database-schema.md
│   ├── 04-implementation-roadmap.md
│   ├── 05-feature-implementation-guide.md
│   ├── 06-testing-strategy.md
│   ├── 07-deployment-guide.md
│   └── 08-manual-steps-summary.md
├── agent_updates/               # Development progress tracking
│   ├── README.md
│   ├── PROJECT_STATUS.md
│   ├── DEVELOPMENT_LOG.md
│   └── CURRENT_SPRINT.md
├── firestore-database/          # Database configuration
│   ├── firestore.rules          # Security rules
│   └── firestore.indexes.json   # Index definitions
└── flutter_app/                 # Flutter application (iOS & Android only)
    ├── android/                 # Android platform files
    ├── ios/                     # iOS platform files
    ├── lib/                     # Dart source code
    │   ├── app/                 # App entry, routes
    │   ├── core/                # Shared utilities & services
    │   └── features/            # Feature modules
    └── test/                    # Test files
```

> **Note**: This project supports **iOS and Android platforms only**. Web, Linux, macOS, and Windows platforms have been removed.

---

## 📚 Documentation Index

| Document | Description |
|----------|-------------|
| [01 - Development Environment Setup](docs/01-development-environment-setup.md) | Prerequisites, installation steps, and tool configuration |
| [02 - Architecture Design](docs/02-architecture-design.md) | System architecture, Flutter app structure, backend services |
| [03 - Database Schema](docs/03-database-schema.md) | Firestore collections, data models, and relationships |
| [04 - Implementation Roadmap](docs/04-implementation-roadmap.md) | 16-week timeline with sprints and milestones |
| [05 - Feature Implementation Guide](docs/05-feature-implementation-guide.md) | Detailed specs for each feature with code examples |
| [06 - Testing Strategy](docs/06-testing-strategy.md) | Unit, widget, integration tests and CI/CD |
| [07 - Deployment Guide](docs/07-deployment-guide.md) | GCP deployment, app store submission |
| [08 - Manual Steps Summary](docs/08-manual-steps-summary.md) | All human-required configuration steps |

---

## 🏗️ Tech Stack

### Frontend
- **Framework**: Flutter 3.24+
- **Platforms**: iOS and Android only
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: GoRouter
- **Local Storage**: Hive, SharedPreferences
- **Architecture**: Clean Architecture

### Backend
- **Platform**: Google Cloud Platform (GCP)
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Storage**: Cloud Storage
- **Messaging**: Firebase Cloud Messaging (FCM)

### Core Services
| Service | Purpose |
|---------|---------|
| LoggingService | Structured logging with levels |
| AnalyticsService | Firebase Analytics integration |
| ConnectivityService | Network state monitoring |
| OfflineQueueManager | Offline operation queue with retry |
| SyncService | Firestore sync operations |
| AudioService | Voice note recording/playback |

### DevOps
- **CI/CD**: GitHub Actions
- **Monitoring**: Firebase Crashlytics, Cloud Monitoring
- **Distribution**: Fastlane

---

## 🏛️ Architecture Summary

```
flutter_app/
├── lib/
│   ├── app/                  # App entry, routes
│   │   ├── app.dart          # Main app widget
│   │   └── routes.dart       # GoRouter configuration
│   ├── core/                 # Shared utilities
│   │   ├── config/           # App & theme config
│   │   ├── constants/        # App constants
│   │   ├── di/               # Dependency injection
│   │   ├── errors/           # Exceptions, failures, error messages
│   │   ├── models/           # Core models (offline operations)
│   │   ├── services/         # Core services (6 services)
│   │   ├── utils/            # Utility functions
│   │   └── widgets/          # Reusable widgets
│   └── features/             # Feature modules
│       ├── auth/             # Authentication
│       ├── profile/          # User profile
│       ├── groups/           # Group management
│       ├── expenses/         # Expenses & chat
│       ├── settlements/      # Settlements
│       ├── notifications/    # Notifications
│       └── dashboard/        # Dashboard
```

---

## 📊 Sprint History

| Sprint | Focus | Status |
|--------|-------|--------|
| Sprint 1-2 | Foundation & Auth | ✅ Complete |
| Sprint 3 | Group Management | ✅ Complete |
| Sprint 4 | Expense Management & Splits | ✅ Complete |
| Sprint 5 | Settlements & Debt Algorithm | ✅ Complete |
| Sprint 6 | Notifications & Activity Feed | ✅ Complete |
| Sprint 7 | Offline Support | ✅ Complete |
| Sprint 7.5 | Expense Chat & Voice Notes | ✅ Complete |
| Sprint 7.6 | Technical Infrastructure | ✅ Complete |
| Sprint 8 | Testing & Quality | 🔄 Next |
| Sprint 9 | Beta & Launch | ⏳ Pending |

---

## 🔧 Manual Steps Required

There are **58 manual steps** that cannot be automated and require human intervention:

| Category | Steps | Time |
|----------|-------|------|
| Environment Setup | 12 | 8-10 hours |
| GCP/Firebase Setup | 15 | 4-6 hours |
| iOS Development | 9 | 3-4 hours |
| Android Release | 10 | 4-6 hours |
| App Store Setup | 8 | 6-8 hours |
| Pre-Launch | 4 | 8-12 hours |

**Total Manual Effort**: 24-33 hours

See [08 - Manual Steps Summary](docs/08-manual-steps-summary.md) for complete details.

---

## 🚀 Quick Start

### Prerequisites
- macOS (for iOS development)
- Flutter SDK 3.24+
- Xcode 15+
- Android Studio
- GCP/Firebase Account
- Apple Developer Account ($99/year) - for iOS deployment
- Google Play Developer Account ($25 one-time) - for Android deployment

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/whatsmyshare.git
   cd whatsmyshare
   ```

2. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project (e.g., `whatsmyshare-dev`)
   - Enable Authentication (Email/Password + Google)
   - Create Firestore Database
   - Enable Cloud Storage

3. **Enable GCP Services**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   gcloud services enable \
     firestore.googleapis.com \
     cloudfunctions.googleapis.com \
     storage.googleapis.com \
     pubsub.googleapis.com \
     secretmanager.googleapis.com \
     cloudscheduler.googleapis.com \
     firebase.googleapis.com \
     identitytoolkit.googleapis.com \
     fcm.googleapis.com
   ```

4. **Configure Flutter App**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase (generates required config files)
   cd flutter_app
   flutterfire configure --project=YOUR_PROJECT_ID
   ```

5. **Create Required Files**
   
   Create `.firebaserc` in project root:
   ```json
   {
     "projects": {
       "default": "YOUR_PROJECT_ID"
     }
   }
   ```
   
   Create `.env` in project root:
   ```env
   FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
   GCP_PROJECT_ID=YOUR_PROJECT_ID
   GCP_REGION=asia-south1
   ```

6. **Install Dependencies & Run**
   ```bash
   cd flutter_app
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

### Files NOT in Repository

These files are excluded from git for security and must be created locally:

| File | How to Create |
|------|---------------|
| `.firebaserc` | Manual (step 5 above) |
| `.env` | Manual (step 5 above) |
| `service-account.json` | Download from GCP Console |
| `flutter_app/android/app/google-services.json` | Generated by `flutterfire configure` |
| `flutter_app/ios/Runner/GoogleService-Info.plist` | Generated by `flutterfire configure` |
| `flutter_app/lib/firebase_options.dart` | Generated by `flutterfire configure` |

See [01 - Development Environment Setup](docs/01-development-environment-setup.md) for detailed instructions.

---

## 📊 Database Schema Highlights

### Collections Structure
```
firestore-root/
├── users/{userId}
│   ├── friends/{friendId}
│   └── notifications/{notificationId}
├── groups/{groupId}
│   ├── expenses/{expenseId}
│   │   └── chat/{messageId}
│   ├── settlements/{settlementId}
│   └── activity/{activityId}
├── invitations/{invitationId}
└── metadata/{configId}
```

### Key Design Decisions
- **Amounts stored in paisa** (1/100 INR) to avoid floating-point errors
- **Denormalized data** for offline access and read efficiency
- **Subcollections** for scalable expense and activity storage
- **Server timestamps** for consistent ordering

See [03 - Database Schema](docs/03-database-schema.md) for complete details.

---

## 🔒 Security Features

- **Authentication**: Firebase Auth (Email + Google OAuth)
- **Authorization**: Firestore Security Rules with row-level security
- **Encryption**: TLS 1.3 in transit, AES-256 at rest
- **Biometric**: Required for settlements > ₹5,000
- **Audit Logs**: Cloud Audit Logs for admin actions

---

## 🌍 Internationalization

### Initial Launch (India)
- Default Currency: INR (₹)
- Languages: English (en-IN), Hindi (hi-IN)
- Region: asia-south1 (Mumbai)

### Future Expansion
- Multi-currency support built-in
- Region-configurable deployments
- Localization-ready with ARB files

---

## 📈 Success Metrics

### Launch Criteria
- [x] All P0 features complete
- [ ] Dashboard load < 2 seconds (4G)
- [ ] Crash-free rate > 99.5%
- [ ] Test coverage > 80%
- [ ] Security audit passed

### Post-Launch KPIs
| Metric | Month 1 Target |
|--------|----------------|
| DAU | 1,000 |
| D7 Retention | 40% |
| App Store Rating | 4.0+ |
| Crash-free | 99.5% |

---

## 🛠️ Development Commands

```bash
# Navigate to Flutter app
cd flutter_app

# Get dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/

# Build release
flutter build ios --release
flutter build apk --release
```

---

## 🤝 Contributing

This is a planning document for a new project. Once development begins:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support

- **Documentation**: See `/docs` folder
- **Issues**: GitHub Issues
- **Email**: support@whatsmyshare.com (future)

---

## 🙏 Acknowledgments

- Inspired by Splitwise
- Built with Flutter ❤️
- Powered by Google Cloud Platform

---

*Last Updated: January 9, 2026*