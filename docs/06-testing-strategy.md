# Testing Strategy

## Overview
This document outlines the comprehensive testing approach for "What's My Share" application, covering unit tests, widget tests, integration tests, and quality assurance processes.

---

## 1. Testing Pyramid

```
                    ┌───────────────┐
                    │    E2E /      │
                    │  Manual QA    │  ← 10%
                    │    Tests      │
                    └───────┬───────┘
                    ┌───────┴───────┐
                    │  Integration  │
                    │    Tests      │  ← 20%
                    └───────┬───────┘
            ┌───────────────┴───────────────┐
            │        Widget Tests           │  ← 30%
            │    (Component Testing)        │
            └───────────────┬───────────────┘
    ┌───────────────────────┴───────────────────────┐
    │              Unit Tests                        │  ← 40%
    │     (Business Logic, Services, Utils)          │
    └────────────────────────────────────────────────┘
```

---

## 2. Testing Goals

| Metric | Target | Minimum |
|--------|--------|---------|
| Code Coverage | 85% | 80% |
| Unit Test Pass Rate | 100% | 100% |
| Widget Test Pass Rate | 100% | 100% |
| Integration Test Pass Rate | 100% | 95% |
| Performance Test Pass | All | Critical paths |

---

## 3. Unit Testing

### 3.1 Testing Framework Setup

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  bloc_test: ^9.1.0
  fake_cloud_firestore: ^2.4.0
  firebase_auth_mocks: ^0.12.0
```

### 3.2 Test Directory Structure

```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl_test.dart
│   │   │   └── domain/
│   │   │       └── usecases/
│   │   │           ├── sign_in_with_email_test.dart
│   │   │           └── sign_up_with_email_test.dart
│   │   ├── groups/
│   │   │   ├── data/
│   │   │   └── domain/
│   │   ├── expenses/
│   │   │   ├── data/
│   │   │   └── domain/
│   │   │       └── services/
│   │   │           └── split_calculator_test.dart
│   │   └── settlements/
│   │       └── domain/
│   │           └── services/
│   │               └── debt_simplifier_test.dart
│   └── core/
│       └── utils/
│           ├── currency_formatter_test.dart
│           └── decimal_utils_test.dart
├── widget/
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── login_page_test.dart
│   │   └── expenses/
│   │       └── presentation/
│   │           └── widgets/
│   │               └── split_selector_test.dart
│   └── shared/
│       └── widgets/
│           └── amount_input_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   ├── expense_flow_test.dart
│   └── settlement_flow_test.dart
└── mocks/
    ├── mock_repositories.dart
    └── mock_services.dart
```

### 3.3 Unit Test Examples

#### Split Calculator Tests
```dart
// test/unit/features/expenses/domain/services/split_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsmyshare/features/expenses/domain/services/split_calculator.dart';

