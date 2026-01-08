# Manual Steps Summary

## Overview
This document consolidates all manual steps required during the development and deployment of "What's My Share" application. These steps cannot be automated and require human intervention.

---

## Quick Reference

| Phase | Manual Steps | Time Estimate |
|-------|--------------|---------------|
| Environment Setup | 12 steps | 8-10 hours |
| GCP/Firebase Setup | 15 steps | 4-6 hours |
| Development | 5 steps | 2-3 hours |
| Store Setup | 18 steps | 6-8 hours |
| Launch | 8 steps | 4-6 hours |
| **Total** | **58 steps** | **24-33 hours** |

---

## 1. Development Environment Setup

### 1.1 macOS Development Machine

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M1 | Install Xcode | Download from App Store, open to complete setup | Dev | 1 hour |
| M2 | Accept Xcode License | Run `sudo xcodebuild -license accept` | Dev | 5 min |
| M3 | Configure Xcode CLI | Open Xcode → Preferences → Locations → Command Line Tools | Dev | 5 min |
| M4 | Install Android Studio | Download and run installer | Dev | 30 min |
| M5 | Configure Android SDK | SDK Manager → Install required SDK versions | Dev | 30 min |
| M6 | Create Android Emulator | AVD Manager → Create Virtual Device | Dev | 15 min |
| M7 | Install VS Code Extensions | Install Flutter, Dart, and recommended extensions | Dev | 15 min |

### 1.2 GCP Authentication

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M8 | Create GCP Account | Sign up at console.cloud.google.com | Lead | 15 min |
| M9 | Set Up Billing | Add payment method, set billing alerts | Lead | 30 min |
| M10 | Install gcloud CLI | Run `gcloud init` and authenticate | Dev | 15 min |
| M11 | Authenticate ADC | Run `gcloud auth application-default login` | Dev | 5 min |
| M12 | Install Firebase CLI | Run `npm install -g firebase-tools && firebase login` | Dev | 10 min |

---

## 2. GCP & Firebase Project Setup

### 2.1 Firebase Console Configuration

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M13 | Create Firebase Project | console.firebase.google.com → Add Project | Dev | 15 min |
| M14 | Enable Authentication | Authentication → Sign-in method → Enable Email/Password | Dev | 10 min |
| M15 | Enable Google Sign-In | Authentication → Sign-in method → Enable Google | Dev | 15 min |
| M16 | Configure OAuth Consent | GCP Console → APIs & Services → OAuth consent screen | Dev | 30 min |
| M17 | Create OAuth Credentials | GCP Console → Credentials → Create OAuth 2.0 Client ID | Dev | 20 min |
| M18 | Initialize Firestore | Firestore → Create database → Select region (asia-south1) | Dev | 10 min |
| M19 | Set Firestore Mode | Select "Native mode" (not Datastore mode) | Dev | 5 min |
| M20 | Enable Cloud Storage | Storage → Get started → Set rules | Dev | 10 min |

### 2.2 Firebase App Registration

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M21 | Register Android App | Project Settings → Add app → Android | Dev | 15 min |
| M22 | Download google-services.json | Download and place in android/app/ | Dev | 5 min |
| M23 | Register iOS App | Project Settings → Add app → iOS | Dev | 15 min |
| M24 | Download GoogleService-Info.plist | Download and add to Xcode project | Dev | 10 min |
| M25 | Configure SHA Certificates | Project Settings → Android app → Add SHA-1 and SHA-256 | Dev | 15 min |

### 2.3 GCP Service Configuration

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M26 | Enable FCM | Firebase Console → Cloud Messaging → Enable | Dev | 5 min |
| M27 | Create Service Account | GCP Console → IAM → Service Accounts → Create | Dev | 15 min |
| M28 | Download Service Account Key | Generate JSON key (store securely!) | Dev | 5 min |

---

## 3. iOS Development Setup

### 3.1 Apple Developer Account

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M29 | Enroll in Apple Developer Program | developer.apple.com ($99/year) | Lead | 1-2 days |
| M30 | Create App ID | Certificates, Identifiers & Profiles → Identifiers | Dev | 15 min |
| M31 | Enable Capabilities | Push Notifications, Sign in with Apple, etc. | Dev | 20 min |
| M32 | Create Development Certificate | Certificates → Development → iOS App Development | Dev | 20 min |
| M33 | Create Distribution Certificate | Certificates → Production → App Store | Dev | 20 min |
| M34 | Create Provisioning Profiles | Development + Distribution profiles | Dev | 30 min |
| M35 | Configure Xcode Signing | Select Team, enable automatic signing or manual | Dev | 15 min |

### 3.2 Push Notification Setup

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M36 | Create APNs Key | Certificates → Keys → Create APNs Auth Key | Dev | 15 min |
| M37 | Upload to Firebase | Project Settings → Cloud Messaging → APNs Authentication Key | Dev | 10 min |

---

## 4. Android Release Setup

