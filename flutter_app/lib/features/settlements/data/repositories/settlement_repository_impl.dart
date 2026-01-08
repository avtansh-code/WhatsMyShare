import '../../../../core/services/logging_service.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/services/debt_simplifier.dart';
import '../datasources/settlement_datasource.dart';
import '../models/settlement_model.dart';

/// Implementation of SettlementRepository
class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementDataSource _dataSource;
  final LoggingService _log = LoggingService();

  SettlementRepositoryImpl({required SettlementDataSource dataSource})
    : _dataSource = dataSource {
    _log.debug('SettlementRepository initialized', tag: LogTags.settlements);
  }

  @override
  Future<SettlementEntity> createSettlement({
    required String groupId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required int amount,
    required String currency,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    String? notes,
  }) async {
    _log.info(
      'Creating settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': groupId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'currency': currency,
      },
    );

    final requiresBiometric = DebtSimplifier.requiresBiometric(amount);
    _log.debug(
      'Biometric requirement',
      tag: LogTags.settlements,
      data: {'requiresBiometric': requiresBiometric, 'amount': amount},
    );

    final settlement = SettlementModel(
      id: '', // Will be set by Firestore
      groupId: groupId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      amount: amount,
      currency: currency,
      status: SettlementStatus.pending,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      requiresBiometric: requiresBiometric,
      biometricVerified: false,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final created = await _dataSource.createSettlement(settlement);
    _log.info(
      'Settlement created',
      tag: LogTags.settlements,
      data: {'settlementId': created.id, 'amount': amount},
    );
    return created;
  }

  @override
  Future<List<SettlementEntity>> getGroupSettlements(String groupId) async {
    _log.debug(
      'Getting group settlements',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    final settlements = await _dataSource.getGroupSettlements(groupId);
    _log.info(
      'Group settlements fetched',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'count': settlements.length},
    );
    return settlements;
  }

  @override
  Stream<List<SettlementEntity>> watchGroupSettlements(String groupId) {
    _log.debug(
      'Setting up settlements stream',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    return _dataSource.watchGroupSettlements(groupId);
  }

  @override
  Future<SettlementEntity?> getSettlement(
    String groupId,
    String settlementId,
  ) async {
    _log.debug(
      'Getting settlement',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'settlementId': settlementId},
    );
    final settlement = await _dataSource.getSettlement(groupId, settlementId);
    if (settlement != null) {
      _log.info(
        'Settlement fetched',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId, 'status': settlement.status.name},
      );
    } else {
      _log.warning(
        'Settlement not found',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId},
      );
    }
    return settlement;
  }

  @override
  Future<SettlementEntity> confirmSettlement({
    required String groupId,
    required String settlementId,
    required String confirmedBy,
    bool biometricVerified = false,
  }) async {
    _log.info(
      'Confirming settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': groupId,
        'settlementId': settlementId,
        'confirmedBy': confirmedBy,
        'biometricVerified': biometricVerified,
      },
    );

    final settlement = await _dataSource.getSettlement(groupId, settlementId);
    if (settlement == null) {
      _log.error(
        'Settlement not found for confirmation',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId},
      );
      throw Exception('Settlement not found');
    }

    // Check if biometric verification is required but not provided
    if (settlement.requiresBiometric && !biometricVerified) {
      _log.warning(
        'Biometric verification required but not provided',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId},
      );
      throw Exception('Biometric verification required for this settlement');
    }

    final updatedSettlement = SettlementModel.fromEntity(
      settlement.copyWith(
        status: SettlementStatus.confirmed,
        biometricVerified: biometricVerified,
        confirmedAt: DateTime.now(),
        confirmedBy: confirmedBy,
      ),
    );

    final result = await _dataSource.updateSettlement(
      groupId,
      updatedSettlement,
    );
    _log.info(
      'Settlement confirmed',
      tag: LogTags.settlements,
      data: {'settlementId': settlementId, 'amount': result.amount},
    );
    return result;
  }

  @override
  Future<SettlementEntity> rejectSettlement({
    required String groupId,
    required String settlementId,
    String? reason,
  }) async {
    _log.info(
      'Rejecting settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': groupId,
        'settlementId': settlementId,
        'reason': reason,
      },
    );

    final settlement = await _dataSource.getSettlement(groupId, settlementId);
    if (settlement == null) {
      _log.error(
        'Settlement not found for rejection',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId},
      );
      throw Exception('Settlement not found');
    }

    final updatedSettlement = SettlementModel.fromEntity(
      settlement.copyWith(
        status: SettlementStatus.rejected,
        notes: reason ?? settlement.notes,
      ),
    );

    final result = await _dataSource.updateSettlement(
      groupId,
      updatedSettlement,
    );
    _log.info(
      'Settlement rejected',
      tag: LogTags.settlements,
      data: {'settlementId': settlementId},
    );
    return result;
  }

  @override
  Future<Map<String, int>> getGroupBalances(String groupId) async {
    _log.debug(
      'Getting group balances',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    final balances = await _dataSource.getGroupBalances(groupId);
    _log.info(
      'Group balances fetched',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'userCount': balances.length},
    );
    return balances;
  }

  @override
  Future<List<SimplifiedDebt>> getSimplifiedDebts(
    String groupId,
    Map<String, String> displayNames,
  ) async {
    _log.debug(
      'Getting simplified debts',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    final balances = await _dataSource.getGroupBalances(groupId);
    final simplified = DebtSimplifier.simplify(balances, displayNames);
    _log.info(
      'Simplified debts calculated',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'debtCount': simplified.length},
    );
    return simplified;
  }

  @override
  Future<List<SettlementEntity>> getSettlementsBetweenUsers({
    required String groupId,
    required String userId1,
    required String userId2,
  }) async {
    _log.debug(
      'Getting settlements between users',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'userId1': userId1, 'userId2': userId2},
    );
    final settlements = await _dataSource.getGroupSettlements(groupId);

    final filtered = settlements.where((s) {
      return (s.fromUserId == userId1 && s.toUserId == userId2) ||
          (s.fromUserId == userId2 && s.toUserId == userId1);
    }).toList();

    _log.info(
      'Settlements between users fetched',
      tag: LogTags.settlements,
      data: {'count': filtered.length},
    );
    return filtered;
  }

  @override
  Future<List<SettlementEntity>> getPendingSettlementsForUser(
    String userId,
  ) async {
    _log.warning(
      'getPendingSettlementsForUser not implemented',
      tag: LogTags.settlements,
      data: {'userId': userId},
    );
    // Note: This requires a cross-group query
    // In production, consider using a separate pending_settlements collection
    throw UnimplementedError(
      'Cross-group queries not implemented. Consider using Cloud Functions.',
    );
  }

  @override
  Future<List<SettlementEntity>> getSettlementsByPayer({
    required String groupId,
    required String userId,
  }) async {
    _log.debug(
      'Getting settlements by payer',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'userId': userId},
    );
    final settlements = await _dataSource.getGroupSettlements(groupId);
    final filtered = settlements.where((s) => s.fromUserId == userId).toList();
    _log.info(
      'Settlements by payer fetched',
      tag: LogTags.settlements,
      data: {'count': filtered.length},
    );
    return filtered;
  }

  @override
  Future<List<SettlementEntity>> getSettlementsByReceiver({
    required String groupId,
    required String userId,
  }) async {
    _log.debug(
      'Getting settlements by receiver',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'userId': userId},
    );
    final settlements = await _dataSource.getGroupSettlements(groupId);
    final filtered = settlements.where((s) => s.toUserId == userId).toList();
    _log.info(
      'Settlements by receiver fetched',
      tag: LogTags.settlements,
      data: {'count': filtered.length},
    );
    return filtered;
  }
}
