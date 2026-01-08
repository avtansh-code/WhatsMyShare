import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/offline_operation.dart';
import 'logging_service.dart';

/// Service that executes offline operations when syncing
/// Uses Firestore directly for maximum flexibility with offline data
class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LoggingService _log = LoggingService();

  SyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _log.debug('SyncService initialized', tag: LogTags.sync);
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Execute an offline operation
  Future<void> executeOperation(OfflineOperation operation) async {
    _log.info(
      'Executing offline operation',
      tag: LogTags.sync,
      data: {
        'operationId': operation.id,
        'type': operation.type.name,
        'entityId': operation.entityId,
        'groupId': operation.groupId,
      },
    );

    if (_currentUserId == null) {
      _log.error('User not authenticated for sync', tag: LogTags.sync);
      throw Exception('User not authenticated');
    }

    try {
      switch (operation.type) {
        case OperationType.createExpense:
          await _createExpense(operation);
          break;
        case OperationType.updateExpense:
          await _updateExpense(operation);
          break;
        case OperationType.deleteExpense:
          await _deleteExpense(operation);
          break;
        case OperationType.createGroup:
          await _createGroup(operation);
          break;
        case OperationType.updateGroup:
          await _updateGroup(operation);
          break;
        case OperationType.createSettlement:
          await _createSettlement(operation);
          break;
        case OperationType.updateSettlement:
          await _updateSettlement(operation);
          break;
        case OperationType.updateProfile:
          await _updateProfile(operation);
          break;
        case OperationType.addGroupMember:
          await _addGroupMember(operation);
          break;
        case OperationType.removeGroupMember:
          await _removeGroupMember(operation);
          break;
      }
      _log.info(
        'Operation executed successfully',
        tag: LogTags.sync,
        data: {'operationId': operation.id, 'type': operation.type.name},
      );
    } catch (e) {
      _log.error(
        'Operation execution failed',
        tag: LogTags.sync,
        data: {
          'operationId': operation.id,
          'type': operation.type.name,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  Future<void> _createExpense(OfflineOperation operation) async {
    final groupId = operation.groupId;
    if (groupId == null) throw Exception('Group ID required');

    _log.debug(
      'Creating expense via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _currentUserId;
    data['status'] = 'active';

    final docRef = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .add(data);

    _log.debug(
      'Expense created via sync',
      tag: LogTags.sync,
      data: {'expenseId': docRef.id},
    );
  }

  Future<void> _updateExpense(OfflineOperation operation) async {
    final expenseId = operation.entityId;
    final groupId = operation.groupId;
    if (expenseId == null || groupId == null) {
      throw Exception('Expense ID and Group ID required');
    }

    _log.debug(
      'Updating expense via sync',
      tag: LogTags.sync,
      data: {'expenseId': expenseId, 'groupId': groupId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .update(data);
  }

  Future<void> _deleteExpense(OfflineOperation operation) async {
    final expenseId = operation.entityId;
    final groupId = operation.groupId;
    if (expenseId == null || groupId == null) {
      throw Exception('Expense ID and Group ID required');
    }

    _log.debug(
      'Deleting expense via sync',
      tag: LogTags.sync,
      data: {'expenseId': expenseId, 'groupId': groupId},
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .update({
          'status': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': _currentUserId,
        });
  }

  Future<void> _createGroup(OfflineOperation operation) async {
    _log.debug('Creating group via sync', tag: LogTags.sync);

    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _currentUserId;
    data['memberIds'] = [_currentUserId];
    data['admins'] = [_currentUserId];

    final docRef = await _firestore.collection('groups').add(data);
    _log.debug(
      'Group created via sync',
      tag: LogTags.sync,
      data: {'groupId': docRef.id},
    );
  }

  Future<void> _updateGroup(OfflineOperation operation) async {
    final groupId = operation.entityId;
    if (groupId == null) throw Exception('Group ID required');

    _log.debug(
      'Updating group via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('groups').doc(groupId).update(data);
  }

  Future<void> _createSettlement(OfflineOperation operation) async {
    final groupId = operation.groupId;
    if (groupId == null) throw Exception('Group ID required');

    _log.debug(
      'Creating settlement via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['status'] = 'pending';

    final docRef = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('settlements')
        .add(data);

    _log.debug(
      'Settlement created via sync',
      tag: LogTags.sync,
      data: {'settlementId': docRef.id},
    );
  }

  Future<void> _updateSettlement(OfflineOperation operation) async {
    final settlementId = operation.entityId;
    final groupId = operation.groupId;
    if (settlementId == null || groupId == null) {
      throw Exception('Settlement ID and Group ID required');
    }

    _log.debug(
      'Updating settlement via sync',
      tag: LogTags.sync,
      data: {'settlementId': settlementId, 'groupId': groupId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    if (data['status'] == 'confirmed') {
      data['confirmedAt'] = FieldValue.serverTimestamp();
      data['confirmedBy'] = _currentUserId;
    }

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('settlements')
        .doc(settlementId)
        .update(data);
  }

  Future<void> _updateProfile(OfflineOperation operation) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    _log.debug(
      'Updating profile via sync',
      tag: LogTags.sync,
      data: {'userId': _currentUserId},
    );

    final data = Map<String, dynamic>.from(operation.data);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(_currentUserId).update(data);
  }

  Future<void> _addGroupMember(OfflineOperation operation) async {
    final groupId = operation.entityId;
    if (groupId == null) throw Exception('Group ID required');

    final email = operation.data['email'] as String?;
    if (email == null) throw Exception('Email required');

    _log.debug(
      'Adding group member via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId, 'email': email},
    );

    // Find user by email
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      _log.warning(
        'User not found for email',
        tag: LogTags.sync,
        data: {'email': email},
      );
      throw Exception('User not found with email: $email');
    }

    final userId = userQuery.docs.first.id;

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    _log.info(
      'Group member added via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId, 'userId': userId},
    );
  }

  Future<void> _removeGroupMember(OfflineOperation operation) async {
    final groupId = operation.entityId;
    final userId = operation.data['userId'] as String?;
    if (groupId == null || userId == null) {
      throw Exception('Group ID and User ID required');
    }

    _log.debug(
      'Removing group member via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId, 'userId': userId},
    );

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    _log.info(
      'Group member removed via sync',
      tag: LogTags.sync,
      data: {'groupId': groupId, 'userId': userId},
    );
  }
}
