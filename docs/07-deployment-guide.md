# Deployment Guide

## Overview
This document provides comprehensive deployment instructions for "What's My Share" application, covering both mobile app distribution and GCP backend services.

---

## 1. Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEPLOYMENT PIPELINE                                │
│                                                                              │
│   ┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐     │
│   │   Local    │───►│   GitHub   │───►│   CI/CD    │───►│  Staging   │     │
│   │    Dev     │    │    Repo    │    │  Pipeline  │    │   Deploy   │     │
│   └────────────┘    └────────────┘    └────────────┘    └─────┬──────┘     │
│                                                                │             │
│                                                         ┌──────▼──────┐     │
│                                                         │   Manual    │     │
│                                                         │  Approval   │     │
│                                                         └──────┬──────┘     │
│                                                                │             │
│   ┌────────────┐    ┌────────────┐    ┌────────────┐    ┌─────▼──────┐     │
│   │   Users    │◄───│ App Stores │◄───│   Release  │◄───│ Production │     │
│   │            │    │            │    │   Build    │    │   Deploy   │     │
│   └────────────┘    └────────────┘    └────────────┘    └────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Environment Configuration

### 2.1 Environment Types

| Environment | Purpose | GCP Project ID | Firebase Project |
|-------------|---------|----------------|------------------|
| Development | Local testing | whatsmyshare-dev | whatsmyshare-dev |
| Staging | QA & testing | whatsmyshare-staging | whatsmyshare-staging |
| Production | Live users | whatsmyshare-prod | whatsmyshare-prod |

### 2.2 Environment Configuration Files

```
config/
├── dev/
│   ├── firebase_options.dart
│   ├── google-services.json (Android)
│   └── GoogleService-Info.plist (iOS)
├── staging/
│   ├── firebase_options.dart
│   ├── google-services.json
│   └── GoogleService-Info.plist
└── prod/
    ├── firebase_options.dart
    ├── google-services.json
    └── GoogleService-Info.plist
```

### 2.3 Build Flavors Setup

```dart
// lib/core/config/environment.dart
enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static Environment current = Environment.dev;
  
  static String get apiBaseUrl {
    switch (current) {
      case Environment.dev:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://api-staging.whatsmyshare.com';
      case Environment.prod:
        return 'https://api.whatsmyshare.com';
    }
  }
  
  static String get firebaseProjectId {
    switch (current) {
      case Environment.dev:
        return 'whatsmyshare-dev';
      case Environment.staging:
        return 'whatsmyshare-staging';
      case Environment.prod:
        return 'whatsmyshare-prod';
    }
  }
}
```

### 2.4 Android Build Flavors

```groovy
// android/app/build.gradle
android {
    flavorDimensions "environment"
    
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "WMS Dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "WMS Staging"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "What's My Share"
        }
    }
}
```

### 2.5 iOS Build Schemes

Create separate schemes in Xcode:
- `Runner-dev`
- `Runner-staging`
- `Runner-prod`

---

## 3. GCP Backend Deployment

### 3.1 Infrastructure as Code (Terraform)

```hcl
# infrastructure/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "whatsmyshare-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  name     = "whatsmyshare-api"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/whatsmyshare-api:${var.image_tag}"
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
        
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
      }
      
      container_concurrency = 80
      timeout_seconds       = 300
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
        "autoscaling.knative.dev/minScale" = "1"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "media" {
  name          = "${var.project_id}-media"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Cloud Scheduler for Reminders
resource "google_cloud_scheduler_job" "daily_reminder" {
  name        = "daily-reminder"
  description = "Sends daily settlement reminders"
  schedule    = "0 9 * * *"  # 9 AM daily
  time_zone   = "Asia/Kolkata"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.api.status[0].url}/api/reminders/send"
    
    oidc_token {
      service_account_email = google_service_account.scheduler.email
    }
  }
}
```

### 3.2 Deploy Cloud Run Services

