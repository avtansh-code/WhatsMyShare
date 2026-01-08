# Feature Implementation Guide

## Overview
This document provides detailed implementation specifications for each feature of "What's My Share" app, including code patterns, UI guidelines, and acceptance criteria.

---

## 1. Authentication Feature

### 1.1 Feature Requirements
- Email/password registration and login
- Google Sign-In (OAuth)
- Password reset functionality
- Session persistence
- Secure token management

### 1.2 Implementation Details

#### Data Layer
```dart
// lib/features/auth/data/models/user_model.dart
class UserModel extends UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String defaultCurrency;
  final String locale;
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      defaultCurrency: data['defaultCurrency'] ?? 'INR',
      locale: data['locale'] ?? 'en-IN',
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'defaultCurrency': defaultCurrency,
    'locale': locale,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

#### Repository Interface
```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserEntity>> signInWithEmail(String email, String password);
  Future<Either<Failure, UserEntity>> signUpWithEmail(String email, String password, String name);
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resetPassword(String email);
}
```

#### BLoC Implementation
```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignInWithGoogle signInWithGoogle;
  final SignOut signOut;
  
  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signInWithGoogle,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }
  
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInWithEmail(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

### 1.3 UI Screens

#### Login Screen Wireframe
```
┌─────────────────────────────────┐
│         What's My Share         │
│              [Logo]             │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Email                     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Password              👁  │  │
│  └───────────────────────────┘  │
│                                 │
│  [      Sign In Button      ]   │
│                                 │
│  ─────── Or continue with ───── │
│                                 │
│  [G] Sign in with Google        │
│                                 │
│  Don't have an account? Sign Up │
│  Forgot password?               │
└─────────────────────────────────┘
```

### 1.4 Acceptance Criteria
- [ ] User can register with valid email and password
- [ ] User can login with registered credentials
- [ ] User can login with Google account
- [ ] Error messages display for invalid inputs
- [ ] Loading state shows during authentication
- [ ] Session persists across app restarts
- [ ] Password reset email is sent successfully

---

## 2. Group Management Feature

### 2.1 Feature Requirements
- Create groups with name, type, and currency
- Add/remove group members
- Edit group settings
- View group details and balances
- Delete groups (admin only)

### 2.2 Implementation Details

#### Domain Entity
```dart
// lib/features/groups/domain/entities/group_entity.dart
class GroupEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final GroupType type;
  final List<GroupMember> members;
  final String currency;
  final bool simplifyDebts;
  final String createdBy;
  final List<String> admins;
  final Map<String, int> balances; // userId -> balance in paisa
  final int totalExpenses;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  @override
  List<Object?> get props => [id, name, members, balances];
}

enum GroupType { trip, home, couple, other }

class GroupMember extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String email;
  final DateTime joinedAt;
  final MemberRole role;
  
  @override
  List<Object?> get props => [userId, email, role];
}

enum MemberRole { admin, member }
```

#### Use Cases
```dart
// lib/features/groups/domain/usecases/create_group.dart
class CreateGroup implements UseCase<GroupEntity, CreateGroupParams> {
  final GroupRepository repository;
  
  CreateGroup(this.repository);
  
  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) {
    return repository.createGroup(
      name: params.name,
      type: params.type,
      currency: params.currency,
      members: params.initialMembers,
    );
  }
}

class CreateGroupParams extends Equatable {
  final String name;
  final GroupType type;
  final String currency;
  final List<String> initialMembers; // User IDs
  
  @override
  List<Object?> get props => [name, type, currency, initialMembers];
}
```

#### Group BLoC
```dart
// lib/features/groups/presentation/bloc/group_bloc.dart
@freezed
class GroupEvent with _$GroupEvent {
  const factory GroupEvent.loadGroups() = LoadGroups;
  const factory GroupEvent.createGroup(CreateGroupParams params) = CreateGroup;
  const factory GroupEvent.updateGroup(String groupId, UpdateGroupParams params) = UpdateGroup;
  const factory GroupEvent.deleteGroup(String groupId) = DeleteGroup;
  const factory GroupEvent.addMember(String groupId, String userId) = AddMember;
  const factory GroupEvent.removeMember(String groupId, String userId) = RemoveMember;
}

@freezed
class GroupState with _$GroupState {
  const factory GroupState.initial() = GroupInitial;
  const factory GroupState.loading() = GroupLoading;
  const factory GroupState.loaded(List<GroupEntity> groups) = GroupLoaded;
  const factory GroupState.error(String message) = GroupError;
}
```

### 2.3 UI Screens

#### Group List Screen
```
┌─────────────────────────────────┐
│  Groups                    [+]  │
├─────────────────────────────────┤
│  ┌─────────────────────────────┐│
│  │ 🏠 Home Expenses           ││
│  │ 4 members • Last: Today    ││
│  │ You owe ₹1,250             ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ ✈️ Trip to Goa             ││
│  │ 6 members • Last: 2 days   ││
│  │ You are owed ₹3,400        ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 💑 With Partner            ││
│  │ 2 members • Last: 1 week   ││
│  │ Settled up                 ││
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

#### Create Group Screen
```
┌─────────────────────────────────┐
│  ←  Create Group                │
├─────────────────────────────────┤
│                                 │
│        [ Add Image ]            │
│           📷                    │
│                                 │
│  Group Name                     │
│  ┌───────────────────────────┐  │
│  │ e.g., Trip to Goa         │  │
│  └───────────────────────────┘  │
│                                 │
│  Group Type                     │
│  [Trip] [Home] [Couple] [Other] │
│                                 │
│  Currency                       │
│  ┌───────────────────────────┐  │
│  │ INR (₹)              ▼    │  │
│  └───────────────────────────┘  │
│                                 │
│  Add Members                    │
│  ┌───────────────────────────┐  │
│  │ 🔍 Search by name/email   │  │
│  └───────────────────────────┘  │
│                                 │
│  [     Create Group        ]    │
└─────────────────────────────────┘
```

### 2.4 Acceptance Criteria
- [ ] User can create a group with required fields
- [ ] User can add members by email or from contacts
- [ ] Group list shows summary with balances
- [ ] User can edit group name, image, and settings
- [ ] Only admins can delete groups
- [ ] Real-time updates when group data changes

---

## 3. Expense Management Feature

### 3.1 Feature Requirements
- Add expenses with description, amount, date, category
- Support multiple split strategies
- Multi-payer support
- Attach receipt images
- Edit and delete expenses
- View expense history

### 3.2 Implementation Details

#### Expense Entity
```dart
// lib/features/expenses/domain/entities/expense_entity.dart
class ExpenseEntity extends Equatable {
  final String id;
  final String groupId;
  final String description;
  final int amount; // in paisa
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final List<PayerInfo> paidBy;
  final SplitType splitType;
  final List<ExpenseSplit> splits;
  final List<String>? receiptUrls;
  final String? notes;
  final String createdBy;
  final ExpenseStatus status;
  final int chatMessageCount;
  
  @override
  List<Object?> get props => [id, groupId, amount, splits];
  
  // Helper to get formatted amount
  String get formattedAmount => 
    CurrencyFormatter.format(amount, currency);
}

enum SplitType { equal, exact, percentage, shares }

class PayerInfo extends Equatable {
  final String userId;
  final String displayName;
  final int amount; // in paisa
  
  @override
  List<Object?> get props => [userId, amount];
}

class ExpenseSplit extends Equatable {
  final String userId;
  final String displayName;
  final int amount; // in paisa
  final double? percentage;
  final int? shares;
  final bool isPaid;
  
  @override
  List<Object?> get props => [userId, amount, isPaid];
}
```

#### Split Calculator Service
```dart
// lib/features/expenses/domain/services/split_calculator.dart
class SplitCalculator {
  /// Calculate equal split
  static List<ExpenseSplit> calculateEqual(
    int totalAmount,
    List<GroupMember> participants,
  ) {
    final perPerson = totalAmount ~/ participants.length;
    final remainder = totalAmount % participants.length;
    
    return participants.asMap().entries.map((entry) {
      final index = entry.key;
      final member = entry.value;
      // Distribute remainder to first few members
      final extra = index < remainder ? 1 : 0;
      
      return ExpenseSplit(
        userId: member.userId,
        displayName: member.displayName,
        amount: perPerson + extra,
        isPaid: false,
      );
    }).toList();
  }
  
  /// Calculate percentage-based split
  static List<ExpenseSplit> calculatePercentage(
    int totalAmount,
    Map<String, double> percentages, // userId -> percentage
    Map<String, String> displayNames,
  ) {
    int allocated = 0;
    final splits = <ExpenseSplit>[];
    final entries = percentages.entries.toList();
    
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      int splitAmount;
      
      if (i == entries.length - 1) {
        // Last person gets remainder to avoid rounding errors
        splitAmount = totalAmount - allocated;
      } else {
        splitAmount = (totalAmount * entry.value / 100).round();
      }
      
      allocated += splitAmount;
      splits.add(ExpenseSplit(
        userId: entry.key,
        displayName: displayNames[entry.key]!,
        amount: splitAmount,
        percentage: entry.value,
        isPaid: false,
      ));
    }
    
    return splits;
  }
  
  /// Calculate shares/ratio-based split
  static List<ExpenseSplit> calculateShares(
    int totalAmount,
    Map<String, int> shares, // userId -> shares
    Map<String, String> displayNames,
  ) {
    final totalShares = shares.values.reduce((a, b) => a + b);
    int allocated = 0;
    final splits = <ExpenseSplit>[];
    final entries = shares.entries.toList();
    
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      int splitAmount;
      
      if (i == entries.length - 1) {
        splitAmount = totalAmount - allocated;
      } else {
        splitAmount = (totalAmount * entry.value / totalShares).round();
      }
      
      allocated += splitAmount;
      splits.add(ExpenseSplit(
        userId: entry.key,
        displayName: displayNames[entry.key]!,
        amount: splitAmount,
        shares: entry.value,
        isPaid: false,
      ));
    }
    
    return splits;
  }
}
```

### 3.3 UI Screens

#### Add Expense Screen
```
┌─────────────────────────────────┐
│  ←  Add Expense                 │
├─────────────────────────────────┤
│                                 │
│  Amount                         │
│  ┌───────────────────────────┐  │
│  │ ₹  │    0.00              │  │
│  └───────────────────────────┘  │
│                                 │
│  Description                    │
│  ┌───────────────────────────┐  │
│  │ Enter description         │  │
│  └───────────────────────────┘  │
│                                 │
│  Category          Date         │
│  [🍕 Food ▼]      [Today ▼]    │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Paid by                        │
│  ┌─────────────────────────────┐│
│  │ 👤 You               ₹500  ││
│  │ + Add another payer        ││
│  └─────────────────────────────┘│
│                                 │
│  Split                          │
│  [Equal][Exact][%][Shares]     │
│                                 │
│  ┌─────────────────────────────┐│
│  │ ☑ You              ₹166.67 ││
│  │ ☑ Alice            ₹166.67 ││
│  │ ☑ Bob              ₹166.66 ││
│  └─────────────────────────────┘│
│                                 │
│  📷 Add receipt                 │
│                                 │
│  [      Save Expense       ]    │
└─────────────────────────────────┘
```

### 3.4 Acceptance Criteria
- [ ] User can add expense with all required fields
- [ ] Equal split divides evenly (handles remainder)
- [ ] Exact amounts must sum to total
- [ ] Percentages must sum to 100%
- [ ] Multi-payer support works correctly
- [ ] Receipt images can be attached
- [ ] Expense can be edited/deleted
- [ ] Balance updates immediately after adding expense

---

## 4. Settlement Feature

### 4.1 Feature Requirements
- View who owes whom
- Record payments between users
- Support multiple payment methods
- Biometric verification for large amounts
- Settlement history

### 4.2 Implementation Details

#### Settlement Entity
```dart
// lib/features/settlements/domain/entities/settlement_entity.dart
class SettlementEntity extends Equatable {
  final String id;
  final String groupId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int amount; // in paisa
  final String currency;
  final SettlementStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final bool requiresBiometric;
  final bool biometricVerified;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  
  @override
  List<Object?> get props => [id, fromUserId, toUserId, amount, status];
}

