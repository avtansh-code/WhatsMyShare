# Architecture Design

## Overview
This document describes the system architecture for "What's My Share" - a scalable, maintainable bill-splitting application built with Flutter and Google Cloud Platform.

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Flutter Mobile App                                │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │   UI     │ │  State   │ │ Offline  │ │  Local   │ │ Biometric│  │   │
│  │  │  Layer   │ │  Mgmt    │ │  Cache   │ │   DB     │ │   Auth   │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTPS/WSS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Firebase Authentication                            │   │
│  │              (JWT Token Validation, Rate Limiting)                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BACKEND SERVICES                                   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │  User        │ │  Group       │ │  Expense     │ │  Settlement  │       │
│  │  Service     │ │  Service     │ │  Service     │ │  Service     │       │
│  │  (Cloud Run) │ │  (Cloud Run) │ │  (Cloud Run) │ │  (Cloud Run) │       │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │  Notification│ │  Sync        │ │  Analytics   │ │  Simplify    │       │
│  │  Service     │ │  Service     │ │  Service     │ │  Debt Algo   │       │
│  │  (Functions) │ │  (Functions) │ │  (Functions) │ │  (Cloud Run) │       │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │   Cloud      │ │   Cloud      │ │   Cloud      │ │   BigQuery   │       │
│  │   Firestore  │ │   Storage    │ │   Memorystore│ │   (Analytics)│       │
│  │   (Primary)  │ │   (Files)    │ │   (Cache)    │ │              │       │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter App Architecture

### 2.1 Clean Architecture Pattern

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── firebase_config.dart
│   │   └── theme_config.dart
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── network_info.dart
│   │   └── api_client.dart
│   ├── utils/
│   │   ├── decimal_utils.dart      # Precise financial calculations
│   │   ├── currency_utils.dart
│   │   └── date_utils.dart
│   └── di/
│       └── injection_container.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   ├── groups/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── expenses/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── settlements/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── friends/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── notifications/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── services/
└── l10n/
    ├── app_en.arb
    └── app_hi.arb
```

### 2.2 State Management - BLoC Pattern

```dart
// Example: ExpenseBloc
abstract class ExpenseEvent {}
class LoadExpenses extends ExpenseEvent {}
class AddExpense extends ExpenseEvent {
  final ExpenseEntity expense;
}
class SplitExpense extends ExpenseEvent {
  final String expenseId;
  final SplitStrategy strategy;
}

abstract class ExpenseState {}
class ExpenseInitial extends ExpenseState {}
class ExpenseLoading extends ExpenseState {}
class ExpenseLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;
}
class ExpenseError extends ExpenseState {
  final String message;
}
```

### 2.3 Offline-First Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Repository Layer                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Repository Implementation            │   │
│  │  - Checks connectivity                           │   │
│  │  - Prioritizes local cache                       │   │
│  │  - Syncs with remote when online                 │   │
│  └─────────────────────────────────────────────────┘   │
│           │                           │                  │
│           ▼                           ▼                  │
│  ┌─────────────────┐      ┌─────────────────────┐      │
│  │  Local Data     │      │   Remote Data       │      │
│  │  Source         │      │   Source            │      │
│  │  (Hive/SQLite)  │      │   (Firestore)       │      │
│  └─────────────────┘      └─────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

**CRDT Implementation for Offline Sync:**
- Use Firestore's built-in offline persistence
- Implement conflict resolution using Last-Write-Wins (LWW) with vector clocks
- Queue offline operations for retry on reconnection

---

## 3. Backend Architecture

### 3.1 Microservices Overview

| Service | Technology | Purpose | Scaling |
|---------|------------|---------|---------|
| User Service | Cloud Run | User management, profile | Auto-scale 0-100 |
| Group Service | Cloud Run | Group CRUD, memberships | Auto-scale 0-100 |
| Expense Service | Cloud Run | Expense management, splits | Auto-scale 0-200 |
| Settlement Service | Cloud Run | Payment tracking, simplify debt | Auto-scale 0-50 |
| Notification Service | Cloud Functions | Push notifications, FCM | Event-driven |
| Sync Service | Cloud Functions | Offline sync, conflict resolution | Event-driven |

### 3.2 Service Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    Synchronous (REST/gRPC)                   │
│                                                              │
│   Client ──► API Gateway ──► Service ──► Response           │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Asynchronous (Pub/Sub)                      │
│                                                              │
│   Service A ──► Pub/Sub Topic ──► Service B                 │
│                      │                                       │
│                      └──► Service C                          │
│                                                              │
│   Topics:                                                    │
│   - expense-created                                          │
│   - group-member-added                                       │
│   - settlement-completed                                     │
│   - notification-request                                     │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 API Design (REST)

```yaml
# Base URL: https://api.whatsmyshare.com/v1

