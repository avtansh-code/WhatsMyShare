# Development Environment Setup

## Overview
This document outlines the steps to set up the development environment for the "What's My Share" bill-splitting application.

> **Note**: This project supports **iOS and Android platforms only**. Web, Linux, macOS, and Windows desktop platforms are not supported.

---

## 1. Prerequisites

### 1.1 Hardware Requirements
- **macOS**: macOS 10.15 (Catalina) or later (for iOS development)
- **RAM**: Minimum 8GB, recommended 16GB
- **Storage**: At least 50GB free space

### 1.2 Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| Flutter SDK | 3.24+ | Cross-platform mobile development |
| Dart SDK | 3.5+ | Programming language (bundled with Flutter) |
| Android Studio | Latest | Android SDK, emulators, and tooling |
| Xcode | 15+ | iOS development and simulators |
| VS Code | Latest | Recommended IDE |
| Git | Latest | Version control |
| Google Cloud SDK | Latest | GCP CLI tools |
| Node.js | 18+ LTS | Cloud Functions development |
| Docker | Latest | Local testing of containerized services |

### 1.3 Required Accounts
- **Google Cloud Platform Account** - For Firebase and backend services
- **Apple Developer Account** - $99/year (required for iOS deployment)
- **Google Play Developer Account** - $25 one-time (required for Android deployment)

---

## 2. Installation Steps

### 2.1 Install Flutter SDK

```bash
# Using Homebrew (macOS)
brew install --cask flutter

# Or manual installation
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2.2 Install Android Studio

```bash
brew install --cask android-studio
```

**Manual Steps Required:**
1. Open Android Studio
2. Go to SDK Manager → SDK Tools
3. Install:
   - Android SDK Command-line Tools
   - Android SDK Build-Tools
   - Android Emulator
   - Android SDK Platform-Tools

### 2.3 Install Xcode (macOS only)

```bash
# Install from App Store or:
xcode-select --install

# Accept license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods
```

**Manual Steps Required:**
1. Open Xcode at least once to complete setup
2. Go to Preferences → Locations → Command Line Tools (select Xcode version)

### 2.4 Install Google Cloud SDK

```bash
brew install --cask google-cloud-sdk

# Initialize and authenticate
gcloud init
gcloud auth application-default login
```

### 2.5 Install Node.js (for Cloud Functions)

```bash
brew install node@18

# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### 2.6 Install VS Code Extensions

**Recommended Extensions:**
- Flutter
- Dart
- Google Cloud Code
- GitLens
- Error Lens
- Bracket Pair Colorizer
- REST Client

---

## 3. Clone and Configure Project

### 3.1 Clone Repository

```bash
git clone https://github.com/your-org/whatsmyshare.git
cd whatsmyshare
```

### 3.2 Project Structure Overview

After cloning, you'll see this structure:

```
WhatsMyShare/
├── .gitignore                   # Git ignore rules
├── README.md                    # Project overview
├── firebase.json                # Firebase CLI configuration
├── storage.rules                # Cloud Storage security rules
├── docs/                        # Documentation
├── firestore-database/          # Firestore rules and indexes
│   ├── firestore.rules
│   └── firestore.indexes.json
└── flutter_app/                 # Flutter application
    ├── android/
    ├── ios/
    ├── lib/
    └── pubspec.yaml
```

### 3.3 Files You Need to Create

The following files are **not included in the repository** for security reasons. You must create them:

| File | Location | Purpose |
|------|----------|---------|
| `.firebaserc` | Root | Links to your Firebase project |
| `.env` | Root | Environment variables |
| `service-account.json` | Root | GCP service account key |
| `google-services.json` | `flutter_app/android/app/` | Firebase Android config |
| `GoogleService-Info.plist` | `flutter_app/ios/Runner/` | Firebase iOS config |
| `firebase_options.dart` | `flutter_app/lib/` | Generated Firebase options |
| `firebase.json` | `flutter_app/` | FlutterFire CLI config |

---

## 4. Firebase/GCP Project Setup

### 4.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name (e.g., `whatsmyshare-dev` for development)
4. Enable Google Analytics (optional)
5. Wait for project creation

### 4.2 Enable Required GCP Services

```bash
# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable \
  firestore.googleapis.com \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com \
  secretmanager.googleapis.com \
  cloudscheduler.googleapis.com \
  firebase.googleapis.com \
  identitytoolkit.googleapis.com \
  fcm.googleapis.com \
  artifactregistry.googleapis.com \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### 4.3 Create Service Account

1. Go to [GCP Console → IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Click "Create Service Account"
3. Name: `firebase-admin-sdk`
4. Grant roles:
   - Firebase Admin SDK Administrator Service Agent
   - Cloud Datastore User
   - Storage Admin
5. Create key (JSON format)
6. Save as `service-account.json` in project root

**Store in Secret Manager (recommended):**
```bash
gcloud secrets create firebase-admin-key \
  --data-file=./service-account.json
```

### 4.4 Enable Firebase Services

In Firebase Console for your project:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"
   - Enable "Google" (configure OAuth consent screen if prompted)

2. **Firestore Database**
   - Go to Firestore Database → Create database
   - Start in production mode
   - Choose location: `asia-south1` (Mumbai) for India

3. **Cloud Storage**
   - Go to Storage → Get started
   - Start in production mode

4. **Cloud Messaging**
   - Enabled by default for push notifications

---

## 5. Configure Flutter App

### 5.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 5.2 Configure Firebase for Flutter

```bash
cd flutter_app

