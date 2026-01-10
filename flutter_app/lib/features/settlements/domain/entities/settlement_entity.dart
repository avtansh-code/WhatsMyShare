import 'package:equatable/equatable.dart';

/// Status of a settlement
enum SettlementStatus { pending, confirmed, rejected }

/// Payment method used for settlement
enum PaymentMethod { cash, upi, bankTransfer, other }

/// Represents a settlement (payment) between two users
class SettlementEntity extends Equatable {
  final String id;
  final String groupId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int amount; // in smallest unit (paisa)
  final String currency;
  final SettlementStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final bool requiresBiometric;
  final bool biometricVerified;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? confirmedBy;

  const SettlementEntity({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    this.currency = 'INR',
    this.status = SettlementStatus.pending,
    this.paymentMethod,
    this.paymentReference,
    this.requiresBiometric = false,
    this.biometricVerified = false,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.confirmedBy,
  });

  /// Create a copy with modified fields
  SettlementEntity copyWith({
    String? id,
    String? groupId,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? toUserName,
    int? amount,
    String? currency,
    SettlementStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    bool? requiresBiometric,
    bool? biometricVerified,
    String? notes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? confirmedBy,
  }) {
    return SettlementEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      requiresBiometric: requiresBiometric ?? this.requiresBiometric,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    fromUserId,
    toUserId,
    amount,
    status,
    createdAt,
  ];
}

/// Represents a simplified debt between two users
class SimplifiedDebt extends Equatable {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int amount; // in smallest unit (paisa)

  const SimplifiedDebt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  @override
  List<Object?> get props => [fromUserId, toUserId, amount];
}

/// Balance summary for a user in a group
class UserBalance extends Equatable {
  final String userId;
  final String displayName;
  final int balance; // positive = owed money, negative = owes money

  const UserBalance({
    required this.userId,
    required this.displayName,
    required this.balance,
  });

  bool get isOwed => balance > 0;
  bool get owes => balance < 0;
  bool get isSettled => balance == 0;

  @override
  List<Object?> get props => [userId, balance];
}

/// Step in the debt simplification explanation
class SimplificationStep extends Equatable {
  final String title;
  final String description;
  final Map<String, int> balances;
  final Map<String, String> displayNames;
  final SimplifiedDebt? settlement;

  const SimplificationStep({
    required this.title,
    required this.description,
    required this.balances,
    required this.displayNames,
    this.settlement,
  });

  @override
  List<Object?> get props => [title, description, balances, settlement];
}