void main() {
  group('SplitCalculator', () {
    group('calculateEqual', () {
      test('should split evenly when amount is divisible', () {
        // Arrange
        const totalAmount = 30000; // ₹300.00
        final participants = [
          GroupMember(userId: 'u1', displayName: 'Alice'),
          GroupMember(userId: 'u2', displayName: 'Bob'),
          GroupMember(userId: 'u3', displayName: 'Charlie'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result.length, 3);
        expect(result[0].amount, 10000);
        expect(result[1].amount, 10000);
        expect(result[2].amount, 10000);
        expect(result.map((s) => s.amount).reduce((a, b) => a + b), totalAmount);
      });

      test('should distribute remainder to first participants', () {
        // Arrange
        const totalAmount = 10000; // ₹100.00
        final participants = [
          GroupMember(userId: 'u1', displayName: 'Alice'),
          GroupMember(userId: 'u2', displayName: 'Bob'),
          GroupMember(userId: 'u3', displayName: 'Charlie'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result[0].amount, 3334); // ₹33.34
        expect(result[1].amount, 3333); // ₹33.33
        expect(result[2].amount, 3333); // ₹33.33
        expect(result.map((s) => s.amount).reduce((a, b) => a + b), totalAmount);
      });

      test('should handle single participant', () {
        // Arrange
        const totalAmount = 10000;
        final participants = [
          GroupMember(userId: 'u1', displayName: 'Alice'),
        ];

        // Act
        final result = SplitCalculator.calculateEqual(
          totalAmount,
          participants,
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].amount, totalAmount);
      });
    });

    group('calculatePercentage', () {
      test('should split by percentage correctly', () {
        // Arrange
        const totalAmount = 10000; // ₹100.00
        final percentages = {
          'u1': 50.0,
          'u2': 30.0,
          'u3': 20.0,
        };
        final displayNames = {
          'u1': 'Alice',
          'u2': 'Bob',
          'u3': 'Charlie',
        };

        // Act
        final result = SplitCalculator.calculatePercentage(
          totalAmount,
          percentages,
          displayNames,
        );

        // Assert
        expect(result.firstWhere((s) => s.userId == 'u1').amount, 5000);
        expect(result.firstWhere((s) => s.userId == 'u2').amount, 3000);
        expect(result.firstWhere((s) => s.userId == 'u3').amount, 2000);
        expect(result.map((s) => s.amount).reduce((a, b) => a + b), totalAmount);
      });

      test('should handle rounding and assign remainder to last person', () {
        // Arrange
        const totalAmount = 1000; // ₹10.00
        final percentages = {
          'u1': 33.33,
          'u2': 33.33,
          'u3': 33.34,
        };
        final displayNames = {
          'u1': 'Alice',
          'u2': 'Bob',
          'u3': 'Charlie',
        };

        // Act
        final result = SplitCalculator.calculatePercentage(
          totalAmount,
          percentages,
          displayNames,
        );

        // Assert
        final total = result.map((s) => s.amount).reduce((a, b) => a + b);
        expect(total, totalAmount); // Must equal exactly
      });
    });

    group('calculateShares', () {
      test('should split by shares/ratio correctly', () {
        // Arrange
        const totalAmount = 12000; // ₹120.00
        final shares = {
          'u1': 2, // 2 shares
          'u2': 1, // 1 share
        };
        final displayNames = {
          'u1': 'Alice',
          'u2': 'Bob',
        };

        // Act
        final result = SplitCalculator.calculateShares(
          totalAmount,
          shares,
          displayNames,
        );

        // Assert
        expect(result.firstWhere((s) => s.userId == 'u1').amount, 8000);
        expect(result.firstWhere((s) => s.userId == 'u2').amount, 4000);
      });
    });
  });
}
```

#### Debt Simplifier Tests
```dart
// test/unit/features/settlements/domain/services/debt_simplifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsmyshare/features/settlements/domain/services/debt_simplifier.dart';

void main() {
  group('DebtSimplifier', () {
    test('should simplify simple debt chain', () {
      // A owes ₹100, B is owed ₹100
      final balances = {
        'A': -10000, // A owes ₹100
        'B': 10000,  // B is owed ₹100
      };

      final result = DebtSimplifier.simplify(balances);

      expect(result.length, 1);
      expect(result[0].from, 'A');
      expect(result[0].to, 'B');
      expect(result[0].amount, 10000);
    });

    test('should minimize transactions for multiple debts', () {
      // A owes ₹100, B owes ₹50, C is owed ₹150
      final balances = {
        'A': -10000, // A owes ₹100
        'B': -5000,  // B owes ₹50
        'C': 15000,  // C is owed ₹150
      };

      final result = DebtSimplifier.simplify(balances);

      // Should result in 2 transactions: A→C and B→C
      expect(result.length, 2);
      
      final totalSettled = result.map((s) => s.amount).reduce((a, b) => a + b);
      expect(totalSettled, 15000); // Total amount settled
    });

    test('should handle complex debt graph', () {
      // A is owed ₹500, B owes ₹300, C owes ₹200
      final balances = {
        'A': 50000,  // A is owed ₹500
        'B': -30000, // B owes ₹300
        'C': -20000, // C owes ₹200
      };

      final result = DebtSimplifier.simplify(balances);

      // Verify all debts are settled
      expect(result.length, 2);
      expect(
        result.every((s) => s.to == 'A'),
        true,
        reason: 'All payments should go to A',
      );
    });

    test('should return empty list when everyone is settled', () {
      final balances = {
        'A': 0,
        'B': 0,
        'C': 0,
      };

      final result = DebtSimplifier.simplify(balances);

      expect(result, isEmpty);
    });

    test('should handle single debtor and multiple creditors', () {
      // A owes ₹300, B is owed ₹100, C is owed ₹200
      final balances = {
        'A': -30000,
        'B': 10000,
        'C': 20000,
      };

      final result = DebtSimplifier.simplify(balances);

      expect(result.length, 2);
      expect(result.every((s) => s.from == 'A'), true);
    });
  });
}
```

#### BLoC Tests
```dart
// test/unit/features/auth/presentation/bloc/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([SignInWithEmail, SignUpWithEmail, SignInWithGoogle, SignOut])
import 'auth_bloc_test.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockSignInWithEmail mockSignInWithEmail;
  late MockSignUpWithEmail mockSignUpWithEmail;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignOut mockSignOut;

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    mockSignUpWithEmail = MockSignUpWithEmail();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignOut = MockSignOut();
    
    authBloc = AuthBloc(
      signInWithEmail: mockSignInWithEmail,
      signUpWithEmail: mockSignUpWithEmail,
      signInWithGoogle: mockSignInWithGoogle,
      signOut: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final tUser = UserEntity(
      id: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
      build: () {
        when(mockSignInWithEmail(any))
            .thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(tUser),
      ],
      verify: (_) {
        verify(mockSignInWithEmail(const SignInParams(
          email: 'test@example.com',
          password: 'password123',
        ))).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when sign in fails',
      build: () {
        when(mockSignInWithEmail(any))
            .thenAnswer((_) async => const Left(AuthFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when sign out succeeds',
      build: () {
        when(mockSignOut(any))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        AuthLoading(),
        AuthUnauthenticated(),
      ],
    );
  });
}
```

---

## 4. Widget Testing

### 4.1 Widget Test Examples

```dart
// test/widget/features/auth/presentation/pages/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('should display email and password fields', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('should show loading indicator when state is AuthLoading', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should trigger sign in when valid credentials entered', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
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

      // Assert
      verify(mockAuthBloc.add(const AuthSignInRequested(
        email: 'test@example.com',
        password: 'password123',
      ))).called(1);
    });

    testWidgets('should navigate to signup when link tapped', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Assert - Navigation occurred
      expect(find.byType(SignUpPage), findsOneWidget);
    });
  });
}
```

#### Amount Input Widget Test
```dart
// test/widget/shared/widgets/amount_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountInput', () {
    testWidgets('should format input as currency', (tester) async {
      int? capturedValue;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AmountInput(
            currency: 'INR',
            onChanged: (value) => capturedValue = value,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), '1000');
      await tester.pump();

      expect(capturedValue, 100000); // 1000 rupees = 100000 paisa
      expect(find.text('₹1,000.00'), findsOneWidget);
    });

    testWidgets('should show error for negative amounts', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AmountInput(
            currency: 'INR',
            onChanged: (_) {},
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), '-100');
      await tester.pump();

      expect(find.text('Amount must be positive'), findsOneWidget);
    });

    testWidgets('should respect maximum amount limit', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AmountInput(
            currency: 'INR',
            maxAmount: 10000000, // ₹1,00,000
            onChanged: (_) {},
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), '200000');
      await tester.pump();

      expect(find.text('Amount exceeds limit'), findsOneWidget);
    });
  });
}
```

---

## 5. Integration Testing

### 5.1 Integration Test Setup

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsmyshare/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete expense creation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to a group
      await tester.tap(find.text('Test Group'));
      await tester.pumpAndSettle();

      // Add expense
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill expense form
      await tester.enterText(
        find.byKey(const Key('amountField')),
        '500',
      );
      await tester.enterText(
        find.byKey(const Key('descriptionField')),
        'Test Expense',
      );
      
      // Select equal split
      await tester.tap(find.text('Equal'));
      await tester.pumpAndSettle();

      // Save expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify expense appears in list
      expect(find.text('Test Expense'), findsOneWidget);
      expect(find.text('₹500.00'), findsOneWidget);
    });

    testWidgets('settlement flow with biometric', (tester) async {
      // Test settlement flow
      // Note: Biometric testing requires mock setup
    });
  });
}
```

