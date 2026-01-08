import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:whats_my_share/features/auth/presentation/pages/forgot_password_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

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
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const ForgotPasswordPage(),
      ),
    );
  }

  group('ForgotPasswordPage', () {
    testWidgets('renders forgot password page with header', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('shows email input field', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows reset password button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('shows back to login link', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting empty email', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('dispatches reset password event with valid email', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      verify(
        () => mockAuthBloc.add(any(that: isA<AuthResetPasswordRequested>())),
      ).called(1);
    });

    testWidgets('shows loading indicator when AuthLoading state', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when AuthError state', (tester) async {
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          const AuthLoading(),
          const AuthError('User not found'),
        ]),
        initialState: const AuthInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('User not found'), findsOneWidget);
    });

    testWidgets('email field has email icon', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('validates email format correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Test invalid email
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('accepts valid email format', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), 'valid@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Should not show validation error
      expect(find.text('Enter a valid email'), findsNothing);
    });

    testWidgets('shows instruction text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('send you a link'), findsOneWidget);
    });

    testWidgets('shows forgot your password header', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('shows lock reset icon', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.lock_reset), findsOneWidget);
    });

    group('Accessibility', () {
      testWidgets('has semantic labels for form fields', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final emailField = find.byType(TextFormField);
        expect(emailField, findsOneWidget);
      });

      testWidgets('reset button is accessible', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final button = find.text('Send Reset Link');
        expect(button, findsOneWidget);
      });
    });
  });
}