```bash
#!/bin/bash
# scripts/deploy-backend.sh

set -e

PROJECT_ID=$1
ENVIRONMENT=$2
IMAGE_TAG=$3

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy-backend.sh <project-id> <environment> [image-tag]"
  exit 1
fi

IMAGE_TAG=${IMAGE_TAG:-$(git rev-parse --short HEAD)}

echo "Building and deploying to $ENVIRONMENT..."

# Build Docker image
docker build -t gcr.io/$PROJECT_ID/whatsmyshare-api:$IMAGE_TAG ./backend

# Push to Container Registry
docker push gcr.io/$PROJECT_ID/whatsmyshare-api:$IMAGE_TAG

# Deploy to Cloud Run
gcloud run deploy whatsmyshare-api \
  --image gcr.io/$PROJECT_ID/whatsmyshare-api:$IMAGE_TAG \
  --platform managed \
  --region asia-south1 \
  --allow-unauthenticated \
  --set-env-vars="ENVIRONMENT=$ENVIRONMENT,PROJECT_ID=$PROJECT_ID" \
  --min-instances=1 \
  --max-instances=100 \
  --memory=512Mi \
  --cpu=1 \
  --concurrency=80 \
  --project=$PROJECT_ID

echo "Deployment complete!"
```

### 3.3 Deploy Cloud Functions

```bash
#!/bin/bash
# scripts/deploy-functions.sh

set -e

PROJECT_ID=$1
ENVIRONMENT=$2

cd functions

# Deploy all functions
firebase deploy --only functions --project=$PROJECT_ID

echo "Functions deployed!"
```

### 3.4 Firestore Security Rules Deployment

```bash
# Deploy security rules
firebase deploy --only firestore:rules --project=whatsmyshare-prod

# Deploy indexes
firebase deploy --only firestore:indexes --project=whatsmyshare-prod
```

---

## 4. Mobile App Deployment

### 4.1 Android Release Build

#### Generate Keystore (One-time, MANUAL)

```bash
# Create keystore (store securely!)
keytool -genkey -v -keystore whatsmyshare-release.keystore \
  -alias whatsmyshare \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

#### Configure Signing

```properties
# android/key.properties (DO NOT COMMIT)
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=whatsmyshare
storeFile=/path/to/whatsmyshare-release.keystore
```

```groovy
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### Build Release APK/Bundle

```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release --flavor prod -t lib/main_prod.dart

# Build APK
flutter build apk --release --flavor prod -t lib/main_prod.dart

# Output locations:
# - build/app/outputs/bundle/prodRelease/app-prod-release.aab
# - build/app/outputs/flutter-apk/app-prod-release.apk
```

### 4.2 iOS Release Build

#### Configure Signing (MANUAL)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Select Team and Bundle Identifier
5. Configure provisioning profiles

#### Build iOS Release

```bash
# Build iOS release
flutter build ios --release --flavor prod -t lib/main_prod.dart

# Archive in Xcode
open ios/Runner.xcworkspace
# Product → Archive
```

### 4.3 Fastlane Automation

#### Fastlane Setup

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Deploy to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner-prod",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Deploy to App Store"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner-prod",
      export_method: "app-store"
    )
    upload_to_app_store(
      skip_screenshots: true,
      skip_metadata: false
    )
  end
end
```

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to Play Store Internal Testing"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release",
      flavor: "prod"
    )
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/prodRelease/app-prod-release.aab"
    )
  end

  desc "Deploy to Play Store Production"
  lane :release do
    gradle(
      task: "bundle",
      build_type: "Release",
      flavor: "prod"
    )
    upload_to_play_store(
      track: "production",
      aab: "../build/app/outputs/bundle/prodRelease/app-prod-release.aab"
    )
  end
end
```

---

## 5. CI/CD Pipeline

### 5.1 GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

env:
  FLUTTER_VERSION: '3.24.0'
  JAVA_VERSION: '17'

