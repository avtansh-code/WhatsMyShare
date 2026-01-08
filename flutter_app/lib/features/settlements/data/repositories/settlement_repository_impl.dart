import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/services/debt_simplifier.dart';
import '../datasources/settlement_datasource.dart';
import '../models/settlement_model.dart';

/// Implementation of SettlementRepository
class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementDataSource _dataSource;

  SettlementRepositoryImpl({required SettlementDataSource dataSource})
    : _dataSource = dataSource;

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
    final requiresBiometric = DebtSimplifier.requiresBiometric(amount);

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

    return await _dataSource.createSettlement(settlement);
  }

  @override
  Future<List<SettlementEntity>> getGroupSettlements(String groupId) async {
    return await _dataSource.getGroupSettlements(groupId);
  }

  @override
  Stream<List<SettlementEntity>> watchGroupSettlements(String groupId) {
    return _dataSource.watchGroupSettlements(groupId);
  }

  @override
  Future<SettlementEntity?> getSettlement(
    String groupId,
    String settlementId,
  ) async {
    return await _dataSource.getSettlement(groupId, settlementId);
  }

  @override
  Future<SettlementEntity> confirmSettlement({
    required String groupId,
    required String settlementId,
    required String confirmedBy,
    bool biometricVerified = false,
  }) async {
    final settlement = await _dataSource.getSettlement(groupId, settlementId);
    if (settlement == null) {
      throw Exception('Settlement not found');
    }

    // Check if biometric verification is required but not provided
    if (settlement.requiresBiometric && !biometricVerified) {
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

    return await _dataSource.updateSettlement(groupId, updatedSettlement);
  }

  @override
  Future<SettlementEntity> rejectSettlement({
    required String groupId,
    required String settlementId,
    String? reason,
  }) async {
    final settlement = await _dataSource.getSettlement(groupId, settlementId);
    if (settlement == null) {
      throw Exception('Settlement not found');
    }

    final updatedSettlement = SettlementModel.fromEntity(
      settlement.copyWith(
        status: SettlementStatus.rejected,
        notes: reason ?? settlement.notes,
      ),
    );

    return await _dataSource.updateSettlement(groupId, updatedSettlement);
  }

  @override
  Future<Map<String, int>> getGroupBalances(String groupId) async {
    return await _dataSource.getGroupBalances(groupId);
  }

  @override
  Future<List<SimplifiedDebt>> getSimplifiedDebts(
    String groupId,
    Map<String, String> displayNames,
  ) async {
    final balances = await _dataSource.getGroupBalances(groupId);
    return DebtSimplifier.simplify(balances, displayNames);
  }

  @override
  Future<List<SettlementEntity>> getSettlementsBetweenUsers({
    required String groupId,
    required String userId1,
    required String userId2,
  }) async {
    final settlements = await _dataSource.getGroupSettlements(groupId);

    return settlements.where((s) {
      return (s.fromUserId == userId1 && s.toUserId == userId2) ||
          (s.fromUserId == userId2 && s.toUserId == userId1);
    }).toList();
  }

  @override
  Future<List<SettlementEntity>> getPendingSettlementsForUser(
    String userId,
  ) async {
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
    final settlements = await _dataSource.getGroupSettlements(groupId);
    return settlements.where((s) => s.fromUserId == userId).toList();
  }

  @override
  Future<List<SettlementEntity>> getSettlementsByReceiver({
    required String groupId,
    required String userId,
  }) async {
    final settlements = await _dataSource.getGroupSettlements(groupId);
    return settlements.where((s) => s.toUserId == userId).toList();
  }
}
