import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/settlements/data/models/settlement_model.dart';
import 'package:whats_my_share/features/settlements/domain/entities/settlement_entity.dart';

void main() {
  group('SettlementModel', () {
    final testCreatedAt = DateTime(2026, 1, 9, 10, 0, 0);
    final testConfirmedAt = DateTime(2026, 1, 9, 12, 0, 0);

    group('fromEntity', () {
      test('creates SettlementModel from SettlementEntity with all fields', () {
        final entity = SettlementEntity(
          id: 'settlement-123',
          groupId: 'group-456',
          fromUserId: 'user-1',
          fromUserName: 'John Doe',
          toUserId: 'user-2',
          toUserName: 'Jane Smith',
          amount: 50000,
          currency: 'INR',
          status: SettlementStatus.pending,
          paymentMethod: PaymentMethod.upi,
          paymentReference: 'UPI123456',
          requiresBiometric: true,
          biometricVerified: false,
          notes: 'Dinner payment',
          createdAt: testCreatedAt,
          confirmedAt: null,
          confirmedBy: null,
        );

        final model = SettlementModel.fromEntity(entity);

        expect(model.id, equals('settlement-123'));
        expect(model.groupId, equals('group-456'));
        expect(model.fromUserId, equals('user-1'));
        expect(model.fromUserName, equals('John Doe'));
        expect(model.toUserId, equals('user-2'));
        expect(model.toUserName, equals('Jane Smith'));
        expect(model.amount, equals(50000));
        expect(model.currency, equals('INR'));
        expect(model.status, equals(SettlementStatus.pending));
        expect(model.paymentMethod, equals(PaymentMethod.upi));
        expect(model.paymentReference, equals('UPI123456'));
        expect(model.requiresBiometric, isTrue);
        expect(model.biometricVerified, isFalse);
        expect(model.notes, equals('Dinner payment'));
        expect(model.createdAt, equals(testCreatedAt));
      });

      test('creates SettlementModel from confirmed settlement', () {
        final entity = SettlementEntity(
          id: 'settlement-123',
          groupId: 'group-456',
          fromUserId: 'user-1',
          fromUserName: 'John Doe',
          toUserId: 'user-2',
          toUserName: 'Jane Smith',
          amount: 50000,
          status: SettlementStatus.confirmed,
          createdAt: testCreatedAt,
          confirmedAt: testConfirmedAt,
          confirmedBy: 'user-2',
        );

        final model = SettlementModel.fromEntity(entity);

        expect(model.status, equals(SettlementStatus.confirmed));
        expect(model.confirmedAt, equals(testConfirmedAt));
        expect(model.confirmedBy, equals('user-2'));
      });
    });

    group('toFirestoreCreate', () {
      test('converts SettlementModel to Firestore map for creation', () {
        final model = SettlementModel(
          id: 'settlement-123',
          groupId: 'group-456',
          fromUserId: 'user-1',
          fromUserName: 'John Doe',
          toUserId: 'user-2',
          toUserName: 'Jane Smith',
          amount: 50000,
          currency: 'INR',
          status: SettlementStatus.pending,
          paymentMethod: PaymentMethod.cash,
          paymentReference: null,
          requiresBiometric: false,
          biometricVerified: false,
          notes: 'Test payment',
          createdAt: testCreatedAt,
        );

        final map = model.toFirestoreCreate();

        expect(map['groupId'], equals('group-456'));
        expect(map['fromUserId'], equals('user-1'));
        expect(map['fromUserName'], equals('John Doe'));
        expect(map['toUserId'], equals('user-2'));
        expect(map['toUserName'], equals('Jane Smith'));
        expect(map['amount'], equals(50000));
        expect(map['currency'], equals('INR'));
        expect(map['status'], equals('pending'));
        expect(map['paymentMethod'], equals('cash'));
        expect(map['requiresBiometric'], isFalse);
        expect(map['biometricVerified'], isFalse);
        expect(map['notes'], equals('Test payment'));
        expect(map['confirmedAt'], isNull);
        expect(map['confirmedBy'], isNull);
      });

      test('converts status to string correctly', () {
        final pendingModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          status: SettlementStatus.pending,
          createdAt: testCreatedAt,
        );
        expect(pendingModel.toFirestoreCreate()['status'], equals('pending'));

        final confirmedModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          status: SettlementStatus.confirmed,
          createdAt: testCreatedAt,
        );
        expect(
          confirmedModel.toFirestoreCreate()['status'],
          equals('confirmed'),
        );

        final rejectedModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          status: SettlementStatus.rejected,
          createdAt: testCreatedAt,
        );
        expect(rejectedModel.toFirestoreCreate()['status'], equals('rejected'));
      });

      test('converts payment method to string correctly', () {
        final cashModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          paymentMethod: PaymentMethod.cash,
          createdAt: testCreatedAt,
        );
        expect(cashModel.toFirestoreCreate()['paymentMethod'], equals('cash'));

        final upiModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          paymentMethod: PaymentMethod.upi,
          createdAt: testCreatedAt,
        );
        expect(upiModel.toFirestoreCreate()['paymentMethod'], equals('upi'));

        final bankModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          paymentMethod: PaymentMethod.bankTransfer,
          createdAt: testCreatedAt,
        );
        expect(
          bankModel.toFirestoreCreate()['paymentMethod'],
          equals('bank_transfer'),
        );

        final otherModel = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          paymentMethod: PaymentMethod.other,
          createdAt: testCreatedAt,
        );
        expect(
          otherModel.toFirestoreCreate()['paymentMethod'],
          equals('other'),
        );
      });

      test('sets null for paymentMethod when not provided', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          paymentMethod: null,
          createdAt: testCreatedAt,
        );
        expect(model.toFirestoreCreate()['paymentMethod'], isNull);
      });
    });

    group('toFirestoreUpdate', () {
      test('includes status and payment info in update map', () {
        final model = SettlementModel(
          id: 'settlement-123',
          groupId: 'group-456',
          fromUserId: 'user-1',
          fromUserName: 'John Doe',
          toUserId: 'user-2',
          toUserName: 'Jane Smith',
          amount: 50000,
          status: SettlementStatus.confirmed,
          paymentMethod: PaymentMethod.upi,
          paymentReference: 'UPI12345',
          biometricVerified: true,
          notes: 'Updated notes',
          createdAt: testCreatedAt,
          confirmedAt: testConfirmedAt,
          confirmedBy: 'user-2',
        );

        final map = model.toFirestoreUpdate();

        expect(map['status'], equals('confirmed'));
        expect(map['paymentMethod'], equals('upi'));
        expect(map['paymentReference'], equals('UPI12345'));
        expect(map['biometricVerified'], isTrue);
        expect(map['notes'], equals('Updated notes'));
        expect(map['confirmedBy'], equals('user-2'));
      });

      test('excludes confirmedAt and confirmedBy when null', () {
        final model = SettlementModel(
          id: 'settlement-123',
          groupId: 'group-456',
          fromUserId: 'user-1',
          fromUserName: 'John Doe',
          toUserId: 'user-2',
          toUserName: 'Jane Smith',
          amount: 50000,
          status: SettlementStatus.pending,
          createdAt: testCreatedAt,
          confirmedAt: null,
          confirmedBy: null,
        );

        final map = model.toFirestoreUpdate();

        expect(map.containsKey('confirmedAt'), isFalse);
        expect(map.containsKey('confirmedBy'), isFalse);
      });
    });

    group('SettlementEntity', () {
      test('copyWith creates copy with updated fields', () {
        final original = SettlementEntity(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'user-1',
          fromUserName: 'User 1',
          toUserId: 'user-2',
          toUserName: 'User 2',
          amount: 1000,
          status: SettlementStatus.pending,
          createdAt: testCreatedAt,
        );

        final updated = original.copyWith(
          status: SettlementStatus.confirmed,
          confirmedAt: testConfirmedAt,
          confirmedBy: 'user-2',
        );

        expect(updated.id, equals(original.id));
        expect(updated.groupId, equals(original.groupId));
        expect(updated.amount, equals(original.amount));
        expect(updated.status, equals(SettlementStatus.confirmed));
        expect(updated.confirmedAt, equals(testConfirmedAt));
        expect(updated.confirmedBy, equals('user-2'));
      });

      test('copyWith preserves original values when not specified', () {
        final original = SettlementEntity(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'user-1',
          fromUserName: 'User 1',
          toUserId: 'user-2',
          toUserName: 'User 2',
          amount: 1000,
          currency: 'USD',
          status: SettlementStatus.pending,
          paymentMethod: PaymentMethod.cash,
          notes: 'Original notes',
          createdAt: testCreatedAt,
        );

        final updated = original.copyWith(status: SettlementStatus.confirmed);

        expect(updated.currency, equals('USD'));
        expect(updated.paymentMethod, equals(PaymentMethod.cash));
        expect(updated.notes, equals('Original notes'));
      });

      test('uses Equatable for equality based on props', () {
        final entity1 = SettlementEntity(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        final entity2 = SettlementEntity(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(entity1, equals(entity2));
      });
    });

    group('SettlementModel inheritance', () {
      test('SettlementModel is a SettlementEntity', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(model, isA<SettlementEntity>());
      });

      test(
        'SettlementModel can be used where SettlementEntity is expected',
        () {
          SettlementEntity entity = SettlementModel(
            id: 'id',
            groupId: 'gid',
            fromUserId: 'u1',
            fromUserName: 'User 1',
            toUserId: 'u2',
            toUserName: 'User 2',
            amount: 1000,
            createdAt: testCreatedAt,
          );

          expect(entity.id, equals('id'));
          expect(entity.amount, equals(1000));
        },
      );
    });

    group('Default values', () {
      test('uses default currency INR when not specified', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(model.currency, equals('INR'));
      });

      test('uses default status pending when not specified', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(model.status, equals(SettlementStatus.pending));
      });

      test('uses default requiresBiometric false when not specified', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(model.requiresBiometric, isFalse);
      });

      test('uses default biometricVerified false when not specified', () {
        final model = SettlementModel(
          id: 'id',
          groupId: 'gid',
          fromUserId: 'u1',
          fromUserName: 'User 1',
          toUserId: 'u2',
          toUserName: 'User 2',
          amount: 1000,
          createdAt: testCreatedAt,
        );

        expect(model.biometricVerified, isFalse);
      });
    });
  });

  group('UserBalance', () {
    test('isOwed returns true for positive balance', () {
      final balance = UserBalance(
        userId: 'user-1',
        displayName: 'User 1',
        balance: 1000,
      );

      expect(balance.isOwed, isTrue);
      expect(balance.owes, isFalse);
      expect(balance.isSettled, isFalse);
    });

    test('owes returns true for negative balance', () {
      final balance = UserBalance(
        userId: 'user-1',
        displayName: 'User 1',
        balance: -1000,
      );

      expect(balance.isOwed, isFalse);
      expect(balance.owes, isTrue);
      expect(balance.isSettled, isFalse);
    });

    test('isSettled returns true for zero balance', () {
      final balance = UserBalance(
        userId: 'user-1',
        displayName: 'User 1',
        balance: 0,
      );

      expect(balance.isOwed, isFalse);
      expect(balance.owes, isFalse);
      expect(balance.isSettled, isTrue);
    });

    test('uses Equatable for equality', () {
      final balance1 = UserBalance(
        userId: 'user-1',
        displayName: 'User 1',
        balance: 1000,
      );

      final balance2 = UserBalance(
        userId: 'user-1',
        displayName: 'User 1',
        balance: 1000,
      );

      expect(balance1, equals(balance2));
    });
  });

  group('SimplifiedDebt', () {
    test('creates SimplifiedDebt with correct properties', () {
      final debt = SimplifiedDebt(
        fromUserId: 'user-1',
        fromUserName: 'User 1',
        toUserId: 'user-2',
        toUserName: 'User 2',
        amount: 5000,
      );

      expect(debt.fromUserId, equals('user-1'));
      expect(debt.fromUserName, equals('User 1'));
      expect(debt.toUserId, equals('user-2'));
      expect(debt.toUserName, equals('User 2'));
      expect(debt.amount, equals(5000));
    });

    test('uses Equatable for equality', () {
      final debt1 = SimplifiedDebt(
        fromUserId: 'user-1',
        fromUserName: 'User 1',
        toUserId: 'user-2',
        toUserName: 'User 2',
        amount: 5000,
      );

      final debt2 = SimplifiedDebt(
        fromUserId: 'user-1',
        fromUserName: 'Different Name',
        toUserId: 'user-2',
        toUserName: 'Another Name',
        amount: 5000,
      );

      // Equality is based on userId and amount, not names
      expect(debt1, equals(debt2));
    });
  });

  group('SimplificationStep', () {
    test('creates SimplificationStep with correct properties', () {
      final step = SimplificationStep(
        title: 'Step 1',
        description: 'Calculate initial balances',
        balances: {'user-1': 1000, 'user-2': -1000},
        displayNames: {'user-1': 'User 1', 'user-2': 'User 2'},
        settlement: null,
      );

      expect(step.title, equals('Step 1'));
      expect(step.description, equals('Calculate initial balances'));
      expect(step.balances['user-1'], equals(1000));
      expect(step.displayNames['user-1'], equals('User 1'));
      expect(step.settlement, isNull);
    });

    test('creates SimplificationStep with settlement', () {
      final settlement = SimplifiedDebt(
        fromUserId: 'user-1',
        fromUserName: 'User 1',
        toUserId: 'user-2',
        toUserName: 'User 2',
        amount: 1000,
      );

      final step = SimplificationStep(
        title: 'Settlement Step',
        description: 'User 1 pays User 2',
        balances: {},
        displayNames: {},
        settlement: settlement,
      );

      expect(step.settlement, isNotNull);
      expect(step.settlement!.amount, equals(1000));
    });
  });
}
