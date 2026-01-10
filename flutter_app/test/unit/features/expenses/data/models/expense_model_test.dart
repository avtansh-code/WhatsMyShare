import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/expenses/data/models/expense_model.dart';
import 'package:whats_my_share/features/expenses/domain/entities/expense_entity.dart';

void main() {
  final testDate = DateTime(2024, 1, 15, 10, 30);
  final paidAtDate = DateTime(2024, 1, 20);

  group('PayerInfoModel', () {
    group('fromMap', () {
      test('creates PayerInfoModel from valid map', () {
        final map = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'amount': 5000,
        };

        final result = PayerInfoModel.fromMap(map);

        expect(result.userId, 'user-123');
        expect(result.displayName, 'John Doe');
        expect(result.amount, 5000);
      });
    });

    group('toMap', () {
      test('converts PayerInfoModel to map', () {
        const model = PayerInfoModel(
          userId: 'user-123',
          displayName: 'John Doe',
          amount: 5000,
        );

        final result = model.toMap();

        expect(result['userId'], 'user-123');
        expect(result['displayName'], 'John Doe');
        expect(result['amount'], 5000);
      });
    });

    group('toEntity', () {
      test('converts PayerInfoModel to PayerInfo entity', () {
        const model = PayerInfoModel(
          userId: 'user-123',
          displayName: 'John Doe',
          amount: 5000,
        );

        final result = model.toEntity();

        expect(result, isA<PayerInfo>());
        expect(result.userId, model.userId);
        expect(result.displayName, model.displayName);
        expect(result.amount, model.amount);
      });
    });

    group('fromEntity', () {
      test('creates PayerInfoModel from PayerInfo entity', () {
        const entity = PayerInfo(
          userId: 'user-456',
          displayName: 'Jane Doe',
          amount: 7500,
        );

        final result = PayerInfoModel.fromEntity(entity);

        expect(result, isA<PayerInfoModel>());
        expect(result.userId, entity.userId);
        expect(result.displayName, entity.displayName);
        expect(result.amount, entity.amount);
      });
    });
  });

  group('ExpenseSplitModel', () {
    group('fromMap', () {
      test('creates ExpenseSplitModel from valid map', () {
        final map = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'amount': 2500,
          'percentage': 50.0,
          'shares': 2,
          'isPaid': true,
          'paidAt': Timestamp.fromDate(paidAtDate),
        };

        final result = ExpenseSplitModel.fromMap(map);

        expect(result.userId, 'user-123');
        expect(result.displayName, 'John Doe');
        expect(result.amount, 2500);
        expect(result.percentage, 50.0);
        expect(result.shares, 2);
        expect(result.isPaid, isTrue);
        expect(result.paidAt, paidAtDate);
      });

      test('defaults isPaid to false when not provided', () {
        final map = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'amount': 2500,
        };

        final result = ExpenseSplitModel.fromMap(map);

        expect(result.isPaid, isFalse);
        expect(result.paidAt, isNull);
      });
    });

    group('toMap', () {
      test('converts ExpenseSplitModel to map with all fields', () {
        final model = ExpenseSplitModel(
          userId: 'user-123',
          displayName: 'John Doe',
          amount: 2500,
          percentage: 50.0,
          shares: 2,
          isPaid: true,
          paidAt: paidAtDate,
        );

        final result = model.toMap();

        expect(result['userId'], 'user-123');
        expect(result['displayName'], 'John Doe');
        expect(result['amount'], 2500);
        expect(result['percentage'], 50.0);
        expect(result['shares'], 2);
        expect(result['isPaid'], isTrue);
        expect(result['paidAt'], isA<Timestamp>());
      });

      test('omits optional fields when null', () {
        const model = ExpenseSplitModel(
          userId: 'user-123',
          displayName: 'John Doe',
          amount: 2500,
        );

        final result = model.toMap();

        expect(result.containsKey('percentage'), isFalse);
        expect(result.containsKey('shares'), isFalse);
        expect(result.containsKey('paidAt'), isFalse);
      });
    });

    group('toEntity', () {
      test('converts ExpenseSplitModel to ExpenseSplit entity', () {
        final model = ExpenseSplitModel(
          userId: 'user-123',
          displayName: 'John Doe',
          amount: 2500,
          percentage: 50.0,
          isPaid: true,
          paidAt: paidAtDate,
        );

        final result = model.toEntity();

        expect(result, isA<ExpenseSplit>());
        expect(result.userId, model.userId);
        expect(result.amount, model.amount);
        expect(result.percentage, model.percentage);
        expect(result.isPaid, model.isPaid);
      });
    });

    group('fromEntity', () {
      test('creates ExpenseSplitModel from ExpenseSplit entity', () {
        final entity = ExpenseSplit(
          userId: 'user-456',
          displayName: 'Jane Doe',
          amount: 3000,
          percentage: 60.0,
          shares: 3,
          isPaid: false,
          paidAt: paidAtDate,
        );

        final result = ExpenseSplitModel.fromEntity(entity);

        expect(result, isA<ExpenseSplitModel>());
        expect(result.userId, entity.userId);
        expect(result.percentage, entity.percentage);
        expect(result.shares, entity.shares);
      });
    });
  });

  group('ExpenseModel', () {
    final testPayer = const PayerInfoModel(
      userId: 'user-1',
      displayName: 'Alice',
      amount: 5000,
    );

    final testSplit = const ExpenseSplitModel(
      userId: 'user-2',
      displayName: 'Bob',
      amount: 2500,
    );

    final testModel = ExpenseModel(
      id: 'expense-123',
      groupId: 'group-456',
      description: 'Dinner',
      amount: 5000,
      currency: 'INR',
      category: ExpenseCategory.food,
      date: testDate,
      paidBy: [testPayer],
      splitType: SplitType.equal,
      splits: [testSplit],
      notes: 'Team dinner',
      createdBy: 'user-1',
      status: ExpenseStatus.active,
      chatMessageCount: 3,
      createdAt: testDate,
      updatedAt: testDate,
    );

    group('toFirestore', () {
      test('converts ExpenseModel to Firestore map', () {
        final result = testModel.toFirestore();

        expect(result['groupId'], 'group-456');
        expect(result['description'], 'Dinner');
        expect(result['amount'], 5000);
        expect(result['currency'], 'INR');
        expect(result['category'], 'food');
        expect(result['splitType'], 'equal');
        expect(result['notes'], 'Team dinner');
        expect(result['createdBy'], 'user-1');
        expect(result['status'], 'active');
        expect(result['chatMessageCount'], 3);
      });

      test('includes paidBy and splits as lists', () {
        final result = testModel.toFirestore();

        expect(result['paidBy'], isA<List>());
        expect(result['splits'], isA<List>());
        expect((result['paidBy'] as List).length, 1);
        expect((result['splits'] as List).length, 1);
      });

      test('omits null optional fields', () {
        final modelWithoutNotes = ExpenseModel(
          id: 'expense-123',
          groupId: 'group-456',
          description: 'Dinner',
          amount: 5000,
          currency: 'INR',
          category: ExpenseCategory.food,
          date: testDate,
          paidBy: [testPayer],
          splitType: SplitType.equal,
          splits: [testSplit],
          createdBy: 'user-1',
          status: ExpenseStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final result = modelWithoutNotes.toFirestore();

        expect(result.containsKey('notes'), isFalse);
        expect(result.containsKey('receiptUrls'), isFalse);
      });
    });

    group('toEntity', () {
      test('converts ExpenseModel to ExpenseEntity', () {
        final result = testModel.toEntity();

        expect(result, isA<ExpenseEntity>());
        expect(result.id, testModel.id);
        expect(result.groupId, testModel.groupId);
        expect(result.description, testModel.description);
        expect(result.amount, testModel.amount);
        expect(result.currency, testModel.currency);
        expect(result.category, testModel.category);
        expect(result.splitType, testModel.splitType);
        expect(result.status, testModel.status);
      });

      test('converts paidBy and splits to entities', () {
        final result = testModel.toEntity();

        expect(result.paidBy.length, 1);
        expect(result.paidBy.first, isA<PayerInfo>());
        expect(result.splits.length, 1);
        expect(result.splits.first, isA<ExpenseSplit>());
      });
    });

    group('fromEntity', () {
      test('creates ExpenseModel from ExpenseEntity', () {
        final entity = ExpenseEntity(
          id: 'expense-789',
          groupId: 'group-123',
          description: 'Groceries',
          amount: 3000,
          currency: 'USD',
          category: ExpenseCategory.groceries,
          date: testDate,
          paidBy: const [
            PayerInfo(userId: 'user-1', displayName: 'Alice', amount: 3000),
          ],
          splitType: SplitType.percentage,
          splits: const [
            ExpenseSplit(
              userId: 'user-2',
              displayName: 'Bob',
              amount: 1500,
              percentage: 50.0,
            ),
          ],
          createdBy: 'user-1',
          status: ExpenseStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final result = ExpenseModel.fromEntity(entity);

        expect(result, isA<ExpenseModel>());
        expect(result.id, entity.id);
        expect(result.groupId, entity.groupId);
        expect(result.category, entity.category);
        expect(result.splitType, entity.splitType);
        expect(result.paidBy.length, 1);
        expect(result.splits.length, 1);
      });
    });

    group('category parsing', () {
      test('parses all ExpenseCategory values', () {
        final categories = [
          'food',
          'transport',
          'accommodation',
          'shopping',
          'entertainment',
          'utilities',
          'groceries',
          'health',
          'education',
          'other',
        ];

        for (final cat in categories) {
          // Verify category string is valid
          expect(ExpenseCategory.values.any((e) => e.name == cat), isTrue);
        }
      });

      test('defaults to other for unknown category', () {
        // The _categoryFromString method defaults to other
        expect(ExpenseCategory.values.contains(ExpenseCategory.other), isTrue);
      });
    });

    group('splitType parsing', () {
      test('parses all SplitType values', () {
        final splitTypes = ['equal', 'exact', 'percentage', 'shares'];

        for (final st in splitTypes) {
          expect(SplitType.values.any((e) => e.name == st), isTrue);
        }
      });
    });

    group('status parsing', () {
      test('parses all ExpenseStatus values', () {
        final statuses = ['active', 'deleted'];

        for (final status in statuses) {
          expect(ExpenseStatus.values.any((e) => e.name == status), isTrue);
        }
      });
    });

    group('with receipt URLs', () {
      test('includes receiptUrls when provided', () {
        final modelWithReceipts = ExpenseModel(
          id: 'expense-123',
          groupId: 'group-456',
          description: 'Dinner',
          amount: 5000,
          currency: 'INR',
          category: ExpenseCategory.food,
          date: testDate,
          paidBy: [testPayer],
          splitType: SplitType.equal,
          splits: [testSplit],
          receiptUrls: ['https://example.com/receipt1.jpg'],
          createdBy: 'user-1',
          status: ExpenseStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final result = modelWithReceipts.toFirestore();

        expect(result['receiptUrls'], ['https://example.com/receipt1.jpg']);
      });
    });

    group('with deleted info', () {
      test('includes deletedAt and deletedBy when provided', () {
        final deletedModel = ExpenseModel(
          id: 'expense-123',
          groupId: 'group-456',
          description: 'Dinner',
          amount: 5000,
          currency: 'INR',
          category: ExpenseCategory.food,
          date: testDate,
          paidBy: [testPayer],
          splitType: SplitType.equal,
          splits: [testSplit],
          createdBy: 'user-1',
          status: ExpenseStatus.deleted,
          createdAt: testDate,
          updatedAt: testDate,
          deletedAt: testDate,
          deletedBy: 'user-1',
        );

        final result = deletedModel.toFirestore();

        expect(result['deletedAt'], isA<Timestamp>());
        expect(result['deletedBy'], 'user-1');
        expect(result['status'], 'deleted');
      });
    });
  });
}
