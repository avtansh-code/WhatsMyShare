import 'package:equatable/equatable.dart';

import '../../domain/entities/settlement_entity.dart';

/// Base class for settlement states
abstract class SettlementState extends Equatable {
  const SettlementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettlementInitial extends SettlementState {
  const SettlementInitial();
}

/// Loading settlements
class SettlementLoading extends SettlementState {
  const SettlementLoading();
}

/// Settlements loaded successfully
class SettlementLoaded extends SettlementState {
  final List<SettlementEntity> settlements;
  final Map<String, int> balances;
  final List<SimplifiedDebt> simplifiedDebts;
  final String? currentGroupId;

  const SettlementLoaded({
    required this.settlements,
    this.balances = const {},
    this.simplifiedDebts = const [],
    this.currentGroupId,
  });

  @override
  List<Object?> get props => [
    settlements,
    balances,
    simplifiedDebts,
    currentGroupId,
  ];

  /// Create a copy with updated fields
  SettlementLoaded copyWith({
    List<SettlementEntity>? settlements,
    Map<String, int>? balances,
    List<SimplifiedDebt>? simplifiedDebts,
    String? currentGroupId,
  }) {
    return SettlementLoaded(
      settlements: settlements ?? this.settlements,
      balances: balances ?? this.balances,
      simplifiedDebts: simplifiedDebts ?? this.simplifiedDebts,
      currentGroupId: currentGroupId ?? this.currentGroupId,
    );
  }

  /// Get pending settlements
  List<SettlementEntity> get pendingSettlements =>
      settlements.where((s) => s.status == SettlementStatus.pending).toList();

  /// Get confirmed settlements
  List<SettlementEntity> get confirmedSettlements =>
      settlements.where((s) => s.status == SettlementStatus.confirmed).toList();

  /// Get total pending amount
  int get totalPendingAmount =>
      pendingSettlements.fold(0, (sum, s) => sum + s.amount);

  /// Get total confirmed amount
  int get totalConfirmedAmount =>
      confirmedSettlements.fold(0, (sum, s) => sum + s.amount);
}

/// Settlement operation in progress
class SettlementOperationInProgress extends SettlementState {
  final String operationType; // 'create', 'confirm', 'reject'

  const SettlementOperationInProgress(this.operationType);

  @override
  List<Object?> get props => [operationType];
}

/// Settlement operation succeeded
class SettlementOperationSuccess extends SettlementState {
  final String message;
  final SettlementEntity? settlement;

  const SettlementOperationSuccess({required this.message, this.settlement});

  @override
  List<Object?> get props => [message, settlement];
}

/// Error state
class SettlementError extends SettlementState {
  final String message;

  const SettlementError(this.message);

  @override
  List<Object?> get props => [message];
}
