import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/expense_entity.dart';

/// Abstract expense repository interface
abstract class ExpenseRepository {
  /// Get all expenses for a group
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses(String groupId);

  /// Watch expenses for a group in real-time
  Stream<List<ExpenseEntity>> watchExpenses(String groupId);

  /// Get a single expense by ID
  Future<Either<Failure, ExpenseEntity>> getExpense(
    String groupId,
    String expenseId,
  );

  /// Create a new expense
  Future<Either<Failure, ExpenseEntity>> createExpense({
    required String groupId,
    required String description,
    required int amount,
    required String currency,
    required ExpenseCategory category,
    required DateTime date,
    required List<PayerInfo> paidBy,
    required SplitType splitType,
    required List<ExpenseSplit> splits,
    List<String>? receiptUrls,
    String? notes,
  });

  /// Update an existing expense
  Future<Either<Failure, ExpenseEntity>> updateExpense({
    required String groupId,
    required String expenseId,
    String? description,
    int? amount,
    ExpenseCategory? category,
    DateTime? date,
    List<PayerInfo>? paidBy,
    SplitType? splitType,
    List<ExpenseSplit>? splits,
    List<String>? receiptUrls,
    String? notes,
  });

  /// Soft delete an expense (marks as deleted)
  Future<Either<Failure, void>> deleteExpense(String groupId, String expenseId);

  /// Permanently delete an expense
  Future<Either<Failure, void>> permanentlyDeleteExpense(
    String groupId,
    String expenseId,
  );

  /// Upload receipt image and return URL
  Future<Either<Failure, String>> uploadReceipt({
    required String groupId,
    required String expenseId,
    required String filePath,
  });

  /// Delete a receipt image
  Future<Either<Failure, void>> deleteReceipt({
    required String groupId,
    required String expenseId,
    required String receiptUrl,
  });

  /// Get expenses by category for a group
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByCategory(
    String groupId,
    ExpenseCategory category,
  );

  /// Get expenses within a date range
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get recent expenses across all user's groups
  Future<Either<Failure, List<ExpenseEntity>>> getRecentExpenses({
    int limit = 10,
  });

  /// Get total expenses for a group
  Future<Either<Failure, int>> getTotalExpenses(String groupId);

  /// Get expense statistics for a group
  Future<Either<Failure, ExpenseStatistics>> getExpenseStatistics(
    String groupId,
  );
}

/// Statistics about expenses in a group
class ExpenseStatistics {
  final int totalAmount;
  final int expenseCount;
  final Map<ExpenseCategory, int> byCategory;
  final Map<String, int> byPayer; // userId -> total paid
  final DateTime? oldestExpense;
  final DateTime? newestExpense;

  const ExpenseStatistics({
    required this.totalAmount,
    required this.expenseCount,
    required this.byCategory,
    required this.byPayer,
    this.oldestExpense,
    this.newestExpense,
  });

  /// Average expense amount
  double get averageAmount =>
      expenseCount > 0 ? totalAmount / expenseCount : 0.0;

  /// Get the most used category
  ExpenseCategory? get topCategory {
    if (byCategory.isEmpty) return null;
    return byCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
