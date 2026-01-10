import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/core/services/encryption_service.dart';
import 'package:whats_my_share/features/auth/domain/entities/user_entity.dart';
import 'package:whats_my_share/features/auth/domain/usecases/get_current_user.dart';
import 'package:whats_my_share/features/auth/domain/usecases/reset_password.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_out.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:whats_my_share/features/auth/presentation/bloc/auth_bloc.dart';

@GenerateMocks([
  SignInWithEmail,
  SignUpWithEmail,
  SignInWithGoogle,
  SignOut,
  GetCurrentUser,
  ResetPassword,
  EncryptionService,
])
import 'auth_bloc_test.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockSignInWithEmail mockSignInWithEmail;
  late MockSignUpWithEmail mockSignUpWithEmail;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignOut mockSignOut;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockResetPassword mockResetPassword;
  late MockEncryptionService mockEncryptionService;
  late StreamController<UserEntity?> authStateController;

  const tUser = UserEntity(
    id: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    mockSignUpWithEmail = MockSignUpWithEmail();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignOut = MockSignOut();
    mockGetCurrentUser = MockGetCurrentUser();
    mockResetPassword = MockResetPassword();
    mockEncryptionService = MockEncryptionService();
    authStateController = StreamController<UserEntity?>.broadcast();

    // Setup default auth state changes stream
    when(
      mockGetCurrentUser.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);

    // Setup encryption service mocks
    when(mockEncryptionService.isInitialized).thenReturn(false);
    when(mockEncryptionService.initialize(any)).thenAnswer((_) async {});
    when(mockEncryptionService.clearCache()).thenReturn(null);

    authBloc = AuthBloc(
      signInWithEmail: mockSignInWithEmail,
      signUpWithEmail: mockSignUpWithEmail,
      signInWithGoogle: mockSignInWithGoogle,
      signOut: mockSignOut,
      getCurrentUser: mockGetCurrentUser,
      resetPassword: mockResetPassword,
      encryptionService: mockEncryptionService,
    );
  });

  tearDown(() {
    authBloc.close();
    authStateController.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
        build: () {
          when(mockGetCurrentUser.call()).thenAnswer((_) async => tUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.user.id,
            'user.id',
            'test-uid',
          ),
        ],
        verify: (_) {
          verify(mockGetCurrentUser.call()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when user is not authenticated',
        build: () {
          when(mockGetCurrentUser.call()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
      );
    });

    group('AuthSignInWithEmailRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
        build: () {
          when(
            mockSignInWithEmail.call(any),
          ).thenAnswer((_) async => const Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignInWithEmailRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.user.email,
            'user.email',
            'test@example.com',
          ),
        ],
        verify: (_) {
          verify(
            mockSignInWithEmail.call(
              const SignInParams(
                email: 'test@example.com',
                password: 'password123',
              ),
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(
            mockSignInWithEmail.call(any),
          ).thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignInWithEmailRequested(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('AuthSignUpWithEmailRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign up succeeds',
        build: () {
          when(
            mockSignUpWithEmail.call(any),
          ).thenAnswer((_) async => const Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignUpWithEmailRequested(
            email: 'test@example.com',
            password: 'password123',
            displayName: 'Test User',
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
        verify: (_) {
          verify(mockSignUpWithEmail.call(any)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign up fails',
        build: () {
          when(
            mockSignUpWithEmail.call(any),
          ).thenAnswer((_) async => Left(AuthFailure.emailAlreadyInUse()));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignUpWithEmailRequested(
            email: 'existing@example.com',
            password: 'password123',
            displayName: 'Test User',
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('AuthSignInWithGoogleRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Google sign in succeeds',
        build: () {
          when(
            mockSignInWithGoogle.call(),
          ).thenAnswer((_) async => const Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
        verify: (_) {
          verify(mockSignInWithGoogle.call()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when Google sign in is cancelled',
        build: () {
          when(mockSignInWithGoogle.call()).thenAnswer(
            (_) async =>
                const Left(AuthFailure(message: 'Sign in cancelled by user')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when Google sign in fails',
        build: () {
          when(mockSignInWithGoogle.call()).thenAnswer(
            (_) async =>
                const Left(AuthFailure(message: 'Google sign in failed')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when sign out succeeds',
        build: () {
          when(mockSignOut.call()).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
        verify: (_) {
          verify(mockSignOut.call()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign out fails',
        build: () {
          when(mockSignOut.call()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Sign out failed')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('AuthResetPasswordRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordResetSent] when reset password succeeds',
        build: () {
          when(
            mockResetPassword.call(any),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthResetPasswordRequested(email: 'test@example.com'),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthPasswordResetSent>().having(
            (s) => s.email,
            'email',
            'test@example.com',
          ),
        ],
        verify: (_) {
          verify(mockResetPassword.call(any)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when reset password fails',
        build: () {
          when(
            mockResetPassword.call(any),
          ).thenAnswer((_) async => Left(AuthFailure.userNotFound()));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthResetPasswordRequested(email: 'nonexistent@example.com'),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('AuthUserChanged', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when user becomes authenticated',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthUserChanged(tUser)),
        expect: () => [
          isA<AuthAuthenticated>().having(
            (s) => s.user.id,
            'user.id',
            'test-uid',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when user becomes null',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthUserChanged(null)),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });
  });

  group('AuthState', () {
    test('AuthInitial props are empty', () {
      const state = AuthInitial();
      expect(state.props, isEmpty);
    });

    test('AuthLoading props are empty', () {
      const state = AuthLoading();
      expect(state.props, isEmpty);
    });

    test('AuthAuthenticated props contain user', () {
      const state = AuthAuthenticated(tUser);
      expect(state.props, [tUser]);
      expect(state.user, tUser);
    });

    test('AuthUnauthenticated props are empty', () {
      const state = AuthUnauthenticated();
      expect(state.props, isEmpty);
    });

    test('AuthError props contain message', () {
      const state = AuthError('Test error');
      expect(state.props, ['Test error']);
      expect(state.message, 'Test error');
    });

    test('AuthPasswordResetSent props contain email', () {
      const state = AuthPasswordResetSent('test@example.com');
      expect(state.props, ['test@example.com']);
      expect(state.email, 'test@example.com');
    });
  });

  group('AuthEvent', () {
    test('AuthCheckRequested props are empty', () {
      const event = AuthCheckRequested();
      expect(event.props, isEmpty);
    });

    test('AuthSignInWithEmailRequested props contain email and password', () {
      const event = AuthSignInWithEmailRequested(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(event.props, ['test@example.com', 'password123']);
    });

    test(
      'AuthSignUpWithEmailRequested props contain email, password, and displayName',
      () {
        const event = AuthSignUpWithEmailRequested(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );
        expect(event.props, ['test@example.com', 'password123', 'Test User']);
      },
    );

    test('AuthSignInWithGoogleRequested props are empty', () {
      const event = AuthSignInWithGoogleRequested();
      expect(event.props, isEmpty);
    });

    test('AuthSignOutRequested props are empty', () {
      const event = AuthSignOutRequested();
      expect(event.props, isEmpty);
    });

    test('AuthResetPasswordRequested props contain email', () {
      const event = AuthResetPasswordRequested(email: 'test@example.com');
      expect(event.props, ['test@example.com']);
    });

    test('AuthUserChanged props contain user', () {
      const event = AuthUserChanged(tUser);
      expect(event.props, [tUser]);
    });

    test('AuthUserChanged props can contain null', () {
      const event = AuthUserChanged(null);
      expect(event.props, [null]);
    });
  });
}
