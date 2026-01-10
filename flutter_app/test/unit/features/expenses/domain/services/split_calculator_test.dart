import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/expenses/domain/entities/expense_entity.dart';
import 'package:whats_my_share/features/expenses/domain/services/split_calculator.dart';

void main() {
  group('SplitCalculator', () {
    group('calculateEqual', () {
      test(
        'should split evenly when amount is divisible by participant count',
        () {
          // Arrange
          const totalAmount = 30000; // ₹300.00
          final participants = [
            const SplitParticipant(userId: 'u1', displayName: 'Alice'),
            const SplitParticipant(userId: 'u2', displayName: 'Bob'),
            const SplitParticipant(userId: 'u3', displayName: 'Charlie'),
          ];

          // Act
          final result = SplitCalculator.calculateEqual(
            totalAmount,
            participants,
          );

          // Assert
          expect(result.length, 3);
          expect(result[0].amount, 10000);
          expect(result[1].amount, 10000);
          expect(result[2].amount, 10000);
          expect(
            result.map((s) => s.amount).reduce((a, b) => a + b),
            totalAmount,
          );
        },
      );

      test(
        'should distribute remainder to first participants when not evenly divisible',
        () {
          // Arrange
          const totalAmount = 10000; // ₹100.00
          final participants = [
            const SplitParticipant(userId: 'u1', displayName: 'Alice'),
            const SplitParticipant(userId: 'u2', displayName: 'Bob'),
            const SplitParticipant(userId: 'u3', displayName: 'Charlie'),
          ];

          // Act
          final result = SplitCalculator.calculateEqual(
            totalAmount,
            participants,
          );

          // Assert
          // 10000 / 3 = 3333.33..., so 3333 per person with 1 remainder
          expect(result[0].amount, 3334); // Gets extra 1
          expect(result[1].amount, 3333);
          expect(result[2].amount, 3333);
          expect(
            result.map((s) => s.amount).reduce((a, b) => a + b),
            totalAmount,
          );
        },
      );

      test('should handle single participant', () {
        // Arrange
        const totalAmount = 10000;
        final participants = [
          const SplitParticipant(userId: 'u1', displayName: 'Alice'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].amount, totalAmount);
        expect(result[0].userId, 'u1');
        expect(result[0].displayName, 'Alice');
      });

      test('should return empty list for empty participants', () {
        // Arrange
        const totalAmount = 10000;
        final participants = <SplitParticipant>[];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle two-way split with odd amount', () {
        // Arrange
        const totalAmount = 10001; // ₹100.01
        final participants = [
          const SplitParticipant(userId: 'u1', displayName: 'Alice'),
          const SplitParticipant(userId: 'u2', displayName: 'Bob'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result[0].amount, 5001); // Gets extra 1
        expect(result[1].amount, 5000);
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test('should set isPaid to false for all splits', () {
        // Arrange
        const totalAmount = 10000;
        final participants = [
          const SplitParticipant(userId: 'u1', displayName: 'Alice'),
          const SplitParticipant(userId: 'u2', displayName: 'Bob'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result.every((s) => s.isPaid == false), true);
      });
    });

    group('calculateExact', () {
      test('should split by exact amounts correctly', () {
        // Arrange
        const totalAmount = 10000;
        final exactAmounts = {'u1': 6000, 'u2': 4000};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act
        final result = SplitCalculator.calculateExact(
          totalAmount,
          exactAmounts,
          displayNames,
        );

        // Assert
        expect(result.length, 2);
        expect(result.firstWhere((s) => s.userId == 'u1').amount, 6000);
        expect(result.firstWhere((s) => s.userId == 'u2').amount, 4000);
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test(
        'should throw ArgumentError when exact amounts do not sum to total',
        () {
          // Arrange
          const totalAmount = 10000;
          final exactAmounts = {
            'u1': 5000,
            'u2': 4000, // Total: 9000, missing 1000
          };
          final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

          // Act & Assert
          expect(
            () => SplitCalculator.calculateExact(
              totalAmount,
              exactAmounts,
              displayNames,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test('should use "Unknown" for missing display names', () {
        // Arrange
        const totalAmount = 10000;
        final exactAmounts = {'u1': 6000, 'u2': 4000};
        final displayNames = {
          'u1': 'Alice',
          // u2 missing
        };

        // Act
        final result = SplitCalculator.calculateExact(
          totalAmount,
          exactAmounts,
          displayNames,
        );

        // Assert
        expect(
          result.firstWhere((s) => s.userId == 'u2').displayName,
          'Unknown',
        );
      });
    });

    group('calculatePercentage', () {
      test('should split by percentage correctly', () {
        // Arrange
        const totalAmount = 10000; // ₹100.00
        final percentages = {'u1': 50.0, 'u2': 30.0, 'u3': 20.0};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob', 'u3': 'Charlie'};

        // Act
        final result = SplitCalculator.calculatePercentage(
          totalAmount,
          percentages,
          displayNames,
        );

        // Assert
        expect(result.firstWhere((s) => s.userId == 'u1').amount, 5000);
        expect(result.firstWhere((s) => s.userId == 'u2').amount, 3000);
        expect(result.firstWhere((s) => s.userId == 'u3').amount, 2000);
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test('should handle rounding and assign remainder to last person', () {
        // Arrange
        const totalAmount = 1000; // ₹10.00
        final percentages = {'u1': 33.33, 'u2': 33.33, 'u3': 33.34};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob', 'u3': 'Charlie'};

        // Act
        final result = SplitCalculator.calculatePercentage(
          totalAmount,
          percentages,
          displayNames,
        );

        // Assert - Total must equal exactly
        final total = result.map((s) => s.amount).reduce((a, b) => a + b);
        expect(total, totalAmount);
      });

      test('should throw ArgumentError when percentages do not sum to 100', () {
        // Arrange
        const totalAmount = 10000;
        final percentages = {
          'u1': 50.0,
          'u2': 30.0,
          // Missing 20%
        };
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act & Assert
        expect(
          () => SplitCalculator.calculatePercentage(
            totalAmount,
            percentages,
            displayNames,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should store percentage in split', () {
        // Arrange
        const totalAmount = 10000;
        final percentages = {'u1': 60.0, 'u2': 40.0};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act
        final result = SplitCalculator.calculatePercentage(
          totalAmount,
          percentages,
          displayNames,
        );

        // Assert
        expect(result.firstWhere((s) => s.userId == 'u1').percentage, 60.0);
        expect(result.firstWhere((s) => s.userId == 'u2').percentage, 40.0);
      });
    });

    group('calculateShares', () {
      test('should split by shares correctly', () {
        // Arrange
        const totalAmount = 12000; // ₹120.00
        final shares = {
          'u1': 2, // 2 shares
          'u2': 1, // 1 share
        };
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act
        final result = SplitCalculator.calculateShares(
          totalAmount,
          shares,
          displayNames,
        );

        // Assert (2:1 ratio means 8000:4000)
        expect(result.firstWhere((s) => s.userId == 'u1').amount, 8000);
        expect(result.firstWhere((s) => s.userId == 'u2').amount, 4000);
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test('should handle equal shares', () {
        // Arrange
        const totalAmount = 9000;
        final shares = {'u1': 1, 'u2': 1, 'u3': 1};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob', 'u3': 'Charlie'};

        // Act
        final result = SplitCalculator.calculateShares(
          totalAmount,
          shares,
          displayNames,
        );

        // Assert
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test('should throw ArgumentError when total shares is zero', () {
        // Arrange
        const totalAmount = 10000;
        final shares = {'u1': 0, 'u2': 0};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act & Assert
        expect(
          () => SplitCalculator.calculateShares(
            totalAmount,
            shares,
            displayNames,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should return empty list for empty shares', () {
        // Arrange
        const totalAmount = 10000;
        final shares = <String, int>{};
        final displayNames = <String, String>{};

        // Act
        final result = SplitCalculator.calculateShares(
          totalAmount,
          shares,
          displayNames,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should store shares in split', () {
        // Arrange
        const totalAmount = 10000;
        final shares = {'u1': 3, 'u2': 2};
        final displayNames = {'u1': 'Alice', 'u2': 'Bob'};

        // Act
        final result = SplitCalculator.calculateShares(
          totalAmount,
          shares,
          displayNames,
        );

        // Assert
        expect(result.firstWhere((s) => s.userId == 'u1').shares, 3);
        expect(result.firstWhere((s) => s.userId == 'u2').shares, 2);
      });
    });

    group('validateSplits', () {
      test('should return true when splits sum to total amount', () {
        // Arrange
        const totalAmount = 10000;
        final splits = [
          const ExpenseSplit(userId: 'u1', displayName: 'Alice', amount: 6000),
          const ExpenseSplit(userId: 'u2', displayName: 'Bob', amount: 4000),
        ];

        // Act
        final result = SplitCalculator.validateSplits(totalAmount, splits);

        // Assert
        expect(result, true);
      });

      test('should return false when splits do not sum to total amount', () {
        // Arrange
        const totalAmount = 10000;
        final splits = [
          const ExpenseSplit(userId: 'u1', displayName: 'Alice', amount: 5000),
          const ExpenseSplit(userId: 'u2', displayName: 'Bob', amount: 4000),
        ];

        // Act
        final result = SplitCalculator.validateSplits(totalAmount, splits);

        // Assert
        expect(result, false);
      });
    });

    group('calculate (unified)', () {
      test('should call calculateEqual for SplitType.equal', () {
        // Arrange
        const totalAmount = 10000;
        final participants = [
          const SplitParticipant(userId: 'u1', displayName: 'Alice'),
          const SplitParticipant(userId: 'u2', displayName: 'Bob'),
        ];

        // Act
        final result = SplitCalculator.calculate(
          totalAmount: totalAmount,
          splitType: SplitType.equal,
          participants: participants,
        );

        // Assert
        expect(result.length, 2);
        expect(
          result.map((s) => s.amount).reduce((a, b) => a + b),
          totalAmount,
        );
      });

      test(
        'should throw ArgumentError for exact split without exactAmounts',
        () {
          // Arrange
          const totalAmount = 10000;
          final participants = [
            const SplitParticipant(userId: 'u1', displayName: 'Alice'),
          ];

          // Act & Assert
          expect(
            () => SplitCalculator.calculate(
              totalAmount: totalAmount,
              splitType: SplitType.exact,
              participants: participants,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'should throw ArgumentError for percentage split without percentages',
        () {
          // Arrange
          const totalAmount = 10000;
          final participants = [
            const SplitParticipant(userId: 'u1', displayName: 'Alice'),
          ];

          // Act & Assert
          expect(
            () => SplitCalculator.calculate(
              totalAmount: totalAmount,
              splitType: SplitType.percentage,
              participants: participants,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test('should throw ArgumentError for shares split without shares', () {
        // Arrange
        const totalAmount = 10000;
        final participants = [
          const SplitParticipant(userId: 'u1', displayName: 'Alice'),
        ];

        // Act & Assert
        expect(
          () => SplitCalculator.calculate(
            totalAmount: totalAmount,
            splitType: SplitType.shares,
            participants: participants,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('calculateDebts', () {
      test('should calculate simple debt correctly', () {
        // Arrange: Alice paid 10000, Bob owes 5000
        final paidBy = [
          const PayerInfo(userId: 'u1', displayName: 'Alice', amount: 10000),
        ];
        final splits = [
          const ExpenseSplit(userId: 'u1', displayName: 'Alice', amount: 5000),
          const ExpenseSplit(userId: 'u2', displayName: 'Bob', amount: 5000),
        ];

        // Act
        final debts = SplitCalculator.calculateDebts(paidBy, splits);

        // Assert: Bob owes Alice 5000
        expect(debts.containsKey('u2'), true);
        expect(debts['u2']!['u1'], 5000);
      });

      test('should handle multi-payer scenario', () {
        // Arrange: Alice paid 6000, Bob paid 4000, each owes 5000
        final paidBy = [
          const PayerInfo(userId: 'u1', displayName: 'Alice', amount: 6000),
          const PayerInfo(userId: 'u2', displayName: 'Bob', amount: 4000),
        ];
        final splits = [
          const ExpenseSplit(userId: 'u1', displayName: 'Alice', amount: 5000),
          const ExpenseSplit(userId: 'u2', displayName: 'Bob', amount: 5000),
        ];

        // Act
        final debts = SplitCalculator.calculateDebts(paidBy, splits);

        // Assert: Bob owes Alice 1000 (Alice: 6000-5000=+1000, Bob: 4000-5000=-1000)
        expect(debts.containsKey('u2'), true);
        expect(debts['u2']!['u1'], 1000);
      });

      test('should return empty debts when everyone is settled', () {
        // Arrange: Each person paid what they owe
        final paidBy = [
          const PayerInfo(userId: 'u1', displayName: 'Alice', amount: 5000),
          const PayerInfo(userId: 'u2', displayName: 'Bob', amount: 5000),
        ];
        final splits = [
          const ExpenseSplit(userId: 'u1', displayName: 'Alice', amount: 5000),
          const ExpenseSplit(userId: 'u2', displayName: 'Bob', amount: 5000),
        ];

        // Act
        final debts = SplitCalculator.calculateDebts(paidBy, splits);

        // Assert: No debts
        expect(debts, isEmpty);
      });
    });
  });
}
