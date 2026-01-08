import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/settlement_repository.dart';
import 'settlement_event.dart';
import 'settlement_state.dart';

/// BLoC for managing settlement state
class SettlementBloc extends Bloc<SettlementEvent, SettlementState> {
  final SettlementRepository _repository;
  final LoggingService _log = LoggingService();

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

    _log.info('SettlementBloc initialized', tag: LogTags.settlements);
  }

  Future<void> _onLoadGroupSettlements(
    LoadGroupSettlements event,
    Emitter<SettlementState> emit,
  ) async {
    _log.debug(
      'Loading group settlements',
      tag: LogTags.settlements,
      data: {'groupId': event.groupId},
    );
    emit(const SettlementLoading());

    try {
      final settlements = await _repository.getGroupSettlements(event.groupId);
      _log.info(
        'Settlements loaded successfully',
        tag: LogTags.settlements,
        data: {'groupId': event.groupId, 'count': settlements.length},
      );
      emit(
        SettlementLoaded(
          settlements: settlements,
          currentGroupId: event.groupId,
        ),
      );
    } catch (e, stackTrace) {
      _log.error(
        'Failed to load settlements',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementLoadFailed));
    }
  }

  Future<void> _onWatchGroupSettlements(
    WatchGroupSettlements event,
    Emitter<SettlementState> emit,
  ) async {
    _log.debug(
      'Watching group settlements',
      tag: LogTags.settlements,
      data: {'groupId': event.groupId},
    );
    emit(const SettlementLoading());

    await _settlementsSubscription?.cancel();
    _settlementsSubscription = _repository
        .watchGroupSettlements(event.groupId)
        .listen(
          (settlements) {
            _log.debug(
              'Settlements stream updated',
              tag: LogTags.settlements,
              data: {'count': settlements.length},
            );
          },
          onError: (error, stackTrace) {
            _log.error(
              'Settlements stream error',
              tag: LogTags.settlements,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    // Get initial data
    try {
      final settlements = await _repository.getGroupSettlements(event.groupId);
      _log.info(
        'Initial settlements loaded',
        tag: LogTags.settlements,
        data: {'count': settlements.length},
      );
      emit(
        SettlementLoaded(
          settlements: settlements,
          currentGroupId: event.groupId,
        ),
      );
    } catch (e, stackTrace) {
      _log.error(
        'Failed to load initial settlements',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementLoadFailed));
    }
  }

  Future<void> _onLoadGroupBalances(
    LoadGroupBalances event,
    Emitter<SettlementState> emit,
  ) async {
    _log.debug(
      'Loading group balances',
      tag: LogTags.settlements,
      data: {'groupId': event.groupId},
    );
    final currentState = state;

    try {
      final balances = await _repository.getGroupBalances(event.groupId);
      final simplifiedDebts = await _repository.getSimplifiedDebts(
        event.groupId,
        event.displayNames,
      );

      _log.info(
        'Balances loaded successfully',
        tag: LogTags.settlements,
        data: {
          'groupId': event.groupId,
          'balanceCount': balances.length,
          'simplifiedDebtCount': simplifiedDebts.length,
        },
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
    } catch (e, stackTrace) {
      _log.error(
        'Failed to load balances',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementLoadFailed));
    }
  }

  Future<void> _onCreateSettlement(
    CreateSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    _log.info(
      'Creating settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': event.groupId,
        'fromUserId': event.fromUserId,
        'toUserId': event.toUserId,
        'amount': event.amount,
      },
    );
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

      _log.info(
        'Settlement created successfully',
        tag: LogTags.settlements,
        data: {'settlementId': settlement.id, 'amount': settlement.amount},
      );

      emit(
        SettlementOperationSuccess(
          message: 'Settlement recorded successfully',
          settlement: settlement,
        ),
      );

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to create settlement',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementCreateFailed));
    }
  }

  Future<void> _onConfirmSettlement(
    ConfirmSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    _log.info(
      'Confirming settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': event.groupId,
        'settlementId': event.settlementId,
        'biometricVerified': event.biometricVerified,
      },
    );
    emit(const SettlementOperationInProgress('confirm'));

    try {
      final settlement = await _repository.confirmSettlement(
        groupId: event.groupId,
        settlementId: event.settlementId,
        confirmedBy: event.confirmedBy,
        biometricVerified: event.biometricVerified,
      );

      _log.info(
        'Settlement confirmed successfully',
        tag: LogTags.settlements,
        data: {'settlementId': settlement.id},
      );

      emit(
        SettlementOperationSuccess(
          message: 'Settlement confirmed',
          settlement: settlement,
        ),
      );

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to confirm settlement',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementConfirmationFailed));
    }
  }

  Future<void> _onRejectSettlement(
    RejectSettlement event,
    Emitter<SettlementState> emit,
  ) async {
    _log.info(
      'Rejecting settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': event.groupId,
        'settlementId': event.settlementId,
        'reason': event.reason,
      },
    );
    emit(const SettlementOperationInProgress('reject'));

    try {
      await _repository.rejectSettlement(
        groupId: event.groupId,
        settlementId: event.settlementId,
        reason: event.reason,
      );

      _log.info(
        'Settlement rejected successfully',
        tag: LogTags.settlements,
        data: {'settlementId': event.settlementId},
      );

      emit(const SettlementOperationSuccess(message: 'Settlement rejected'));

      // Reload settlements
      add(LoadGroupSettlements(event.groupId));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to reject settlement',
        tag: LogTags.settlements,
        error: e,
        stackTrace: stackTrace,
      );
      emit(SettlementError(ErrorMessages.settlementUpdateFailed));
    }
  }

  void _onClearError(
    ClearSettlementError event,
    Emitter<SettlementState> emit,
  ) {
    _log.debug('Clearing settlement error', tag: LogTags.settlements);
    emit(const SettlementInitial());
  }

  @override
  Future<void> close() {
    _log.debug('SettlementBloc closing', tag: LogTags.settlements);
    _settlementsSubscription?.cancel();
    return super.close();
  }
}