jobs:
  # Build and test first
  test:
    uses: ./.github/workflows/test.yml

  # Deploy backend
  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    
    steps:
      - uses: actions/checkout@v3
      
      - id: auth
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - uses: google-github-actions/setup-gcloud@v1
      
      - name: Deploy to Cloud Run
        run: |
          ./scripts/deploy-backend.sh \
            ${{ vars.GCP_PROJECT_ID }} \
            ${{ github.event.inputs.environment || 'staging' }} \
            ${{ github.sha }}
      
      - name: Deploy Cloud Functions
        run: |
          npm install -g firebase-tools
          firebase deploy --only functions --project=${{ vars.GCP_PROJECT_ID }}

  # Build Android
  build-android:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: ${{ env.JAVA_VERSION }}
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
      
      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 -d > android/whatsmyshare.keystore
      
      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=whatsmyshare" >> android/key.properties
          echo "storeFile=whatsmyshare.keystore" >> android/key.properties
      
      - name: Build App Bundle
        run: flutter build appbundle --release --flavor prod -t lib/main_prod.dart
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/bundle/prodRelease/

  # Build iOS
  build-ios:
    needs: test
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
      
      - name: Install certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_P12_BASE64 }}
          p12-password: ${{ secrets.IOS_P12_PASSWORD }}
      
      - name: Install provisioning profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISIONING_PROFILE }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
      
      - name: Build iOS
        run: flutter build ios --release --flavor prod -t lib/main_prod.dart --no-codesign
      
      - name: Archive
        run: |
          cd ios
          xcodebuild -workspace Runner.xcworkspace \
            -scheme Runner-prod \
            -configuration Release \
            -archivePath $PWD/build/Runner.xcarchive \
            archive
      
      - name: Export IPA
        run: |
          cd ios
          xcodebuild -exportArchive \
            -archivePath $PWD/build/Runner.xcarchive \
            -exportPath $PWD/build/ipa \
            -exportOptionsPlist ExportOptions.plist
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: ios-release
          path: ios/build/ipa/

  # Deploy to stores
  deploy-stores:
    needs: [build-android, build-ios, deploy-backend]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    environment: production
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Download Android artifact
        uses: actions/download-artifact@v3
        with:
          name: android-release
          path: android-release/
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SA }}
          packageName: com.whatsmyshare.app
          releaseFiles: android-release/app-prod-release.aab
          track: production
          status: completed

      - name: Download iOS artifact  
        uses: actions/download-artifact@v3
        with:
          name: ios-release
          path: ios-release/
      
      - name: Upload to App Store Connect
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: ios-release/Runner.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

---

## 6. App Store Submission

### 6.1 Google Play Store

#### Pre-submission Checklist (MANUAL)

- [ ] Create developer account ($25 one-time fee)
- [ ] Create app listing in Play Console
- [ ] Prepare store listing:
  - [ ] App name: "What's My Share - Split Bills"
  - [ ] Short description (80 chars)
  - [ ] Full description (4000 chars)
  - [ ] Screenshots (phone + tablet)
  - [ ] Feature graphic (1024x500)
  - [ ] App icon (512x512)
- [ ] Complete content rating questionnaire
- [ ] Set up pricing (Free)
- [ ] Configure target audience and content
- [ ] Privacy policy URL
- [ ] Data safety section

#### Play Store Metadata

```yaml
# fastlane/metadata/android/en-IN/
title.txt: "What's My Share - Split Bills"
short_description.txt: "Split expenses easily with friends. Track who owes whom."
full_description.txt: |
  What's My Share makes splitting bills with friends and family effortless!
  
  ✨ KEY FEATURES:
  • Create groups for trips, home, or couples
  • Add expenses with multiple split options
  • Track who owes whom with smart balances
  • Simplify debts to minimize payments
  • Works offline - sync when connected
  
  💰 SMART SPLITTING:
  • Equal split among participants
  • Exact amounts for each person
  • Percentage-based splitting
  • Share/ratio based division
  
  🔒 SECURE & PRIVATE:
  • Bank-grade encryption
  • Biometric protection for large payments
  • Your data stays private
  
  📱 INDIAN MARKET FOCUSED:
  • Amounts in ₹ (INR)
  • UPI payment support
  • Works on 4G networks
  
  Download now and never argue about money again!

changelogs/
  default.txt: "Initial release"
```

### 6.2 Apple App Store

#### Pre-submission Checklist (MANUAL)

- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create App ID in Developer Portal
- [ ] Create app in App Store Connect
- [ ] Prepare app information:
  - [ ] App name
  - [ ] Subtitle
  - [ ] Description
  - [ ] Keywords
  - [ ] Screenshots (iPhone 6.7", 6.5", 5.5", iPad)
  - [ ] App icon (1024x1024)
- [ ] Privacy policy URL
- [ ] App privacy details
- [ ] Age rating
- [ ] Pricing (Free)
- [ ] Review notes

#### App Store Metadata

```yaml
# fastlane/metadata/en-IN/
name.txt: "What's My Share"
subtitle.txt: "Split Bills with Friends"
description.txt: |
  What's My Share makes splitting bills with friends and family effortless!
  
  KEY FEATURES:
  • Create groups for trips, home expenses, or couples
  • Add expenses with flexible splitting options
  • Track balances - know who owes whom
  • Simplify debts to minimize transactions
  • Works offline - perfect for travel
  
  SMART EXPENSE SPLITTING:
  • Equal split among all participants
  • Specify exact amounts per person
  • Percentage-based splitting
  • Ratio/share based division
  
  BUILT FOR INDIA:
  • Amounts in ₹ (INR)
  • UPI payment tracking
  • Works great on 4G
  
  SECURE:
  • End-to-end encryption
  • Face ID/Touch ID for large settlements
  • Your financial data stays private
  
  Download now and split expenses the smart way!

keywords.txt: "split,bills,expenses,money,friends,group,travel,settle,debt,share"
privacy_url.txt: "https://whatsmyshare.com/privacy"
support_url.txt: "https://whatsmyshare.com/support"
```

---

## 7. Monitoring & Alerts

### 7.1 GCP Monitoring Setup

```yaml
# monitoring/alert-policies.yaml
alertPolicies:
  - displayName: "High Error Rate"
    conditions:
      - displayName: "Error rate > 1%"
        conditionThreshold:
          filter: 'resource.type="cloud_run_revision" AND metric.type="run.googleapis.com/request_count"'
          aggregations:
            - alignmentPeriod: "60s"
              perSeriesAligner: ALIGN_RATE
          comparison: COMPARISON_GT
          thresholdValue: 0.01
    notificationChannels:
      - "projects/whatsmyshare-prod/notificationChannels/email-ops"
    alertStrategy:
      autoClose: "604800s"

  - displayName: "High Latency"
    conditions:
      - displayName: "P99 latency > 1s"
        conditionThreshold:
          filter: 'resource.type="cloud_run_revision" AND metric.type="run.googleapis.com/request_latencies"'
          aggregations:
            - alignmentPeriod: "60s"
              perSeriesAligner: ALIGN_PERCENTILE_99
          comparison: COMPARISON_GT
          thresholdValue: 1000
```

### 7.2 Firebase Crashlytics Setup

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const MyApp());
}
```

### 7.3 Uptime Monitoring

```bash
# Create uptime check
gcloud monitoring uptime-checks create whatsmyshare-api \
  --display-name="API Health Check" \
  --uri="https://api.whatsmyshare.com/health" \
  --http-check-request-method=GET \
  --period=60s \
  --timeout=10s
```

---

## 8. Rollback Procedures

### 8.1 Backend Rollback

```bash
#!/bin/bash
# scripts/rollback-backend.sh

REVISION=$1

if [ -z "$REVISION" ]; then
  # List available revisions
  gcloud run revisions list --service=whatsmyshare-api --region=asia-south1
  echo "Usage: ./rollback-backend.sh <revision-name>"
  exit 1
fi

# Rollback to specific revision
gcloud run services update-traffic whatsmyshare-api \
  --to-revisions=$REVISION=100 \
  --region=asia-south1

echo "Rolled back to $REVISION"
```

### 8.2 App Rollback

For mobile apps, rollback requires publishing a new version with the previous code. Keep tagged releases for quick rollback:

```bash
# Checkout previous release
git checkout v1.0.0

# Build and deploy
./scripts/build-release.sh
```

---

## 9. Post-Deployment Verification

### 9.1 Smoke Tests

```bash
#!/bin/bash
# scripts/smoke-test.sh

BASE_URL=$1
echo "Running smoke tests against $BASE_URL"

# Health check
echo "Testing health endpoint..."
curl -f "$BASE_URL/health" || exit 1

# Auth endpoint
echo "Testing auth endpoint..."
curl -f "$BASE_URL/auth/verify" || exit 1

# API version
echo "Testing API version..."
VERSION=$(curl -s "$BASE_URL/version" | jq -r '.version')
echo "API Version: $VERSION"

echo "All smoke tests passed!"
```

### 9.2 Deployment Checklist

| Step | Staging | Production |
|------|---------|------------|
| Backend deployed | ✓ | ✓ |
| Cloud Functions deployed | ✓ | ✓ |
| Security rules updated | ✓ | ✓ |
| Smoke tests passed | ✓ | ✓ |
| App uploaded to store | ✓ | ✓ |
| Monitoring alerts configured | ✓ | ✓ |
| Rollback plan documented | ✓ | ✓ |

---

## Next Steps
Proceed to [08-manual-steps-summary.md](./08-manual-steps-summary.md) for a complete list of manual configuration steps.