### 4.1 Keystore Management

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M38 | Generate Release Keystore | `keytool -genkey ...` (store password securely!) | Dev | 15 min |
| M39 | Backup Keystore | Store in secure location (cannot be recreated) | Lead | 15 min |
| M40 | Create key.properties | Configure signing in android/key.properties | Dev | 10 min |

### 4.2 Google Play Console

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M41 | Create Developer Account | play.google.com/console ($25 one-time) | Lead | 1-2 days |
| M42 | Create App Listing | All apps → Create app | Dev | 30 min |
| M43 | Complete Store Listing | App name, description, screenshots, graphics | Marketing | 2-3 hours |
| M44 | Content Rating | Fill content rating questionnaire | Dev | 30 min |
| M45 | Privacy Policy | Create and host privacy policy, add URL | Legal | 2 hours |
| M46 | Data Safety Section | Complete data collection declarations | Dev | 1 hour |
| M47 | Set Up App Signing | Let Google manage signing OR upload your key | Dev | 20 min |

---

## 5. App Store Connect Setup

### 5.1 App Configuration

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M48 | Create App in App Store Connect | My Apps → + → New App | Dev | 30 min |
| M49 | Complete App Information | Name, subtitle, primary category, age rating | Marketing | 1 hour |
| M50 | Prepare Screenshots | iPhone 6.7", 6.5", 5.5", iPad screenshots | Design | 4-6 hours |
| M51 | Write App Description | Description, keywords, promotional text | Marketing | 2 hours |
| M52 | Set Up Privacy Details | App privacy → Complete all sections | Legal | 1 hour |
| M53 | Add Review Notes | Instructions for App Review team | Dev | 30 min |

---

## 6. Pre-Launch

### 6.1 Testing Setup

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M54 | Create TestFlight Group | App Store Connect → TestFlight → Groups | Dev | 15 min |
| M55 | Add Beta Testers | Invite internal and external testers | QA | 30 min |
| M56 | Create Play Store Testing Track | Play Console → Testing → Internal testing | Dev | 15 min |

### 6.2 Final Checks

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M57 | Security Audit | Review security configurations, penetration test | Security | 4-8 hours |
| M58 | Accessibility Audit | Test with TalkBack/VoiceOver, verify contrast | QA | 4 hours |

---

## 7. Launch

### 7.1 Store Submission

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M59 | Submit to App Store | Upload build, submit for review | Dev | 1 hour |
| M60 | Submit to Play Store | Upload AAB, roll out to production | Dev | 1 hour |
| M61 | Monitor Review Status | Check for rejections, respond to inquiries | Dev | 1-7 days |

### 7.2 Post-Launch

| # | Step | Details | Owner | Time |
|---|------|---------|-------|------|
| M62 | Monitor Crashlytics | Check for crashes in first 24 hours | Dev | Ongoing |
| M63 | Monitor Store Reviews | Respond to user reviews | Support | Ongoing |
| M64 | Set Up Support Channels | Email, in-app support, FAQ page | Support | 4 hours |

---

## 8. Detailed Instructions for Critical Steps

### 8.1 Creating OAuth Credentials (M17)

