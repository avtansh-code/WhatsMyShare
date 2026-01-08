import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/group_entity.dart';
import '../bloc/group_bloc.dart';
import '../bloc/group_event.dart';
import '../bloc/group_state.dart';

/// Page for creating a new group
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final LoggingService _log = LoggingService();

  GroupType _selectedType = GroupType.other;
  String _selectedCurrency = AppConstants.defaultCurrency;
  bool _simplifyDebts = true;

  @override
  void initState() {
    super.initState();
    _log.info('CreateGroupPage opened', tag: LogTags.ui);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createGroup() {
    if (_formKey.currentState?.validate() ?? false) {
      _log.info(
        'Create group requested',
        tag: LogTags.ui,
        data: {
          'name': _nameController.text.trim(),
          'type': _selectedType.name,
          'currency': _selectedCurrency,
        },
      );
      context.read<GroupBloc>().add(
        GroupCreateRequested(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _selectedType,
          currency: _selectedCurrency,
          simplifyDebts: _simplifyDebts,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state.status == GroupStatus.success &&
              state.selectedGroup != null) {
            // Group created successfully, navigate to group detail
            context.go('/groups/${state.selectedGroup!.id}');
          } else if (state.status == GroupStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name *',
                    hintText: 'e.g., Trip to Goa',
                    prefixIcon: Icon(Icons.group),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this group for?',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Group Type
                Text(
                  'Group Type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: GroupType.values.map((type) {
                    final isSelected = type == _selectedType;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getTypeEmoji(type)),
                          const SizedBox(width: 4),
                          Text(_getTypeName(type)),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Currency
                Text('Currency', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  items: AppConstants.supportedCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(
                        '$currency (${_getCurrencySymbol(currency)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Simplify Debts toggle
                SwitchListTile(
                  title: const Text('Simplify Debts'),
                  subtitle: const Text(
                    'Automatically minimize the number of payments needed',
                  ),
                  value: _simplifyDebts,
                  onChanged: (value) {
                    setState(() => _simplifyDebts = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),

                // Create button
                FilledButton(
                  onPressed: state.isCreating ? null : _createGroup,
                  child: state.isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Create Group'),
                ),
                const SizedBox(height: 16),

                // Info text
                Text(
                  'You can add members after creating the group',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTypeEmoji(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return '✈️';
      case GroupType.home:
        return '🏠';
      case GroupType.couple:
        return '💑';
      case GroupType.other:
        return '👥';
    }
  }

  String _getTypeName(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return 'Trip';
      case GroupType.home:
        return 'Home';
      case GroupType.couple:
        return 'Couple';
      case GroupType.other:
        return 'Other';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }
}
