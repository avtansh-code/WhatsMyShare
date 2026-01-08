import 'dart:math';

import '../entities/expense_entity.dart';

/// Participant information for splitting
class SplitParticipant {
  final String userId;
  final String displayName;

  const SplitParticipant({required this.userId, required this.displayName});
}

/// Service for calculating expense splits
class SplitCalculator {
  /// Calculate equal split among participants
  /// Handles remainder by distributing extra paisa to first N participants
  static List<ExpenseSplit> calculateEqual(
    int totalAmount,
    List<SplitParticipant> participants,
  ) {
    if (participants.isEmpty) {
      return [];
    }

    final perPerson = totalAmount ~/ participants.length;
    final remainder = totalAmount % participants.length;

    return participants.asMap().entries.map((entry) {
      final index = entry.key;
      final participant = entry.value;
      // Distribute remainder to first few members (1 paisa each)
      final extra = index < remainder ? 1 : 0;

      return ExpenseSplit(
        userId: participant.userId,
        displayName: participant.displayName,
        amount: perPerson + extra,
        isPaid: false,
      );
    }).toList();
  }

  /// Calculate exact amount split
  /// Validates that amounts sum to total
  static List<ExpenseSplit> calculateExact(
    int totalAmount,
    Map<String, int> exactAmounts, // userId -> amount
    Map<String, String> displayNames,
  ) {
    final splits = <ExpenseSplit>[];
    int allocatedTotal = 0;

    for (final entry in exactAmounts.entries) {
      splits.add(
        ExpenseSplit(
          userId: entry.key,
          displayName: displayNames[entry.key] ?? 'Unknown',
          amount: entry.value,
          isPaid: false,
        ),
      );
      allocatedTotal += entry.value;
    }

    // Validate total matches
    if (allocatedTotal != totalAmount) {
      throw ArgumentError(
        'Exact amounts sum ($allocatedTotal) does not match total ($totalAmount)',
      );
    }

    return splits;
  }

  /// Calculate percentage-based split
  /// Validates that percentages sum to 100%
  /// Handles rounding by assigning remainder to last person
  static List<ExpenseSplit> calculatePercentage(
    int totalAmount,
    Map<String, double> percentages, // userId -> percentage (0-100)
    Map<String, String> displayNames,
  ) {
    // Validate percentages sum to 100
    final totalPercentage = percentages.values.fold(0.0, (sum, p) => sum + p);
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError(
        'Percentages must sum to 100% (got $totalPercentage%)',
      );
    }

    int allocated = 0;
    final splits = <ExpenseSplit>[];
    final entries = percentages.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      int splitAmount;

      if (i == entries.length - 1) {
        // Last person gets remainder to avoid rounding errors
        splitAmount = totalAmount - allocated;
      } else {
        splitAmount = (totalAmount * entry.value / 100).round();
      }

      allocated += splitAmount;
      splits.add(
        ExpenseSplit(
          userId: entry.key,
          displayName: displayNames[entry.key] ?? 'Unknown',
          amount: splitAmount,
          percentage: entry.value,
          isPaid: false,
        ),
      );
    }

    return splits;
  }

  /// Calculate shares/ratio-based split
  /// Example: shares = {A: 2, B: 1, C: 1} means A pays 50%, B and C pay 25% each
  static List<ExpenseSplit> calculateShares(
    int totalAmount,
    Map<String, int> shares, // userId -> number of shares
    Map<String, String> displayNames,
  ) {
    if (shares.isEmpty) {
      return [];
    }

    final totalShares = shares.values.fold(0, (sum, s) => sum + s);
    if (totalShares == 0) {
      throw ArgumentError('Total shares cannot be zero');
    }

    int allocated = 0;
    final splits = <ExpenseSplit>[];
    final entries = shares.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      int splitAmount;

      if (i == entries.length - 1) {
        // Last person gets remainder
        splitAmount = totalAmount - allocated;
      } else {
        splitAmount = (totalAmount * entry.value / totalShares).round();
      }

      allocated += splitAmount;
      splits.add(
        ExpenseSplit(
          userId: entry.key,
          displayName: displayNames[entry.key] ?? 'Unknown',
          amount: splitAmount,
          shares: entry.value,
          isPaid: false,
        ),
      );
    }

    return splits;
  }

  /// Validate that splits sum to total amount
  static bool validateSplits(int totalAmount, List<ExpenseSplit> splits) {
    final splitSum = splits.fold(0, (sum, split) => sum + split.amount);
    return splitSum == totalAmount;
  }

  /// Calculate split based on type
  static List<ExpenseSplit> calculate({
    required int totalAmount,
    required SplitType splitType,
    required List<SplitParticipant> participants,
    Map<String, int>? exactAmounts,
    Map<String, double>? percentages,
    Map<String, int>? shares,
  }) {
    final displayNames = Map.fromEntries(
      participants.map((p) => MapEntry(p.userId, p.displayName)),
    );

    switch (splitType) {
      case SplitType.equal:
        return calculateEqual(totalAmount, participants);

      case SplitType.exact:
        if (exactAmounts == null) {
          throw ArgumentError('exactAmounts required for exact split');
        }
        return calculateExact(totalAmount, exactAmounts, displayNames);

      case SplitType.percentage:
        if (percentages == null) {
          throw ArgumentError('percentages required for percentage split');
        }
        return calculatePercentage(totalAmount, percentages, displayNames);

      case SplitType.shares:
        if (shares == null) {
          throw ArgumentError('shares required for shares split');
        }
        return calculateShares(totalAmount, shares, displayNames);
    }
  }

  /// Calculate what each person owes to each payer
  /// Returns a map of fromUserId -> (toUserId -> amount)
  static Map<String, Map<String, int>> calculateDebts(
    List<PayerInfo> paidBy,
    List<ExpenseSplit> splits,
  ) {
    final debts = <String, Map<String, int>>{};

    // Calculate net balance for each person
    final balances = <String, int>{};

    // Add what each person paid
    for (final payer in paidBy) {
      balances[payer.userId] = (balances[payer.userId] ?? 0) + payer.amount;
    }

    // Subtract what each person owes
    for (final split in splits) {
      balances[split.userId] = (balances[split.userId] ?? 0) - split.amount;
    }

    // Separate into creditors (positive balance) and debtors (negative balance)
    final creditors = <MapEntry<String, int>>[];
    final debtors = <MapEntry<String, int>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, -entry.value)); // Make positive
      }
    }

    // Sort by amount (descending)
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Match debtors with creditors
    final creditorBalances = Map<String, int>.fromEntries(creditors);
    final debtorBalances = Map<String, int>.fromEntries(debtors);

    while (creditorBalances.isNotEmpty && debtorBalances.isNotEmpty) {
      // Get largest creditor and debtor
      final creditor = creditorBalances.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final debtor = debtorBalances.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      // Settlement amount is minimum of both
      final amount = min(creditor.value, debtor.value);

      // Record the debt
      debts.putIfAbsent(debtor.key, () => {});
      debts[debtor.key]![creditor.key] = amount;

      // Update balances
      if (creditor.value == amount) {
        creditorBalances.remove(creditor.key);
      } else {
        creditorBalances[creditor.key] = creditor.value - amount;
      }

      if (debtor.value == amount) {
        debtorBalances.remove(debtor.key);
      } else {
        debtorBalances[debtor.key] = debtor.value - amount;
      }
    }

    return debts;
  }
}