# This will generate the required config files
flutterfire configure --project=YOUR_PROJECT_ID
```

This command will:
- Create `lib/firebase_options.dart`
- Create `android/app/google-services.json`
- Create `ios/Runner/GoogleService-Info.plist`
- Create `firebase.json` in flutter_app

### 5.3 Link Firebase Project

Create `.firebaserc` in project root:

```json
{
  "projects": {
    "default": "YOUR_PROJECT_ID"
  }
}
```

### 5.4 Create Environment File

Create `.env` in project root:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com

# GCP Configuration
GCP_PROJECT_ID=YOUR_PROJECT_ID
GCP_REGION=asia-south1

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_BIOMETRIC_AUTH=true
DEFAULT_CURRENCY=INR
```

### 5.5 Install Flutter Dependencies

```bash
cd flutter_app
flutter pub get
```

### 5.6 iOS Configuration

The iOS platform is already set to iOS 13.0. Run:

```bash
cd ios
pod install
cd ..
```

### 5.7 Verify Setup

```bash
# Run Flutter analysis
flutter analyze

# Run on iOS Simulator
flutter run -d ios

# Run on Android Emulator
flutter run -d android
```

---

## 6. Deploy Firebase Rules

### 6.1 Deploy Firestore Rules

```bash
# From project root
firebase deploy --only firestore:rules
```

### 6.2 Deploy Storage Rules

```bash
firebase deploy --only storage
```

### 6.3 Deploy All Rules

```bash
firebase deploy --only firestore,storage
```

---

## 7. Firebase Emulators (Local Development)

### 7.1 Start Emulators

```bash
firebase emulators:start --only firestore,auth,functions,storage
```

### 7.2 Emulator Ports

| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Storage | 9199 |
| Emulator UI | 4000 |

### 7.3 Connect Flutter App to Emulators

In your Flutter app, enable emulator connection during development:

```dart
// In main.dart or firebase initialization
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

---

## 8. Verification Checklist

Run these commands to verify setup:

```bash
# Flutter setup
flutter doctor -v

# Firebase CLI
firebase projects:list

# GCP setup
gcloud info

# Current project
gcloud config get-value project

# Android SDK
adb devices

# iOS (macOS only)
xcrun simctl list devices

# Flutter app analysis
cd flutter_app && flutter analyze
```

**Expected Output:** All checks should pass with no critical errors.

---

## 9. Troubleshooting

### 9.1 Common Issues

| Issue | Solution |
|-------|----------|
| `firebase_options.dart` not found | Run `flutterfire configure` |
| CocoaPods issues | Run `cd ios && pod install --repo-update` |
| Android build fails | Check `minSdkVersion` is 23+ |
| Firebase Auth errors | Verify SHA-1 fingerprint is added in Firebase Console |
| Firestore permission denied | Deploy Firestore rules with `firebase deploy --only firestore:rules` |

### 9.2 Reset Firebase Configuration

```bash
cd flutter_app
rm -f lib/firebase_options.dart
rm -f android/app/google-services.json
rm -f ios/Runner/GoogleService-Info.plist
rm -f firebase.json
flutterfire configure --project=YOUR_PROJECT_ID
```

### 9.3 Get Android SHA-1 for Firebase Auth

```bash
cd flutter_app/android
./gradlew signingReport
```

Add the SHA-1 fingerprint to Firebase Console → Project Settings → Your apps → Android app → Add fingerprint.

---

## 10. Files Reference

### 10.1 Files in Repository (Version Controlled)

| File | Description |
|------|-------------|
| `firebase.json` (root) | Firebase CLI config for deploying rules/functions |
| `storage.rules` | Cloud Storage security rules |
| `firestore-database/firestore.rules` | Firestore security rules |
| `firestore-database/firestore.indexes.json` | Firestore index definitions |
| `flutter_app/pubspec.yaml` | Flutter dependencies |
| `flutter_app/ios/Podfile` | iOS CocoaPods configuration |

### 10.2 Files NOT in Repository (Must Create)

| File | How to Create |
|------|---------------|
| `.firebaserc` | Manual (see Section 5.3) |
| `.env` | Manual (see Section 5.4) |
| `service-account.json` | Download from GCP Console |
| `flutter_app/android/app/google-services.json` | Generated by `flutterfire configure` |
| `flutter_app/ios/Runner/GoogleService-Info.plist` | Generated by `flutterfire configure` |
| `flutter_app/lib/firebase_options.dart` | Generated by `flutterfire configure` |
| `flutter_app/firebase.json` | Generated by `flutterfire configure` |

---

## 11. Manual Steps Summary

| Step | Description | Time |
|------|-------------|------|
| M1 | Create Firebase project in console | 5 min |
| M2 | Enable GCP services | 5 min |
| M3 | Create service account | 10 min |
| M4 | Enable Firebase Auth providers | 5 min |
| M5 | Create Firestore database | 5 min |
| M6 | Run `flutterfire configure` | 5 min |
| M7 | Create `.firebaserc` and `.env` | 5 min |
| M8 | Configure Android Studio SDK Tools | 15 min |
| M9 | Accept Xcode license and configure | 10 min |
| M10 | Add SHA-1 fingerprint for Android | 5 min |

**Total Setup Time**: ~1-2 hours for a new developer

---

## Next Steps

1. Verify the app runs on both iOS and Android
2. Proceed to [02-architecture-design.md](./02-architecture-design.md) for system architecture details
3. Review [03-database-schema.md](./03-database-schema.md) for data models
4. Follow [04-implementation-roadmap.md](./04-implementation-roadmap.md) for development phases