import 'package:equatable/equatable.dart';

/// Expense category enum
enum ExpenseCategory {
  food,
  transport,
  accommodation,
  shopping,
  entertainment,
  utilities,
  groceries,
  health,
  education,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Drinks';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.groceries:
        return 'Groceries';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.food:
        return '🍕';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.accommodation:
        return '🏨';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.groceries:
        return '🛒';
      case ExpenseCategory.health:
        return '🏥';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.other:
        return '📝';
    }
  }
}

/// Split type enum
enum SplitType {
  equal,
  exact,
  percentage,
  shares;

  String get displayName {
    switch (this) {
      case SplitType.equal:
        return 'Equal';
      case SplitType.exact:
        return 'Exact Amounts';
      case SplitType.percentage:
        return 'Percentage';
      case SplitType.shares:
        return 'Shares';
    }
  }

  String get description {
    switch (this) {
      case SplitType.equal:
        return 'Split equally among all participants';
      case SplitType.exact:
        return 'Specify exact amount for each person';
      case SplitType.percentage:
        return 'Split by percentage';
      case SplitType.shares:
        return 'Split by ratio/shares';
    }
  }
}

/// Expense status enum
enum ExpenseStatus { active, deleted }

/// Split context type - whether expense is within a group or between friends
enum SplitContextType { group, friends }

/// Context information for friend-based expense splits
/// Phone number is the primary identifier for users
class FriendSplitParticipant extends Equatable {
  final String? userId; // null if unregistered user
  final String? phone; // Primary identifier
  final String displayName;
  final String? photoUrl;

  const FriendSplitParticipant({
    this.userId,
    this.phone,
    required this.displayName,
    this.photoUrl,
  });

  /// Check if participant is a registered user
  bool get isRegistered => userId != null && userId!.isNotEmpty;

  /// Get identifier (userId or phone)
  String get identifier => userId ?? phone ?? displayName;

  @override
  List<Object?> get props => [userId, phone, displayName, photoUrl];
}

/// Split context information
class SplitContext extends Equatable {
  final SplitContextType type;
  final String? groupId; // only for group context
  final List<FriendSplitParticipant>?
  friendParticipants; // only for friends context

  const SplitContext({
    required this.type,
    this.groupId,
    this.friendParticipants,
  });

  /// Create group context
  const SplitContext.group(this.groupId)
    : type = SplitContextType.group,
      friendParticipants = null;

  /// Create friends context
  const SplitContext.friends(List<FriendSplitParticipant> participants)
    : type = SplitContextType.friends,
      groupId = null,
      friendParticipants = participants;

  bool get isGroupContext => type == SplitContextType.group;
  bool get isFriendsContext => type == SplitContextType.friends;

  @override
  List<Object?> get props => [type, groupId, friendParticipants];
}

/// Information about who paid for the expense
class PayerInfo extends Equatable {
  final String userId;
  final String displayName;
  final int amount; // in paisa (smallest unit)

  const PayerInfo({
    required this.userId,
    required this.displayName,
    required this.amount,
  });

  @override
  List<Object?> get props => [userId, displayName, amount];
}

/// Information about how the expense is split among participants
class ExpenseSplit extends Equatable {
  final String userId;
  final String displayName;
  final int amount; // in paisa
  final double? percentage;
  final int? shares;
  final bool isPaid;
  final DateTime? paidAt;

  const ExpenseSplit({
    required this.userId,
    required this.displayName,
    required this.amount,
    this.percentage,
    this.shares,
    this.isPaid = false,
    this.paidAt,
  });

  ExpenseSplit copyWith({
    String? userId,
    String? displayName,
    int? amount,
    double? percentage,
    int? shares,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return ExpenseSplit(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    displayName,
    amount,
    percentage,
    shares,
    isPaid,
    paidAt,
  ];
}

/// Main expense entity
class ExpenseEntity extends Equatable {
  final String id;
  final String
  groupId; // Kept for backward compatibility, use splitContext for new code
  final String description;
  final int amount; // in paisa (smallest unit)
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final SplitContext? splitContext; // New: context for split (group or friends)

  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    this.receiptUrls,
    this.notes,
    required this.createdBy,
    required this.status,
    this.chatMessageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.splitContext,
  });

  /// Check if this is a friend-based split (not group-based)
  bool get isFriendSplit =>
      splitContext?.isFriendsContext == true || groupId.isEmpty;

  /// Check if this is a group-based split
  bool get isGroupSplit =>
      splitContext?.isGroupContext == true || groupId.isNotEmpty;

  /// Get the formatted amount string
  String get formattedAmount {
    final rupees = amount / 100;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Check if this is a multi-payer expense
  bool get isMultiPayer => paidBy.length > 1;

  /// Get the total amount paid (should equal expense amount)
  int get totalPaid => paidBy.fold(0, (sum, payer) => sum + payer.amount);

  /// Get the total split amount (should equal expense amount)
  int get totalSplit => splits.fold(0, (sum, split) => sum + split.amount);

  /// Check if the expense is balanced (paid == split amounts)
  bool get isBalanced => totalPaid == amount && totalSplit == amount;

  /// Get the primary payer (person who paid the most)
  PayerInfo get primaryPayer {
    return paidBy.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  /// Get list of participant user IDs
  List<String> get participantIds => splits.map((s) => s.userId).toList();

  /// Get split for a specific user
  ExpenseSplit? getSplitForUser(String userId) {
    try {
      return splits.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get amount paid by a specific user
  int getAmountPaidByUser(String userId) {
    return paidBy
        .where((p) => p.userId == userId)
        .fold(0, (sum, p) => sum + p.amount);
  }

  /// Get net balance for a user (positive = owed to them, negative = they owe)
  int getNetBalanceForUser(String userId) {
    final paid = getAmountPaidByUser(userId);
    final split = getSplitForUser(userId)?.amount ?? 0;
    return paid - split;
  }

  ExpenseEntity copyWith({
    String? id,
    String? groupId,
    String? description,
    int? amount,
    String? currency,
    ExpenseCategory? category,
    DateTime? date,
    List<PayerInfo>? paidBy,
    SplitType? splitType,
    List<ExpenseSplit>? splits,
    List<String>? receiptUrls,
    String? notes,
    String? createdBy,
    ExpenseStatus? status,
    int? chatMessageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    SplitContext? splitContext,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      receiptUrls: receiptUrls ?? this.receiptUrls,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      chatMessageCount: chatMessageCount ?? this.chatMessageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      splitContext: splitContext ?? this.splitContext,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    description,
    amount,
    currency,
    category,
    date,
    paidBy,
    splitType,
    splits,
    receiptUrls,
    notes,
    createdBy,
    status,
    chatMessageCount,
    createdAt,
    updatedAt,
    deletedAt,
    deletedBy,
    splitContext,
  ];
}
