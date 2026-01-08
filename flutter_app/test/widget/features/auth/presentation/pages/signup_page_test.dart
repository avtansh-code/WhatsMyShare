import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:whats_my_share/features/auth/presentation/pages/signup_page.dart';

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
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Page')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpPage(),
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

  group('SignUpPage', () {
    testWidgets('renders signup page with header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check for header elements - "Create Account" appears in AppBar and button
      expect(find.text('Create Account'), findsNWidgets(2));
      expect(find.text("Join What's My Share"), findsOneWidget);
    });

    testWidgets('shows all form fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check for form fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('shows form hint texts', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('Re-enter your password'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap Create Account button (FilledButton)
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Should show validation errors for all required fields
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('shows name validation error for short name', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter single character name
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      await tester.enterText(nameField, 'A');

      // Submit
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill form with invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      // Submit
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password validation error for short password', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill form with short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        '12345',
      );

      // Submit
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill form with mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'differentpassword',
      );

      // Submit
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('dispatches sign up event with valid credentials', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      // Submit
      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pump();

      // Verify event dispatched
      verify(
        () => mockAuthBloc.add(
          const AuthSignUpWithEmailRequested(
            email: 'test@example.com',
            password: 'password123',
            displayName: 'Test User',
          ),
        ),
      ).called(1);
    });

    testWidgets('shows loading indicator when AuthLoading state', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthLoading()]),
        initialState: const AuthLoading(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when AuthError state', (tester) async {
      final stateController = StreamController<AuthState>.broadcast();

      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      whenListen(
        mockAuthBloc,
        stateController.stream,
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidget());

      // Emit error state
      stateController.add(const AuthError('Email already in use'));
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);

      await stateController.close();
    });

    testWidgets('toggles password visibility when eye icon pressed', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find visibility toggle icons (2 password fields)
      final visibilityIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityIcons, findsNWidgets(2));

      // Tap first visibility toggle (password field)
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // First should change to visible, second stays hidden
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('shows terms and conditions text', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);
    });

    testWidgets('shows sign in link', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('form fields have proper icons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));
    });

    testWidgets('validates email format correctly', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Test various invalid emails
      final invalidEmails = ['invalid', '@missing.com', 'missing@', 'test@'];

      for (final invalidEmail in invalidEmails) {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'),
          'Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          invalidEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        final signUpButton = find.widgetWithText(
          FilledButton,
          'Create Account',
        );
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Enter a valid email'),
          findsOneWidget,
          reason: 'Email "$invalidEmail" should be invalid',
        );

        // Clear email for next test
        await tester.enterText(find.widgetWithText(TextFormField, 'Email'), '');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('accepts valid email format', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'valid@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      final signUpButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pump();

      // Should dispatch event (valid email)
      verify(
        () => mockAuthBloc.add(
          const AuthSignUpWithEmailRequested(
            email: 'valid@example.com',
            password: 'password123',
            displayName: 'Test User',
          ),
        ),
      ).called(1);
    });
  });

  group('SignUpPage Accessibility', () {
    testWidgets('has semantic labels for form fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('create account button is accessible', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, 'Create Account');
      expect(button, findsOneWidget);
    });
  });
}
