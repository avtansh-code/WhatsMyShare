# Database Schema

## Architecture: UID-Based User Identification

### Overview

The WhatsMyShare app uses **User UID (Firebase Auth ID) as the primary identifier** for all user references in the database. This architecture ensures:

1. **No data staleness** - When a user updates their profile (name, photo, phone), all references are automatically up-to-date
2. **Reduced storage duplication** - User data is stored once in the `users` collection
3. **Single source of truth** - The `users` collection is the authoritative source for user information
4. **Consistent data across features** - Friends, groups, and expenses all reference users the same way

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Backend (Firestore)                        │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐               │
│  │   friends   │   │   groups    │   │  expenses   │               │
│  │             │   │             │   │             │               │
│  │ friendUserId│   │ members[]   │   │ paidBy[]    │               │
│  │    (UID)    │   │  userId     │   │  userId     │               │
│  │             │   │   (UID)     │   │   (UID)     │               │
│  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘               │
│         │                 │                  │                      │
│         └────────────────┼──────────────────┘                      │
│                          │                                          │
│                          ▼                                          │
│               ┌─────────────────────┐                              │
│               │       users         │                              │
│               │   (Source of Truth) │                              │
│               │   - displayName     │                              │
│               │   - phone           │                              │
│               │   - photoUrl        │                              │
│               └─────────────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend (Flutter App)                       │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐  │
│   │                    UserCacheService                          │  │
│   │  - Resolves UIDs to display names, photos, phones            │  │
│   │  - In-memory cache with 5-minute TTL                         │  │
│   │  - Batch fetching for performance                            │  │
│   │  - Real-time updates via Firestore streams                   │  │
│   └─────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│              ┌───────────────┼───────────────┐                     │
│              │               │               │                     │
│              ▼               ▼               ▼                     │
│   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐              │
│   │ FriendEntity │ │ GroupMember  │ │ExpenseSplit  │              │
│   │              │ │              │ │              │              │
│   │ cached*      │ │ cached*      │ │ (userId)     │              │
│   │ DisplayName  │ │ DisplayName  │ │              │              │
│   │ cachedPhone  │ │ cachedPhone  │ │              │              │
│   │ cachedPhoto  │ │ cachedPhoto  │ │              │              │
│   └──────────────┘ └──────────────┘ └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

## Collections

### 1. users

Primary collection storing all registered user profiles.

```typescript
users/{userId}
{
  // Primary identifier
  phone: string,              // Phone number with country code, e.g., "+919876543210"
  
  // Profile information
  displayName: string | null, // User's display name
  displayNameLower: string,   // Lowercase for case-insensitive search
  photoUrl: string | null,    // Profile photo URL
  
  // Settings
  currency: string,           // Default: "INR"
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastActiveAt: Timestamp,
}
```

**Indexes:**
- `phone` - For phone number lookup
- `displayNameLower` - For name search

### 2. friends

Stores friendship relationships between registered users.

