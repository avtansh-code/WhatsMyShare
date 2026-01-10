import 'package:equatable/equatable.dart';

import '../../domain/entities/settlement_entity.dart';

/// Base class for settlement events
abstract class SettlementEvent extends Equatable {
  const SettlementEvent();

  @override
  List<Object?> get props => [];
}

/// Load settlements for a group
class LoadGroupSettlements extends SettlementEvent {
  final String groupId;

  const LoadGroupSettlements(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Watch settlements for a group (real-time)
class WatchGroupSettlements extends SettlementEvent {
  final String groupId;

  const WatchGroupSettlements(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Load group balances
class LoadGroupBalances extends SettlementEvent {
  final String groupId;
  final Map<String, String> displayNames;

  const LoadGroupBalances({required this.groupId, required this.displayNames});

  @override
  List<Object?> get props => [groupId, displayNames];
}

/// Create a new settlement
class CreateSettlement extends SettlementEvent {
  final String groupId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int amount;
  final String currency;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final String? notes;

  const CreateSettlement({
    required this.groupId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.currency,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
  });

  @override
  List<Object?> get props => [
    groupId,
    fromUserId,
    toUserId,
    amount,
    paymentMethod,
  ];
}

/// Confirm a settlement
class ConfirmSettlement extends SettlementEvent {
  final String groupId;
  final String settlementId;
  final String confirmedBy;
  final bool biometricVerified;

  const ConfirmSettlement({
    required this.groupId,
    required this.settlementId,
    required this.confirmedBy,
    this.biometricVerified = false,
  });

  @override
  List<Object?> get props => [
    groupId,
    settlementId,
    confirmedBy,
    biometricVerified,
  ];
}

/// Reject a settlement
class RejectSettlement extends SettlementEvent {
  final String groupId;
  final String settlementId;
  final String? reason;

  const RejectSettlement({
    required this.groupId,
    required this.settlementId,
    this.reason,
  });

  @override
  List<Object?> get props => [groupId, settlementId, reason];
}

/// Clear settlement error
class ClearSettlementError extends SettlementEvent {
  const ClearSettlementError();
}
