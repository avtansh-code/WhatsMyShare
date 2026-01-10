import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_event.dart';
import 'expense_state.dart';

/// BLoC for managing expense state
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;
  final LoggingService _log = LoggingService();
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

    _log.info('ExpenseBloc initialized', tag: LogTags.expenses);
  }

  /// Load expenses for a group
  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    _log.debug(
      'Loading expenses',
      tag: LogTags.expenses,
      data: {'groupId': event.groupId},
    );
    emit(const ExpenseLoading());

    final result = await _expenseRepository.getExpenses(event.groupId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to load expenses',
          tag: LogTags.expenses,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(ExpenseError(message: ErrorMessages.expenseLoadFailed));
      },
      (expenses) {
        _log.info(
          'Expenses loaded successfully',
          tag: LogTags.expenses,
          data: {'groupId': event.groupId, 'count': expenses.length},
        );
        final totalAmount = expenses.fold(0, (sum, e) => sum + e.amount);
        emit(
          ExpenseLoaded(
            expenses: expenses,
            groupId: event.groupId,
            totalAmount: totalAmount,
          ),
        );
      },
    );
  }

  /// Watch expenses for real-time updates
  Future<void> _onWatchExpenses(
    WatchExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    _log.debug(
      'Watching expenses',
      tag: LogTags.expenses,
      data: {'groupId': event.groupId},
    );
    emit(const ExpenseLoading());

    // Cancel any existing subscription
    await _expensesSubscription?.cancel();

    _expensesSubscription = _expenseRepository
        .watchExpenses(event.groupId)
        .listen(
          (expenses) {
            _log.debug(
              'Expenses stream updated',
              tag: LogTags.expenses,
              data: {'count': expenses.length},
            );
            add(ExpensesUpdated(expenses));
          },
          onError: (error, stackTrace) {
            _log.error(
              'Expenses stream error',
              tag: LogTags.expenses,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
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
    _log.info(
      'Creating expense',
      tag: LogTags.expenses,
      data: {
        'groupId': event.groupId,
        'description': event.description,
        'amount': event.amount,
      },
    );
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
      (failure) {
        _log.error(
          'Failed to create expense',
          tag: LogTags.expenses,
          data: {'error': failure.message},
        );
        emit(ExpenseError(message: ErrorMessages.expenseCreateFailed));
      },
      (expense) {
        _log.info(
          'Expense created successfully',
          tag: LogTags.expenses,
          data: {'expenseId': expense.id, 'amount': expense.amount},
        );
        emit(ExpenseCreated(expense: expense));
      },
    );
  }

  /// Update an existing expense
  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    _log.info(
      'Updating expense',
      tag: LogTags.expenses,
      data: {'groupId': event.groupId, 'expenseId': event.expenseId},
    );
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
      (failure) {
        _log.error(
          'Failed to update expense',
          tag: LogTags.expenses,
          data: {'expenseId': event.expenseId, 'error': failure.message},
        );
        emit(ExpenseError(message: ErrorMessages.expenseUpdateFailed));
      },
      (expense) {
        _log.info(
          'Expense updated successfully',
          tag: LogTags.expenses,
          data: {'expenseId': expense.id},
        );
        emit(ExpenseUpdated(expense: expense));
      },
    );
  }

  /// Delete an expense
  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    _log.info(
      'Deleting expense',
      tag: LogTags.expenses,
      data: {'groupId': event.groupId, 'expenseId': event.expenseId},
    );
    emit(const ExpenseOperationInProgress(operation: 'Deleting expense...'));

    final result = await _expenseRepository.deleteExpense(
      event.groupId,
      event.expenseId,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete expense',
          tag: LogTags.expenses,
          data: {'expenseId': event.expenseId, 'error': failure.message},
        );
        emit(ExpenseError(message: ErrorMessages.expenseDeleteFailed));
      },
      (_) {
        _log.info(
          'Expense deleted successfully',
          tag: LogTags.expenses,
          data: {'expenseId': event.expenseId},
        );
        emit(ExpenseDeleted(expenseId: event.expenseId));
      },
    );
  }

  /// Load a single expense detail
  Future<void> _onLoadExpenseDetail(
    LoadExpenseDetail event,
    Emitter<ExpenseState> emit,
  ) async {
    _log.debug(
      'Loading expense detail',
      tag: LogTags.expenses,
      data: {'groupId': event.groupId, 'expenseId': event.expenseId},
    );
    emit(const ExpenseLoading());

    final result = await _expenseRepository.getExpense(
      event.groupId,
      event.expenseId,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to load expense detail',
          tag: LogTags.expenses,
          data: {'expenseId': event.expenseId, 'error': failure.message},
        );
        emit(ExpenseError(message: ErrorMessages.expenseNotFound));
      },
      (expense) {
        _log.debug(
          'Expense detail loaded',
          tag: LogTags.expenses,
          data: {'expenseId': expense.id},
        );
        emit(ExpenseDetailLoaded(expense: expense));
      },
    );
  }

  /// Clear expense state
  void _onClearExpenseState(
    ClearExpenseState event,
    Emitter<ExpenseState> emit,
  ) {
    _log.debug('Clearing expense state', tag: LogTags.expenses);
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(const ExpenseInitial());
  }

  @override
  Future<void> close() {
    _log.debug('ExpenseBloc closing', tag: LogTags.expenses);
    _expensesSubscription?.cancel();
    return super.close();
  }
}