```typescript
friends/{friendshipId}
{
  // Relationship identifiers
  userId: string,         // Owner of this friend entry (who added the friend)
  friendUserId: string,   // The friend's UID - PRIMARY identifier for the friend
  
  // Relationship status
  status: "pending" | "accepted" | "blocked",
  addedVia: "manual" | "contact_sync" | "group" | "invitation",
  
  // Balance tracking
  balance: number,        // In paisa (100 paisa = 1 INR)
  currency: string,       // Default: "INR"
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

**Note:** Display properties (displayName, phone, photoUrl) are NOT stored here. They are resolved via `UserCacheService` using `friendUserId`.

**Indexes:**
- `userId` + `status` - For listing user's friends
- `friendUserId` - For reverse lookup

### 3. groups

Stores bill-splitting groups.

```typescript
groups/{groupId}
{
  // Group information
  name: string,
  description: string | null,
  imageUrl: string | null,
  type: "trip" | "home" | "couple" | "other",
  
  // Members - stores only UIDs
  members: [
    {
      userId: string,     // Member's UID - PRIMARY identifier
      role: "admin" | "member",
      joinedAt: Timestamp,
    }
  ],
  memberIds: string[],    // Array of UIDs for efficient querying
  memberCount: number,
  
  // Settings
  currency: string,       // Default: "INR"
  simplifyDebts: boolean, // Default: true
  
  // Admin info
  createdBy: string,      // UID of creator
  admins: string[],       // UIDs of admins
  
  // Statistics
  totalExpenses: number,  // In paisa
  expenseCount: number,
  balances: {             // userId -> balance in paisa
    [userId: string]: number
  },
  simplifiedDebts: [      // Only UIDs stored
    {
      from: string,       // UID of debtor
      to: string,         // UID of creditor
      amount: number,     // In paisa
    }
  ] | null,
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastActivityAt: Timestamp,
}
```

**Note:** Member display properties are resolved via `UserCacheService` using member `userId`.

**Indexes:**
- `memberIds` (array-contains) - For querying groups by member
- `createdBy` - For querying groups by creator

### 4. expenses

Stores expense records within groups.

```typescript
groups/{groupId}/expenses/{expenseId}
{
  // Expense info
  groupId: string,
  description: string,
  amount: number,         // In paisa
  currency: string,
  category: string,       // "food", "transport", "accommodation", etc.
  date: Timestamp,
  
  // Payers - uses UIDs
  paidBy: [
    {
      userId: string,     // UID of payer
      displayName: string, // Cached at creation time for historical record
      amount: number,     // In paisa
    }
  ],
  
  // Splits - uses UIDs
  splitType: "equal" | "exact" | "percentage" | "shares",
  splits: [
    {
      userId: string,     // UID of participant
      displayName: string, // Cached at creation time for historical record
      amount: number,     // In paisa
      percentage: number | null,
      shares: number | null,
      isPaid: boolean,
      paidAt: Timestamp | null,
    }
  ],
  
  // Split context (for friend expenses)
  splitContext: {
    type: "group" | "friends",
    groupId: string | null,
    friendParticipants: [  // For friend-based expenses
      {
        userId: string,   // UID (if registered)
        phone: string,    // Phone number
        displayName: string,
        photoUrl: string | null,
      }
    ] | null,
  } | null,
  
  // Metadata
  receiptUrls: string[] | null,
  notes: string | null,
  createdBy: string,      // UID
  status: "active" | "deleted",
  chatMessageCount: number,
  
  // Deletion tracking
  deletedAt: Timestamp | null,
  deletedBy: string | null,
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

**Note:** Expenses store displayName at creation time for historical accuracy (showing who paid even if they change their name later).

### 5. settlements

Stores settlement records.

```typescript
groups/{groupId}/settlements/{settlementId}
{
  groupId: string,
  fromUserId: string,     // UID of payer
  toUserId: string,       // UID of receiver
  amount: number,         // In paisa
  currency: string,
  method: "cash" | "upi" | "bank" | "other",
  note: string | null,
  status: "pending" | "confirmed" | "rejected",
  createdAt: Timestamp,
  confirmedAt: Timestamp | null,
}
```

### 6. notifications

Stores user notifications.

```typescript
notifications/{notificationId}
{
  userId: string,         // UID of notification recipient
  type: string,           // "expense_added", "friend_request", etc.
  title: string,
  body: string,
  data: {                 // Type-specific data
    // Contains UIDs for references
  },
  isRead: boolean,
  createdAt: Timestamp,
}
```

## UserCacheService

The `UserCacheService` is the central service for resolving UIDs to user information.

### Usage Pattern

```dart
// Get single user
final user = await userCacheService.getUser(userId);
print(user?.displayName ?? 'Unknown');

// Get multiple users (batch)
final users = await userCacheService.getUsers([uid1, uid2, uid3]);

// Search by phone
final results = await userCacheService.searchUsersByPhone('+919876543210');

// Real-time updates
userCacheService.watchUser(userId).listen((user) {
  // Update UI when user profile changes
});
```

### Cache Strategy

1. **In-memory cache** with 5-minute TTL
2. **Batch fetching** to minimize Firestore reads
3. **Pending request deduplication** to avoid concurrent fetches for same user
4. **Real-time streams** for UI components that need live updates

## Migration Notes

### From Denormalized to UID-Based

If migrating from an older schema that stored denormalized user data:

1. **Friends collection**: Remove `displayName`, `phone`, `photoUrl` fields
2. **Groups members**: Keep only `userId`, `role`, `joinedAt`
3. **Expenses**: Already stores UIDs; `displayName` is kept for historical record

### Backward Compatibility

The model classes include `toEntityWithCache()` methods that accept cached display properties, allowing gradual migration:

```dart
// Old way (reading denormalized data)
final friend = FriendModel.fromFirestore(doc).toEntity();

// New way (resolving from cache)
final friend = FriendModel.fromFirestore(doc).toEntity();
final user = await userCacheService.getUser(friend.friendUserId);
final enrichedFriend = friend.withCachedData(
  displayName: user?.displayName,
  phone: user?.phone,
  photoUrl: user?.photoUrl,
);
```

## Security Rules Summary

See `firestore.rules` for complete rules. Key points:

1. Users can only read/write their own profile
2. Friends can only be created between registered users
3. Group members can read group data; admins can modify
4. Expenses are readable by group members; creators can modify
5. Phone numbers are indexed but protected from enumeration

## Best Practices

1. **Always use UIDs** for user references in backend storage
2. **Use UserCacheService** for resolving user details in the app
3. **Batch fetch users** when displaying lists (friends, group members)
4. **Subscribe to user streams** for real-time profile updates
5. **Store displayName in expenses** for historical accuracy
6. **Use `displayNameLower`** for case-insensitive search---
