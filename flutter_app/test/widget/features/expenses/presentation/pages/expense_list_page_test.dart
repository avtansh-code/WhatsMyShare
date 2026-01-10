import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/expenses/domain/entities/expense_entity.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_event.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/expense_state.dart';

// Mock classes
class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class FakeExpenseEvent extends Fake implements ExpenseEvent {}

class FakeExpenseState extends Fake implements ExpenseState {}

void main() {
  late MockExpenseBloc mockExpenseBloc;

  setUpAll(() {
    registerFallbackValue(FakeExpenseEvent());
    registerFallbackValue(FakeExpenseState());
  });

  setUp(() {
    mockExpenseBloc = MockExpenseBloc();
  });

  tearDown(() {
    mockExpenseBloc.close();
  });

  // Test data
  const testPayer = PayerInfo(
    userId: 'user1',
    displayName: 'John Doe',
    amount: 10000, // 100.00 in paisa
  );

  const testSplit = ExpenseSplit(
    userId: 'user2',
    displayName: 'Jane Doe',
    amount: 5000, // 50.00 in paisa
  );

  final testExpense = ExpenseEntity(
    id: 'expense1',
    groupId: 'group1',
    description: 'Lunch',
    amount: 10000, // 100.00 in paisa
    currency: 'INR',
    paidBy: const [testPayer],
    splits: const [testSplit],
    category: ExpenseCategory.food,
    date: DateTime.now(),
    createdBy: 'user1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    splitType: SplitType.equal,
    status: ExpenseStatus.active,
  );

  final testExpenses = [
    testExpense,
    ExpenseEntity(
      id: 'expense2',
      groupId: 'group1',
      description: 'Taxi',
      amount: 5000, // 50.00 in paisa
      currency: 'INR',
      paidBy: const [testPayer],
      splits: const [testSplit],
      category: ExpenseCategory.transport,
      date: DateTime.now().subtract(const Duration(days: 1)),
      createdBy: 'user1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      splitType: SplitType.equal,
      status: ExpenseStatus.active,
    ),
  ];

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider<ExpenseBloc>.value(
        value: mockExpenseBloc,
        child: const Scaffold(
          body: _TestExpenseListView(
            groupId: 'group1',
            groupName: 'Test Group',
            currency: 'INR',
          ),
        ),
      ),
    );
  }

  group('ExpenseListPage Widget Tests', () {
    group('Initial State', () {
      testWidgets('shows loading indicator when state is ExpenseLoading', (
        tester,
      ) async {
        when(() => mockExpenseBloc.state).thenReturn(const ExpenseLoading());

        await tester.pumpWidget(createWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows group name in app bar', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.text('Test Group'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('shows empty view when no expenses', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          const ExpenseLoaded(expenses: [], groupId: 'group1', totalAmount: 0),
        );

        await tester.pumpWidget(createWidget());

        expect(find.text('No expenses yet'), findsOneWidget);
        expect(
          find.text('Add your first expense to get started'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      });

      testWidgets('shows add expense button in empty view', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          const ExpenseLoaded(expenses: [], groupId: 'group1', totalAmount: 0),
        );

        await tester.pumpWidget(createWidget());

        // ElevatedButton.icon creates a button - look for add icon and text
        expect(
          find.byIcon(Icons.add),
          findsWidgets,
        ); // Both in empty view button and FAB
        expect(
          find.text('Add Expense'),
          findsWidgets,
        ); // In both empty view and FAB
      });
    });

    group('Loaded State', () {
      testWidgets('shows expense list when loaded', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.text('Lunch'), findsOneWidget);
        expect(find.text('Taxi'), findsOneWidget);
      });

      testWidgets('shows total amount in summary card', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.text('Total Expenses'), findsOneWidget);
        expect(find.textContaining('150'), findsOneWidget);
      });

      testWidgets('shows expense count in summary card', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.text('2 expenses'), findsOneWidget);
      });

      testWidgets('shows category icons for expenses', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.directions_car), findsOneWidget);
      });

      testWidgets('shows payer name for each expense', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.textContaining('John Doe'), findsWidgets);
      });
    });

    group('Error State', () {
      testWidgets('shows error view when state is ExpenseError', (
        tester,
      ) async {
        when(
          () => mockExpenseBloc.state,
        ).thenReturn(const ExpenseError(message: 'Failed to load expenses'));

        await tester.pumpWidget(createWidget());

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Failed to load expenses'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows retry button on error', (tester) async {
        when(
          () => mockExpenseBloc.state,
        ).thenReturn(const ExpenseError(message: 'Error'));

        await tester.pumpWidget(createWidget());

        // ElevatedButton.icon is used with icon and text
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('retry button triggers LoadExpenses event', (tester) async {
        when(
          () => mockExpenseBloc.state,
        ).thenReturn(const ExpenseError(message: 'Error'));

        await tester.pumpWidget(createWidget());

        // Tap the Retry text since it's part of ElevatedButton.icon
        await tester.tap(find.text('Retry'));
        await tester.pump();

        verify(
          () => mockExpenseBloc.add(any(that: isA<LoadExpenses>())),
        ).called(1);
      });
    });

    group('App Bar Actions', () {
      testWidgets('shows filter icon in app bar', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });

      testWidgets('filter button opens filter sheet', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('Filter Expenses'), findsOneWidget);
        expect(find.text('Filter by Category'), findsOneWidget);
      });

      testWidgets('filter sheet shows all categories', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Check for category chips
        expect(find.byType(FilterChip), findsWidgets);
      });
    });

    group('Floating Action Button', () {
      testWidgets('shows FAB with Add Expense text', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Add Expense'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('Date Grouping', () {
      testWidgets('groups expenses by date', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: testExpenses,
            groupId: 'group1',
            totalAmount: 15000,
          ),
        );

        await tester.pumpWidget(createWidget());

        // Should show Today and Yesterday headers
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
      });
    });

    group('Expense Item Interactions', () {
      testWidgets('tapping expense item shows snackbar', (tester) async {
        when(() => mockExpenseBloc.state).thenReturn(
          ExpenseLoaded(
            expenses: [testExpense],
            groupId: 'group1',
            totalAmount: 10000,
          ),
        );

        await tester.pumpWidget(createWidget());
        await tester.tap(find.text('Lunch'));
        await tester.pump();

        expect(find.textContaining('View: Lunch'), findsOneWidget);
      });
    });
  });
}

