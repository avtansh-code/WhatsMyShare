import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/offline_operation.dart';

/// Service that executes offline operations when syncing
/// Uses Firestore directly for maximum flexibility with offline data
class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Execute an offline operation
  Future<void> executeOperation(OfflineOperation operation) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

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
  }

  Future<void> _createExpense(OfflineOperation operation) async {
    final groupId = operation.groupId;
    if (groupId == null) throw Exception('Group ID required');

    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _currentUserId;
    data['status'] = 'active';

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .add(data);
  }

  Future<void> _updateExpense(OfflineOperation operation) async {
    final expenseId = operation.entityId;
    final groupId = operation.groupId;
    if (expenseId == null || groupId == null) {
      throw Exception('Expense ID and Group ID required');
    }

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
    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _currentUserId;
    data['memberIds'] = [_currentUserId];
    data['admins'] = [_currentUserId];

    await _firestore.collection('groups').add(data);
  }

  Future<void> _updateGroup(OfflineOperation operation) async {
    final groupId = operation.entityId;
    if (groupId == null) throw Exception('Group ID required');

    final data = Map<String, dynamic>.from(operation.data);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('groups').doc(groupId).update(data);
  }

  Future<void> _createSettlement(OfflineOperation operation) async {
    final groupId = operation.groupId;
    if (groupId == null) throw Exception('Group ID required');

    final data = Map<String, dynamic>.from(operation.data);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['status'] = 'pending';

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('settlements')
        .add(data);
  }

  Future<void> _updateSettlement(OfflineOperation operation) async {
    final settlementId = operation.entityId;
    final groupId = operation.groupId;
    if (settlementId == null || groupId == null) {
      throw Exception('Settlement ID and Group ID required');
    }

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

    final data = Map<String, dynamic>.from(operation.data);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(_currentUserId).update(data);
  }

  Future<void> _addGroupMember(OfflineOperation operation) async {
    final groupId = operation.entityId;
    if (groupId == null) throw Exception('Group ID required');

    final email = operation.data['email'] as String?;
    if (email == null) throw Exception('Email required');

    // Find user by email
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('User not found with email: $email');
    }

    final userId = userQuery.docs.first.id;

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> _removeGroupMember(OfflineOperation operation) async {
    final groupId = operation.entityId;
    final userId = operation.data['userId'] as String?;
    if (groupId == null || userId == null) {
      throw Exception('Group ID and User ID required');
    }

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }
}
