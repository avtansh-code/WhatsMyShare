import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_entity.dart';

/// Base class for all expense states
abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

/// Loading expenses
class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

/// Expenses loaded successfully
class ExpenseLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;
  final String groupId;
  final int totalAmount;

  const ExpenseLoaded({
    required this.expenses,
    required this.groupId,
    this.totalAmount = 0,
  });

  @override
  List<Object?> get props => [expenses, groupId, totalAmount];

  ExpenseLoaded copyWith({
    List<ExpenseEntity>? expenses,
    String? groupId,
    int? totalAmount,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      groupId: groupId ?? this.groupId,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

/// Single expense detail loaded
class ExpenseDetailLoaded extends ExpenseState {
  final ExpenseEntity expense;

  const ExpenseDetailLoaded({required this.expense});

  @override
  List<Object?> get props => [expense];
}

/// Expense created successfully
class ExpenseCreated extends ExpenseState {
  final ExpenseEntity expense;
  final String message;

  const ExpenseCreated({
    required this.expense,
    this.message = 'Expense created successfully',
  });

  @override
  List<Object?> get props => [expense, message];
}

/// Expense updated successfully
class ExpenseUpdated extends ExpenseState {
  final ExpenseEntity expense;
  final String message;

  const ExpenseUpdated({
    required this.expense,
    this.message = 'Expense updated successfully',
  });

  @override
  List<Object?> get props => [expense, message];
}

/// Expense deleted successfully
class ExpenseDeleted extends ExpenseState {
  final String expenseId;
  final String message;

  const ExpenseDeleted({
    required this.expenseId,
    this.message = 'Expense deleted successfully',
  });

  @override
  List<Object?> get props => [expenseId, message];
}

/// Error state
class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Operation in progress (for create/update/delete)
class ExpenseOperationInProgress extends ExpenseState {
  final String operation;

  const ExpenseOperationInProgress({required this.operation});

  @override
  List<Object?> get props => [operation];
}