### 5.2 Firebase Emulator Integration Tests

```dart
// integration_test/firebase_integration_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    // Connect to Firebase emulators
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  });

  group('Firestore Integration', () {
    test('should create and read expense', () async {
      // Create test user
      final auth = FirebaseAuth.instance;
      await auth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Create expense
      final firestore = FirebaseFirestore.instance;
      final expenseRef = await firestore
          .collection('groups')
          .doc('test-group')
          .collection('expenses')
          .add({
        'description': 'Test Expense',
        'amount': 50000,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Read expense
      final expense = await expenseRef.get();
      expect(expense.data()?['description'], 'Test Expense');
      expect(expense.data()?['amount'], 50000);
    });
  });
}
```

---

## 6. Performance Testing

### 6.1 Performance Benchmarks

| Operation | Target | Maximum |
|-----------|--------|---------|
| App cold start | < 2s | 3s |
| Dashboard load | < 1s | 2s |
| Add expense | < 500ms | 1s |
| List scroll (60fps) | 16.67ms/frame | 32ms/frame |
| Image upload | < 3s | 5s |

### 6.2 Performance Test Implementation

```dart
// test/performance/app_performance_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Tests', () {
    testWidgets('dashboard should render within threshold', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const DashboardPage());
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Dashboard should load within 2 seconds',
      );
    });

    testWidgets('expense list should scroll smoothly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ExpenseListPage(expenses: generateLargeExpenseList(100)),
      ));
      await tester.pumpAndSettle();

      // Measure scroll performance
      final binding = tester.binding;
      await binding.traceAction(() async {
        await tester.fling(
          find.byType(ListView),
          const Offset(0, -500),
          1000,
        );
        await tester.pumpAndSettle();
      }, reportKey: 'expense_list_scroll');
    });
  });
}
```