enum SettlementStatus { pending, confirmed, rejected }
enum PaymentMethod { cash, upi, bankTransfer, other }
```

#### Biometric Service
```dart
// lib/core/services/biometric_service.dart
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<bool> isAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }
  
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern fallback
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
  
  static bool requiresBiometric(int amount, int threshold) {
    return amount >= threshold; // threshold is in paisa (e.g., 500000 = ₹5000)
  }
}
```

### 4.3 UI Screens

#### Settle Up Screen
```
┌─────────────────────────────────┐
│  ←  Settle Up                   │
├─────────────────────────────────┤
│                                 │
│  You owe Alice                  │
│                                 │
│          ₹1,250.00              │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Amount to settle               │
│  ┌───────────────────────────┐  │
│  │ ₹  │    1,250.00          │  │
│  └───────────────────────────┘  │
│  [Settle Full Amount]           │
│                                 │
│  Payment Method                 │
│  ○ Cash                         │
│  ● UPI                          │
│  ○ Bank Transfer                │
│  ○ Other                        │
│                                 │
│  Reference (optional)           │
│  ┌───────────────────────────┐  │
│  │ UPI transaction ID        │  │
│  └───────────────────────────┘  │
│                                 │
│  Note (optional)                │
│  ┌───────────────────────────┐  │
│  │ Add a note                │  │
│  └───────────────────────────┘  │
│                                 │
│  [    Record Payment    ]       │
│                                 │
│  ⚠️ Amounts over ₹5,000 require │
│     biometric verification      │
└─────────────────────────────────┘
```

### 4.4 Acceptance Criteria
- [ ] Shows correct amounts owed
- [ ] Can record full or partial payments
- [ ] Payment method selection works
- [ ] Biometric prompt appears for amounts > ₹5000
- [ ] Settlement updates balances correctly
- [ ] Both parties see settlement in history
- [ ] Pending settlements can be confirmed/rejected

---

## 5. Simplify Debts Feature

### 5.1 Feature Requirements
- Algorithm to minimize number of transactions
- Visual explanation of simplified debts
- "Show Me the Math" feature
- Toggle to enable/disable per group

### 5.2 Implementation Details

#### Simplify Debt Algorithm
```dart
// lib/features/settlements/domain/services/debt_simplifier.dart
class DebtSimplifier {
  /// Simplifies debts to minimize transactions
  /// Uses a greedy algorithm matching largest creditors with largest debtors
  static List<SimplifiedDebt> simplify(Map<String, int> balances) {
    // Separate into creditors (positive) and debtors (negative)
    final creditors = <MapEntry<String, int>>[];
    final debtors = <MapEntry<String, int>>[];
    
    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, -entry.value)); // Store as positive
      }
    }
    
    // Sort by amount (descending)
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));
    
    final settlements = <SimplifiedDebt>[];
    final creditorBalances = Map<String, int>.fromEntries(creditors);
    final debtorBalances = Map<String, int>.fromEntries(debtors);
    
    while (creditorBalances.isNotEmpty && debtorBalances.isNotEmpty) {
      // Get largest creditor and debtor
      final creditor = creditorBalances.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final debtor = debtorBalances.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      // Settlement amount is minimum of both
      final amount = min(creditor.value, debtor.value);
      
      settlements.add(SimplifiedDebt(
        from: debtor.key,
        to: creditor.key,
        amount: amount,
      ));
      
      // Update balances
      if (creditor.value == amount) {
        creditorBalances.remove(creditor.key);
      } else {
        creditorBalances[creditor.key] = creditor.value - amount;
      }
      
      if (debtor.value == amount) {
        debtorBalances.remove(debtor.key);
      } else {
        debtorBalances[debtor.key] = debtor.value - amount;
      }
    }
    
    return settlements;
  }
  
  /// Generates explanation steps for the algorithm
  static List<SimplificationStep> generateExplanation(
    Map<String, int> originalBalances,
    Map<String, String> displayNames,
  ) {
    final steps = <SimplificationStep>[];
    
    // Step 1: Show original balances
    steps.add(SimplificationStep(
      title: 'Original Balances',
      description: 'Starting point before simplification',
      balances: Map.from(originalBalances),
      displayNames: displayNames,
    ));
    
    // Step 2: Categorize
    final creditors = <String>[];
    final debtors = <String>[];
    for (final entry in originalBalances.entries) {
      if (entry.value > 0) {
        creditors.add(displayNames[entry.key]!);
      } else if (entry.value < 0) {
        debtors.add(displayNames[entry.key]!);
      }
    }
    
    steps.add(SimplificationStep(
      title: 'Categorize Members',
      description: 'Owed money: ${creditors.join(", ")}\n'
          'Owes money: ${debtors.join(", ")}',
      balances: Map.from(originalBalances),
      displayNames: displayNames,
    ));
    
    // Step 3+: Show each settlement
    final settlements = simplify(originalBalances);
    final runningBalances = Map<String, int>.from(originalBalances);
    
    for (final settlement in settlements) {
      runningBalances[settlement.from] = 
          (runningBalances[settlement.from] ?? 0) + settlement.amount;
      runningBalances[settlement.to] = 
          (runningBalances[settlement.to] ?? 0) - settlement.amount;
      
      steps.add(SimplificationStep(
        title: '${displayNames[settlement.from]} pays ${displayNames[settlement.to]}',
        description: 'Amount: ${CurrencyFormatter.format(settlement.amount, "INR")}',
        balances: Map.from(runningBalances),
        displayNames: displayNames,
        settlement: settlement,
      ));
    }
    
    return steps;
  }
}

