import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../groups/domain/entities/group_entity.dart' hide SimplifiedDebt;
import '../../domain/entities/settlement_entity.dart';
import '../bloc/settlement_bloc.dart';
import '../bloc/settlement_event.dart';
import '../bloc/settlement_state.dart';

/// Page for recording a settlement payment
class SettleUpPage extends StatefulWidget {
  final GroupEntity group;
  final String currentUserId;
  final String currentUserName;
  final SimplifiedDebt? suggestedDebt;

  const SettleUpPage({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.currentUserName,
    this.suggestedDebt,
  });

  @override
  State<SettleUpPage> createState() => _SettleUpPageState();
}

class _SettleUpPageState extends State<SettleUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final LoggingService _log = LoggingService();

  String? _selectedPayerId;
  String? _selectedPayerName;
  String? _selectedReceiverId;
  String? _selectedReceiverName;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.upi;

  @override
  void initState() {
    super.initState();
    _log.info(
      'SettleUpPage opened',
      tag: LogTags.ui,
      data: {'groupId': widget.group.id},
    );
    // Pre-fill from suggested debt
    if (widget.suggestedDebt != null) {
      _selectedPayerId = widget.suggestedDebt!.fromUserId;
      _selectedPayerName = widget.suggestedDebt!.fromUserName;
      _selectedReceiverId = widget.suggestedDebt!.toUserId;
      _selectedReceiverName = widget.suggestedDebt!.toUserName;
      _amountController.text = (widget.suggestedDebt!.amount / 100)
          .toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettlementBloc, SettlementState>(
      listener: (context, state) {
        if (state is SettlementOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is SettlementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settle Up')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Payer selection
              _buildParticipantSelector(
                label: 'Who is paying?',
                selectedUserId: _selectedPayerId,
                selectedUserName: _selectedPayerName,
                excludeUserId: _selectedReceiverId,
                onSelected: (userId, userName) {
                  setState(() {
                    _selectedPayerId = userId;
                    _selectedPayerName = userName;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Arrow indicator
              const Center(
                child: Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Receiver selection
              _buildParticipantSelector(
                label: 'Who is receiving?',
                selectedUserId: _selectedReceiverId,
                selectedUserName: _selectedReceiverName,
                excludeUserId: _selectedPayerId,
                onSelected: (userId, userName) {
                  setState(() {
                    _selectedReceiverId = userId;
                    _selectedReceiverName = userName;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText:
                      '${CurrencyUtils.getSymbol(widget.group.currency)} ',
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 24),

              // Payment method selection
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((method) {
                  return ChoiceChip(
                    label: Text(
                      PaymentMethods.getDisplayName(
                        _paymentMethodToString(method),
                      ),
                    ),
                    selected: _selectedPaymentMethod == method,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reference input (for UPI, bank transfer)
              if (_selectedPaymentMethod == PaymentMethod.upi ||
                  _selectedPaymentMethod == PaymentMethod.bankTransfer)
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: _selectedPaymentMethod == PaymentMethod.upi
                        ? 'UPI Transaction ID (optional)'
                        : 'Reference Number (optional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),

              // Notes input
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Biometric warning
              BlocBuilder<SettlementBloc, SettlementState>(
                builder: (context, state) {
                  final amountText = _amountController.text;
                  final amount = double.tryParse(amountText) ?? 0;
                  final amountInPaisa = (amount * 100).round();

                  if (amountInPaisa >= AppConstants.biometricThresholdPaisa) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Amounts over ${CurrencyUtils.format((AppConstants.biometricThresholdPaisa / 100).round(), widget.group.currency)} require biometric verification',
                              style: TextStyle(color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              BlocBuilder<SettlementBloc, SettlementState>(
                builder: (context, state) {
                  final isLoading = state is SettlementOperationInProgress;

                  return ElevatedButton(
                    onPressed: isLoading ? null : _submitSettlement,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Record Payment'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantSelector({
    required String label,
    required String? selectedUserId,
    required String? selectedUserName,
    required String? excludeUserId,
    required void Function(String userId, String userName) onSelected,
  }) {
    final availableMembers = widget.group.members
        .where((m) => m.userId != excludeUserId)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (selectedUserId != null)
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      selectedUserName?.substring(0, 1).toUpperCase() ?? '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedUserName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showMemberPicker(availableMembers, onSelected),
                    child: const Text('Change'),
                  ),
                ],
              )
            else
              OutlinedButton(
                onPressed: () =>
                    _showMemberPicker(availableMembers, onSelected),
                child: const Text('Select Member'),
              ),
          ],
        ),
      ),
    );
  }

  void _showMemberPicker(
    List<GroupMember> members,
    void Function(String userId, String userName) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(member.displayName.substring(0, 1).toUpperCase()),
            ),
            title: Text(member.displayName),
            subtitle: Text(member.email),
            onTap: () {
              onSelected(member.userId, member.displayName);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _submitSettlement() {
    if (!_formKey.currentState!.validate()) return;
    _log.info(
      'Settlement submission requested',
      tag: LogTags.ui,
      data: {
        'groupId': widget.group.id,
        'payerId': _selectedPayerId,
        'receiverId': _selectedReceiverId,
      },
    );

    if (_selectedPayerId == null || _selectedReceiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both payer and receiver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final amountInPaisa = (amount * 100).round();

    context.read<SettlementBloc>().add(
      CreateSettlement(
        groupId: widget.group.id,
        fromUserId: _selectedPayerId!,
        fromUserName: _selectedPayerName!,
        toUserId: _selectedReceiverId!,
        toUserName: _selectedReceiverName!,
        amount: amountInPaisa,
        currency: widget.group.currency,
        paymentMethod: _selectedPaymentMethod,
        paymentReference: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ),
    );
  }

  String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.other:
        return 'other';
    }
  }
}
