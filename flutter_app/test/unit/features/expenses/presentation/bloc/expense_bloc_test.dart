import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/features/expenses/domain/entities/expense_entity.dart';
import 'package:whats_my_share/features/expenses/domain/repositories/expense_repository.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_event.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_state.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ExpenseCategory.food);
    registerFallbackValue(SplitType.equal);
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(<PayerInfo>[]);
    registerFallbackValue(<ExpenseSplit>[]);
    registerFallbackValue(<String>[]);
  });

  late ExpenseBloc bloc;
  late MockExpenseRepository mockRepository;

  final testDateTime = DateTime(2026, 1, 9);

  final testExpense = ExpenseEntity(
    id: 'expense-1',
    groupId: 'group-1',
    description: 'Dinner at restaurant',
    amount: 100000, // ₹1000.00
    currency: 'INR',
    category: ExpenseCategory.food,
    date: testDateTime,
    paidBy: [
      const PayerInfo(
        userId: 'user-1',
        displayName: 'John Doe',
        amount: 100000,
      ),
    ],
    splitType: SplitType.equal,
    splits: [
      const ExpenseSplit(
        userId: 'user-1',
        displayName: 'John Doe',
        amount: 50000,
      ),
      const ExpenseSplit(
        userId: 'user-2',
        displayName: 'Jane Doe',
        amount: 50000,
      ),
    ],
    createdBy: 'user-1',
    status: ExpenseStatus.active,
    createdAt: testDateTime,
    updatedAt: testDateTime,
  );

  final testExpense2 = ExpenseEntity(
    id: 'expense-2',
    groupId: 'group-1',
    description: 'Cab ride',
    amount: 50000, // ₹500.00
    currency: 'INR',
    category: ExpenseCategory.transport,
    date: testDateTime,
    paidBy: [
      const PayerInfo(userId: 'user-2', displayName: 'Jane Doe', amount: 50000),
    ],
    splitType: SplitType.equal,
    splits: [
      const ExpenseSplit(
        userId: 'user-1',
        displayName: 'John Doe',
        amount: 25000,
      ),
      const ExpenseSplit(
        userId: 'user-2',
        displayName: 'Jane Doe',
        amount: 25000,
      ),
    ],
    createdBy: 'user-2',
    status: ExpenseStatus.active,
    createdAt: testDateTime,
    updatedAt: testDateTime,
  );

  setUp(() {
    mockRepository = MockExpenseRepository();
    bloc = ExpenseBloc(expenseRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ExpenseBloc', () {
    test('initial state is ExpenseInitial', () {
      expect(bloc.state, isA<ExpenseInitial>());
    });

    group('LoadExpenses', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseLoading, ExpenseLoaded] when loading succeeds',
        build: () {
          when(
            () => mockRepository.getExpenses(any()),
          ).thenAnswer((_) async => Right([testExpense, testExpense2]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadExpenses('group-1')),
        expect: () => [
          isA<ExpenseLoading>(),
          isA<ExpenseLoaded>()
              .having((s) => s.expenses.length, 'expenses count', 2)
              .having((s) => s.groupId, 'groupId', 'group-1')
              .having((s) => s.totalAmount, 'totalAmount', 150000),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseLoading, ExpenseError] when loading fails',
        build: () {
          when(() => mockRepository.getExpenses(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Failed to load')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadExpenses('group-1')),
        expect: () => [
          isA<ExpenseLoading>(),
          isA<ExpenseError>().having((s) => s.message, 'message', isNotEmpty),
        ],
      );
    });

    group('CreateExpense', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseCreated] when creation succeeds',
        build: () {
          when(
            () => mockRepository.createExpense(
              groupId: any(named: 'groupId'),
              description: any(named: 'description'),
              amount: any(named: 'amount'),
              currency: any(named: 'currency'),
              category: any(named: 'category'),
              date: any(named: 'date'),
              paidBy: any(named: 'paidBy'),
              splitType: any(named: 'splitType'),
              splits: any(named: 'splits'),
              receiptUrls: any(named: 'receiptUrls'),
              notes: any(named: 'notes'),
            ),
          ).thenAnswer((_) async => Right(testExpense));
          return bloc;
        },
        act: (bloc) => bloc.add(
          CreateExpense(
            groupId: 'group-1',
            description: 'Dinner at restaurant',
            amount: 100000,
            currency: 'INR',
            category: ExpenseCategory.food,
            date: testDateTime,
            paidBy: testExpense.paidBy,
            splitType: SplitType.equal,
            splits: testExpense.splits,
          ),
        ),
        expect: () => [
          isA<ExpenseOperationInProgress>().having(
            (s) => s.operation,
            'operation',
            contains('Creating'),
          ),
          isA<ExpenseCreated>().having(
            (s) => s.expense.id,
            'expense id',
            'expense-1',
          ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseError] when creation fails',
        build: () {
          when(
            () => mockRepository.createExpense(
              groupId: any(named: 'groupId'),
              description: any(named: 'description'),
              amount: any(named: 'amount'),
              currency: any(named: 'currency'),
              category: any(named: 'category'),
              date: any(named: 'date'),
              paidBy: any(named: 'paidBy'),
              splitType: any(named: 'splitType'),
              splits: any(named: 'splits'),
              receiptUrls: any(named: 'receiptUrls'),
              notes: any(named: 'notes'),
            ),
          ).thenAnswer((_) async => Left(ServerFailure(message: 'Failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(
          CreateExpense(
            groupId: 'group-1',
            description: 'Dinner at restaurant',
            amount: 100000,
            currency: 'INR',
            category: ExpenseCategory.food,
            date: testDateTime,
            paidBy: testExpense.paidBy,
            splitType: SplitType.equal,
            splits: testExpense.splits,
          ),
        ),
        expect: () => [isA<ExpenseOperationInProgress>(), isA<ExpenseError>()],
      );
    });

    group('UpdateExpense', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseUpdated] when update succeeds',
        build: () {
          final updatedExpense = testExpense.copyWith(
            description: 'Updated dinner',
          );
          when(
            () => mockRepository.updateExpense(
              groupId: 'group-1',
              expenseId: 'expense-1',
              description: 'Updated dinner',
              amount: null,
              category: null,
              date: null,
              paidBy: null,
              splitType: null,
              splits: null,
              receiptUrls: null,
              notes: null,
            ),
          ).thenAnswer((_) async => Right(updatedExpense));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const UpdateExpense(
            groupId: 'group-1',
            expenseId: 'expense-1',
            description: 'Updated dinner',
          ),
        ),
        expect: () => [
          isA<ExpenseOperationInProgress>().having(
            (s) => s.operation,
            'operation',
            contains('Updating'),
          ),
          isA<ExpenseUpdated>().having(
            (s) => s.expense.description,
            'description',
            'Updated dinner',
          ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseError] when update fails',
        build: () {
          when(
            () => mockRepository.updateExpense(
              groupId: 'group-1',
              expenseId: 'expense-1',
              description: 'Updated dinner',
              amount: null,
              category: null,
              date: null,
              paidBy: null,
              splitType: null,
              splits: null,
              receiptUrls: null,
              notes: null,
            ),
          ).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Update failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const UpdateExpense(
            groupId: 'group-1',
            expenseId: 'expense-1',
            description: 'Updated dinner',
          ),
        ),
        expect: () => [isA<ExpenseOperationInProgress>(), isA<ExpenseError>()],
      );
    });

    group('DeleteExpense', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockRepository.deleteExpense(any(), any()),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteExpense(groupId: 'group-1', expenseId: 'expense-1'),
        ),
        expect: () => [
          isA<ExpenseOperationInProgress>().having(
            (s) => s.operation,
            'operation',
            contains('Deleting'),
          ),
          isA<ExpenseDeleted>().having(
            (s) => s.expenseId,
            'expenseId',
            'expense-1',
          ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseOperationInProgress, ExpenseError] when deletion fails',
        build: () {
          when(() => mockRepository.deleteExpense(any(), any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Delete failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteExpense(groupId: 'group-1', expenseId: 'expense-1'),
        ),
        expect: () => [isA<ExpenseOperationInProgress>(), isA<ExpenseError>()],
      );
    });

    group('LoadExpenseDetail', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseLoading, ExpenseDetailLoaded] when loading detail succeeds',
        build: () {
          when(
            () => mockRepository.getExpense(any(), any()),
          ).thenAnswer((_) async => Right(testExpense));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const LoadExpenseDetail(groupId: 'group-1', expenseId: 'expense-1'),
        ),
        expect: () => [
          isA<ExpenseLoading>(),
          isA<ExpenseDetailLoaded>().having(
            (s) => s.expense.id,
            'expense id',
            'expense-1',
          ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'emits [ExpenseLoading, ExpenseError] when loading detail fails',
        build: () {
          when(
            () => mockRepository.getExpense(any(), any()),
          ).thenAnswer((_) async => Left(ServerFailure(message: 'Not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const LoadExpenseDetail(groupId: 'group-1', expenseId: 'expense-1'),
        ),
        expect: () => [isA<ExpenseLoading>(), isA<ExpenseError>()],
      );
    });

    group('ExpensesUpdated', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'updates expenses when ExpensesUpdated event is received',
        build: () => bloc,
        act: (bloc) => bloc.add(ExpensesUpdated([testExpense, testExpense2])),
        expect: () => [
          isA<ExpenseLoaded>()
              .having((s) => s.expenses.length, 'expenses count', 2)
              .having((s) => s.totalAmount, 'total', 150000),
        ],
      );
    });

    group('ClearExpenseState', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'emits ExpenseInitial when clearing state',
        build: () => bloc,
        act: (bloc) => bloc.add(const ClearExpenseState()),
        expect: () => [isA<ExpenseInitial>()],
      );
    });
  });

  group('ExpenseState', () {
    test('ExpenseLoaded copyWith creates copy with updated fields', () {
      final state = ExpenseLoaded(
        expenses: [testExpense],
        groupId: 'group-1',
        totalAmount: 100000,
      );

      final updated = state.copyWith(totalAmount: 200000);

      expect(updated.totalAmount, equals(200000));
      expect(updated.expenses, equals(state.expenses));
      expect(updated.groupId, equals(state.groupId));
    });

    test('ExpenseLoaded props are correct', () {
      final state = ExpenseLoaded(
        expenses: [testExpense],
        groupId: 'group-1',
        totalAmount: 100000,
      );

      expect(state.props, containsAll([state.expenses, 'group-1', 100000]));
    });

    test('ExpenseCreated has default success message', () {
      final state = ExpenseCreated(expense: testExpense);
      expect(state.message, equals('Expense created successfully'));
    });

    test('ExpenseUpdated has default success message', () {
      final state = ExpenseUpdated(expense: testExpense);
      expect(state.message, equals('Expense updated successfully'));
    });

    test('ExpenseDeleted has default success message', () {
      const state = ExpenseDeleted(expenseId: 'exp-1');
      expect(state.message, equals('Expense deleted successfully'));
    });

    test('ExpenseError props contain message', () {
      const state = ExpenseError(message: 'Something went wrong');
      expect(state.props, equals(['Something went wrong']));
    });

    test('ExpenseOperationInProgress props contain operation', () {
      const state = ExpenseOperationInProgress(operation: 'Creating...');
      expect(state.props, equals(['Creating...']));
    });
  });

  group('ExpenseEvent', () {
    test('LoadExpenses props contain groupId', () {
      const event = LoadExpenses('group-1');
      expect(event.props, equals(['group-1']));
    });

    test('WatchExpenses props contain groupId', () {
      const event = WatchExpenses('group-1');
      expect(event.props, equals(['group-1']));
    });

    test('CreateExpense props contain all required fields', () {
      final event = CreateExpense(
        groupId: 'group-1',
        description: 'Test expense',
        amount: 10000,
        currency: 'INR',
        category: ExpenseCategory.food,
        date: testDateTime,
        paidBy: testExpense.paidBy,
        splitType: SplitType.equal,
        splits: testExpense.splits,
      );

      expect(event.props, contains('group-1'));
      expect(event.props, contains('Test expense'));
      expect(event.props, contains(10000));
      expect(event.props, contains(ExpenseCategory.food));
      expect(event.props, contains(SplitType.equal));
    });

    test('UpdateExpense props contain groupId and expenseId', () {
      const event = UpdateExpense(
        groupId: 'g1',
        expenseId: 'e1',
        description: 'Updated',
      );
      expect(event.props, contains('g1'));
      expect(event.props, contains('e1'));
      expect(event.props, contains('Updated'));
    });

    test('DeleteExpense props contain groupId and expenseId', () {
      const event = DeleteExpense(groupId: 'g1', expenseId: 'e1');
      expect(event.props, equals(['g1', 'e1']));
    });

    test('LoadExpenseDetail props contain groupId and expenseId', () {
      const event = LoadExpenseDetail(groupId: 'g1', expenseId: 'e1');
      expect(event.props, equals(['g1', 'e1']));
    });

    test('ExpensesUpdated props contain expenses list', () {
      final event = ExpensesUpdated([testExpense]);
      expect(event.props.first, isA<List<ExpenseEntity>>());
    });

    test('ClearExpenseState props are empty', () {
      const event = ClearExpenseState();
      expect(event.props, isEmpty);
    });
  });

  group('ExpenseEntity helpers', () {
    test('formattedAmount returns correct string', () {
      expect(testExpense.formattedAmount, equals('₹1000.00'));
    });

    test('isMultiPayer returns false for single payer', () {
      expect(testExpense.isMultiPayer, isFalse);
    });

    test('isMultiPayer returns true for multiple payers', () {
      final multiPayerExpense = testExpense.copyWith(
        paidBy: [
          const PayerInfo(userId: 'u1', displayName: 'User 1', amount: 50000),
          const PayerInfo(userId: 'u2', displayName: 'User 2', amount: 50000),
        ],
      );
      expect(multiPayerExpense.isMultiPayer, isTrue);
    });

    test('totalPaid calculates correctly', () {
      expect(testExpense.totalPaid, equals(100000));
    });

    test('totalSplit calculates correctly', () {
      expect(testExpense.totalSplit, equals(100000));
    });

    test('isBalanced returns true when amounts match', () {
      expect(testExpense.isBalanced, isTrue);
    });

    test('primaryPayer returns the person who paid most', () {
      expect(testExpense.primaryPayer.userId, equals('user-1'));
    });

    test('participantIds returns list of user IDs', () {
      expect(testExpense.participantIds, equals(['user-1', 'user-2']));
    });

    test('getSplitForUser returns correct split', () {
      final split = testExpense.getSplitForUser('user-1');
      expect(split?.amount, equals(50000));
    });

    test('getSplitForUser returns null for non-participant', () {
      final split = testExpense.getSplitForUser('user-99');
      expect(split, isNull);
    });

    test('getAmountPaidByUser returns correct amount', () {
      expect(testExpense.getAmountPaidByUser('user-1'), equals(100000));
      expect(testExpense.getAmountPaidByUser('user-2'), equals(0));
    });

    test('getNetBalanceForUser calculates correctly', () {
      // User 1 paid 100000, owes 50000 -> net +50000
      expect(testExpense.getNetBalanceForUser('user-1'), equals(50000));
      // User 2 paid 0, owes 50000 -> net -50000
      expect(testExpense.getNetBalanceForUser('user-2'), equals(-50000));
    });
  });
}
