# Database Schema Design

## Overview
This document defines the database schema for "What's My Share" using Cloud Firestore (NoSQL). The schema is designed for scalability, real-time sync, and offline-first operations.

---

## 1. Database Choice: Cloud Firestore

### 1.1 Why Firestore?

| Criteria | Firestore Advantage |
|----------|---------------------|
| Real-time sync | Built-in real-time listeners |
| Offline support | Automatic offline persistence |
| Scalability | Auto-scaling, serverless |
| GCP Integration | Native Firebase/GCP integration |
| Mobile SDKs | First-class Flutter support |
| Security | Granular security rules |

### 1.2 Design Principles

1. **Denormalization**: Duplicate data where needed for read efficiency
2. **Subcollections**: Use for large, queryable child data
3. **Composite Keys**: For efficient querying
4. **Smallest Unit Storage**: Store amounts in paisa (1/100 of INR)
5. **Timestamps**: Use server timestamps for consistency

---

## 2. Collection Structure

```
firestore-root/
├── users/
│   └── {userId}/
│       ├── [user document]
│       ├── friends/
│       │   └── {friendId}/
│       └── notifications/
│           └── {notificationId}/
├── groups/
│   └── {groupId}/
│       ├── [group document]
│       ├── expenses/
│       │   └── {expenseId}/
│       │       └── chat/
│       │           └── {messageId}/
│       ├── settlements/
│       │   └── {settlementId}/
│       └── activity/
│           └── {activityId}/
├── invitations/
│   └── {invitationId}/
└── metadata/
    └── {configId}/
```

---

## 3. Collection Schemas

### 3.1 Users Collection

**Path**: `/users/{userId}`

```typescript
interface User {
  // Identity
  id: string;                    // Firebase Auth UID
  email: string;                 // User email
  phone?: string;                // Optional phone number
  
  // Profile
  displayName: string;           // Full name
  photoUrl?: string;             // Profile picture URL (Cloud Storage)
  
  // Preferences
  defaultCurrency: string;       // "INR", "USD", etc.
  locale: string;                // "en-IN", "hi-IN"
  timezone: string;              // "Asia/Kolkata"
  
  // Settings
  notificationsEnabled: boolean;
  contactSyncEnabled: boolean;
  biometricAuthEnabled: boolean;
  
  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;
  
  // Cached Aggregates (denormalized for quick access)
  totalOwed: number;             // Amount owed to this user (in paisa)
  totalOwing: number;            // Amount this user owes (in paisa)
  groupCount: number;            // Number of active groups
  
  // Regional
  countryCode: string;           // "IN" for India
  
  // FCM Token for push notifications
  fcmTokens: string[];           // Multiple device tokens
}
```

**Indexes:**
- `email` (unique)
- `phone` (unique, sparse)
- `createdAt` (for admin queries)

---

### 3.2 Friends Subcollection

**Path**: `/users/{userId}/friends/{friendId}`

```typescript
interface Friend {
  id: string;                    // Friend's user ID
  
  // Denormalized friend info (for offline access)
  displayName: string;
  photoUrl?: string;
  email: string;
  
  // Balance (real-time updated)
  balance: number;               // Positive = friend owes you, Negative = you owe friend (in paisa)
  currency: string;              // Currency for balance
  
  // Relationship
  addedAt: Timestamp;
  addedVia: 'contact_sync' | 'manual' | 'group' | 'invitation';
  
  // Status
  status: 'active' | 'blocked';
}
```

---

### 3.3 Groups Collection

**Path**: `/groups/{groupId}`

```typescript
interface Group {
  id: string;                    // Auto-generated
  
  // Basic Info
  name: string;                  // "Trip to Goa"
  description?: string;
  imageUrl?: string;             // Group cover image
  
  // Type
  type: 'trip' | 'home' | 'couple' | 'other';
  
  // Members (embedded for quick access, max ~50 members)
  members: GroupMember[];
  memberIds: string[];           // Array of user IDs (for security rules)
  memberCount: number;
  
  // Settings
  currency: string;              // Default currency for group
  simplifyDebts: boolean;        // Auto-simplify enabled
  
  // Ownership
  createdBy: string;             // User ID of creator
  admins: string[];              // User IDs with admin rights
  
  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  
  // Cached Totals (denormalized)
  totalExpenses: number;         // Total expense amount (in paisa)
  expenseCount: number;
  lastActivityAt: Timestamp;
  
  // Balances (pre-calculated for each member)
  balances: {
    [userId: string]: number;    // Balance for each member (in paisa)
  };
  
  // Simplified debts (if enabled)
  simplifiedDebts?: SimplifiedDebt[];
}

interface GroupMember {
  userId: string;
  displayName: string;
  photoUrl?: string;
  email: string;
  joinedAt: Timestamp;
  role: 'admin' | 'member';
}

interface SimplifiedDebt {
  from: string;                  // User ID who owes
  to: string;                    // User ID who is owed
  amount: number;                // Amount in paisa
}
```