---

## 7. Security Testing

### 7.1 Security Test Checklist

| Test | Description | Priority |
|------|-------------|----------|
| Auth token validation | Verify JWT tokens are properly validated | P0 |
| SQL injection | Test Firestore query sanitization | P0 |
| XSS prevention | Test input sanitization | P0 |
| Biometric bypass | Verify biometric can't be bypassed | P0 |
| Data encryption | Verify sensitive data is encrypted | P0 |
| API rate limiting | Test rate limit enforcement | P1 |
| Session management | Test session timeout/refresh | P1 |
| Deep link injection | Test deep link validation | P1 |

### 7.2 Security Tests

```dart
// test/security/auth_security_test.dart
void main() {
  group('Auth Security', () {
    test('should reject expired tokens', () async {
      final expiredToken = generateExpiredToken();
      
      expect(
        () => authService.validateToken(expiredToken),
        throwsA(isA<TokenExpiredException>()),
      );
    });

    test('should reject tampered tokens', () async {
      final tamperedToken = validToken.replaceRange(10, 20, 'tampered');
      
      expect(
        () => authService.validateToken(tamperedToken),
        throwsA(isA<InvalidTokenException>()),
      );
    });

    test('should sanitize user input', () async {
      final maliciousInput = '<script>alert("xss")</script>';
      
      final sanitized = inputSanitizer.sanitize(maliciousInput);
      
      expect(sanitized, isNot(contains('<script>')));
    });
  });
}
```

---

## 8. Accessibility Testing

### 8.1 Accessibility Requirements

- Screen reader support (TalkBack/VoiceOver)
- Minimum touch target size: 48x48dp
- Color contrast ratio: 4.5:1 (AA) minimum
- Text scaling support up to 200%
- Focus management for keyboard navigation

### 8.2 Accessibility Tests

```dart
// test/accessibility/accessibility_test.dart
void main() {
  group('Accessibility', () {
    testWidgets('all buttons should have semantic labels', (tester) async {
      await tester.pumpWidget(const MyApp());
      
      final semantics = tester.getSemantics(find.byType(ElevatedButton).first);
      
      expect(semantics.label, isNotEmpty);
    });

    testWidgets('text should be readable at 200% scale', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaleFactor: 2.0),
        child: const MyApp(),
      ));
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch targets should meet minimum size', (tester) async {
      await tester.pumpWidget(const MyApp());
      
      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      
      for (final button in buttons) {
        final size = tester.getSize(find.byWidget(button));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });
}
```

---

## 9. Test Automation & CI/CD

### 9.1 GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run unit tests
        run: flutter test --coverage
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep 'lines' | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  integration-test:
    runs-on: macos-latest
    needs: test
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
      
      - name: Start Firebase Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore,auth &
          sleep 10
      
      - name: Run integration tests
        run: flutter test integration_test
```

### 9.2 Test Coverage Report

```bash
# Generate coverage report
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

---

## 10. Quality Gates

### 10.1 PR Merge Requirements

| Check | Requirement |
|-------|-------------|
| Unit tests | 100% pass |
| Widget tests | 100% pass |
| Code coverage | ≥ 80% |
| Lint errors | 0 |
| Security scan | Pass |

### 10.2 Release Requirements

| Check | Requirement |
|-------|-------------|
| All tests pass | Yes |
| Integration tests | Pass |
| Performance tests | Within thresholds |
| Security audit | Pass |
| Accessibility audit | Pass |
| Manual QA | Sign-off |

---

## Next Steps
Proceed to [07-deployment-guide.md](./07-deployment-guide.md) for deployment instructions.