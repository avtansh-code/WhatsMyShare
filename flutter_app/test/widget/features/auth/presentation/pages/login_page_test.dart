import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:whats_my_share/features/auth/presentation/pages/login_page.dart';

// Mock classes using mocktail
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late GoRouter router;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) =>
              const Scaffold(body: Text('Sign Up Page')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Text('Forgot Password')),
        ),
      ],
    );
  });

  Widget createWidget({Size size = const Size(800, 1200)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('renders login page with all elements', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert - Header elements
      expect(find.text("What's My Share"), findsOneWidget);
      expect(find.text('Split expenses with friends easily'), findsOneWidget);

      // Assert - Form elements
      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Assert - Other elements
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Or continue with'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - Tap sign in without filling form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Assert - Validation errors appear
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid email', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - Enter invalid email and submit
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password validation error for short password', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - Enter short password
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(find.byKey(const Key('passwordField')), '12345');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('dispatches sign in event with valid credentials', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - Fill form with valid data
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert - Event dispatched
      verify(
        () => mockAuthBloc.add(
          const AuthSignInWithEmailRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    });

    testWidgets('toggles password visibility when eye icon pressed', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Find the visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityIcon, findsOneWidget);

      // Act - Tap visibility toggle
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Assert - Icon changes to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('shows loading indicator when AuthLoading state', (
      tester,
    ) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthLoading()]),
        initialState: const AuthLoading(),
      );

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when AuthError state', (tester) async {
      // Arrange
      final stateController = StreamController<AuthState>.broadcast();

      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      whenListen(
        mockAuthBloc,
        stateController.stream,
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidget());

      // Act - Emit error state
      stateController.add(const AuthError('Invalid credentials'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);

      await stateController.close();
    });

    testWidgets('shows app logo with correct icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('form has email and password labels', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());

      // Assert - Labels are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('form fields have hint text', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('form fields have proper icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('validates email format correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Test various invalid emails
      final invalidEmails = [
        'invalid',
        '@missing.com',
        'missing@.com',
        'missing.com',
        'test@',
      ];

      for (final invalidEmail in invalidEmails) {
        await tester.enterText(
          find.byKey(const Key('emailField')),
          invalidEmail,
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          'password123',
        );
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(
          find.text('Enter a valid email'),
          findsOneWidget,
          reason: 'Email "$invalidEmail" should be invalid',
        );

        // Clear for next test
        await tester.enterText(find.byKey(const Key('emailField')), '');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('accepts valid email format', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Valid email
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'valid@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should dispatch event (valid email)
      verify(
        () => mockAuthBloc.add(
          const AuthSignInWithEmailRequested(
            email: 'valid@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    });

    testWidgets('password minimum length is 6 characters', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Test passwords of various lengths
      final shortPasswords = ['1', '12', '123', '1234', '12345'];

      for (final shortPassword in shortPasswords) {
        await tester.enterText(
          find.byKey(const Key('emailField')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          shortPassword,
        );
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
          reason: 'Password "$shortPassword" should be too short',
        );

        // Clear for next test
        await tester.enterText(find.byKey(const Key('passwordField')), '');
        await tester.pumpAndSettle();
      }

      // Test minimum valid length
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        '123456',
      ); // 6 chars
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should dispatch event (valid password)
      verify(
        () => mockAuthBloc.add(
          const AuthSignInWithEmailRequested(
            email: 'test@example.com',
            password: '123456',
          ),
        ),
      ).called(1);
    });
  });

  group('LoginPage Accessibility', () {
    testWidgets('has semantic labels for form fields', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Assert - Labels are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('sign in button is accessible', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('Sign In'), findsOneWidget);
      final button = find.widgetWithText(FilledButton, 'Sign In');
      expect(button, findsOneWidget);
    });
  });
}