class SimplificationStep {
  final String title;
  final String description;
  final Map<String, int> balances;
  final Map<String, String> displayNames;
  final SimplifiedDebt? settlement;
  
  SimplificationStep({
    required this.title,
    required this.description,
    required this.balances,
    required this.displayNames,
    this.settlement,
  });
}
```

### 5.3 UI Screens

#### Show Me the Math Screen
```
┌─────────────────────────────────┐
│  ←  How We Simplified           │
├─────────────────────────────────┤
│                                 │
│  Step 1: Original Balances      │
│  ┌─────────────────────────────┐│
│  │ Alice      is owed  ₹500   ││
│  │ Bob        owes     ₹300   ││
│  │ Charlie    owes     ₹200   ││
│  │            ──────────────  ││
│  │            Total: ₹0 ✓     ││
│  └─────────────────────────────┘│
│                                 │
│  Step 2: Match Debtors          │
│  ┌─────────────────────────────┐│
│  │ Bob pays Alice ₹300        ││
│  │ [Visual: Bob → Alice]      ││
│  └─────────────────────────────┘│
│                                 │
│  Step 3: Remaining              │
│  ┌─────────────────────────────┐│
│  │ Charlie pays Alice ₹200    ││
│  │ [Visual: Charlie → Alice]  ││
│  └─────────────────────────────┘│
│                                 │
│  Result: 2 payments instead     │
│  of potentially 3!              │
│                                 │
│  [      Got It      ]           │
└─────────────────────────────────┘
```

### 5.4 Acceptance Criteria
- [ ] Algorithm correctly minimizes transactions
- [ ] Totals balance (net zero)
- [ ] Visual explanation is clear
- [ ] Can be toggled on/off per group
- [ ] Handles edge cases (already settled, single debt)

---

## 6. Expense Chat Feature

### 6.1 Feature Requirements
- Text messages per expense
- Image attachments
- Voice notes
- System messages for changes
- Real-time updates

### 6.2 Implementation Details

#### Chat Repository
```dart
// lib/features/expenses/domain/repositories/expense_chat_repository.dart
abstract class ExpenseChatRepository {
  Stream<List<ExpenseMessage>> watchMessages(String groupId, String expenseId);
  Future<Either<Failure, ExpenseMessage>> sendTextMessage(
    String groupId, String expenseId, String text);
  Future<Either<Failure, ExpenseMessage>> sendImageMessage(
    String groupId, String expenseId, File image);
  Future<Either<Failure, ExpenseMessage>> sendVoiceMessage(
    String groupId, String expenseId, File audio, int durationSeconds);
}
```

### 6.3 Acceptance Criteria
- [ ] Can send text messages
- [ ] Can attach images
- [ ] Can record and send voice notes
- [ ] Messages appear in real-time
- [ ] Shows sender info and timestamp
- [ ] System messages for expense edits

---

## 7. Notifications Feature

### 7.1 Feature Requirements
- Push notifications via FCM
- In-app notification center
- Notification preferences
- Deep linking from notifications

### 7.2 Implementation Details

#### Cloud Function for Notifications
```typescript
// functions/src/notifications.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onExpenseCreated = functions.firestore
  .document('groups/{groupId}/expenses/{expenseId}')
  .onCreate(async (snapshot, context) => {
    const expense = snapshot.data();
    const { groupId } = context.params;
    
    // Get group data
    const groupDoc = await admin.firestore()
      .collection('groups')
      .doc(groupId)
      .get();
    const group = groupDoc.data();
    
    // Get all member tokens except creator
    const memberIds = group.memberIds.filter(
      (id: string) => id !== expense.createdBy
    );
    
    const tokens: string[] = [];
    for (const memberId of memberIds) {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(memberId)
        .get();
      const user = userDoc.data();
      if (user?.fcmTokens) {
        tokens.push(...user.fcmTokens);
      }
    }
    
    if (tokens.length === 0) return;
    
    // Send notification
    const message = {
      notification: {
        title: `New expense in ${group.name}`,
        body: `${expense.description} - ₹${(expense.amount / 100).toFixed(2)}`,
      },
      data: {
        type: 'expense_added',
        groupId,
        expenseId: snapshot.id,
      },
      tokens,
    };
    
    await admin.messaging().sendEachForMulticast(message);
  });
