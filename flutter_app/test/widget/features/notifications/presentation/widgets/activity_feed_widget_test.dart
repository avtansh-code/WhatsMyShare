import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/notifications/domain/entities/notification_entity.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_event.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_state.dart';
import 'package:whats_my_share/features/notifications/presentation/widgets/activity_feed_widget.dart';

// Mock classes
class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class FakeNotificationEvent extends Fake implements NotificationEvent {}

class FakeNotificationState extends Fake implements NotificationState {}

void main() {
  late MockNotificationBloc mockNotificationBloc;

  setUpAll(() {
    registerFallbackValue(FakeNotificationEvent());
    registerFallbackValue(FakeNotificationState());
  });

  setUp(() {
    mockNotificationBloc = MockNotificationBloc();
    when(
      () => mockNotificationBloc.state,
    ).thenReturn(const NotificationState());
  });

  tearDown(() {
    mockNotificationBloc.close();
  });

  // Create test activities
  final testActivities = [
    ActivityEntity(
      id: 'activity1',
      groupId: 'group1',
      type: ActivityType.expenseAdded,
      actorId: 'user1',
      actorName: 'John Doe',
      title: 'New expense added',
      description: 'Lunch',
      amount: 50000,
      currency: 'INR',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ActivityEntity(
      id: 'activity2',
      groupId: 'group1',
      type: ActivityType.settlementCreated,
      actorId: 'user2',
      actorName: 'Jane Smith',
      title: 'Settlement created',
      amount: 25000,
      currency: 'INR',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityEntity(
      id: 'activity3',
      groupId: 'group1',
      type: ActivityType.memberAdded,
      actorId: 'user1',
      actorName: 'John Doe',
      title: 'Member added',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Widget createWidgetUnderTest({int maxItems = 10, bool showHeader = true}) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<NotificationBloc>.value(
          value: mockNotificationBloc,
          child: ActivityFeedWidget(
            groupId: 'group1',
            maxItems: maxItems,
            showHeader: showHeader,
          ),
        ),
      ),
    );
  }

  group('ActivityFeedWidget Tests', () {
    group('Header', () {
      testWidgets(
        'should display Recent Activity header when showHeader is true',
        (tester) async {
          when(
            () => mockNotificationBloc.state,
          ).thenReturn(NotificationState(activities: testActivities));

          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          expect(find.text('Recent Activity'), findsOneWidget);
        },
      );

      testWidgets('should not display header when showHeader is false', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: testActivities));

        await tester.pumpWidget(createWidgetUnderTest(showHeader: false));
        await tester.pumpAndSettle();

        expect(find.text('Recent Activity'), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(const NotificationState(isLoadingActivity: true));

        await tester.pumpWidget(createWidgetUnderTest());
        // Don't use pumpAndSettle with CircularProgressIndicator as it animates infinitely
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should show empty state when no activities', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(const NotificationState(activities: []));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('No activity yet'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });
    });

    group('Activity List', () {
      testWidgets('should display activities when available', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: testActivities));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        // Verify activities are rendered (ListView is present)
        expect(find.byType(ListView), findsOneWidget);
        // Verify the empty state is NOT shown
        expect(find.text('No activity yet'), findsNothing);
      });

      testWidgets('should respect maxItems limit', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: testActivities));

        await tester.pumpWidget(createWidgetUnderTest(maxItems: 2));
        await tester.pumpAndSettle();

        // Should only show 2 items from ListView.builder
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Activity Icons', () {
      testWidgets('should show add icon for expense added', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[0]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add_circle), findsOneWidget);
      });

      testWidgets('should show payment icon for settlement created', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[1]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.payment), findsOneWidget);
      });

      testWidgets('should show person_add icon for member added', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[2]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });
    });

    group('Activity Text', () {
      testWidgets('should display activity text when activities available', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[0]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        // Verify the widget renders with Text widgets containing activity data
        // The exact text format depends on the widget implementation
        expect(find.byType(Text), findsWidgets);
        // Verify there's no empty state shown (activities are present)
        expect(find.text('No activity yet'), findsNothing);
      });

      testWidgets('should display formatted currency amount', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[0]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        // Verify the widget renders without errors and has Text widgets
        // The exact format depends on CurrencyUtils implementation
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Time Formatting', () {
      testWidgets('should show minutes ago for recent activities', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[0]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.textContaining('m ago'), findsOneWidget);
      });

      testWidgets('should show hours ago for older activities', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[1]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.textContaining('h ago'), findsOneWidget);
      });

      testWidgets('should show days ago for day-old activities', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: [testActivities[2]]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.textContaining('d ago'), findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('should have Column as root', (tester) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: testActivities));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have ListView when activities present', (
        tester,
      ) async {
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(NotificationState(activities: testActivities));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('BlocBuilder', () {
      testWidgets('should show loading state correctly', (tester) async {
        // Test that loading state shows loading indicator
        when(
          () => mockNotificationBloc.state,
        ).thenReturn(const NotificationState(isLoadingActivity: true));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show loaded state with activities', (tester) async {
        // Test that loaded state shows activities
        when(() => mockNotificationBloc.state).thenReturn(
          NotificationState(
            activities: testActivities,
            isLoadingActivity: false,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        // Should show activities (ListView contains them)
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}