1. Go to [GCP Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to APIs & Services → Credentials
4. Click "Create Credentials" → "OAuth 2.0 Client ID"
5. For Android:
   - Select "Android"
   - Enter package name: `com.whatsmyshare.app`
   - Get SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Add SHA-1 fingerprint
6. For iOS:
   - Select "iOS"
   - Enter Bundle ID: `com.whatsmyshare.app`
7. Save the Client IDs for app configuration

### 8.2 Generating Android Keystore (M38)

```bash
# Generate keystore
keytool -genkey -v \
  -keystore whatsmyshare-release.keystore \
  -alias whatsmyshare \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# You will be prompted for:
# - Keystore password (remember this!)
# - Key password (can be same as keystore)
# - Name, Organization, Location info

# Get SHA-1 and SHA-256 for Firebase
keytool -list -v \
  -keystore whatsmyshare-release.keystore \
  -alias whatsmyshare

# IMPORTANT: Backup the keystore file securely!
# If lost, you cannot update your app on Play Store
```

### 8.3 iOS Signing Setup (M35)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project in the navigator
3. Select the Runner target
4. Go to "Signing & Capabilities" tab
5. Check "Automatically manage signing" (recommended for simplicity)
6. Select your Team from the dropdown
7. Xcode will create and manage provisioning profiles
8. For release builds:
   - Ensure Distribution certificate is installed
   - For manual signing, select appropriate provisioning profile

### 8.4 Firebase Cloud Messaging iOS Setup (M36-M37)

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Go to Keys → Create new Key
4. Enable "Apple Push Notifications service (APNs)"
5. Download the .p8 key file (save it securely!)
6. Note the Key ID
7. Go to Firebase Console → Project Settings → Cloud Messaging
8. Under "Apple app configuration", click "Upload" next to APNs Authentication Key
9. Upload the .p8 file, enter Key ID and Team ID

### 8.5 Play Store Data Safety Section (M46)

Answer these questions in Play Console:

| Question | Typical Answer for This App |
|----------|----------------------------|
| Does your app collect data? | Yes |
| Is data encrypted in transit? | Yes |
| Can users request data deletion? | Yes |
| Data types collected | Email, name, photos (optional), financial transactions |
| Purpose of collection | Account management, app functionality |
| Is data shared? | No (unless user explicitly shares) |

---

## 9. Secrets & Credentials Checklist

### 9.1 Secrets to Generate and Store Securely

| Secret | Location | Backup Required |
|--------|----------|-----------------|
| Android Keystore | Secure vault | Yes (CRITICAL) |
| Keystore password | Password manager | Yes (CRITICAL) |
| iOS Distribution Certificate | Keychain | Yes |
| iOS APNs Key (.p8) | Password manager | Yes |
| Firebase Service Account JSON | GCP Secret Manager | Yes |
| GCP OAuth Client Secrets | GCP Secret Manager | No (can regenerate) |

### 9.2 CI/CD Secrets to Configure

For GitHub Actions (Settings → Secrets):

| Secret Name | Value |
|-------------|-------|
| `GCP_SA_KEY` | Service account JSON (base64) |
| `ANDROID_KEYSTORE` | Keystore file (base64) |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `IOS_P12_BASE64` | iOS certificate (base64) |
| `IOS_P12_PASSWORD` | Certificate password |
| `IOS_PROVISIONING_PROFILE` | Profile (base64) |
| `PLAY_STORE_SA` | Play Store service account JSON |
| `APPSTORE_API_KEY_ID` | App Store Connect API Key ID |
| `APPSTORE_API_PRIVATE_KEY` | App Store Connect private key |
| `APPSTORE_ISSUER_ID` | App Store Connect Issuer ID |

---

## 10. Timeline for Manual Steps

### Week 1: Setup (Day 1-5)
- [ ] Day 1: Create developer accounts (Apple, Google, GCP)
- [ ] Day 1-2: Development environment setup
- [ ] Day 2-3: Firebase/GCP project configuration
- [ ] Day 4: iOS certificates and profiles
- [ ] Day 5: Android keystore and signing

### Week 15: Pre-Launch (Day 1-5)
- [ ] Day 1-2: Complete store listings (screenshots, descriptions)
- [ ] Day 2: Privacy policy and data safety
- [ ] Day 3: Content ratings and age ratings
- [ ] Day 4: TestFlight and internal testing setup
- [ ] Day 5: Beta tester invitations

### Week 16: Launch (Day 1-7)
- [ ] Day 1: Final security and accessibility audits
- [ ] Day 2: Submit to App Store
- [ ] Day 2: Submit to Play Store
- [ ] Day 3-7: Monitor review, respond to rejections
- [ ] Day 7: Launch and monitoring

---

## 11. Troubleshooting Common Issues

### Issue: App Store Rejection

| Rejection Reason | Solution |
|------------------|----------|
| Missing privacy policy | Add privacy policy URL |
| Incomplete metadata | Fill all required fields |
| Guideline 4.2 (Minimum Functionality) | Ensure app has sufficient features |
| Guideline 2.1 (Crashes) | Test thoroughly, fix crash before resubmit |

### Issue: Google Sign-In Not Working

1. Verify SHA-1 fingerprint in Firebase Console
2. Check OAuth consent screen is configured
3. Ensure `google-services.json` is updated
4. Check package name matches exactly

### Issue: Push Notifications Not Received

1. iOS: Verify APNs key is uploaded to Firebase
2. Android: Verify google-services.json has correct project
3. Check notification permissions are granted
4. Verify FCM token is being registered correctly

---

## Summary

This manual steps summary identifies 58 distinct manual tasks required to launch "What's My Share". The estimated total time is 24-33 hours of manual work, spread across the development timeline.

**Key Recommendations:**
1. Start account setup (Apple, Google) early - approval can take days
2. Never lose the Android keystore - it's irreplaceable
3. Document all secrets securely before they're needed
4. Allow buffer time for store review (1-7 days)
5. Have rollback plan ready before launch

---

## Document Index

| Document | Description |
|----------|-------------|
| [01-development-environment-setup.md](./01-development-environment-setup.md) | Development tools and setup |
| [02-architecture-design.md](./02-architecture-design.md) | System architecture |
| [03-database-schema.md](./03-database-schema.md) | Firestore schema design |
| [04-implementation-roadmap.md](./04-implementation-roadmap.md) | Timeline and milestones |
| [05-feature-implementation-guide.md](./05-feature-implementation-guide.md) | Feature specifications |
| [06-testing-strategy.md](./06-testing-strategy.md) | Testing approach |
| [07-deployment-guide.md](./07-deployment-guide.md) | Deployment instructions |
| [08-manual-steps-summary.md](./08-manual-steps-summary.md) | This document |