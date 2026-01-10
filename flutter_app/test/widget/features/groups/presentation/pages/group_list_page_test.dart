import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/groups/domain/entities/group_entity.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_bloc.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_event.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_state.dart';
import 'package:whats_my_share/features/groups/presentation/pages/group_list_page.dart';

// Mock classes
class MockGroupBloc extends Mock implements GroupBloc {}

class FakeGroupEvent extends Fake implements GroupEvent {}

class FakeGroupState extends Fake implements GroupState {}

void main() {
  late MockGroupBloc mockGroupBloc;

  setUpAll(() {
    registerFallbackValue(FakeGroupEvent());
    registerFallbackValue(FakeGroupState());
  });

  setUp(() {
    mockGroupBloc = MockGroupBloc();
    when(
      () => mockGroupBloc.stream,
    ).thenAnswer((_) => Stream<GroupState>.empty());
  });

  Widget createTestWidget({GroupState? groupState}) {
    when(
      () => mockGroupBloc.state,
    ).thenReturn(groupState ?? const GroupState());

    return MaterialApp(
      home: BlocProvider<GroupBloc>.value(
        value: mockGroupBloc,
        child: const GroupListPage(),
      ),
    );
  }

  GroupEntity createTestGroup({
    String id = 'group-1',
    String name = 'Test Group',
    GroupType type = GroupType.trip,
    int memberCount = 3,
    int totalExpenses = 10000, // in paisa
    DateTime? lastActivityAt,
  }) {
    final members = List.generate(
      memberCount,
      (i) => GroupMember(
        userId: 'member-$i',
        displayName: 'Member $i',
        email: 'member$i@test.com',
        joinedAt: DateTime(2025, 1, 1),
        role: i == 0 ? MemberRole.admin : MemberRole.member,
      ),
    );
    return GroupEntity(
      id: id,
      name: name,
      type: type,
      members: members,
      memberIds: List.generate(memberCount, (i) => 'member-$i'),
      memberCount: memberCount,
      currency: 'INR',
      simplifyDebts: true,
      createdBy: 'member-0',
      admins: ['member-0'],
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      totalExpenses: totalExpenses,
      expenseCount: 0,
      lastActivityAt: lastActivityAt,
      balances: {},
    );
  }

  group('GroupListPage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Groups'), findsOneWidget);
      });

      testWidgets('should display search icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(status: GroupStatus.loading),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('should show error message when has error', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.failure,
              errorMessage: 'Failed to load groups',
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Failed to load groups'), findsOneWidget);
      });

      testWidgets('should show retry button on error', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.failure,
              errorMessage: 'Error',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should trigger reload when retry is tapped', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.failure,
              errorMessage: 'Error',
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Retry'));
        await tester.pump();

        verify(
          () => mockGroupBloc.add(const GroupLoadAllRequested()),
        ).called(2); // Init + retry
      });
    });

    group('Empty State', () {
      testWidgets('should show empty state when no groups', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.success,
              groups: [],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('No groups yet'), findsOneWidget);
        expect(
          find.text('Create a group to start splitting expenses with friends'),
          findsOneWidget,
        );
      });

      testWidgets('should show group icon in empty state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.success,
              groups: [],
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      });

      testWidgets('should show create group button in empty state', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.success,
              groups: [],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Create Group'), findsOneWidget);
      });
    });

    group('Groups List', () {
      testWidgets('should display groups when available', (tester) async {
        final groups = [
          createTestGroup(id: 'g1', name: 'Trip to Paris'),
          createTestGroup(id: 'g2', name: 'Roommates'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('Trip to Paris'), findsOneWidget);
        expect(find.text('Roommates'), findsOneWidget);
      });

      testWidgets('should display member count', (tester) async {
        final groups = [createTestGroup(memberCount: 5)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('5 members'), findsOneWidget);
      });

      testWidgets('should display no expenses label when total is 0', (
        tester,
      ) async {
        final groups = [createTestGroup(totalExpenses: 0)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('No expenses'), findsOneWidget);
      });

      testWidgets('should display total expenses when > 0', (tester) async {
        final groups = [createTestGroup(totalExpenses: 150050)]; // in paisa

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('total'), findsOneWidget);
      });
    });

    group('Group Type Icons', () {
      testWidgets('should display trip emoji for trip group', (tester) async {
        final groups = [createTestGroup(type: GroupType.trip)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('✈️'), findsOneWidget);
      });

      testWidgets('should display home emoji for home group', (tester) async {
        final groups = [createTestGroup(type: GroupType.home)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('🏠'), findsOneWidget);
      });

      testWidgets('should display couple emoji for couple group', (
        tester,
      ) async {
        final groups = [createTestGroup(type: GroupType.couple)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('💑'), findsOneWidget);
      });

      testWidgets('should display group emoji for other group', (tester) async {
        final groups = [createTestGroup(type: GroupType.other)];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('👥'), findsOneWidget);
      });
    });

    group('Last Activity Formatting', () {
      testWidgets('should display Today for today activity', (tester) async {
        final groups = [createTestGroup(lastActivityAt: DateTime.now())];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Today'), findsOneWidget);
      });

      testWidgets('should display Yesterday for yesterday activity', (
        tester,
      ) async {
        final groups = [
          createTestGroup(
            lastActivityAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Yesterday'), findsOneWidget);
      });

      testWidgets('should display days ago for recent activity', (
        tester,
      ) async {
        final groups = [
          createTestGroup(
            lastActivityAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.textContaining('3 days ago'), findsOneWidget);
      });
    });

    group('Floating Action Button', () {
      testWidgets('should display New Group FAB', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // Multiple add icons can exist in the UI
        expect(find.byIcon(Icons.add), findsWidgets);
      });

      testWidgets('should have FloatingActionButton', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('RefreshIndicator', () {
      testWidgets('should have RefreshIndicator when groups exist', (
        tester,
      ) async {
        final groups = [createTestGroup()];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Group Cards', () {
      testWidgets('should display group in a Card widget', (tester) async {
        final groups = [createTestGroup()];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should display people icon for member count', (
        tester,
      ) async {
        final groups = [createTestGroup()];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });
    });

    group('Multiple Groups', () {
      testWidgets('should display multiple groups in ListView', (tester) async {
        final groups = [
          createTestGroup(id: 'g1', name: 'Group 1'),
          createTestGroup(id: 'g2', name: 'Group 2'),
          createTestGroup(id: 'g3', name: 'Group 3'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(status: GroupStatus.success, groups: groups),
          ),
        );
        await tester.pump();

        expect(find.text('Group 1'), findsOneWidget);
        expect(find.text('Group 2'), findsOneWidget);
        expect(find.text('Group 3'), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(3));
      });
    });

    group('Initialization', () {
      testWidgets('should load groups on init', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        verify(
          () => mockGroupBloc.add(const GroupLoadAllRequested()),
        ).called(1);
      });
    });
  });
}