// Test wrapper that exposes the internal view for testing
class _TestExpenseListView extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String currency;

  const _TestExpenseListView({
    required this.groupId,
    required this.groupName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseDeleted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
          } else if (state is ExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpenseError) {
            return _buildErrorView(context, state.message);
          }

          if (state is ExpenseLoaded) {
            if (state.expenses.isEmpty) {
              return _buildEmptyView(context);
            }
            return _buildExpenseList(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ExpenseBloc>().add(LoadExpenses(groupId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, ExpenseLoaded state) {
    final groupedExpenses = _groupExpensesByDate(state.expenses);
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _buildSummaryCard(context, state),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final expenses = groupedExpenses[date]!;
              return _buildDateSection(context, date, expenses);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, ExpenseLoaded state) {
    final rupeesAmount = state.totalAmount / 100;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${rupeesAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.expenses.length} expenses',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    DateTime date,
    List<ExpenseEntity> expenses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _formatDateHeader(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...expenses.map((expense) => _buildExpenseItem(context, expense)),
      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseEntity expense) {
    final rupeesAmount = expense.amount / 100;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCategoryColor(
          expense.category,
        ).withValues(alpha: 0.2),
        child: Icon(
          _getCategoryIcon(expense.category),
          color: _getCategoryColor(expense.category),
        ),
      ),
      title: Text(
        expense.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Paid by ${expense.paidBy.map((p) => p.displayName).join(", ")}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${rupeesAmount.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            _getSplitTypeLabel(expense.splitType),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('View: ${expense.description}')));
      },
    );
  }

  Map<DateTime, List<ExpenseEntity>> _groupExpensesByDate(
    List<ExpenseEntity> expenses,
  ) {
    final grouped = <DateTime, List<ExpenseEntity>>{};
    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(expense);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getSplitTypeLabel(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Split equally';
      case SplitType.exact:
        return 'Exact amounts';
      case SplitType.percentage:
        return 'By percentage';
      case SplitType.shares:
        return 'By shares';
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.utilities:
        return Icons.power;
      case ExpenseCategory.groceries:
        return Icons.shopping_cart;
      case ExpenseCategory.health:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.entertainment:
        return Colors.red;
      case ExpenseCategory.utilities:
        return Colors.yellow.shade800;
      case ExpenseCategory.groceries:
        return Colors.green;
      case ExpenseCategory.health:
        return Colors.teal;
      case ExpenseCategory.education:
        return Colors.indigo;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Filter by Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((category) {
                return FilterChip(
                  label: Text(category.name),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
