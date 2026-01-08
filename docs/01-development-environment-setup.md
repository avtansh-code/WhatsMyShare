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

## 3. Project Setup

### 3.1 Create Flutter Project

```bash
# Create new Flutter project (iOS and Android only)
flutter create --org com.<your_org> --project-name whats_my_share --platforms=ios,android flutter_app

cd flutter_app

# Get dependencies
flutter pub get
```

> **Note**: The `--platforms=ios,android` flag ensures only iOS and Android platform support is generated. If you already have a project with other platforms, you can remove the `linux/`, `macos/`, `web/`, and `windows/` directories.

### 3.2 Configure Firebase/GCP

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase project
flutterfire configure --project=whatsmyshare-prod
```

**Manual Steps Required:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: `whatsmyshare-prod`
3. Enable required services (see Section 4)

### 3.3 Android Configuration

Edit `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 23  // Android 6.0+
        targetSdkVersion 34
        multiDexEnabled true
    }
}
```

### 3.4 iOS Configuration

Edit `ios/Podfile`:
```ruby
platform :ios, '13.0'
```

---

## 4. GCP Services Setup

### 4.1 Required GCP Services

| Service | Purpose |
|---------|---------|
| Cloud Firestore | NoSQL database for real-time data |
| Cloud Run | Containerized backend services |
| Cloud Functions | Event-driven serverless functions |
| Cloud Storage | File storage (receipts, profile pictures) |
| Firebase Auth | User authentication |
| Cloud Pub/Sub | Async messaging & notifications |
| Secret Manager | API keys and secrets |
| Cloud Scheduler | Scheduled tasks (reminders) |

### 4.2 Enable Services

```bash
# Set project
gcloud config set project whatsmyshare-prod

# Enable APIs
gcloud services enable \
  firestore.googleapis.com \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com \
  secretmanager.googleapis.com \
  cloudscheduler.googleapis.com \
  firebase.googleapis.com \
  identitytoolkit.googleapis.com
```

---

## 5. Environment Variables

### 5.1 Local Development

Create `.env` file (DO NOT COMMIT):
```env
# Firebase Configuration
FIREBASE_PROJECT_ID=whatsmyshare-prod
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=whatsmyshare-prod.firebaseapp.com

# GCP Configuration
GCP_PROJECT_ID=whatsmyshare-prod
GCP_REGION=asia-south1

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_BIOMETRIC_AUTH=true
DEFAULT_CURRENCY=INR
```

### 5.2 Secrets Management

```bash
# Store sensitive data in Secret Manager
gcloud secrets create firebase-admin-key \
  --data-file=./service-account.json

gcloud secrets create razorpay-api-key \
  --data-file=./razorpay-key.txt
```

---

## 6. Development Tools

### 6.1 Emulators Setup

```bash
# Android Emulator
flutter emulators --create --name Pixel_5_API_34

# iOS Simulator
open -a Simulator

# Firebase Emulators (for local testing)
firebase emulators:start --only firestore,auth,functions
```

### 6.2 Code Quality Tools

```bash
# Add to pubspec.yaml dev_dependencies
flutter pub add --dev flutter_lints
flutter pub add --dev build_runner
flutter pub add --dev mockito
```

---

## 7. Verification Checklist

Run these commands to verify setup:

```bash
# Flutter setup
flutter doctor -v

# Firebase setup
firebase projects:list

# GCP setup
gcloud info

# Android SDK
adb devices

# iOS (macOS only)
xcrun simctl list devices
```

**Expected Output:** All checks should pass with no critical errors.

---

## 8. Manual Steps Summary

| Step | Description | Owner |
|------|-------------|-------|
| M1 | Create Firebase project in console | Developer |
| M2 | Configure Android Studio SDK Tools | Developer |
| M3 | Accept Xcode license and configure | Developer |
| M4 | Set up GCP billing account | Project Lead |
| M5 | Create OAuth credentials in GCP Console | Developer |
| M6 | Configure iOS signing certificates | Developer |
| M7 | Set up Android keystore for signing | Developer |

---

## Next Steps
Proceed to [02-architecture-design.md](./02-architecture-design.md) for system architecture details.