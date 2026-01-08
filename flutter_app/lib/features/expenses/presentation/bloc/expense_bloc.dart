import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_event.dart';
import 'expense_state.dart';

/// BLoC for managing expense state
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;
  StreamSubscription<List<ExpenseEntity>>? _expensesSubscription;

  ExpenseBloc({required ExpenseRepository expenseRepository})
    : _expenseRepository = expenseRepository,
      super(const ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<WatchExpenses>(_onWatchExpenses);
    on<ExpensesUpdated>(_onExpensesUpdated);
    on<CreateExpense>(_onCreateExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<LoadExpenseDetail>(_onLoadExpenseDetail);
    on<ClearExpenseState>(_onClearExpenseState);
  }

  /// Load expenses for a group
  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    final result = await _expenseRepository.getExpenses(event.groupId);

    result.fold((failure) => emit(ExpenseError(message: failure.message)), (
      expenses,
    ) {
      final totalAmount = expenses.fold(0, (sum, e) => sum + e.amount);
      emit(
        ExpenseLoaded(
          expenses: expenses,
          groupId: event.groupId,
          totalAmount: totalAmount,
        ),
      );
    });
  }

  /// Watch expenses for real-time updates
  Future<void> _onWatchExpenses(
    WatchExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    // Cancel any existing subscription
    await _expensesSubscription?.cancel();

    _expensesSubscription = _expenseRepository
        .watchExpenses(event.groupId)
        .listen((expenses) {
          add(ExpensesUpdated(expenses));
        });
  }

  /// Handle expense stream updates
  void _onExpensesUpdated(ExpensesUpdated event, Emitter<ExpenseState> emit) {
    final currentState = state;
    String groupId = '';

    if (currentState is ExpenseLoaded) {
      groupId = currentState.groupId;
    }

    final totalAmount = event.expenses.fold(0, (sum, e) => sum + e.amount);
    emit(
      ExpenseLoaded(
        expenses: event.expenses,
        groupId: groupId,
        totalAmount: totalAmount,
      ),
    );
  }

  /// Create a new expense
  Future<void> _onCreateExpense(
    CreateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseOperationInProgress(operation: 'Creating expense...'));

    final result = await _expenseRepository.createExpense(
      groupId: event.groupId,
      description: event.description,
      amount: event.amount,
      currency: event.currency,
      category: event.category,
      date: event.date,
      paidBy: event.paidBy,
      splitType: event.splitType,
      splits: event.splits,
      receiptUrls: event.receiptUrls,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(ExpenseError(message: failure.message)),
      (expense) => emit(ExpenseCreated(expense: expense)),
    );
  }

  /// Update an existing expense
  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseOperationInProgress(operation: 'Updating expense...'));

    final result = await _expenseRepository.updateExpense(
      groupId: event.groupId,
      expenseId: event.expenseId,
      description: event.description,
      amount: event.amount,
      category: event.category,
      date: event.date,
      paidBy: event.paidBy,
      splitType: event.splitType,
      splits: event.splits,
      receiptUrls: event.receiptUrls,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(ExpenseError(message: failure.message)),
      (expense) => emit(ExpenseUpdated(expense: expense)),
    );
  }

  /// Delete an expense
  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseOperationInProgress(operation: 'Deleting expense...'));

    final result = await _expenseRepository.deleteExpense(
      event.groupId,
      event.expenseId,
    );

    result.fold(
      (failure) => emit(ExpenseError(message: failure.message)),
      (_) => emit(ExpenseDeleted(expenseId: event.expenseId)),
    );
  }

  /// Load a single expense detail
  Future<void> _onLoadExpenseDetail(
    LoadExpenseDetail event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    final result = await _expenseRepository.getExpense(
      event.groupId,
      event.expenseId,
    );

    result.fold(
      (failure) => emit(ExpenseError(message: failure.message)),
      (expense) => emit(ExpenseDetailLoaded(expense: expense)),
    );
  }

  /// Clear expense state
  void _onClearExpenseState(
    ClearExpenseState event,
    Emitter<ExpenseState> emit,
  ) {
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(const ExpenseInitial());
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    return super.close();
  }
}
