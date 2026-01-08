import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

/// Page for adding a new expense
class AddExpensePage extends StatelessWidget {
  final String groupId;
  final String currency;
  final List<Map<String, String>>? members; // [{userId, displayName}]

  const AddExpensePage({
    super.key,
    required this.groupId,
    this.currency = 'INR',
    this.members,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseBloc>(),
      child: _AddExpenseForm(
        groupId: groupId,
        currency: currency,
        members: members,
      ),
    );
  }
}

class _AddExpenseForm extends StatefulWidget {
  final String groupId;
  final String currency;
  final List<Map<String, String>>? members;

  const _AddExpenseForm({
    required this.groupId,
    required this.currency,
    this.members,
  });

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  SplitType _selectedSplitType = SplitType.equal;
  DateTime _selectedDate = DateTime.now();

  // For simplified single payer (current user)
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? user.email ?? 'You';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully!')),
          );
          Navigator.pop(context, true);
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
        final isLoading = state is ExpenseOperationInProgress;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Expense'),
            actions: [
              TextButton(
                onPressed: isLoading ? null : _saveExpense,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Amount Input
                _buildAmountField(),
                const SizedBox(height: 24),

                // Description
                _buildDescriptionField(),
                const SizedBox(height: 16),

                // Category Selector
                _buildCategorySelector(),
                const SizedBox(height: 16),

                // Date Picker
                _buildDatePicker(),
                const SizedBox(height: 24),

                // Split Type Selector
                _buildSplitTypeSelector(),
                const SizedBox(height: 16),

                // Notes (optional)
                _buildNotesField(),
                const SizedBox(height: 32),

                // Save Button
                _buildSaveButton(isLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: Theme.of(context).textTheme.headlineMedium,
          decoration: InputDecoration(
            prefixText: '${CurrencyUtils.getSymbol(widget.currency)} ',
            prefixStyle: Theme.of(context).textTheme.headlineMedium,
            hintText: '0.00',
            border: const OutlineInputBorder(),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'What was this expense for?',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((category) {
            final isSelected = category == _selectedCategory;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Text(_getCategoryLabel(category)),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = category),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('Date'),
      subtitle: Text(
        _formatDate(_selectedDate),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickDate,
    );
  }

  Widget _buildSplitTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split Type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<SplitType>(
          segments: const [
            ButtonSegment(
              value: SplitType.equal,
              label: Text('Equal'),
              icon: Icon(Icons.drag_handle),
            ),
            ButtonSegment(
              value: SplitType.exact,
              label: Text('Exact'),
              icon: Icon(Icons.pin),
            ),
            ButtonSegment(
              value: SplitType.percentage,
              label: Text('%'),
              icon: Icon(Icons.percent),
            ),
            ButtonSegment(
              value: SplitType.shares,
              label: Text('Shares'),
              icon: Icon(Icons.pie_chart),
            ),
          ],
          selected: {_selectedSplitType},
          onSelectionChanged: (selection) {
            setState(() => _selectedSplitType = selection.first);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getSplitTypeDescription(_selectedSplitType),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return FilledButton.icon(
      onPressed: isLoading ? null : _saveExpense,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save),
      label: Text(isLoading ? 'Saving...' : 'Save Expense'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getSplitTypeDescription(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Split the total equally among all participants';
      case SplitType.exact:
        return 'Specify exact amounts for each participant';
      case SplitType.percentage:
        return 'Split by percentage (must total 100%)';
      case SplitType.shares:
        return 'Split by shares/ratios (e.g., 2:1:1)';
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

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.accommodation:
        return 'Stay';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Fun';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.groceries:
        return 'Groceries';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = (double.parse(amountText) * 100).round(); // Convert to paisa

    // Create payer info (simplified: current user paid full amount)
    final paidBy = [
      PayerInfo(
        userId: _currentUserId!,
        displayName: _currentUserName!,
        amount: amount,
      ),
    ];

    // Create splits (simplified: equal split to current user only)
    // In a full implementation, this would include all group members
    final splits = [
      ExpenseSplit(
        userId: _currentUserId!,
        displayName: _currentUserName!,
        amount: amount,
        isPaid: true,
      ),
    ];

    context.read<ExpenseBloc>().add(
      CreateExpense(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        amount: amount,
        currency: widget.currency,
        category: _selectedCategory,
        date: _selectedDate,
        paidBy: paidBy,
        splitType: _selectedSplitType,
        splits: splits,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      ),
    );
  }
}
