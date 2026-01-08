import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
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
  final LoggingService _log = LoggingService();

  SettlementDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore {
    _log.debug('SettlementDataSource initialized', tag: LogTags.settlements);
  }

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
    _log.info(
      'Creating settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': settlement.groupId,
        'fromUserId': settlement.fromUserId,
        'toUserId': settlement.toUserId,
        'amount': settlement.amount,
      },
    );
    try {
      final docRef = await _settlementsRef(
        settlement.groupId,
      ).add(settlement.toFirestoreCreate());

      final doc = await docRef.get();
      _log.info(
        'Settlement created successfully',
        tag: LogTags.settlements,
        data: {'settlementId': docRef.id},
      );
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to create settlement',
        tag: LogTags.settlements,
        data: {'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to create settlement',
      );
    }
  }

  @override
  Future<List<SettlementModel>> getGroupSettlements(String groupId) async {
    _log.debug(
      'Fetching group settlements',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    try {
      final snapshot = await _settlementsRef(
        groupId,
      ).orderBy('createdAt', descending: true).get();

      final settlements = snapshot.docs
          .map((doc) => SettlementModel.fromFirestore(doc))
          .toList();
      _log.info(
        'Settlements fetched successfully',
        tag: LogTags.settlements,
        data: {'groupId': groupId, 'count': settlements.length},
      );
      return settlements;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get settlements',
        tag: LogTags.settlements,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get settlements');
    }
  }

  @override
  Stream<List<SettlementModel>> watchGroupSettlements(String groupId) {
    _log.debug(
      'Setting up settlements stream',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    return _settlementsRef(
      groupId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      _log.debug(
        'Settlements stream updated',
        tag: LogTags.settlements,
        data: {'count': snapshot.docs.length},
      );
      return snapshot.docs
          .map((doc) => SettlementModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<SettlementModel?> getSettlement(
    String groupId,
    String settlementId,
  ) async {
    _log.debug(
      'Fetching settlement by ID',
      tag: LogTags.settlements,
      data: {'groupId': groupId, 'settlementId': settlementId},
    );
    try {
      final doc = await _settlementsRef(groupId).doc(settlementId).get();
      if (!doc.exists) {
        _log.warning(
          'Settlement not found',
          tag: LogTags.settlements,
          data: {'settlementId': settlementId},
        );
        return null;
      }
      _log.debug('Settlement fetched successfully', tag: LogTags.settlements);
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get settlement',
        tag: LogTags.settlements,
        data: {'settlementId': settlementId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get settlement');
    }
  }

  @override
  Future<SettlementModel> updateSettlement(
    String groupId,
    SettlementModel settlement,
  ) async {
    _log.info(
      'Updating settlement',
      tag: LogTags.settlements,
      data: {
        'groupId': groupId,
        'settlementId': settlement.id,
        'status': settlement.status.name,
      },
    );
    try {
      await _settlementsRef(
        groupId,
      ).doc(settlement.id).update(settlement.toFirestoreUpdate());

      final doc = await _settlementsRef(groupId).doc(settlement.id).get();
      _log.info(
        'Settlement updated successfully',
        tag: LogTags.settlements,
        data: {'settlementId': settlement.id},
      );
      return SettlementModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update settlement',
        tag: LogTags.settlements,
        data: {'settlementId': settlement.id, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to update settlement',
      );
    }
  }

  @override
  Future<Map<String, int>> getGroupBalances(String groupId) async {
    _log.debug(
      'Calculating group balances',
      tag: LogTags.settlements,
      data: {'groupId': groupId},
    );
    try {
      // Get all active expenses
      final expensesSnapshot = await _expensesRef(
        groupId,
      ).where('status', isEqualTo: 'active').get();
      _log.debug(
        'Active expenses fetched',
        tag: LogTags.settlements,
        data: {'count': expensesSnapshot.docs.length},
      );

      // Get all confirmed settlements
      final settlementsSnapshot = await _settlementsRef(
        groupId,
      ).where('status', isEqualTo: 'confirmed').get();
      _log.debug(
        'Confirmed settlements fetched',
        tag: LogTags.settlements,
        data: {'count': settlementsSnapshot.docs.length},
      );

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

      final balances = DebtSimplifier.calculateBalancesFromExpenses(
        expenses,
        settlements,
      );
      _log.info(
        'Balances calculated successfully',
        tag: LogTags.settlements,
        data: {'groupId': groupId, 'memberCount': balances.length},
      );
      return balances;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to calculate balances',
        tag: LogTags.settlements,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to calculate balances',
      );
    }
  }
}