# User Endpoints
POST   /auth/register
POST   /auth/login
GET    /users/me
PATCH  /users/me
POST   /users/me/contacts/sync

# Group Endpoints
POST   /groups
GET    /groups
GET    /groups/{groupId}
PATCH  /groups/{groupId}
DELETE /groups/{groupId}
POST   /groups/{groupId}/members
DELETE /groups/{groupId}/members/{userId}

# Expense Endpoints
POST   /expenses
GET    /expenses?groupId={groupId}
GET    /expenses/{expenseId}
PATCH  /expenses/{expenseId}
DELETE /expenses/{expenseId}
POST   /expenses/{expenseId}/split
GET    /expenses/{expenseId}/chat

# Settlement Endpoints
POST   /settlements
GET    /settlements?groupId={groupId}
GET    /settlements/simplify?groupId={groupId}
GET    /settlements/simplify/explain?groupId={groupId}

# Friend Endpoints
POST   /friends
GET    /friends
GET    /friends/{friendId}/balance
```

---

## 4. Security Architecture

### 4.1 Authentication Flow

```
┌─────────┐         ┌──────────────┐         ┌─────────────┐
│  Client │         │   Firebase   │         │   Backend   │
│   App   │         │     Auth     │         │   Services  │
└────┬────┘         └──────┬───────┘         └──────┬──────┘
     │                     │                        │
     │  1. Sign In         │                        │
     │  (Email/Google)     │                        │
     │────────────────────►│                        │
     │                     │                        │
     │  2. ID Token (JWT)  │                        │
     │◄────────────────────│                        │
     │                     │                        │
     │  3. API Request + Token                      │
     │─────────────────────────────────────────────►│
     │                     │                        │
     │                     │  4. Verify Token       │
     │                     │◄───────────────────────│
     │                     │                        │
     │                     │  5. Token Valid        │
     │                     │───────────────────────►│
     │                     │                        │
     │  6. Response                                 │
     │◄─────────────────────────────────────────────│
```

### 4.2 Security Measures

| Layer | Security Measure |
|-------|------------------|
| Transport | TLS 1.3 for all communications |
| Authentication | Firebase Auth with JWT |
| Authorization | Firestore Security Rules + Row-Level Security |
| Data at Rest | AES-256 encryption (GCP default) |
| Sensitive Actions | Biometric step-up authentication (>₹5000) |
| API | Rate limiting, input validation |
| Secrets | GCP Secret Manager |
| Audit | Cloud Audit Logs for all admin actions |

### 4.3 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Group access - only members can read/write
    match /groups/{groupId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid in resource.data.memberIds;
    }
    
    // Expenses - only group members can access
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(resource.data.groupId)) &&
        request.auth.uid in get(/databases/$(database)/documents/groups/$(resource.data.groupId)).data.memberIds;
    }
  }
}
```

---

## 5. Data Flow Diagrams

