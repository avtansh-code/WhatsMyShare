import '../entities/settlement_entity.dart';

/// Repository interface for settlement operations
abstract class SettlementRepository {
  /// Create a new settlement (record a payment)
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
  });

  /// Get settlements for a group
  Future<List<SettlementEntity>> getGroupSettlements(String groupId);

  /// Watch settlements for a group (real-time)
  Stream<List<SettlementEntity>> watchGroupSettlements(String groupId);

  /// Get a specific settlement
  Future<SettlementEntity?> getSettlement(String groupId, String settlementId);

  /// Confirm a settlement
  Future<SettlementEntity> confirmSettlement({
    required String groupId,
    required String settlementId,
    required String confirmedBy,
    bool biometricVerified,
  });

  /// Reject a settlement
  Future<SettlementEntity> rejectSettlement({
    required String groupId,
    required String settlementId,
    String? reason,
  });

  /// Get balances for a group
  Future<Map<String, int>> getGroupBalances(String groupId);

  /// Get simplified debts for a group
  Future<List<SimplifiedDebt>> getSimplifiedDebts(
    String groupId,
    Map<String, String> displayNames,
  );

  /// Get settlements between two users in a group
  Future<List<SettlementEntity>> getSettlementsBetweenUsers({
    required String groupId,
    required String userId1,
    required String userId2,
  });

  /// Get pending settlements for a user (settlements they need to confirm)
  Future<List<SettlementEntity>> getPendingSettlementsForUser(String userId);

  /// Get settlements where user is the payer
  Future<List<SettlementEntity>> getSettlementsByPayer({
    required String groupId,
    required String userId,
  });

  /// Get settlements where user is the receiver
  Future<List<SettlementEntity>> getSettlementsByReceiver({
    required String groupId,
    required String userId,
  });
}
