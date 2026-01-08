# What's My Share - Development Plan

A comprehensive bill-splitting mobile application built with Flutter and Google Cloud Platform, designed for the Indian market with global scalability in mind.

## 📱 App Overview

**What's My Share** is a Splitwise-like application that helps friends and groups split expenses easily. The app supports multiple splitting strategies, offline functionality, and smart debt simplification.

### Key Features

- 👥 **Group Management** - Create groups for trips, home expenses, couples, etc.
- 💰 **Smart Expense Splitting** - Equal, exact, percentage, or ratio-based splits
- 🔄 **Multi-payer Support** - Handle bills paid by multiple people
- 📊 **Debt Simplification** - Minimize transactions with smart algorithms
- 💬 **Expense Chat** - Discuss specific expenses with attachments
- 📱 **Offline Support** - Full functionality even without internet
- 🔒 **Biometric Security** - Extra protection for large settlements
- 🇮🇳 **India-First** - INR support, UPI tracking, optimized for 4G

---

## 📁 Project Structure

```
WhatsMyShare/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore rules
├── docs/                        # Planning documentation
│   ├── 01-development-environment-setup.md
│   ├── 02-architecture-design.md
│   ├── 03-database-schema.md
│   ├── 04-implementation-roadmap.md
│   ├── 05-feature-implementation-guide.md
│   ├── 06-testing-strategy.md
│   ├── 07-deployment-guide.md
│   └── 08-manual-steps-summary.md
├── firestore-database/          # Database configuration
│   ├── firestore.rules          # Security rules
│   └── firestore.indexes.json   # Index definitions
```

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
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: GoRouter
- **Local Storage**: Hive, SharedPreferences
- **Architecture**: Clean Architecture

### Backend
- **Platform**: Google Cloud Platform (GCP)
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Functions**: Cloud Functions (Node.js)
- **Compute**: Cloud Run
- **Storage**: Cloud Storage
- **Messaging**: Firebase Cloud Messaging (FCM)

### DevOps
- **CI/CD**: GitHub Actions
- **Monitoring**: Firebase Crashlytics, Cloud Monitoring
- **Distribution**: Fastlane

---

## 🗓️ Timeline Overview

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 1: Foundation** | Weeks 1-3 | Setup, Auth, Navigation |
| **Phase 2: Core Features** | Weeks 4-8 | Groups, Expenses, Friends |
| **Phase 3: Advanced** | Weeks 9-12 | Settlements, Notifications, Chat |
| **Phase 4: Polish** | Weeks 13-14 | Offline, Testing, Performance |
| **Phase 5: Launch** | Weeks 15-16 | Beta, Store Submission |

**Total Duration**: 16 weeks (~4 months)

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
- GCP Account
- Apple Developer Account ($99/year)
- Google Play Developer Account ($25 one-time)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/avtansh-code/WhatsMyShare.git
   cd WhatsMyShare
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=your-project-id
   ```

4. **Run the app**
   ```bash
   # Development
   flutter run --flavor dev -t lib/main_dev.dart
   
   # Production
   flutter run --flavor prod -t lib/main_prod.dart
   ```

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
- [ ] All P0 features complete
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

*This README was generated as part of the development planning phase. Update as the project evolves.*