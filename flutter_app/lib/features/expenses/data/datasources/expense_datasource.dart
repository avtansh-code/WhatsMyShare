import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

/// Pagination result with cursor for next page
class ExpensePaginatedResult {
  final List<ExpenseModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ExpensePaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}

/// Abstract expense datasource
abstract class ExpenseDatasource {
  /// Get expenses for a group
  Future<List<ExpenseModel>> getExpenses(String groupId);

  /// Get paginated expenses for a group
  Future<ExpensePaginatedResult> getExpensesPaginated(
    String groupId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  });

  /// Watch expenses for a group
  Stream<List<ExpenseModel>> watchExpenses(String groupId);

  /// Watch paginated expenses for a group
  Stream<List<ExpenseModel>> watchExpensesPaginated(
    String groupId, {
    int limit = 20,
  });

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
  final EncryptionService _encryptionService;
  final LoggingService _log = LoggingService();

  FirebaseExpenseDatasource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    required EncryptionService encryptionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _encryptionService = encryptionService {
    _log.debug('ExpenseDatasource initialized', tag: LogTags.expenses);
  }

  /// Get current user ID
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      _log.error(
        'User not authenticated when accessing expenses',
        tag: LogTags.expenses,
      );
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
    _log.debug(
      'Fetching expenses for group',
      tag: LogTags.expenses,
      data: {'groupId': groupId},
    );
    try {
      final snapshot = await _expensesRef(groupId)
          .where('status', isEqualTo: 'active')
          .orderBy('date', descending: true)
          .get();

      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
      _log.info(
        'Expenses fetched successfully',
        tag: LogTags.expenses,
        data: {'groupId': groupId, 'count': expenses.length},
      );
      return expenses;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get expenses',
        tag: LogTags.expenses,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get expenses');
    }
  }

  @override
  Future<ExpensePaginatedResult> getExpensesPaginated(
    String groupId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    _log.debug(
      'Fetching paginated expenses for group',
      tag: LogTags.expenses,
      data: {
        'groupId': groupId,
        'limit': limit,
        'hasStartAfter': startAfter != null,
      },
    );
    try {
      Query<Map<String, dynamic>> query = _expensesRef(groupId)
          .where('status', isEqualTo: 'active')
          .orderBy('date', descending: true)
          .limit(limit + 1); // Fetch one extra to check if there are more

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

      final expenses = docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      _log.info(
        'Paginated expenses fetched successfully',
        tag: LogTags.expenses,
        data: {
          'groupId': groupId,
          'count': expenses.length,
          'hasMore': hasMore,
        },
      );

      return ExpensePaginatedResult(
        items: expenses,
        lastDocument: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get paginated expenses',
        tag: LogTags.expenses,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to get paginated expenses',
      );
    }
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses(String groupId) {
    _log.debug(
      'Setting up expenses stream',
      tag: LogTags.expenses,
      data: {'groupId': groupId},
    );
    return _expensesRef(groupId)
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          _log.debug(
            'Expenses stream updated',
            tag: LogTags.expenses,
            data: {'count': snapshot.docs.length},
          );
          return snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<ExpenseModel>> watchExpensesPaginated(
    String groupId, {
    int limit = 20,
  }) {
    _log.debug(
      'Setting up paginated expenses stream',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'limit': limit},
    );
    return _expensesRef(groupId)
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          _log.debug(
            'Paginated expenses stream updated',
            tag: LogTags.expenses,
            data: {'count': snapshot.docs.length},
          );
          return snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<ExpenseModel> getExpense(String groupId, String expenseId) async {
    _log.debug(
      'Fetching expense by ID',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'expenseId': expenseId},
    );
    try {
      final doc = await _expensesRef(groupId).doc(expenseId).get();
      if (!doc.exists) {
        _log.warning(
          'Expense not found',
          tag: LogTags.expenses,
          data: {'groupId': groupId, 'expenseId': expenseId},
        );
        throw const ServerException(message: 'Expense not found');
      }
      _log.debug('Expense fetched successfully', tag: LogTags.expenses);
      return ExpenseModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get expense',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get expense');
    }
  }

  @override
  Future<ExpenseModel> createExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    _log.info(
      'Creating expense',
      tag: LogTags.expenses,
      data: {
        'groupId': groupId,
        'description': expense.description,
        'amount': expense.amount,
      },
    );
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

      _log.info(
        'Expense created successfully',
        tag: LogTags.expenses,
        data: {'expenseId': docRef.id, 'amount': expense.amount},
      );
      return newExpense;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to create expense',
        tag: LogTags.expenses,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to create expense');
    }
  }

  @override
  Future<ExpenseModel> updateExpense(
    String groupId,
    ExpenseModel expense,
  ) async {
    _log.info(
      'Updating expense',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'expenseId': expense.id},
    );
    try {
      final docRef = _expensesRef(groupId).doc(expense.id);

      // Get current expense for amount difference calculation
      final currentDoc = await docRef.get();
      if (!currentDoc.exists) {
        _log.warning(
          'Expense not found for update',
          tag: LogTags.expenses,
          data: {'expenseId': expense.id},
        );
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
        _log.debug(
          'Updating group stats for amount change',
          tag: LogTags.expenses,
          data: {'amountDiff': amountDiff},
        );
        await _updateGroupStats(groupId, amountDiff);
      }

      _log.info(
        'Expense updated successfully',
        tag: LogTags.expenses,
        data: {'expenseId': expense.id},
      );
      return updatedExpense;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update expense',
        tag: LogTags.expenses,
        data: {'expenseId': expense.id, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to update expense');
    }
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    _log.info(
      'Soft deleting expense',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'expenseId': expenseId},
    );
    try {
      final docRef = _expensesRef(groupId).doc(expenseId);

      // Get expense for amount
      final doc = await docRef.get();
      if (!doc.exists) {
        _log.warning(
          'Expense not found for deletion',
          tag: LogTags.expenses,
          data: {'expenseId': expenseId},
        );
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
      _log.info(
        'Expense soft deleted successfully',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId, 'amount': expense.amount},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete expense',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to delete expense');
    }
  }

  @override
  Future<void> permanentlyDeleteExpense(
    String groupId,
    String expenseId,
  ) async {
    _log.warning(
      'Permanently deleting expense',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'expenseId': expenseId},
    );
    try {
      await _expensesRef(groupId).doc(expenseId).delete();
      _log.info(
        'Expense permanently deleted',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to permanently delete expense',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId, 'error': e.message},
      );
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
    _log.info(
      'Uploading encrypted receipt',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'expenseId': expenseId},
    );
    try {
      final file = File(filePath);
      
      // Encrypt the file before uploading
      _log.debug('Encrypting receipt before upload', tag: LogTags.encryption);
      final encryptedBytes = await _encryptionService.encryptFile(file);
      
      // Use .enc extension to indicate encrypted file
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_receipt.enc';
      final ref = _storage.ref().child(
        'groups/$groupId/expenses/$expenseId/receipts/$fileName',
      );

      // Upload encrypted data with appropriate metadata
      final metadata = SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {
          'encrypted': 'true',
          'originalExtension': file.uri.pathSegments.last.split('.').last,
        },
      );
      
      await ref.putData(encryptedBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();
      
      _log.info(
        'Encrypted receipt uploaded successfully',
        tag: LogTags.expenses,
        data: {
          'expenseId': expenseId,
          'originalSize': (await file.length()),
          'encryptedSize': encryptedBytes.length,
        },
      );
      return downloadUrl;
    } on EncryptionException catch (e) {
      _log.error(
        'Failed to encrypt receipt',
        tag: LogTags.encryption,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: 'Failed to encrypt receipt: ${e.message}');
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to upload receipt',
        tag: LogTags.expenses,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to upload receipt');
    }
  }

  @override
  Future<void> deleteReceipt(String receiptUrl) async {
    _log.info('Deleting receipt', tag: LogTags.expenses);
    try {
      final ref = _storage.refFromURL(receiptUrl);
      await ref.delete();
      _log.info('Receipt deleted successfully', tag: LogTags.expenses);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete receipt',
        tag: LogTags.expenses,
        data: {'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to delete receipt');
    }
  }

  /// Update group statistics after expense changes
  Future<void> _updateGroupStats(String groupId, int amountDelta) async {
    _log.debug(
      'Updating group stats',
      tag: LogTags.expenses,
      data: {'groupId': groupId, 'amountDelta': amountDelta},
    );
    final groupRef = _firestore.collection('groups').doc(groupId);
    await groupRef.update({
      'totalExpenses': FieldValue.increment(amountDelta),
      'expenseCount': FieldValue.increment(amountDelta > 0 ? 1 : -1),
      'lastActivityAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
}
