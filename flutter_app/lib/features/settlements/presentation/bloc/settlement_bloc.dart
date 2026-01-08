import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/settlement_repository.dart';
import 'settlement_event.dart';
import 'settlement_state.dart';

/// BLoC for managing settlement state
class SettlementBloc extends Bloc<SettlementEvent, SettlementState> {
  final SettlementRepository _repository;

  StreamSubscription<List<SettlementEntity>>? _settlementsSubscription;

  SettlementBloc({required SettlementRepository repository})
    : _repository = repository,
      super(const SettlementInitial()) {
    on<LoadGroupSettlements>(_onLoadGroupSettlements);
    on<WatchGroupSettlements>(_onWatchGroupSettlements);
    on<LoadGroupBalances>(_onLoadGroupBalances);
    on<CreateSettlement>(_onCreateSettlement);
    on<ConfirmSettlement>(_onConfirmSettlement);
    on<RejectSettlement>(_onRejectSettlement);
    on<ClearSettlementError>(_onClearError);
  }

  Future<void> _onLoadGroupSettlements(
    LoadGroupSettlements event,
    Emitter<SettlementState> emit,
  ) async {
    emit(const SettlementLoading());

    try {
      final settlements = await _repository.getGroupSettlements(event.groupId);
      emit(
        SettlementLoaded(
          settlements: settlements,
          currentGroupId: event.groupId,
        ),
      );
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onWatchGroupSettlements(
    WatchGroupSettlements event,
    Emitter<SettlementState> emit,
  ) async {
    emit(const SettlementLoading());

    await _settlementsSubscription?.cancel();
    _settlementsSubscription = _repository
        .watchGroupSettlements(event.groupId)
        .listen(
          (settlements) {
            if (!isClosed) {
              // Manually emit state since we're in a stream
              // ignore: invalid_use_of_visible_for_testing_member
              // Use add to trigger another event instead
            }
          },
          onError: (error) {
            if (!isClosed) {
              // ignore: invalid_use_of_visible_for_testing_member
            }
          },
        );

    // Get initial data
    try {
      final settlements = await _repository.getGroupSettlements(event.groupId);
      emit(
        SettlementLoaded(
          settlements: settlements,
          currentGroupId: event.groupId,
        ),
      );
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onLoadGroupBalances(
    LoadGroupBalances event,
    Emitter<SettlementState> emit,
  ) async {
    final currentState = state;

    try {
      final balances = await _repository.getGroupBalances(event.groupId);
      final simplifiedDebts = await _repository.getSimplifiedDebts(
        event.groupId,
        event.displayNames,
      );

      if (currentState is SettlementLoaded) {
        emit(
          currentState.copyWith(
            balances: balances,
            simplifiedDebts: simplifiedDebts,
          ),
        );
      } else {
        emit(
          SettlementLoaded(
            settlements: const [],
            balances: balances,
            simplifiedDebts: simplifiedDebts,
            currentGroupId: event.groupId,
          ),
        );
      }
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onCreateSettlement(
    CreateSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    emit(const SettlementOperationInProgress('create'));

    try {
      final settlement = await _repository.createSettlement(
        groupId: event.groupId,
        fromUserId: event.fromUserId,
        fromUserName: event.fromUserName,
        toUserId: event.toUserId,
        toUserName: event.toUserName,
        amount: event.amount,
        currency: event.currency,
        paymentMethod: event.paymentMethod,
        paymentReference: event.paymentReference,
        notes: event.notes,
      );

      emit(
        SettlementOperationSuccess(
          message: 'Settlement recorded successfully',
          settlement: settlement,
        ),
      );

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onConfirmSettlement(
    ConfirmSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    emit(const SettlementOperationInProgress('confirm'));

    try {
      final settlement = await _repository.confirmSettlement(
        groupId: event.groupId,
        settlementId: event.settlementId,
        confirmedBy: event.confirmedBy,
        biometricVerified: event.biometricVerified,
      );

      emit(
        SettlementOperationSuccess(
          message: 'Settlement confirmed',
          settlement: settlement,
        ),
      );

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onRejectSettlement(
    RejectSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    emit(const SettlementOperationInProgress('reject'));

    try {
      await _repository.rejectSettlement(
        groupId: event.groupId,
        settlementId: event.settlementId,
        reason: event.reason,
      );

      emit(const SettlementOperationSuccess(message: 'Settlement rejected'));

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  void _onClearError(
    ClearSettlementError event,
    Emitter<SettlementState> emit,
  ) {
    emit(const SettlementInitial());
  }

  @override
  Future<void> close() {
    _settlementsSubscription?.cancel();
    return super.close();
  }
}