**Indexes:**
- `memberIds` (array-contains for user's groups)
- `createdAt` (for sorting)
- `lastActivityAt` (for sorting)
- Composite: `memberIds` + `lastActivityAt`

---

### 3.4 Expenses Subcollection

**Path**: `/groups/{groupId}/expenses/{expenseId}`

```typescript
interface Expense {
  id: string;                    // Auto-generated
  groupId: string;               // Parent group ID
  
  // Basic Info
  description: string;           // "Dinner at restaurant"
  amount: number;                // Total amount in paisa
  currency: string;
  
  // Categorization
  category: ExpenseCategory;
  
  // Date
  date: Timestamp;               // When expense occurred
  createdAt: Timestamp;          // When record created
  updatedAt: Timestamp;
  
  // Payers (supports multi-payer)
  paidBy: PayerInfo[];
  
  // Split Details
  splitType: 'equal' | 'exact' | 'percentage' | 'shares';
  splits: ExpenseSplit[];
  
  // Attachments
  receiptUrls?: string[];        // Cloud Storage URLs
  notes?: string;
  
  // Metadata
  createdBy: string;             // User ID who added
  
  // Status
  status: 'active' | 'deleted';
  deletedAt?: Timestamp;
  deletedBy?: string;
  
  // Chat (count for UI)
  chatMessageCount: number;
}

type ExpenseCategory = 
  | 'food'
  | 'transport'
  | 'accommodation'
  | 'shopping'
  | 'entertainment'
  | 'utilities'
  | 'groceries'
  | 'health'
  | 'education'
  | 'other';

interface PayerInfo {
  userId: string;
  displayName: string;           // Denormalized
  amount: number;                // Amount paid by this user (in paisa)
}

interface ExpenseSplit {
  userId: string;
  displayName: string;           // Denormalized
  amount: number;                // Amount owed by this user (in paisa)
  percentage?: number;           // If percentage split
  shares?: number;               // If shares/ratio split
  isPaid: boolean;               // Settled or not
  paidAt?: Timestamp;
}
```

**Indexes:**
- `groupId` + `date` (for sorting within group)
- `groupId` + `status` + `date`
- `createdBy` (for user's expense history)
- `category` + `date`

---

### 3.5 Expense Chat Subcollection

**Path**: `/groups/{groupId}/expenses/{expenseId}/chat/{messageId}`

```typescript
interface ExpenseMessage {
  id: string;
  expenseId: string;
  
  // Sender
  senderId: string;
  senderName: string;            // Denormalized
  senderPhotoUrl?: string;
  
  // Content
  type: 'text' | 'image' | 'voice' | 'system';
  text?: string;
  mediaUrl?: string;             // For image/voice
  mediaDuration?: number;        // For voice (seconds)
  
  // Metadata
  createdAt: Timestamp;
  
  // Status
  isEdited: boolean;
  editedAt?: Timestamp;
}
```

---

### 3.6 Settlements Subcollection

**Path**: `/groups/{groupId}/settlements/{settlementId}`

```typescript
interface Settlement {
  id: string;
  groupId: string;
  
  // Parties
  fromUserId: string;            // Who is paying
  fromUserName: string;          // Denormalized
  toUserId: string;              // Who is receiving
  toUserName: string;            // Denormalized
  
  // Amount
  amount: number;                // In paisa
  currency: string;
  
  // Status
  status: 'pending' | 'confirmed' | 'rejected';
  
  // Payment Method (optional)
  paymentMethod?: 'cash' | 'upi' | 'bank_transfer' | 'other';
  paymentReference?: string;     // UPI transaction ID, etc.
  
  // Verification
  requiresBiometric: boolean;    // True if amount > threshold
  biometricVerified: boolean;
  
  // Metadata
  createdAt: Timestamp;
  confirmedAt?: Timestamp;
  confirmedBy?: string;
  
  // Notes
  notes?: string;
}
```

**Indexes:**
- `groupId` + `createdAt`
- `fromUserId` + `createdAt`
- `toUserId` + `createdAt`
- `status` + `createdAt`

---

### 3.7 Activity Feed Subcollection

**Path**: `/groups/{groupId}/activity/{activityId}`

```typescript
interface ActivityItem {
  id: string;
  groupId: string;
  
  // Activity Type
  type: ActivityType;
  
  // Actor
  actorId: string;
  actorName: string;
  
  // Target (optional)
  targetId?: string;             // Expense ID, Settlement ID, User ID
  targetType?: 'expense' | 'settlement' | 'member';
  
  // Description
  title: string;                 // "John added an expense"
  description?: string;          // "Dinner at Pizza Hut - ₹1,500"
  
  // Metadata
  createdAt: Timestamp;
  
  // Amount (if relevant)
  amount?: number;
  currency?: string;
}

type ActivityType = 
  | 'expense_added'
  | 'expense_updated'
  | 'expense_deleted'
  | 'settlement_created'
  | 'settlement_confirmed'
  | 'member_added'
  | 'member_removed'
  | 'group_created'
  | 'group_updated';
```

---

### 3.8 Notifications Subcollection

**Path**: `/users/{userId}/notifications/{notificationId}`

```typescript
interface Notification {
  id: string;
  userId: string;
  
  // Content
  type: NotificationType;
  title: string;
  body: string;
  
  // Deep Link
  deepLink?: string;             // "/groups/abc123/expenses/xyz789"
  
  // Source
  groupId?: string;
  groupName?: string;
  senderId?: string;
  senderName?: string;
  
  // Status
  isRead: boolean;
  readAt?: Timestamp;
  
  // Metadata
  createdAt: Timestamp;
}

type NotificationType =
  | 'expense_added'
  | 'settlement_request'
  | 'settlement_confirmed'
  | 'group_invitation'
  | 'reminder'
  | 'system';
```

---

### 3.9 Invitations Collection

**Path**: `/invitations/{invitationId}`

```typescript
interface Invitation {
  id: string;
  
  // Invitation Details
  type: 'group' | 'friend';
  
  // Inviter
  inviterId: string;
  inviterName: string;
  inviterEmail: string;
  
  // Invitee (may not be a user yet)
  inviteeEmail?: string;
  inviteePhone?: string;
  
  // Target
  groupId?: string;              // For group invitations
  groupName?: string;
  
  // Status
  status: 'pending' | 'accepted' | 'declined' | 'expired';
  
  // Metadata
  createdAt: Timestamp;
  expiresAt: Timestamp;          // 7 days from creation
  respondedAt?: Timestamp;
}
```

**Indexes:**
- `inviteeEmail` + `status`
- `inviteePhone` + `status`
- `groupId` + `status`
- `expiresAt` (for cleanup)

---

### 3.10 Metadata Collection

**Path**: `/metadata/{configId}`

```typescript
// App Configuration
interface AppConfig {
  id: 'app_config';
  
  // Version
  minAppVersion: string;         // "1.0.0"
  currentAppVersion: string;
  forceUpdate: boolean;
  
  // Features
  maintenanceMode: boolean;
  maintenanceMessage?: string;
  
  // Limits
  maxGroupSize: number;          // 50
  maxExpenseAmount: number;      // 10000000 (₹1,00,000)
  biometricThreshold: number;    // 500000 (₹5,000)
  
  // Supported
  supportedCurrencies: string[]; // ["INR", "USD", "EUR"]
  supportedLocales: string[];    // ["en-IN", "hi-IN"]
}

// Currency Exchange Rates
interface ExchangeRates {
  id: 'exchange_rates';
  baseCurrency: string;          // "INR"
  rates: {
    [currencyCode: string]: number;
  };
  updatedAt: Timestamp;
}

// Categories
interface Categories {
  id: 'categories';
  items: CategoryItem[];
}

interface CategoryItem {
  id: string;
  name: string;
  icon: string;
  color: string;
}
```

---

## 4. Data Relationships Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Data Relationships                              │
│                                                                          │
│    ┌──────────┐         ┌──────────────┐         ┌──────────────┐       │
│    │  User    │◄───────►│  Friendship  │◄───────►│    User      │       │
│    └────┬─────┘         └──────────────┘         └──────────────┘       │
│         │                                                                │
│         │ member of                                                      │
│         ▼                                                                │
│    ┌──────────┐                                                         │
│    │  Group   │                                                         │
│    └────┬─────┘                                                         │
│         │                                                                │
│         ├────────────────┬─────────────────┬────────────────┐           │
│         ▼                ▼                 ▼                ▼           │
│    ┌──────────┐    ┌──────────┐    ┌──────────────┐   ┌──────────┐     │
│    │ Expense  │    │Settlement│    │   Activity   │   │ Members  │     │
│    └────┬─────┘    └──────────┘    └──────────────┘   └──────────┘     │
│         │                                                                │
│         ▼                                                                │
│    ┌──────────┐                                                         │
│    │   Chat   │                                                         │
│    └──────────┘                                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isGroupMember(groupId) {
      return isAuthenticated() &&
        request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
    }
    
    function isGroupAdmin(groupId) {
      return isAuthenticated() &&
        request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.admins;
    }
    
    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
      
      // Friends subcollection
      match /friends/{friendId} {
        allow read, write: if isOwner(userId);
      }
      
      // Notifications
      match /notifications/{notificationId} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // Groups
    match /groups/{groupId} {
      allow read: if isGroupMember(groupId);
      allow create: if isAuthenticated();
      allow update: if isGroupMember(groupId);
      allow delete: if isGroupAdmin(groupId);
      
      // Expenses
      match /expenses/{expenseId} {
        allow read: if isGroupMember(groupId);
        allow create: if isGroupMember(groupId);
        allow update: if isGroupMember(groupId);
        allow delete: if isGroupMember(groupId) && 
          (resource.data.createdBy == request.auth.uid || isGroupAdmin(groupId));
        
        // Expense Chat
        match /chat/{messageId} {
          allow read, write: if isGroupMember(groupId);
        }
      }
      
      // Settlements
      match /settlements/{settlementId} {
        allow read: if isGroupMember(groupId);
        allow create: if isGroupMember(groupId);
        allow update: if isGroupMember(groupId) &&
          (resource.data.fromUserId == request.auth.uid || 
           resource.data.toUserId == request.auth.uid);
      }
      
      // Activity
      match /activity/{activityId} {
        allow read: if isGroupMember(groupId);
        allow create: if isGroupMember(groupId);
      }
    }
    
    // Invitations
    match /invitations/{invitationId} {
      allow read: if isAuthenticated() &&
        (resource.data.inviterId == request.auth.uid ||
         resource.data.inviteeEmail == request.auth.token.email);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() &&
        resource.data.inviteeEmail == request.auth.token.email;
    }
    
    // Metadata (read-only for clients)
    match /metadata/{configId} {
      allow read: if isAuthenticated();
      allow write: if false; // Admin only via backend
    }
  }
}
```

---

## 6. Cloud Storage Structure

```
gs://whatsmyshare-prod/
├── users/
│   └── {userId}/
│       └── profile/
│           └── avatar.jpg
├── groups/
│   └── {groupId}/
│       ├── cover/
│       │   └── image.jpg
│       └── expenses/
│           └── {expenseId}/
│               ├── receipt_1.jpg
│               └── receipt_2.jpg
└── chat/
    └── {groupId}/
        └── {expenseId}/
            ├── images/
            │   └── {messageId}.jpg
            └── voice/
                └── {messageId}.m4a
```

---

## 7. Indexing Strategy

### 7.1 Composite Indexes

```yaml
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "expenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "settlements",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "activity",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 8. Data Migration & Backup

### 8.1 Backup Strategy

```bash
# Daily automated backup via Cloud Scheduler
gcloud firestore export gs://whatsmyshare-backups/$(date +%Y-%m-%d)

# Retention: 30 days of daily backups
```

### 8.2 Data Retention Policy

| Data Type | Retention Period |
|-----------|------------------|
| Active expenses | Indefinite |
| Deleted expenses | 90 days |
| Settlements | Indefinite |
| Activity logs | 1 year |
| Notifications | 30 days (read), 90 days (unread) |
| Chat messages | Indefinite |
| User data | Until account deletion + 30 days |

---

## Next Steps
Proceed to [04-implementation-roadmap.md](./04-implementation-roadmap.md) for the development timeline.