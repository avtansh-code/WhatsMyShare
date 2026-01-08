import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_entity.dart';

/// Base class for all expense events
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

/// Load expenses for a group
class LoadExpenses extends ExpenseEvent {
  final String groupId;

  const LoadExpenses(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Watch expenses for real-time updates
class WatchExpenses extends ExpenseEvent {
  final String groupId;

  const WatchExpenses(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Create a new expense
class CreateExpense extends ExpenseEvent {
  final String groupId;
  final String description;
  final int amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final List<PayerInfo> paidBy;
  final SplitType splitType;
  final List<ExpenseSplit> splits;
  final List<String>? receiptUrls;
  final String? notes;

  const CreateExpense({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    this.receiptUrls,
    this.notes,
  });

  @override
  List<Object?> get props => [
    groupId,
    description,
    amount,
    currency,
    category,
    date,
    paidBy,
    splitType,
    splits,
    receiptUrls,
    notes,
  ];
}

/// Update an existing expense
class UpdateExpense extends ExpenseEvent {
  final String groupId;
  final String expenseId;
  final String? description;
  final int? amount;
  final ExpenseCategory? category;
  final DateTime? date;
  final List<PayerInfo>? paidBy;
  final SplitType? splitType;
  final List<ExpenseSplit>? splits;
  final List<String>? receiptUrls;
  final String? notes;

  const UpdateExpense({
    required this.groupId,
    required this.expenseId,
    this.description,
    this.amount,
    this.category,
    this.date,
    this.paidBy,
    this.splitType,
    this.splits,
    this.receiptUrls,
    this.notes,
  });

  @override
  List<Object?> get props => [
    groupId,
    expenseId,
    description,
    amount,
    category,
    date,
    paidBy,
    splitType,
    splits,
    receiptUrls,
    notes,
  ];
}

/// Delete an expense
class DeleteExpense extends ExpenseEvent {
  final String groupId;
  final String expenseId;

  const DeleteExpense({required this.groupId, required this.expenseId});

  @override
  List<Object?> get props => [groupId, expenseId];
}

/// Load a single expense
class LoadExpenseDetail extends ExpenseEvent {
  final String groupId;
  final String expenseId;

  const LoadExpenseDetail({required this.groupId, required this.expenseId});

  @override
  List<Object?> get props => [groupId, expenseId];
}

/// Expense stream updated
class ExpensesUpdated extends ExpenseEvent {
  final List<ExpenseEntity> expenses;

  const ExpensesUpdated(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

/// Clear expense state
class ClearExpenseState extends ExpenseEvent {
  const ClearExpenseState();
}
