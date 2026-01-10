import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/settlements/domain/entities/settlement_entity.dart';
import 'package:whats_my_share/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_bloc.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_event.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_state.dart';

// Mock classes
class MockSettlementRepository extends Mock implements SettlementRepository {}

void main() {
  late MockSettlementRepository mockRepository;
  late SettlementBloc settlementBloc;

  final testDate = DateTime(2024, 1, 15, 10, 30);
  const testGroupId = 'group-123';

  final testSettlement = SettlementEntity(
    id: 'settlement-1',
    groupId: testGroupId,
    fromUserId: 'user-1',
    fromUserName: 'Alice',
    toUserId: 'user-2',
    toUserName: 'Bob',
    amount: 5000,
    currency: 'INR',
    status: SettlementStatus.pending,
    createdAt: testDate,
  );

  final testBalances = {'user-1': 2500, 'user-2': -2500};

  final testSimplifiedDebts = [
    const SimplifiedDebt(
      fromUserId: 'user-2',
      fromUserName: 'Bob',
      toUserId: 'user-1',
      toUserName: 'Alice',
      amount: 2500,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(testSettlement);
  });

  setUp(() {
    mockRepository = MockSettlementRepository();
    settlementBloc = SettlementBloc(repository: mockRepository);
  });

  tearDown(() {
    settlementBloc.close();
  });

  group('SettlementBloc', () {
    test('initial state is SettlementInitial', () {
      expect(settlementBloc.state, isA<SettlementInitial>());
    });

    group('LoadGroupSettlements', () {
      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementLoading, SettlementLoaded] when loading succeeds',
        build: () {
          when(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).thenAnswer((_) async => [testSettlement]);
          return settlementBloc;
        },
        act: (bloc) => bloc.add(const LoadGroupSettlements(testGroupId)),
        expect: () => [
          const SettlementLoading(),
          isA<SettlementLoaded>()
              .having((s) => s.settlements.length, 'settlements length', 1)
              .having((s) => s.currentGroupId, 'currentGroupId', testGroupId),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).called(1);
        },
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementLoading, SettlementError] when loading fails',
        build: () {
          when(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).thenThrow(Exception('Failed to load'));
          return settlementBloc;
        },
        act: (bloc) => bloc.add(const LoadGroupSettlements(testGroupId)),
        expect: () => [const SettlementLoading(), isA<SettlementError>()],
      );
    });

    group('LoadGroupBalances', () {
      blocTest<SettlementBloc, SettlementState>(
        'emits SettlementLoaded with balances when loading succeeds',
        build: () {
          when(
            () => mockRepository.getGroupBalances(testGroupId),
          ).thenAnswer((_) async => testBalances);
          when(
            () => mockRepository.getSimplifiedDebts(testGroupId, any()),
          ).thenAnswer((_) async => testSimplifiedDebts);
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          LoadGroupBalances(
            groupId: testGroupId,
            displayNames: {'user-1': 'Alice', 'user-2': 'Bob'},
          ),
        ),
        expect: () => [
          isA<SettlementLoaded>()
              .having((s) => s.balances, 'balances', testBalances)
              .having(
                (s) => s.simplifiedDebts.length,
                'simplifiedDebts length',
                1,
              ),
        ],
        verify: (_) {
          verify(() => mockRepository.getGroupBalances(testGroupId)).called(1);
          verify(
            () => mockRepository.getSimplifiedDebts(testGroupId, any()),
          ).called(1);
        },
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits SettlementError when loading balances fails',
        build: () {
          when(
            () => mockRepository.getGroupBalances(testGroupId),
          ).thenThrow(Exception('Failed to load'));
          return settlementBloc;
        },
        act: (bloc) =>
            bloc.add(LoadGroupBalances(groupId: testGroupId, displayNames: {})),
        expect: () => [isA<SettlementError>()],
      );
    });

    group('CreateSettlement', () {
      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementOperationSuccess] when creation succeeds',
        build: () {
          when(
            () => mockRepository.createSettlement(
              groupId: testGroupId,
              fromUserId: 'user-1',
              fromUserName: 'Alice',
              toUserId: 'user-2',
              toUserName: 'Bob',
              amount: 5000,
              currency: 'INR',
              paymentMethod: PaymentMethod.cash,
              paymentReference: null,
              notes: null,
            ),
          ).thenAnswer((_) async => testSettlement);
          when(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).thenAnswer((_) async => [testSettlement]);
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const CreateSettlement(
            groupId: testGroupId,
            fromUserId: 'user-1',
            fromUserName: 'Alice',
            toUserId: 'user-2',
            toUserName: 'Bob',
            amount: 5000,
            currency: 'INR',
            paymentMethod: PaymentMethod.cash,
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('create'),
          isA<SettlementOperationSuccess>().having(
            (s) => s.settlement,
            'settlement',
            isNotNull,
          ),
          const SettlementLoading(),
          isA<SettlementLoaded>(),
        ],
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementError] when creation fails',
        build: () {
          when(
            () => mockRepository.createSettlement(
              groupId: any(named: 'groupId'),
              fromUserId: any(named: 'fromUserId'),
              fromUserName: any(named: 'fromUserName'),
              toUserId: any(named: 'toUserId'),
              toUserName: any(named: 'toUserName'),
              amount: any(named: 'amount'),
              currency: any(named: 'currency'),
              paymentMethod: any(named: 'paymentMethod'),
              paymentReference: any(named: 'paymentReference'),
              notes: any(named: 'notes'),
            ),
          ).thenThrow(Exception('Failed to create'));
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const CreateSettlement(
            groupId: testGroupId,
            fromUserId: 'user-1',
            fromUserName: 'Alice',
            toUserId: 'user-2',
            toUserName: 'Bob',
            amount: 5000,
            currency: 'INR',
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('create'),
          isA<SettlementError>(),
        ],
      );
    });

    group('ConfirmSettlement', () {
      final confirmedSettlement = SettlementEntity(
        id: 'settlement-1',
        groupId: testGroupId,
        fromUserId: 'user-1',
        fromUserName: 'Alice',
        toUserId: 'user-2',
        toUserName: 'Bob',
        amount: 5000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        confirmedAt: testDate,
        confirmedBy: 'user-2',
        createdAt: testDate,
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementOperationSuccess] when confirmation succeeds',
        build: () {
          when(
            () => mockRepository.confirmSettlement(
              groupId: testGroupId,
              settlementId: 'settlement-1',
              confirmedBy: 'user-2',
              biometricVerified: false,
            ),
          ).thenAnswer((_) async => confirmedSettlement);
          when(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).thenAnswer((_) async => [confirmedSettlement]);
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const ConfirmSettlement(
            groupId: testGroupId,
            settlementId: 'settlement-1',
            confirmedBy: 'user-2',
            biometricVerified: false,
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('confirm'),
          isA<SettlementOperationSuccess>().having(
            (s) => s.settlement?.status,
            'status',
            SettlementStatus.confirmed,
          ),
          const SettlementLoading(),
          isA<SettlementLoaded>(),
        ],
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementError] when confirmation fails',
        build: () {
          when(
            () => mockRepository.confirmSettlement(
              groupId: any(named: 'groupId'),
              settlementId: any(named: 'settlementId'),
              confirmedBy: any(named: 'confirmedBy'),
              biometricVerified: any(named: 'biometricVerified'),
            ),
          ).thenThrow(Exception('Failed to confirm'));
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const ConfirmSettlement(
            groupId: testGroupId,
            settlementId: 'settlement-1',
            confirmedBy: 'user-2',
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('confirm'),
          isA<SettlementError>(),
        ],
      );
    });

    group('RejectSettlement', () {
      final rejectedSettlement = SettlementEntity(
        id: 'settlement-1',
        groupId: testGroupId,
        fromUserId: 'user-1',
        fromUserName: 'Alice',
        toUserId: 'user-2',
        toUserName: 'Bob',
        amount: 5000,
        currency: 'INR',
        status: SettlementStatus.rejected,
        createdAt: testDate,
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementOperationSuccess] when rejection succeeds',
        build: () {
          when(
            () => mockRepository.rejectSettlement(
              groupId: testGroupId,
              settlementId: 'settlement-1',
              reason: 'Amount incorrect',
            ),
          ).thenAnswer((_) async => rejectedSettlement);
          when(
            () => mockRepository.getGroupSettlements(testGroupId),
          ).thenAnswer((_) async => []);
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const RejectSettlement(
            groupId: testGroupId,
            settlementId: 'settlement-1',
            reason: 'Amount incorrect',
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('reject'),
          isA<SettlementOperationSuccess>(),
          const SettlementLoading(),
          isA<SettlementLoaded>(),
        ],
      );

      blocTest<SettlementBloc, SettlementState>(
        'emits [SettlementOperationInProgress, SettlementError] when rejection fails',
        build: () {
          when(
            () => mockRepository.rejectSettlement(
              groupId: any(named: 'groupId'),
              settlementId: any(named: 'settlementId'),
              reason: any(named: 'reason'),
            ),
          ).thenThrow(Exception('Failed to reject'));
          return settlementBloc;
        },
        act: (bloc) => bloc.add(
          const RejectSettlement(
            groupId: testGroupId,
            settlementId: 'settlement-1',
            reason: 'Invalid',
          ),
        ),
        expect: () => [
          const SettlementOperationInProgress('reject'),
          isA<SettlementError>(),
        ],
      );
    });

    group('ClearSettlementError', () {
      blocTest<SettlementBloc, SettlementState>(
        'emits SettlementInitial when clearing error',
        build: () => settlementBloc,
        seed: () => const SettlementError('Some error'),
        act: (bloc) => bloc.add(const ClearSettlementError()),
        expect: () => [const SettlementInitial()],
      );
    });
  });

  group('SettlementState', () {
    test('SettlementInitial props are empty', () {
      const state = SettlementInitial();
      expect(state.props, isEmpty);
    });

    test('SettlementLoading props are empty', () {
      const state = SettlementLoading();
      expect(state.props, isEmpty);
    });

    test('SettlementLoaded props contain settlements', () {
      final state = SettlementLoaded(
        settlements: [testSettlement],
        currentGroupId: testGroupId,
      );
      expect(state.props, isNotEmpty);
    });

    test('SettlementLoaded copyWith creates copy with updated fields', () {
      final state = SettlementLoaded(
        settlements: [testSettlement],
        currentGroupId: testGroupId,
      );

      final newBalances = {'user-1': 1000};
      final copied = state.copyWith(balances: newBalances);

      expect(copied.balances, newBalances);
      expect(copied.settlements.length, 1);
      expect(copied.currentGroupId, testGroupId);
    });

    test('SettlementError props contain message', () {
      const state = SettlementError('Error message');
      expect(state.props, contains('Error message'));
    });

    test('SettlementOperationInProgress props contain operation', () {
      const state = SettlementOperationInProgress('create');
      expect(state.props, contains('create'));
    });

    test('SettlementOperationSuccess props contain message', () {
      const state = SettlementOperationSuccess(message: 'Success');
      expect(state.props, isNotEmpty);
    });
  });

  group('SettlementEvent', () {
    test('LoadGroupSettlements props contain groupId', () {
      const event = LoadGroupSettlements(testGroupId);
      expect(event.props, contains(testGroupId));
    });

    test('LoadGroupBalances props contain groupId and displayNames', () {
      final event = LoadGroupBalances(
        groupId: testGroupId,
        displayNames: {'user-1': 'Alice'},
      );
      expect(event.props, contains(testGroupId));
    });

    test('CreateSettlement props contain all required fields', () {
      const event = CreateSettlement(
        groupId: testGroupId,
        fromUserId: 'user-1',
        fromUserName: 'Alice',
        toUserId: 'user-2',
        toUserName: 'Bob',
        amount: 5000,
        currency: 'INR',
      );
      expect(event.props, contains(testGroupId));
      expect(event.props, contains('user-1'));
      expect(event.props, contains(5000));
    });

    test('ConfirmSettlement props contain groupId and settlementId', () {
      const event = ConfirmSettlement(
        groupId: testGroupId,
        settlementId: 'settlement-1',
        confirmedBy: 'user-2',
      );
      expect(event.props, contains(testGroupId));
      expect(event.props, contains('settlement-1'));
    });

    test('RejectSettlement props contain groupId and settlementId', () {
      const event = RejectSettlement(
        groupId: testGroupId,
        settlementId: 'settlement-1',
        reason: 'Invalid',
      );
      expect(event.props, contains(testGroupId));
      expect(event.props, contains('settlement-1'));
    });

    test('ClearSettlementError props are empty', () {
      const event = ClearSettlementError();
      expect(event.props, isEmpty);
    });
  });

  group('SettlementLoaded helpers', () {
    test('pendingSettlements returns only pending settlements', () {
      final pending = testSettlement;
      final confirmed = SettlementEntity(
        id: 'settlement-2',
        groupId: testGroupId,
        fromUserId: 'user-2',
        fromUserName: 'Bob',
        toUserId: 'user-1',
        toUserName: 'Alice',
        amount: 3000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        createdAt: testDate,
      );

      final state = SettlementLoaded(
        settlements: [pending, confirmed],
        currentGroupId: testGroupId,
      );

      expect(state.pendingSettlements.length, 1);
      expect(state.pendingSettlements.first.status, SettlementStatus.pending);
    });

    test('confirmedSettlements returns only confirmed settlements', () {
      final pending = testSettlement;
      final confirmed = SettlementEntity(
        id: 'settlement-2',
        groupId: testGroupId,
        fromUserId: 'user-2',
        fromUserName: 'Bob',
        toUserId: 'user-1',
        toUserName: 'Alice',
        amount: 3000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        createdAt: testDate,
      );

      final state = SettlementLoaded(
        settlements: [pending, confirmed],
        currentGroupId: testGroupId,
      );

      expect(state.confirmedSettlements.length, 1);
      expect(
        state.confirmedSettlements.first.status,
        SettlementStatus.confirmed,
      );
    });

    test('settlements can be filtered by status', () {
      final pending = testSettlement;
      final confirmed = SettlementEntity(
        id: 'settlement-2',
        groupId: testGroupId,
        fromUserId: 'user-2',
        fromUserName: 'Bob',
        toUserId: 'user-1',
        toUserName: 'Alice',
        amount: 3000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        createdAt: testDate,
      );

      final state = SettlementLoaded(
        settlements: [pending, confirmed],
        currentGroupId: testGroupId,
      );

      // Filter settlements manually
      final pendingList = state.settlements
          .where((s) => s.status == SettlementStatus.pending)
          .toList();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, 'settlement-1');
    });

    test('settlements can be filtered by user involvement', () {
      final settlement1 = testSettlement;
      final settlement2 = SettlementEntity(
        id: 'settlement-2',
        groupId: testGroupId,
        fromUserId: 'user-3',
        fromUserName: 'Charlie',
        toUserId: 'user-1',
        toUserName: 'Alice',
        amount: 3000,
        currency: 'INR',
        status: SettlementStatus.pending,
        createdAt: testDate,
      );
      final settlement3 = SettlementEntity(
        id: 'settlement-3',
        groupId: testGroupId,
        fromUserId: 'user-3',
        fromUserName: 'Charlie',
        toUserId: 'user-4',
        toUserName: 'Dave',
        amount: 2000,
        currency: 'INR',
        status: SettlementStatus.pending,
        createdAt: testDate,
      );

      final state = SettlementLoaded(
        settlements: [settlement1, settlement2, settlement3],
        currentGroupId: testGroupId,
      );

      // Filter settlements involving user-1
      final userSettlements = state.settlements
          .where((s) => s.fromUserId == 'user-1' || s.toUserId == 'user-1')
          .toList();
      expect(userSettlements.length, 2);
    });

    test('confirmed settlements amount can be summed', () {
      final confirmed1 = SettlementEntity(
        id: 'settlement-1',
        groupId: testGroupId,
        fromUserId: 'user-1',
        fromUserName: 'Alice',
        toUserId: 'user-2',
        toUserName: 'Bob',
        amount: 5000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        createdAt: testDate,
      );
      final confirmed2 = SettlementEntity(
        id: 'settlement-2',
        groupId: testGroupId,
        fromUserId: 'user-2',
        fromUserName: 'Bob',
        toUserId: 'user-1',
        toUserName: 'Alice',
        amount: 3000,
        currency: 'INR',
        status: SettlementStatus.confirmed,
        createdAt: testDate,
      );
      final pending = testSettlement;

      final state = SettlementLoaded(
        settlements: [confirmed1, confirmed2, pending],
        currentGroupId: testGroupId,
      );

      // Sum confirmed settlements manually
      final totalSettled = state.confirmedSettlements.fold<int>(
        0,
        (sum, s) => sum + s.amount,
      );
      expect(totalSettled, 8000);
    });
  });
}
