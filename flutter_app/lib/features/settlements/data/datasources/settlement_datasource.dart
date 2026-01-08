import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/services/debt_simplifier.dart';
import '../models/settlement_model.dart';

/// Remote data source for settlements using Firestore
abstract class SettlementDataSource {
  /// Create a new settlement
  Future<SettlementModel> createSettlement(SettlementModel settlement);

  /// Get all settlements for a group
  Future<List<SettlementModel>> getGroupSettlements(String groupId);

  /// Watch settlements for a group (real-time)
  Stream<List<SettlementModel>> watchGroupSettlements(String groupId);

  /// Get a specific settlement
  Future<SettlementModel?> getSettlement(String groupId, String settlementId);

  /// Update settlement status (confirm/reject)
  Future<SettlementModel> updateSettlement(
    String groupId,
    SettlementModel settlement,
  );

  /// Get balances for a group from expenses and settlements
  Future<Map<String, int>> getGroupBalances(String groupId);
}

/// Implementation of SettlementDataSource using Firebase
class SettlementDataSourceImpl implements SettlementDataSource {
  final FirebaseFirestore _firestore;

  SettlementDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Reference to settlements collection for a group
  CollectionReference<Map<String, dynamic>> _settlementsRef(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.settlementsCollection);
  }

  /// Reference to expenses collection for a group
  CollectionReference<Map<String, dynamic>> _expensesRef(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.expensesCollection);
  }

  @override
  Future<SettlementModel> createSettlement(SettlementModel settlement) async {
    try {
      final docRef = await _settlementsRef(
        settlement.groupId,
      ).add(settlement.toFirestoreCreate());

      final doc = await docRef.get();
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to create settlement',
      );
    }
  }

  @override
  Future<List<SettlementModel>> getGroupSettlements(String groupId) async {
    try {
      final snapshot = await _settlementsRef(
        groupId,
      ).orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => SettlementModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get settlements');
    }
  }

  @override
  Stream<List<SettlementModel>> watchGroupSettlements(String groupId) {
    return _settlementsRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SettlementModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<SettlementModel?> getSettlement(
    String groupId,
    String settlementId,
  ) async {
    try {
      final doc = await _settlementsRef(groupId).doc(settlementId).get();
      if (!doc.exists) return null;
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get settlement');
    }
  }

  @override
  Future<SettlementModel> updateSettlement(
    String groupId,
    SettlementModel settlement,
  ) async {
    try {
      await _settlementsRef(
        groupId,
      ).doc(settlement.id).update(settlement.toFirestoreUpdate());

      final doc = await _settlementsRef(groupId).doc(settlement.id).get();
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update settlement',
      );
    }
  }

  @override
  Future<Map<String, int>> getGroupBalances(String groupId) async {
    try {
      // Get all active expenses
      final expensesSnapshot = await _expensesRef(
        groupId,
      ).where('status', isEqualTo: 'active').get();

      // Get all confirmed settlements
      final settlementsSnapshot = await _settlementsRef(
        groupId,
      ).where('status', isEqualTo: 'confirmed').get();

      // Convert to maps for balance calculation
      final expenses = expensesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {'paidBy': data['paidBy'], 'splits': data['splits']};
      }).toList();

      final settlements = settlementsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'fromUserId': data['fromUserId'],
          'toUserId': data['toUserId'],
          'amount': data['amount'],
          'status': data['status'],
        };
      }).toList();

      return DebtSimplifier.calculateBalancesFromExpenses(
        expenses,
        settlements,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to calculate balances',
      );
    }
  }
}
