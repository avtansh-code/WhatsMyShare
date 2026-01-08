import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

/// Abstract expense datasource
abstract class ExpenseDatasource {
  /// Get expenses for a group
  Future<List<ExpenseModel>> getExpenses(String groupId);

  /// Watch expenses for a group
  Stream<List<ExpenseModel>> watchExpenses(String groupId);

  /// Get a single expense
  Future<ExpenseModel> getExpense(String groupId, String expenseId);

  /// Create a new expense
  Future<ExpenseModel> createExpense(String groupId, ExpenseModel expense);

  /// Update an expense
  Future<ExpenseModel> updateExpense(String groupId, ExpenseModel expense);

  /// Soft delete an expense
  Future<void> deleteExpense(String groupId, String expenseId);

  /// Permanently delete an expense
  Future<void> permanentlyDeleteExpense(String groupId, String expenseId);

  /// Upload receipt image
  Future<String> uploadReceipt(
    String groupId,
    String expenseId,
    String filePath,
  );

  /// Delete receipt image
  Future<void> deleteReceipt(String receiptUrl);
}

/// Firebase implementation of expense datasource
class FirebaseExpenseDatasource implements ExpenseDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  FirebaseExpenseDatasource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  /// Get current user ID
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'User not authenticated');
    }
    return user.uid;
  }

  /// Get expenses collection reference for a group
  CollectionReference<Map<String, dynamic>> _expensesRef(String groupId) {
    return _firestore.collection('groups').doc(groupId).collection('expenses');
  }

  @override
  Future<List<ExpenseModel>> getExpenses(String groupId) async {
    try {
      final snapshot = await _expensesRef(groupId)
          .where('status', isEqualTo: 'active')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get expenses');
    }
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses(String groupId) {
    return _expensesRef(groupId)
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<ExpenseModel> getExpense(String groupId, String expenseId) async {
    try {
      final doc = await _expensesRef(groupId).doc(expenseId).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Expense not found');
      }
      return ExpenseModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get expense');
    }
  }

  @override
  Future<ExpenseModel> createExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    try {
      final docRef = _expensesRef(groupId).doc();
      final now = DateTime.now();

      final newExpense = ExpenseModel(
        id: docRef.id,
        groupId: groupId,
        description: expense.description,
        amount: expense.amount,
        currency: expense.currency,
        category: expense.category,
        date: expense.date,
        paidBy: expense.paidBy,
        splitType: expense.splitType,
        splits: expense.splits,
        receiptUrls: expense.receiptUrls,
        notes: expense.notes,
        createdBy: _currentUserId,
        status: ExpenseStatus.active,
        chatMessageCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newExpense.toFirestore());

      // Update group's total expenses and last activity
      await _updateGroupStats(groupId, expense.amount);

      return newExpense;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to create expense');
    }
  }

  @override
  Future<ExpenseModel> updateExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    try {
      final docRef = _expensesRef(groupId).doc(expense.id);

      // Get current expense for amount difference calculation
      final currentDoc = await docRef.get();
      if (!currentDoc.exists) {
        throw const ServerException(message: 'Expense not found');
      }
      final currentExpense = ExpenseModel.fromFirestore(currentDoc);

      final updatedExpense = ExpenseModel(
        id: expense.id,
        groupId: groupId,
        description: expense.description,
        amount: expense.amount,
        currency: expense.currency,
        category: expense.category,
        date: expense.date,
        paidBy: expense.paidBy,
        splitType: expense.splitType,
        splits: expense.splits,
        receiptUrls: expense.receiptUrls,
        notes: expense.notes,
        createdBy: currentExpense.createdBy,
        status: expense.status,
        chatMessageCount: currentExpense.chatMessageCount,
        createdAt: currentExpense.createdAt,
        updatedAt: DateTime.now(),
      );

      await docRef.update(updatedExpense.toFirestore());

      // Update group stats if amount changed
      final amountDiff = expense.amount - currentExpense.amount;
      if (amountDiff != 0) {
        await _updateGroupStats(groupId, amountDiff);
      }

      return updatedExpense;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to update expense');
    }
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    try {
      final docRef = _expensesRef(groupId).doc(expenseId);

      // Get expense for amount
      final doc = await docRef.get();
      if (!doc.exists) {
        throw const ServerException(message: 'Expense not found');
      }
      final expense = ExpenseModel.fromFirestore(doc);

      // Soft delete
      await docRef.update({
        'status': 'deleted',
        'deletedAt': Timestamp.now(),
        'deletedBy': _currentUserId,
        'updatedAt': Timestamp.now(),
      });

      // Update group stats (subtract expense amount)
      await _updateGroupStats(groupId, -expense.amount);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete expense');
    }
  }

  @override
  Future<void> permanentlyDeleteExpense(
    String groupId,
    String expenseId,
  ) async {
    try {
      await _expensesRef(groupId).doc(expenseId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to permanently delete expense',
      );
    }
  }

  @override
  Future<String> uploadReceipt(
    String groupId,
    String expenseId,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage.ref().child(
        'groups/$groupId/expenses/$expenseId/receipts/$fileName',
      );

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to upload receipt');
    }
  }

  @override
  Future<void> deleteReceipt(String receiptUrl) async {
    try {
      final ref = _storage.refFromURL(receiptUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete receipt');
    }
  }

  /// Update group statistics after expense changes
  Future<void> _updateGroupStats(String groupId, int amountDelta) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    await groupRef.update({
      'totalExpenses': FieldValue.increment(amountDelta),
      'expenseCount': FieldValue.increment(amountDelta > 0 ? 1 : -1),
      'lastActivityAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
}
