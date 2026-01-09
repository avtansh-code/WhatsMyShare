import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/features/groups/domain/entities/group_entity.dart';
import 'package:whats_my_share/features/groups/domain/repositories/group_repository.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_bloc.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_event.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_state.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(GroupType.trip);
    registerFallbackValue(MemberRole.member);
  });

  late GroupBloc bloc;
  late MockGroupRepository mockRepository;

  final testDateTime = DateTime(2026, 1, 9);

  final testGroup = GroupEntity(
    id: 'group-1',
    name: 'Test Group',
    description: 'A test group',
    type: GroupType.trip,
    createdBy: 'user-1',
    createdAt: testDateTime,
    updatedAt: testDateTime,
    currency: 'INR',
    simplifyDebts: true,
    totalExpenses: 10000,
    expenseCount: 5,
    memberIds: ['user-1'],
    memberCount: 1,
    admins: ['user-1'],
    members: [
      GroupMember(
        userId: 'user-1',
        role: MemberRole.admin,
        joinedAt: testDateTime,
      ),
    ],
    balances: {'user-1': 5000},
    simplifiedDebts: [],
  );

  final testGroup2 = GroupEntity(
    id: 'group-2',
    name: 'Another Group',
    description: 'Another test group',
    type: GroupType.home,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 8),
    updatedAt: DateTime(2026, 1, 8),
    currency: 'INR',
    simplifyDebts: true,
    totalExpenses: 5000,
    expenseCount: 3,
    memberIds: ['user-1'],
    memberCount: 1,
    admins: ['user-1'],
    members: [
      GroupMember(
        userId: 'user-1',
        role: MemberRole.admin,
        joinedAt: DateTime(2026, 1, 8),
      ),
    ],
    balances: {'user-1': -2500},
    simplifiedDebts: [],
  );

  setUp(() {
    mockRepository = MockGroupRepository();
    bloc = GroupBloc(groupRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('GroupBloc', () {
    test('initial state is GroupState.initial()', () {
      expect(bloc.state, equals(GroupState.initial()));
      expect(bloc.state.status, equals(GroupStatus.initial));
      expect(bloc.state.groups, isEmpty);
      expect(bloc.state.selectedGroup, isNull);
    });

    group('GroupCreateRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits [creating, success] when group creation succeeds',
        build: () {
          when(
            () => mockRepository.createGroup(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              currency: any(named: 'currency'),
              simplifyDebts: any(named: 'simplifyDebts'),
              initialMemberIds: any(named: 'initialMemberIds'),
            ),
          ).thenAnswer((_) async => Right(testGroup));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupCreateRequested(
            name: 'Test Group',
            type: GroupType.trip,
            currency: 'INR',
          ),
        ),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.creating)
              .having((s) => s.isCreating, 'isCreating', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having((s) => s.groups.length, 'groups length', 1)
              .having((s) => s.selectedGroup?.id, 'selected group', 'group-1')
              .having((s) => s.isCreating, 'isCreating', false),
        ],
      );

      blocTest<GroupBloc, GroupState>(
        'emits [creating, failure] when group creation fails',
        build: () {
          when(
            () => mockRepository.createGroup(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              currency: any(named: 'currency'),
              simplifyDebts: any(named: 'simplifyDebts'),
              initialMemberIds: any(named: 'initialMemberIds'),
            ),
          ).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Failed to create group')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupCreateRequested(
            name: 'Test Group',
            type: GroupType.trip,
            currency: 'INR',
          ),
        ),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.creating)
              .having((s) => s.isCreating, 'isCreating', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.failure)
              .having((s) => s.errorMessage, 'has error', isNotNull)
              .having((s) => s.isCreating, 'isCreating', false),
        ],
      );
    });

    group('GroupUpdateRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits [updating, success] when group update succeeds',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
          selectedGroup: testGroup,
        ),
        build: () {
          final updatedGroup = testGroup.copyWith(name: 'Updated Group');
          when(
            () => mockRepository.updateGroup(
              groupId: any(named: 'groupId'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              currency: any(named: 'currency'),
              simplifyDebts: any(named: 'simplifyDebts'),
            ),
          ).thenAnswer((_) async => Right(updatedGroup));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupUpdateRequested(groupId: 'group-1', name: 'Updated Group'),
        ),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.updating)
              .having((s) => s.isUpdating, 'isUpdating', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having(
                (s) => s.selectedGroup?.name,
                'updated name',
                'Updated Group',
              )
              .having((s) => s.isUpdating, 'isUpdating', false),
        ],
      );

      blocTest<GroupBloc, GroupState>(
        'emits [updating, failure] when group update fails',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () {
          when(
            () => mockRepository.updateGroup(
              groupId: any(named: 'groupId'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              currency: any(named: 'currency'),
              simplifyDebts: any(named: 'simplifyDebts'),
            ),
          ).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Update failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupUpdateRequested(groupId: 'group-1', name: 'Updated Group'),
        ),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.updating)
              .having((s) => s.isUpdating, 'isUpdating', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.failure)
              .having((s) => s.isUpdating, 'isUpdating', false),
        ],
      );
    });

    group('GroupDeleteRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits [deleting, success] when group deletion succeeds',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup, testGroup2],
        ),
        build: () {
          when(
            () => mockRepository.deleteGroup(any()),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const GroupDeleteRequested('group-1')),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.deleting)
              .having((s) => s.isDeleting, 'isDeleting', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having((s) => s.groups.length, 'groups length', 1)
              .having((s) => s.groups.first.id, 'remaining group', 'group-2')
              .having((s) => s.isDeleting, 'isDeleting', false),
        ],
      );

      blocTest<GroupBloc, GroupState>(
        'emits [deleting, failure] when group deletion fails',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () {
          when(() => mockRepository.deleteGroup(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Delete failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const GroupDeleteRequested('group-1')),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.deleting)
              .having((s) => s.isDeleting, 'isDeleting', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.failure)
              .having((s) => s.isDeleting, 'isDeleting', false)
              .having((s) => s.groups.length, 'groups unchanged', 1),
        ],
      );
    });

    group('GroupLeaveRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits [deleting, success] when leaving group succeeds',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () {
          when(
            () => mockRepository.leaveGroup(any()),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const GroupLeaveRequested('group-1')),
        expect: () => [
          isA<GroupState>().having((s) => s.isDeleting, 'isDeleting', true),
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having((s) => s.groups, 'groups empty', isEmpty)
              .having((s) => s.isDeleting, 'isDeleting', false),
        ],
      );
    });

    group('GroupMemberAddRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits updating state when adding member',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () {
          final updatedGroup = testGroup.copyWith(memberCount: 2);
          when(
            () => mockRepository.addMember(
              groupId: any(named: 'groupId'),
              userId: any(named: 'userId'),
              role: any(named: 'role'),
            ),
          ).thenAnswer((_) async => Right(updatedGroup));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupMemberAddRequested(
            groupId: 'group-1',
            userId: 'user-2',
          ),
        ),
        expect: () => [
          isA<GroupState>().having((s) => s.isUpdating, 'isUpdating', true),
          isA<GroupState>().having((s) => s.isUpdating, 'isUpdating', false),
        ],
      );
    });

    group('GroupMemberRemoveRequested', () {
      blocTest<GroupBloc, GroupState>(
        'emits updating state when removing member',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () {
          final updatedGroup = testGroup.copyWith(memberCount: 0);
          when(
            () => mockRepository.removeMember(
              groupId: any(named: 'groupId'),
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async => Right(updatedGroup));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const GroupMemberRemoveRequested(
            groupId: 'group-1',
            userId: 'user-1',
          ),
        ),
        expect: () => [
          isA<GroupState>().having((s) => s.isUpdating, 'isUpdating', true),
          isA<GroupState>().having((s) => s.isUpdating, 'isUpdating', false),
        ],
      );
    });

    group('GroupUpdated (stream)', () {
      blocTest<GroupBloc, GroupState>(
        'updates groups when GroupUpdated event is received',
        build: () => bloc,
        act: (bloc) => bloc.add(GroupUpdated([testGroup, testGroup2])),
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having((s) => s.groups.length, 'groups count', 2),
        ],
      );
    });

    group('SingleGroupUpdated (stream)', () {
      blocTest<GroupBloc, GroupState>(
        'updates selected group when SingleGroupUpdated is received',
        seed: () => GroupState.initial().copyWith(
          status: GroupStatus.success,
          groups: [testGroup],
        ),
        build: () => bloc,
        act: (bloc) {
          final updatedGroup = testGroup.copyWith(name: 'Realtime Updated');
          bloc.add(SingleGroupUpdated(updatedGroup));
        },
        expect: () => [
          isA<GroupState>()
              .having((s) => s.status, 'status', GroupStatus.success)
              .having((s) => s.selectedGroup?.name, 'name', 'Realtime Updated')
              .having(
                (s) => s.groups.first.name,
                'list name',
                'Realtime Updated',
              ),
        ],
      );
    });
  });

  group('GroupState', () {
    test('initial factory creates correct initial state', () {
      final state = GroupState.initial();

      expect(state.status, equals(GroupStatus.initial));
      expect(state.groups, isEmpty);
      expect(state.selectedGroup, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isCreating, isFalse);
      expect(state.isUpdating, isFalse);
      expect(state.isDeleting, isFalse);
    });

    test('isLoading returns true when status is loading', () {
      const state = GroupState(status: GroupStatus.loading);
      expect(state.isLoading, isTrue);
    });

    test('hasError returns true when status is failure with error message', () {
      const state = GroupState(
        status: GroupStatus.failure,
        errorMessage: 'An error occurred',
      );
      expect(state.hasError, isTrue);
    });

    test('isLoaded returns true when status is success', () {
      const state = GroupState(status: GroupStatus.success);
      expect(state.isLoaded, isTrue);
    });

    test('hasGroups returns true when groups list is not empty', () {
      final state = GroupState(
        status: GroupStatus.success,
        groups: [testGroup],
      );
      expect(state.hasGroups, isTrue);
    });

    test('groupCount returns correct count', () {
      final state = GroupState(
        status: GroupStatus.success,
        groups: [testGroup, testGroup2],
      );
      expect(state.groupCount, equals(2));
    });

    test('copyWith creates copy with updated fields', () {
      final original = GroupState.initial();
      final updated = original.copyWith(
        status: GroupStatus.loading,
        isCreating: true,
      );

      expect(updated.status, equals(GroupStatus.loading));
      expect(updated.isCreating, isTrue);
      expect(updated.groups, equals(original.groups));
    });

    test('copyWith with clearSelectedGroup clears selected group', () {
      final state = GroupState(selectedGroup: testGroup);
      final cleared = state.copyWith(clearSelectedGroup: true);

      expect(cleared.selectedGroup, isNull);
    });

    test('copyWith with clearError clears error message', () {
      const state = GroupState(errorMessage: 'Error');
      final cleared = state.copyWith(clearError: true);

      expect(cleared.errorMessage, isNull);
    });

    test('groupsWhereUserOwes returns groups with negative balance', () {
      final state = GroupState(groups: [testGroup, testGroup2]);
      final owingGroups = state.groupsWhereUserOwes;
      expect(owingGroups.length, equals(1));
      expect(owingGroups.first.id, equals('group-2'));
    });

    test('groupsWhereUserIsOwed returns groups with positive balance', () {
      final state = GroupState(groups: [testGroup, testGroup2]);
      final owedGroups = state.groupsWhereUserIsOwed;
      expect(owedGroups.length, equals(1));
      expect(owedGroups.first.id, equals('group-1'));
    });

    test('recentGroups returns groups sorted by activity', () {
      final state = GroupState(groups: [testGroup, testGroup2]);
      final recent = state.recentGroups;
      expect(recent.first.id, equals('group-1'));
    });
  });

  group('GroupEvent', () {
    test('GroupLoadAllRequested props are empty', () {
      const event = GroupLoadAllRequested();
      expect(event.props, isEmpty);
    });

    test('GroupLoadByIdRequested props contain groupId', () {
      const event = GroupLoadByIdRequested('group-1');
      expect(event.props, equals(['group-1']));
    });

    test('GroupCreateRequested props contain all fields', () {
      const event = GroupCreateRequested(
        name: 'Test',
        description: 'Desc',
        type: GroupType.trip,
        currency: 'INR',
        simplifyDebts: true,
      );
      expect(event.props, contains('Test'));
      expect(event.props, contains('Desc'));
      expect(event.props, contains(GroupType.trip));
      expect(event.props, contains('INR'));
    });

    test('GroupDeleteRequested props contain groupId', () {
      const event = GroupDeleteRequested('group-1');
      expect(event.props, equals(['group-1']));
    });

    test('GroupLeaveRequested props contain groupId', () {
      const event = GroupLeaveRequested('group-1');
      expect(event.props, equals(['group-1']));
    });

    test('GroupUpdated props contain groups list', () {
      final event = GroupUpdated([testGroup]);
      expect(event.props.first, isA<List<GroupEntity>>());
    });

    test('SingleGroupUpdated props contain group', () {
      final event = SingleGroupUpdated(testGroup);
      expect(event.props.first, equals(testGroup));
    });
  });
}