### 5.1 Add Expense Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  User    │    │  Flutter │    │  Cloud   │    │Firestore │    │  Pub/Sub │
│          │    │   App    │    │   Run    │    │          │    │          │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │               │
     │ Add Expense   │               │               │               │
     │──────────────►│               │               │               │
     │               │               │               │               │
     │               │ POST /expenses│               │               │
     │               │──────────────►│               │               │
     │               │               │               │               │
     │               │               │ Validate &    │               │
     │               │               │ Calculate     │               │
     │               │               │ Splits        │               │
     │               │               │               │               │
     │               │               │ Write Expense │               │
     │               │               │──────────────►│               │
     │               │               │               │               │
     │               │               │ Publish Event │               │
     │               │               │──────────────────────────────►│
     │               │               │               │               │
     │               │ Success       │               │               │
     │◄──────────────│◄──────────────│               │               │
     │               │               │               │               │
     │               │               │               │  Trigger      │
     │               │               │               │  Notifications│
     │               │               │               │◄──────────────│
```

### 5.2 Simplify Debt Algorithm Flow

```
Input: List of balances [(A, -100), (B, +50), (C, +50)]
       A owes 100, B is owed 50, C is owed 50

Algorithm: Greedy Settlement Minimization

1. Separate into creditors and debtors
   Debtors: [(A, -100)]
   Creditors: [(B, +50), (C, +50)]

2. Sort both lists by absolute amount (descending)

3. Match largest debtor with largest creditor
   - A pays B: min(100, 50) = 50
   - A pays C: min(50, 50) = 50

Output: 2 transactions instead of potential n*(n-1)/2
```

---

## 6. Scalability Considerations

### 6.1 Database Sharding Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Firestore Collections                     │
│                                                              │
│  /users/{userId}                    - User documents         │
│  /groups/{groupId}                  - Group documents        │
│  /groups/{groupId}/expenses/{id}    - Subcollection          │
│  /groups/{groupId}/settlements/{id} - Subcollection          │
│  /groups/{groupId}/activity/{id}    - Activity feed          │
│                                                              │
│  Benefits:                                                   │
│  - Automatic scaling per collection                          │
│  - Data locality (expenses with groups)                      │
│  - Efficient queries within groups                           │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Caching Strategy

| Data Type | Cache Location | TTL | Invalidation |
|-----------|----------------|-----|--------------|
| User Profile | Local + Memorystore | 1 hour | On update |
| Group List | Local + Memorystore | 5 minutes | On change |
| Expense List | Local | 1 minute | Real-time |
| Balances | Local | 30 seconds | On expense/settlement |
| Static Config | Local | 24 hours | App update |

---

## 7. Internationalization Architecture

### 7.1 Multi-Region Support

```
┌─────────────────────────────────────────────────────────────┐
│                    Region Configuration                      │
│                                                              │
│  India (Primary):                                           │
│  - Firestore: asia-south1 (Mumbai)                          │
│  - Cloud Run: asia-south1                                   │
│  - Storage: asia-south1                                     │
│  - Default Currency: INR                                    │
│  - Languages: en-IN, hi-IN                                  │
│                                                              │
│  Future Regions:                                            │
│  - Southeast Asia: asia-southeast1 (Singapore)              │
│  - US: us-central1                                          │
│  - Europe: europe-west1                                     │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Currency Handling

```dart
// Store amounts in smallest unit (paisa for INR)
class Money {
  final int amountInSmallestUnit;  // 10000 = ₹100.00
  final String currencyCode;       // "INR"
  
  // Conversion handled at display layer
  String get formattedAmount => 
    CurrencyFormatter.format(amountInSmallestUnit, currencyCode);
}
```

---

## 8. Monitoring & Observability

### 8.1 Logging Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Logging Architecture                      │
│                                                              │
│  Flutter App ──► Crashlytics (crashes)                      │
│              ──► Firebase Analytics (events)                │
│              ──► Cloud Logging (debug, via backend)         │
│                                                              │
│  Cloud Run   ──► Cloud Logging (structured JSON)            │
│              ──► Error Reporting (exceptions)               │
│                                                              │
│  Firestore   ──► Cloud Audit Logs (data access)             │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Key Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Latency (p99) | < 500ms | > 1s |
| Error Rate | < 0.1% | > 1% |
| App Crash Rate | < 0.1% | > 0.5% |
| Firestore Reads/sec | - | > 10,000 |
| Cloud Run Instances | 1-100 | > 80 |

---

## Next Steps
Proceed to [03-database-schema.md](./03-database-schema.md) for detailed database design.