import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/auth/domain/entities/user_entity.dart';
import 'package:whats_my_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:whats_my_share/features/dashboard/presentation/pages/dashboard_page.dart';

// Mock classes
class MockAuthBloc extends Mock implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream<AuthState>.empty());
  });

  Widget createTestWidget({AuthState? authState}) {
    when(() => mockAuthBloc.state).thenReturn(authState ?? const AuthInitial());

    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const DashboardPage(),
      ),
    );
  }

  UserEntity createTestUser() {
    return UserEntity(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('DashboardPage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display app title', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text("What's My Share"), findsOneWidget);
      });

      testWidgets('should display notifications icon', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      });

      testWidgets('should display user avatar', (tester) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        // Find the CircleAvatar in the AppBar
        final avatars = tester.widgetList<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(avatars.isNotEmpty, isTrue);
      });

      testWidgets('should show popup menu when avatar is tapped', (
        tester,
      ) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        // Find and tap the popup menu button
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
      });
    });

    group('Welcome Card', () {
      testWidgets('should display welcome message', (tester) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        expect(find.text('Welcome back,'), findsOneWidget);
      });

      testWidgets('should display user name', (tester) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('should display user initials in avatar', (tester) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        // The initials should be displayed
        expect(find.text('TU'), findsWidgets);
      });
    });

    group('Balance Summary', () {
      testWidgets('should display balance summary card', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your Balance'), findsOneWidget);
      });

      testWidgets('should display "You are owed" section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('You are owed'), findsOneWidget);
      });

      testWidgets('should display "You owe" section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('You owe'), findsOneWidget);
      });

      testWidgets('should display zero balances initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹0.00'), findsNWidgets(2));
      });
    });

    group('Quick Actions', () {
      testWidgets('should display quick actions section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Quick Actions'), findsOneWidget);
      });

      testWidgets('should display New Group action', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('New Group'), findsOneWidget);
        expect(find.byIcon(Icons.group_add), findsOneWidget);
      });

      testWidgets('should display Add Friend action', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Add Friend'), findsOneWidget);
        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('should display Settle Up action', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Settle Up'), findsOneWidget);
        expect(find.byIcon(Icons.payments), findsOneWidget);
      });
    });

    group('Recent Activity', () {
      testWidgets('should display recent activity section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Recent Activity'), findsOneWidget);
      });

      testWidgets('should display View All button', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final viewAllButtons = find.text('View All');
        expect(viewAllButtons, findsWidgets);
      });

      testWidgets('should display empty state message', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('No recent activity'), findsOneWidget);
        expect(find.text('Add an expense to get started'), findsOneWidget);
      });
    });

    group('Groups Section', () {
      testWidgets('should display groups section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your Groups'), findsOneWidget);
      });

      testWidgets('should display empty groups message', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('No groups yet'), findsOneWidget);
      });

      testWidgets('should display Create Group button', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Create Group'), findsOneWidget);
      });
    });

    group('Floating Action Button', () {
      testWidgets('should display Add Expense FAB', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Add Expense'), findsOneWidget);
        // Multiple add icons can exist in the UI
        expect(find.byIcon(Icons.add), findsWidgets);
      });

      testWidgets('should show bottom sheet when FAB is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Add Expense'), findsNWidgets(2)); // FAB + sheet item
        expect(find.text('Split a bill with your group'), findsOneWidget);
        expect(find.text('Create Group'), findsNWidgets(2));
        expect(find.text('Start a new expense group'), findsOneWidget);
        expect(find.text('Record a payment'), findsOneWidget);
      });
    });

    group('Bottom Navigation Bar', () {
      testWidgets('should display navigation bar', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('should display Home destination', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Home'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('should display Groups destination', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Groups'), findsOneWidget);
        // Multiple group icons can exist in the UI (navigation bar + page content)
        expect(find.byIcon(Icons.group_outlined), findsWidgets);
      });

      testWidgets('should display Friends destination', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Friends'), findsOneWidget);
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });

      testWidgets('should display Activity destination', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Activity'), findsOneWidget);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget,
        );
      });
    });

    group('Popup Menu Actions', () {
      testWidgets('should trigger sign out when Sign Out is tapped', (
        tester,
      ) async {
        final user = createTestUser();
        await tester.pumpWidget(
          createTestWidget(authState: AuthAuthenticated(user)),
        );

        // Open popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap Sign Out
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        verify(() => mockAuthBloc.add(const AuthSignOutRequested())).called(1);
      });
    });

    group('RefreshIndicator', () {
      testWidgets('should have RefreshIndicator', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Unauthenticated State', () {
      testWidgets('should display placeholder when no user', (tester) async {
        await tester.pumpWidget(
          createTestWidget(authState: const AuthInitial()),
        );

        // Should show ? for unknown user
        expect(find.text('?'), findsWidgets);
      });
    });
  });

  group('DashboardPage with Different User Data', () {
    testWidgets('should display user initial when no display name', (
      tester,
    ) async {
      final userWithoutName = UserEntity(
        id: 'test-user-id',
        email: 'user@example.com',
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        createTestWidget(authState: AuthAuthenticated(userWithoutName)),
      );

      // When no display name, the page shows user initial (first letter of email)
      // Check for the 'U' initial which comes from 'user@example.com'
      expect(find.text('U'), findsWidgets);
    });
  });
}
