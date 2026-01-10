import 'dart:math';

import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../entities/settlement_entity.dart';

/// Service that implements the debt simplification algorithm
/// Uses a greedy approach to minimize the number of transactions
class DebtSimplifier {
  static final LoggingService _log = LoggingService();

  /// Simplifies debts to minimize the number of transactions
  ///
  /// Input: Map of userId to balance (positive = owed money, negative = owes money)
  /// Output: List of simplified debts (minimum transactions to settle all balances)
  ///
  /// Algorithm: Greedy matching of largest creditors with largest debtors
  static List<SimplifiedDebt> simplify(
    Map<String, int> balances,
    Map<String, String> displayNames,
  ) {
    _log.info(
      'Simplifying debts',
      tag: LogTags.settlements,
      data: {'participants': balances.length},
    );

    // Separate into creditors (positive balance) and debtors (negative balance)
    final creditors = <String, int>{};
    final debtors = <String, int>{};

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors[entry.key] = entry.value;
      } else if (entry.value < 0) {
        debtors[entry.key] = -entry.value; // Store as positive for easier math
      }
    }

    _log.debug(
      'Categorized participants',
      tag: LogTags.settlements,
      data: {'creditors': creditors.length, 'debtors': debtors.length},
    );

    final settlements = <SimplifiedDebt>[];

    // While there are still debts to settle
    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      // Find largest creditor
      final creditorEntry = creditors.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      // Find largest debtor
      final debtorEntry = debtors.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      // Settlement amount is minimum of both
      final amount = min(creditorEntry.value, debtorEntry.value);

      _log.debug(
        'Creating settlement',
        tag: LogTags.settlements,
        data: {
          'from': displayNames[debtorEntry.key],
          'to': displayNames[creditorEntry.key],
          'amount': amount,
        },
      );

      // Create settlement
      settlements.add(
        SimplifiedDebt(
          fromUserId: debtorEntry.key,
          fromUserName: displayNames[debtorEntry.key] ?? 'Unknown',
          toUserId: creditorEntry.key,
          toUserName: displayNames[creditorEntry.key] ?? 'Unknown',
          amount: amount,
        ),
      );

      // Update balances
      if (creditorEntry.value == amount) {
        creditors.remove(creditorEntry.key);
      } else {
        creditors[creditorEntry.key] = creditorEntry.value - amount;
      }

      if (debtorEntry.value == amount) {
        debtors.remove(debtorEntry.key);
      } else {
        debtors[debtorEntry.key] = debtorEntry.value - amount;
      }
    }

    _log.info(
      'Debt simplification complete',
      tag: LogTags.settlements,
      data: {'settlements': settlements.length},
    );

    return settlements;
  }

  /// Generates step-by-step explanation of the simplification
  static List<SimplificationStep> generateExplanation(
    Map<String, int> originalBalances,
    Map<String, String> displayNames,
    String currency,
  ) {
    _log.debug(
      'Generating simplification explanation',
      tag: LogTags.settlements,
      data: {'currency': currency, 'participants': originalBalances.length},
    );

    final steps = <SimplificationStep>[];

    // Step 1: Show original balances
    steps.add(
      SimplificationStep(
        title: 'Original Balances',
        description: _formatBalanceDescription(
          originalBalances,
          displayNames,
          currency,
        ),
        balances: Map.from(originalBalances),
        displayNames: displayNames,
      ),
    );

    // Step 2: Categorize members
    final creditors = <String>[];
    final debtors = <String>[];
    for (final entry in originalBalances.entries) {
      if (entry.value > 0) {
        creditors.add(displayNames[entry.key] ?? 'Unknown');
      } else if (entry.value < 0) {
        debtors.add(displayNames[entry.key] ?? 'Unknown');
      }
    }

    steps.add(
      SimplificationStep(
        title: 'Categorize Members',
        description:
            'Owed money: ${creditors.isEmpty ? "None" : creditors.join(", ")}\n'
            'Owes money: ${debtors.isEmpty ? "None" : debtors.join(", ")}',
        balances: Map.from(originalBalances),
        displayNames: displayNames,
      ),
    );

    // Step 3+: Show each settlement
    final settlements = simplify(originalBalances, displayNames);
    final runningBalances = Map<String, int>.from(originalBalances);

    for (var i = 0; i < settlements.length; i++) {
      final settlement = settlements[i];

      // Update running balances
      runningBalances[settlement.fromUserId] =
          (runningBalances[settlement.fromUserId] ?? 0) + settlement.amount;
      runningBalances[settlement.toUserId] =
          (runningBalances[settlement.toUserId] ?? 0) - settlement.amount;

      final formattedAmount = CurrencyUtils.format(settlement.amount);

      steps.add(
        SimplificationStep(
          title:
              'Step ${i + 1}: ${settlement.fromUserName} pays ${settlement.toUserName}',
          description:
              'Amount: $formattedAmount\n\n'
              '${_formatBalanceDescription(runningBalances, displayNames, currency)}',
          balances: Map.from(runningBalances),
          displayNames: displayNames,
          settlement: settlement,
        ),
      );
    }

    // Final step: Summary
    final originalCount = _calculateOriginalTransactionCount(originalBalances);
    steps.add(
      SimplificationStep(
        title: 'Result',
        description:
            'Simplified to ${settlements.length} payment${settlements.length != 1 ? "s" : ""} '
            '(from potentially $originalCount)',
        balances: runningBalances,
        displayNames: displayNames,
      ),
    );

    _log.debug(
      'Explanation generated',
      tag: LogTags.settlements,
      data: {'steps': steps.length},
    );

    return steps;
  }

  /// Calculate the potential number of transactions without simplification
  static int _calculateOriginalTransactionCount(Map<String, int> balances) {
    int creditorCount = 0;
    int debtorCount = 0;

    for (final balance in balances.values) {
      if (balance > 0) creditorCount++;
      if (balance < 0) debtorCount++;
    }

    // Worst case: each debtor pays each creditor
    return creditorCount * debtorCount;
  }

  /// Format balance description for explanation
  static String _formatBalanceDescription(
    Map<String, int> balances,
    Map<String, String> displayNames,
    String currency,
  ) {
    final lines = <String>[];
    int total = 0;

    for (final entry in balances.entries) {
      final name = displayNames[entry.key] ?? 'Unknown';
      final amount = entry.value;
      total += amount;

      if (amount > 0) {
        lines.add('$name is owed ${CurrencyUtils.format(amount)}');
      } else if (amount < 0) {
        lines.add('$name owes ${CurrencyUtils.format(-amount)}');
      } else {
        lines.add('$name is settled');
      }
    }

    // Add total check
    lines.add('─────────────────');
    if (total == 0) {
      lines.add('Total: ${CurrencyUtils.format(0)} ✓');
    } else {
      lines.add('Total: ${CurrencyUtils.format(total)} (should be 0)');
    }

    return lines.join('\n');
  }

  /// Calculate balances from expenses for a group
  static Map<String, int> calculateBalancesFromExpenses(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> settlements,
  ) {
    _log.debug(
      'Calculating balances from expenses',
      tag: LogTags.settlements,
      data: {'expenses': expenses.length, 'settlements': settlements.length},
    );

    final balances = <String, int>{};

    // Process expenses
    for (final expense in expenses) {
      final paidBy = expense['paidBy'] as List<dynamic>?;
      final splits = expense['splits'] as List<dynamic>?;

      if (paidBy == null || splits == null) continue;

      // Add amounts paid
      for (final payer in paidBy) {
        final userId = payer['userId'] as String;
        final amount = payer['amount'] as int;
        balances[userId] = (balances[userId] ?? 0) + amount;
      }

      // Subtract amounts owed
      for (final split in splits) {
        final userId = split['userId'] as String;
        final amount = split['amount'] as int;
        balances[userId] = (balances[userId] ?? 0) - amount;
      }
    }

    // Process confirmed settlements
    for (final settlement in settlements) {
      if (settlement['status'] != 'confirmed') continue;

      final fromUserId = settlement['fromUserId'] as String;
      final toUserId = settlement['toUserId'] as String;
      final amount = settlement['amount'] as int;

      // Settlement reduces debt
      balances[fromUserId] = (balances[fromUserId] ?? 0) + amount;
      balances[toUserId] = (balances[toUserId] ?? 0) - amount;
    }

    _log.debug(
      'Balances calculated',
      tag: LogTags.settlements,
      data: {'participants': balances.length},
    );

    return balances;
  }

  /// Check if biometric verification is required for an amount
  static bool requiresBiometric(int amount, {int threshold = 500000}) {
    // Default threshold is ₹5000 (500000 paisa)
    final required = amount >= threshold;
    if (required) {
      _log.info(
        'Biometric required for settlement',
        tag: LogTags.settlements,
        data: {'amount': amount, 'threshold': threshold},
      );
    }
    return required;
  }
}
