import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/settlements/domain/entities/settlement_entity.dart';
import 'package:whats_my_share/features/settlements/domain/services/debt_simplifier.dart';

void main() {
  group('DebtSimplifier', () {
    group('simplify', () {
      test('should simplify simple two-person debt', () {
        // Arrange: A owes ₹100, B is owed ₹100
        final balances = {
          'A': -10000, // A owes ₹100
          'B': 10000, // B is owed ₹100
        };
        final displayNames = {'A': 'Alice', 'B': 'Bob'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result.length, 1);
        expect(result[0].fromUserId, 'A');
        expect(result[0].toUserId, 'B');
        expect(result[0].amount, 10000);
      });

      test('should minimize transactions for multiple debts', () {
        // Arrange: A owes ₹100, B owes ₹50, C is owed ₹150
        final balances = {
          'A': -10000, // A owes ₹100
          'B': -5000, // B owes ₹50
          'C': 15000, // C is owed ₹150
        };
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert - Should result in 2 transactions: A→C and B→C
        expect(result.length, 2);

        final totalSettled = result
            .map((s) => s.amount)
            .reduce((a, b) => a + b);
        expect(totalSettled, 15000); // Total amount settled

        // All payments should go to C
        expect(result.every((s) => s.toUserId == 'C'), true);
      });

      test('should handle complex debt graph', () {
        // Arrange: A is owed ₹500, B owes ₹300, C owes ₹200
        final balances = {
          'A': 50000, // A is owed ₹500
          'B': -30000, // B owes ₹300
          'C': -20000, // C owes ₹200
        };
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert - All debts are settled
        expect(result.length, 2);
        expect(
          result.every((s) => s.toUserId == 'A'),
          true,
          reason: 'All payments should go to A',
        );

        // Total paid to A should equal what A is owed
        final totalPaidToA = result
            .where((s) => s.toUserId == 'A')
            .map((s) => s.amount)
            .reduce((a, b) => a + b);
        expect(totalPaidToA, 50000);
      });

      test('should return empty list when everyone is settled', () {
        // Arrange
        final balances = {'A': 0, 'B': 0, 'C': 0};
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle single debtor and multiple creditors', () {
        // Arrange: A owes ₹300, B is owed ₹100, C is owed ₹200
        final balances = {'A': -30000, 'B': 10000, 'C': 20000};
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result.length, 2);
        expect(result.every((s) => s.fromUserId == 'A'), true);

        // Total paid by A
        final totalPaidByA = result
            .map((s) => s.amount)
            .reduce((a, b) => a + b);
        expect(totalPaidByA, 30000);
      });

      test('should handle single creditor and multiple debtors', () {
        // Arrange: A is owed ₹300, B owes ₹100, C owes ₹200
        final balances = {'A': 30000, 'B': -10000, 'C': -20000};
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result.length, 2);
        expect(result.every((s) => s.toUserId == 'A'), true);
      });

      test('should handle circular debts', () {
        // Arrange: A owes B ₹100, B owes C ₹100, C owes A ₹100
        // Net: everyone has 0 balance
        final balances = {'A': 0, 'B': 0, 'C': 0};
        final displayNames = {'A': 'Alice', 'B': 'Bob', 'C': 'Charlie'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert - No transactions needed
        expect(result, isEmpty);
      });

      test('should use Unknown for missing display names', () {
        // Arrange
        final balances = {'A': -10000, 'B': 10000};
        final displayNames = <String, String>{}; // Empty display names

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result[0].fromUserName, 'Unknown');
        expect(result[0].toUserName, 'Unknown');
      });

      test('should preserve display names in result', () {
        // Arrange
        final balances = {'A': -10000, 'B': 10000};
        final displayNames = {'A': 'Alice Smith', 'B': 'Bob Johnson'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result[0].fromUserName, 'Alice Smith');
        expect(result[0].toUserName, 'Bob Johnson');
      });

      test('should handle large amounts', () {
        // Arrange
        final balances = {
          'A': -1000000, // ₹10,000
          'B': 1000000,
        };
        final displayNames = {'A': 'Alice', 'B': 'Bob'};

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert
        expect(result.length, 1);
        expect(result[0].amount, 1000000);
      });

      test('should handle many participants', () {
        // Arrange: 5 people with various balances summing to 0
        final balances = {
          'A': -20000, // owes ₹200
          'B': -10000, // owes ₹100
          'C': 15000, // owed ₹150
          'D': 10000, // owed ₹100
          'E': 5000, // owed ₹50
        };
        final displayNames = {
          'A': 'Alice',
          'B': 'Bob',
          'C': 'Charlie',
          'D': 'Diana',
          'E': 'Eve',
        };

        // Act
        final result = DebtSimplifier.simplify(balances, displayNames);

        // Assert - Verify total debts = total credits
        final totalDebts = result.map((s) => s.amount).reduce((a, b) => a + b);
        expect(totalDebts, 30000); // 20000 + 10000

        // All settlements should have valid from/to IDs
        expect(result.every((s) => s.fromUserId.isNotEmpty), true);
        expect(result.every((s) => s.toUserId.isNotEmpty), true);
      });
    });

    group('generateExplanation', () {
      test('should generate explanation steps', () {
        // Arrange
        final balances = {'A': -10000, 'B': 10000};
        final displayNames = {'A': 'Alice', 'B': 'Bob'};

        // Act
        final steps = DebtSimplifier.generateExplanation(
          balances,
          displayNames,
          'INR',
        );

        // Assert - Should have at least original, categorize, settlement, and result steps
        expect(steps.length, greaterThanOrEqualTo(4));
        expect(steps.first.title, 'Original Balances');
        expect(steps.last.title, 'Result');
      });

      test('should include settlement details in steps', () {
        // Arrange
        final balances = {'A': -10000, 'B': 10000};
        final displayNames = {'A': 'Alice', 'B': 'Bob'};

        // Act
        final steps = DebtSimplifier.generateExplanation(
          balances,
          displayNames,
          'INR',
        );

        // Assert - Find the settlement step
        final settlementStep = steps.firstWhere(
          (s) => s.settlement != null,
          orElse: () => throw Exception('No settlement step found'),
        );
        expect(settlementStep.settlement!.fromUserId, 'A');
        expect(settlementStep.settlement!.toUserId, 'B');
        expect(settlementStep.settlement!.amount, 10000);
      });

      test('should show categorization of creditors and debtors', () {
        // Arrange
        final balances = {'A': -10000, 'B': 10000};
        final displayNames = {'A': 'Alice', 'B': 'Bob'};

        // Act
        final steps = DebtSimplifier.generateExplanation(
          balances,
          displayNames,
          'INR',
        );

        // Assert
        final categorizeStep = steps.firstWhere(
          (s) => s.title == 'Categorize Members',
        );
        expect(categorizeStep.description, contains('Alice'));
        expect(categorizeStep.description, contains('Bob'));
      });
    });

    group('calculateBalancesFromExpenses', () {
      test('should calculate balances from expenses', () {
        // Arrange
        final expenses = [
          {
            'paidBy': [
              {'userId': 'A', 'amount': 10000},
            ],
            'splits': [
              {'userId': 'A', 'amount': 5000},
              {'userId': 'B', 'amount': 5000},
            ],
          },
        ];
        final settlements = <Map<String, dynamic>>[];

        // Act
        final balances = DebtSimplifier.calculateBalancesFromExpenses(
          expenses,
          settlements,
        );

        // Assert
        expect(balances['A'], 5000); // Paid 10000, owes 5000 = +5000
        expect(balances['B'], -5000); // Paid 0, owes 5000 = -5000
      });

      test('should subtract confirmed settlements from balances', () {
        // Arrange
        final expenses = [
          {
            'paidBy': [
              {'userId': 'A', 'amount': 10000},
            ],
            'splits': [
              {'userId': 'A', 'amount': 5000},
              {'userId': 'B', 'amount': 5000},
            ],
          },
        ];
        final settlements = [
          {
            'fromUserId': 'B',
            'toUserId': 'A',
            'amount': 5000,
            'status': 'confirmed',
          },
        ];

        // Act
        final balances = DebtSimplifier.calculateBalancesFromExpenses(
          expenses,
          settlements,
        );

        // Assert - After settlement, both should be at 0
        expect(balances['A'], 0);
        expect(balances['B'], 0);
      });

      test('should ignore pending settlements', () {
        // Arrange
        final expenses = [
          {
            'paidBy': [
              {'userId': 'A', 'amount': 10000},
            ],
            'splits': [
              {'userId': 'A', 'amount': 5000},
              {'userId': 'B', 'amount': 5000},
            ],
          },
        ];
        final settlements = [
          {
            'fromUserId': 'B',
            'toUserId': 'A',
            'amount': 5000,
            'status': 'pending', // Not confirmed
          },
        ];

        // Act
        final balances = DebtSimplifier.calculateBalancesFromExpenses(
          expenses,
          settlements,
        );

        // Assert - Settlement not applied
        expect(balances['A'], 5000);
        expect(balances['B'], -5000);
      });

      test('should handle multiple expenses', () {
        // Arrange
        final expenses = [
          {
            'paidBy': [
              {'userId': 'A', 'amount': 10000},
            ],
            'splits': [
              {'userId': 'A', 'amount': 5000},
              {'userId': 'B', 'amount': 5000},
            ],
          },
          {
            'paidBy': [
              {'userId': 'B', 'amount': 6000},
            ],
            'splits': [
              {'userId': 'A', 'amount': 3000},
              {'userId': 'B', 'amount': 3000},
            ],
          },
        ];
        final settlements = <Map<String, dynamic>>[];

        // Act
        final balances = DebtSimplifier.calculateBalancesFromExpenses(
          expenses,
          settlements,
        );

        // Assert
        // A: paid 10000, owes 8000 = +2000
        // B: paid 6000, owes 8000 = -2000
        expect(balances['A'], 2000);
        expect(balances['B'], -2000);
      });

      test('should handle expenses with missing paidBy or splits', () {
        // Arrange
        final expenses = <Map<String, dynamic>>[
          <String, dynamic>{
            // Missing paidBy and splits
          },
          <String, dynamic>{'paidBy': null, 'splits': null},
        ];
        final settlements = <Map<String, dynamic>>[];

        // Act
        final balances = DebtSimplifier.calculateBalancesFromExpenses(
          expenses,
          settlements,
        );

        // Assert - Should handle gracefully
        expect(balances, isEmpty);
      });
    });

    group('requiresBiometric', () {
      test('should return true for amounts at or above threshold', () {
        // Arrange & Act & Assert
        expect(DebtSimplifier.requiresBiometric(500000), true); // ₹5000 exactly
        expect(DebtSimplifier.requiresBiometric(600000), true); // ₹6000
        expect(DebtSimplifier.requiresBiometric(1000000), true); // ₹10000
      });

      test('should return false for amounts below threshold', () {
        // Arrange & Act & Assert
        expect(DebtSimplifier.requiresBiometric(499999), false); // ₹4999.99
        expect(DebtSimplifier.requiresBiometric(100000), false); // ₹1000
        expect(DebtSimplifier.requiresBiometric(0), false);
      });

      test('should use custom threshold when provided', () {
        // Arrange & Act & Assert
        expect(
          DebtSimplifier.requiresBiometric(100000, threshold: 100000),
          true,
        );
        expect(
          DebtSimplifier.requiresBiometric(99999, threshold: 100000),
          false,
        );
      });
    });
  });

  group('SimplifiedDebt', () {
    test('should create SimplifiedDebt with correct properties', () {
      // Arrange & Act
      const debt = SimplifiedDebt(
        fromUserId: 'u1',
        fromUserName: 'Alice',
        toUserId: 'u2',
        toUserName: 'Bob',
        amount: 10000,
      );

      // Assert
      expect(debt.fromUserId, 'u1');
      expect(debt.fromUserName, 'Alice');
      expect(debt.toUserId, 'u2');
      expect(debt.toUserName, 'Bob');
      expect(debt.amount, 10000);
    });

    test('should be equal when userId and amount match', () {
      // Arrange
      const debt1 = SimplifiedDebt(
        fromUserId: 'u1',
        fromUserName: 'Alice',
        toUserId: 'u2',
        toUserName: 'Bob',
        amount: 10000,
      );
      const debt2 = SimplifiedDebt(
        fromUserId: 'u1',
        fromUserName: 'Alice Different', // Different name
        toUserId: 'u2',
        toUserName: 'Bob Different', // Different name
        amount: 10000,
      );

      // Assert - Equatable uses props [fromUserId, toUserId, amount]
      expect(debt1, equals(debt2));
    });
  });

  group('SimplificationStep', () {
    test('should create SimplificationStep with correct properties', () {
      // Arrange & Act
      final step = SimplificationStep(
        title: 'Test Step',
        description: 'Test description',
        balances: {'A': 100, 'B': -100},
        displayNames: {'A': 'Alice', 'B': 'Bob'},
      );

      // Assert
      expect(step.title, 'Test Step');
      expect(step.description, 'Test description');
      expect(step.balances['A'], 100);
      expect(step.settlement, isNull);
    });

    test('should include settlement when provided', () {
      // Arrange
      const settlement = SimplifiedDebt(
        fromUserId: 'A',
        fromUserName: 'Alice',
        toUserId: 'B',
        toUserName: 'Bob',
        amount: 100,
      );

      // Act
      final step = SimplificationStep(
        title: 'Settlement Step',
        description: 'Settling debt',
        balances: {'A': 0, 'B': 0},
        displayNames: {'A': 'Alice', 'B': 'Bob'},
        settlement: settlement,
      );

      // Assert
      expect(step.settlement, isNotNull);
      expect(step.settlement!.amount, 100);
    });
  });

  group('UserBalance', () {
    test('should identify user who is owed money', () {
      // Arrange
      const balance = UserBalance(
        userId: 'u1',
        displayName: 'Alice',
        balance: 10000, // Positive = owed money
      );

      // Assert
      expect(balance.isOwed, true);
      expect(balance.owes, false);
      expect(balance.isSettled, false);
    });

    test('should identify user who owes money', () {
      // Arrange
      const balance = UserBalance(
        userId: 'u1',
        displayName: 'Alice',
        balance: -10000, // Negative = owes money
      );

      // Assert
      expect(balance.isOwed, false);
      expect(balance.owes, true);
      expect(balance.isSettled, false);
    });

    test('should identify settled user', () {
      // Arrange
      const balance = UserBalance(
        userId: 'u1',
        displayName: 'Alice',
        balance: 0, // Zero = settled
      );

      // Assert
      expect(balance.isOwed, false);
      expect(balance.owes, false);
      expect(balance.isSettled, true);
    });
  });
}
