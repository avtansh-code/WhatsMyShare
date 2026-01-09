import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/groups/domain/entities/group_entity.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_bloc.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_event.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_state.dart';
import 'package:whats_my_share/features/groups/presentation/pages/group_detail_page.dart';

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

  Widget createTestWidget({
    GroupState? groupState,
    String groupId = 'group-1',
  }) {
    when(
      () => mockGroupBloc.state,
    ).thenReturn(groupState ?? const GroupState());

    return MaterialApp(
      home: BlocProvider<GroupBloc>.value(
        value: mockGroupBloc,
        child: GroupDetailPage(groupId: groupId),
      ),
    );
  }

  GroupEntity createTestGroup({
    String id = 'group-1',
    String name = 'Test Group',
    GroupType type = GroupType.trip,
    int memberCount = 3,
    int totalExpenses = 10000,
    int expenseCount = 5,
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
      expenseCount: expenseCount,
      balances: {'member-0': 5000, 'member-1': -3000, 'member-2': -2000},
    );
  }

  group('GroupDetailPage Widget Tests', () {
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
      testWidgets('should show error when group not found', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.success,
              selectedGroup: null,
              errorMessage: 'Group not found',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Group not found'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show Go Back button on error', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            groupState: const GroupState(
              status: GroupStatus.success,
              selectedGroup: null,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Go Back'), findsOneWidget);
      });
    });

    group('Group Header', () {
      testWidgets('should display group name', (tester) async {
        final group = createTestGroup(name: 'Trip to Paris');
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Trip to Paris'), findsOneWidget);
      });

      testWidgets('should display trip emoji for trip group', (tester) async {
        final group = createTestGroup(type: GroupType.trip);
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('✈️'), findsOneWidget);
      });

      testWidgets('should display home emoji for home group', (tester) async {
        final group = createTestGroup(type: GroupType.home);
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('🏠'), findsOneWidget);
      });
    });

    group('Balance Summary', () {
      testWidgets('should display Total stat', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Total'), findsOneWidget);
      });

      testWidgets('should display Expenses stat', (tester) async {
        final group = createTestGroup(expenseCount: 5);
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        // 'Expenses' appears in both stat section and tab bar
        expect(find.text('Expenses'), findsAtLeastNWidgets(1));
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('should display Members stat', (tester) async {
        final group = createTestGroup(memberCount: 4);
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        // 'Members' appears in both stat section and tab bar
        expect(find.text('Members'), findsAtLeastNWidgets(1));
        expect(find.text('4'), findsOneWidget);
      });
    });

    group('Tab Bar', () {
      testWidgets('should display Expenses tab', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Expenses'), findsWidgets);
      });

      testWidgets('should display Balances tab', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Balances'), findsOneWidget);
      });

      testWidgets('should display Members tab', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Members'), findsWidgets);
      });
    });

    group('FAB', () {
      testWidgets('should display Add Expense FAB', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Add Expense'), findsOneWidget);
      });

      testWidgets('should display add icon in FAB', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('AppBar Actions', () {
      testWidgets('should display settings icon', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('should display more options menu', (tester) async {
        final group = createTestGroup();
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });
    });

    group('Empty Expenses Tab', () {
      testWidgets('should show empty state when no expenses', (tester) async {
        final group = createTestGroup(expenseCount: 0);
        await tester.pumpWidget(
          createTestWidget(
            groupState: GroupState(
              status: GroupStatus.success,
              selectedGroup: group,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('No expenses yet'), findsOneWidget);
      });
    });

    group('Initialization', () {
      testWidgets('should load group on init', (tester) async {
        await tester.pumpWidget(createTestWidget(groupId: 'test-group'));
        await tester.pump();

        verify(
          () => mockGroupBloc.add(const GroupLoadByIdRequested('test-group')),
        ).called(1);
      });
    });
  });
}