```

### 7.3 Acceptance Criteria
- [ ] Push notifications received when app backgrounded
- [ ] Tapping notification opens relevant screen
- [ ] In-app notifications show in notification center
- [ ] User can disable specific notification types
- [ ] Notifications marked as read when viewed

---

## 8. Offline Support Feature

### 8.1 Feature Requirements
- View data while offline
- Add expenses offline
- Queue operations for sync
- Conflict resolution
- Visual indicator for sync status

### 8.2 Implementation Details

#### Offline Queue Manager
```dart
// lib/core/services/offline_queue_manager.dart
class OfflineQueueManager {
  final Box<OfflineOperation> _queue;
  final ConnectivityService _connectivity;
  
  OfflineQueueManager(this._queue, this._connectivity) {
    _connectivity.onStatusChange.listen((status) {
      if (status == ConnectivityStatus.online) {
        _processQueue();
      }
    });
  }
  
  Future<void> enqueue(OfflineOperation operation) async {
    await _queue.add(operation);
  }
  
  Future<void> _processQueue() async {
    final operations = _queue.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        await _queue.delete(operation.key);
      } catch (e) {
        // Retry on next sync
        operation.retryCount++;
        if (operation.retryCount > 3) {
          // Mark as failed, notify user
          operation.status = OperationStatus.failed;
        }
        await operation.save();
      }
    }
  }
}

@HiveType(typeId: 1)
class OfflineOperation extends HiveObject {
  @HiveField(0)
  final String type; // 'create_expense', 'update_expense', etc.
  
  @HiveField(1)
  final Map<String, dynamic> data;
  
  @HiveField(2)
  final DateTime timestamp;
  
  @HiveField(3)
  int retryCount;
  
  @HiveField(4)
  OperationStatus status;
}
```

### 8.3 Acceptance Criteria
- [ ] Can view groups, expenses, balances offline
- [ ] Can add expenses while offline
- [ ] Offline changes sync when online
- [ ] Conflicts resolved with last-write-wins
- [ ] Clear indicator shows offline status
- [ ] Failed operations can be retried

---

## Next Steps
Proceed to [06-testing-strategy.md](./06-testing-strategy.md) for the testing approach.