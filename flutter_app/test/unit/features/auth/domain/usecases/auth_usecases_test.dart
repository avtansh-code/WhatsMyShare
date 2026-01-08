import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/features/auth/domain/entities/user_entity.dart';
import 'package:whats_my_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:whats_my_share/features/auth/domain/usecases/sign_out.dart';
import 'package:whats_my_share/features/auth/domain/usecases/get_current_user.dart';
import 'package:whats_my_share/features/auth/domain/usecases/reset_password.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  final testUser = UserEntity(
    id: 'user123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 9),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  group('SignInWithEmail', () {
    late SignInWithEmail useCase;

    setUp(() {
      useCase = SignInWithEmail(mockRepository);
    });

    test('returns UserEntity when sign in is successful', () async {
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final params = SignInParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final result = await useCase(params);

      expect(result, Right(testUser));
      verify(
        () => mockRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('returns AuthFailure when credentials are invalid', () async {
      final failure = AuthFailure.invalidCredentials();
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(failure));

      final params = SignInParams(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      final result = await useCase(params);

      expect(result, Left(failure));
    });

    test('returns NetworkFailure when there is no connection', () async {
      const failure = NetworkFailure();
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final params = SignInParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final result = await useCase(params);

      expect(result, const Left(failure));
    });

    group('SignInParams', () {
      test('SignInParams equality', () {
        const params1 = SignInParams(
          email: 'test@example.com',
          password: 'password123',
        );
        const params2 = SignInParams(
          email: 'test@example.com',
          password: 'password123',
        );
        const params3 = SignInParams(
          email: 'other@example.com',
          password: 'password123',
        );

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });

      test('SignInParams props', () {
        const params = SignInParams(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(params.props, ['test@example.com', 'password123']);
      });
    });
  });

  group('SignUpWithEmail', () {
    late SignUpWithEmail useCase;

    setUp(() {
      useCase = SignUpWithEmail(mockRepository);
    });

    test('returns UserEntity when sign up is successful', () async {
      when(
        () => mockRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final params = SignUpParams(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      final result = await useCase(params);

      expect(result, Right(testUser));
      verify(
        () => mockRepository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        ),
      ).called(1);
    });

    test('returns AuthFailure when email is already in use', () async {
      final failure = AuthFailure.emailAlreadyInUse();
      when(
        () => mockRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Left(failure));

      final params = SignUpParams(
        email: 'existing@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      final result = await useCase(params);

      expect(result, Left(failure));
    });

    test('returns AuthFailure when password is weak', () async {
      final failure = AuthFailure.weakPassword();
      when(
        () => mockRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Left(failure));

      final params = SignUpParams(
        email: 'test@example.com',
        password: '123',
        displayName: 'Test User',
      );

      final result = await useCase(params);

      expect(result, Left(failure));
    });

    group('SignUpParams', () {
      test('SignUpParams equality', () {
        const params1 = SignUpParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );
        const params2 = SignUpParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params1, equals(params2));
      });

      test('SignUpParams props', () {
        const params = SignUpParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params.props, ['test@example.com', 'password123', 'Test User']);
      });
    });
  });

  group('SignInWithGoogle', () {
    late SignInWithGoogle useCase;

    setUp(() {
      useCase = SignInWithGoogle(mockRepository);
    });

    test('returns UserEntity when Google sign in is successful', () async {
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase();

      expect(result, Right(testUser));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('returns AuthFailure when Google sign in fails', () async {
      const failure = AuthFailure(
        message: 'Google sign in was cancelled',
        code: 'CANCELLED',
      );
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });

    test('returns NetworkFailure when no internet connection', () async {
      const failure = NetworkFailure();
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });
  });

  group('SignOut', () {
    late SignOut useCase;

    setUp(() {
      useCase = SignOut(mockRepository);
    });

    test('returns success when sign out is successful', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result.isRight(), true);
      verify(() => mockRepository.signOut()).called(1);
    });

    test('returns failure when sign out fails', () async {
      const failure = ServerFailure(message: 'Sign out failed');
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      expect(result, const Left(failure));
    });
  });

  group('GetCurrentUser', () {
    late GetCurrentUser useCase;

    setUp(() {
      useCase = GetCurrentUser(mockRepository);
    });

    test('returns UserEntity when user is logged in', () async {
      when(
        () => mockRepository.getCurrentUser(),
      ).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('returns null when user is not logged in', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
    });
  });

  group('ResetPassword', () {
    late ResetPassword useCase;

    setUp(() {
      useCase = ResetPassword(mockRepository);
    });

    test('returns success when reset email is sent', () async {
      when(
        () => mockRepository.resetPassword(email: any(named: 'email')),
      ).thenAnswer((_) async => const Right(null));

      final params = ResetPasswordParams(email: 'test@example.com');

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(
        () => mockRepository.resetPassword(email: 'test@example.com'),
      ).called(1);
    });

    test('returns AuthFailure when user not found', () async {
      final failure = AuthFailure.userNotFound();
      when(
        () => mockRepository.resetPassword(email: any(named: 'email')),
      ).thenAnswer((_) async => Left(failure));

      final params = ResetPasswordParams(email: 'nonexistent@example.com');

      final result = await useCase(params);

      expect(result, Left(failure));
    });

    test('returns NetworkFailure when no internet connection', () async {
      const failure = NetworkFailure();
      when(
        () => mockRepository.resetPassword(email: any(named: 'email')),
      ).thenAnswer((_) async => const Left(failure));

      final params = ResetPasswordParams(email: 'test@example.com');

      final result = await useCase(params);

      expect(result, const Left(failure));
    });

    group('ResetPasswordParams', () {
      test('ResetPasswordParams equality', () {
        const params1 = ResetPasswordParams(email: 'test@example.com');
        const params2 = ResetPasswordParams(email: 'test@example.com');
        const params3 = ResetPasswordParams(email: 'other@example.com');

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });

      test('ResetPasswordParams props', () {
        const params = ResetPasswordParams(email: 'test@example.com');

        expect(params.props, ['test@example.com']);
      });
    });
  });
}
