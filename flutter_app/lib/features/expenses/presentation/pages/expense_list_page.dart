import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import 'add_expense_page.dart';

/// Page displaying list of expenses for a group
class ExpenseListPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currency;

  const ExpenseListPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.currency = 'INR',
  });

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final LoggingService _log = LoggingService();

  @override
  void initState() {
    super.initState();
    _log.info(
      'ExpenseListPage opened',
      tag: LogTags.ui,
      data: {'groupId': widget.groupId, 'groupName': widget.groupName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseBloc>()..add(WatchExpenses(widget.groupId)),
      child: _ExpenseListView(
        groupId: widget.groupId,
        groupName: widget.groupName,
        currency: widget.currency,
      ),
    );
  }
}

class _ExpenseListView extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String currency;

  const _ExpenseListView({
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Expense deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    // TODO: Implement undo delete
                  },
                ),
              ),
            );
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
        onPressed: () => _navigateToAddExpense(context),
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
            onPressed: () => _navigateToAddExpense(context),
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
        // Summary card
        _buildSummaryCard(context, state),
        // Expense list
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
                    CurrencyUtils.format(state.totalAmount),
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
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text(
              'Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<ExpenseBloc>().add(
          DeleteExpense(groupId: groupId, expenseId: expense.id),
        );
      },
      child: ListTile(
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
              CurrencyUtils.format(expense.amount),
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
        onTap: () => _navigateToExpenseDetail(context, expense),
      ),
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
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(date);
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

  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpensePage(groupId: groupId, currency: currency),
      ),
    );
  }

  void _navigateToExpenseDetail(BuildContext context, ExpenseEntity expense) {
    // TODO: Navigate to expense detail page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('View: ${expense.description}')));
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
                    // TODO: Implement category filter
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
