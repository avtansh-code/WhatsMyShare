import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/errors/failures.dart';

void main() {
  group('Failure', () {
    group('ServerFailure', () {
      test('creates ServerFailure with all fields', () {
        const failure = ServerFailure(
          message: 'Server error',
          code: 'SERVER_ERROR',
          statusCode: 500,
        );

        expect(failure.message, 'Server error');
        expect(failure.code, 'SERVER_ERROR');
        expect(failure.statusCode, 500);
      });

      test('creates ServerFailure with minimal fields', () {
        const failure = ServerFailure(message: 'Error');

        expect(failure.message, 'Error');
        expect(failure.code, isNull);
        expect(failure.statusCode, isNull);
      });

      test('ServerFailure is a Failure', () {
        const failure = ServerFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });

      test('equal ServerFailures have same props', () {
        const failure1 = ServerFailure(
          message: 'Error',
          code: 'ERR',
          statusCode: 500,
        );
        const failure2 = ServerFailure(
          message: 'Error',
          code: 'ERR',
          statusCode: 500,
        );

        expect(failure1, equals(failure2));
      });

      test('different ServerFailures are not equal', () {
        const failure1 = ServerFailure(message: 'Error 1', statusCode: 500);
        const failure2 = ServerFailure(message: 'Error 2', statusCode: 404);

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('NetworkFailure', () {
      test('creates NetworkFailure with default message', () {
        const failure = NetworkFailure();

        expect(
          failure.message,
          'No internet connection. Please check your network.',
        );
        expect(failure.code, 'NETWORK_ERROR');
      });

      test('creates NetworkFailure with custom message', () {
        const failure = NetworkFailure(message: 'Custom network error');

        expect(failure.message, 'Custom network error');
      });

      test('NetworkFailure is a Failure', () {
        const failure = NetworkFailure();
        expect(failure, isA<Failure>());
      });
    });

    group('CacheFailure', () {
      test('creates CacheFailure with required message', () {
        const failure = CacheFailure(message: 'Cache read failed');

        expect(failure.message, 'Cache read failed');
        expect(failure.code, 'CACHE_ERROR');
      });

      test('creates CacheFailure with custom code', () {
        const failure = CacheFailure(
          message: 'Cache error',
          code: 'CUSTOM_CACHE_ERROR',
        );

        expect(failure.code, 'CUSTOM_CACHE_ERROR');
      });

      test('CacheFailure is a Failure', () {
        const failure = CacheFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('AuthFailure', () {
      test('creates AuthFailure with message and code', () {
        const failure = AuthFailure(message: 'Auth error', code: 'AUTH_ERROR');

        expect(failure.message, 'Auth error');
        expect(failure.code, 'AUTH_ERROR');
      });

      test('invalidCredentials factory creates correct failure', () {
        final failure = AuthFailure.invalidCredentials();

        expect(failure.message, 'Invalid email or password');
        expect(failure.code, 'INVALID_CREDENTIALS');
      });

      test('userNotFound factory creates correct failure', () {
        final failure = AuthFailure.userNotFound();

        expect(failure.message, 'User not found');
        expect(failure.code, 'USER_NOT_FOUND');
      });

      test('emailAlreadyInUse factory creates correct failure', () {
        final failure = AuthFailure.emailAlreadyInUse();

        expect(failure.message, 'Email is already registered');
        expect(failure.code, 'EMAIL_ALREADY_IN_USE');
      });

      test('weakPassword factory creates correct failure', () {
        final failure = AuthFailure.weakPassword();

        expect(
          failure.message,
          'Password is too weak. Use at least 8 characters.',
        );
        expect(failure.code, 'WEAK_PASSWORD');
      });

      test('sessionExpired factory creates correct failure', () {
        final failure = AuthFailure.sessionExpired();

        expect(failure.message, 'Session expired. Please login again.');
        expect(failure.code, 'SESSION_EXPIRED');
      });

      test('unauthorized factory creates correct failure', () {
        final failure = AuthFailure.unauthorized();

        expect(
          failure.message,
          'You are not authorized to perform this action',
        );
        expect(failure.code, 'UNAUTHORIZED');
      });

      test('AuthFailure is a Failure', () {
        const failure = AuthFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('DatabaseFailure', () {
      test('creates DatabaseFailure with message and code', () {
        const failure = DatabaseFailure(
          message: 'Database error',
          code: 'DB_ERROR',
        );

        expect(failure.message, 'Database error');
        expect(failure.code, 'DB_ERROR');
      });

      test('notFound factory creates correct failure', () {
        final failure = DatabaseFailure.notFound('Document');

        expect(failure.message, 'Document not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('permissionDenied factory creates correct failure', () {
        final failure = DatabaseFailure.permissionDenied();

        expect(
          failure.message,
          'You do not have permission to access this data',
        );
        expect(failure.code, 'PERMISSION_DENIED');
      });

      test('DatabaseFailure is a Failure', () {
        const failure = DatabaseFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('NotFoundFailure', () {
      test('creates NotFoundFailure with default code', () {
        const failure = NotFoundFailure(message: 'Item not found');

        expect(failure.message, 'Item not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('creates NotFoundFailure with custom code', () {
        const failure = NotFoundFailure(
          message: 'Not found',
          code: 'CUSTOM_NOT_FOUND',
        );

        expect(failure.code, 'CUSTOM_NOT_FOUND');
      });

      test('group factory creates correct failure', () {
        final failure = NotFoundFailure.group();

        expect(failure.message, 'Group not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('user factory creates correct failure', () {
        final failure = NotFoundFailure.user();

        expect(failure.message, 'User not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('expense factory creates correct failure', () {
        final failure = NotFoundFailure.expense();

        expect(failure.message, 'Expense not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('NotFoundFailure is a Failure', () {
        const failure = NotFoundFailure(message: 'Not found');
        expect(failure, isA<Failure>());
      });
    });

    group('ValidationFailure', () {
      test('creates ValidationFailure with message only', () {
        const failure = ValidationFailure(message: 'Invalid input');

        expect(failure.message, 'Invalid input');
        expect(failure.code, 'VALIDATION_ERROR');
        expect(failure.fieldErrors, isNull);
      });

      test('creates ValidationFailure with field errors', () {
        const failure = ValidationFailure(
          message: 'Validation failed',
          fieldErrors: {
            'email': 'Invalid email format',
            'password': 'Password too short',
          },
        );

        expect(failure.fieldErrors, isNotNull);
        expect(failure.fieldErrors!['email'], 'Invalid email format');
        expect(failure.fieldErrors!['password'], 'Password too short');
      });

      test('ValidationFailure props include fieldErrors', () {
        const failure1 = ValidationFailure(
          message: 'Error',
          fieldErrors: {'field': 'error'},
        );
        const failure2 = ValidationFailure(
          message: 'Error',
          fieldErrors: {'field': 'error'},
        );
        const failure3 = ValidationFailure(
          message: 'Error',
          fieldErrors: {'field': 'different'},
        );

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });

      test('ValidationFailure is a Failure', () {
        const failure = ValidationFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('StorageFailure', () {
      test('creates StorageFailure with message and code', () {
        const failure = StorageFailure(
          message: 'Storage error',
          code: 'STORAGE_ERROR',
        );

        expect(failure.message, 'Storage error');
        expect(failure.code, 'STORAGE_ERROR');
      });

      test('uploadFailed factory creates correct failure', () {
        final failure = StorageFailure.uploadFailed();

        expect(failure.message, 'Failed to upload file. Please try again.');
        expect(failure.code, 'UPLOAD_FAILED');
      });

      test('fileTooLarge factory creates correct failure', () {
        final failure = StorageFailure.fileTooLarge();

        expect(failure.message, 'File size exceeds the maximum limit');
        expect(failure.code, 'FILE_TOO_LARGE');
      });

      test('StorageFailure is a Failure', () {
        const failure = StorageFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('BiometricFailure', () {
      test('creates BiometricFailure with message and code', () {
        const failure = BiometricFailure(
          message: 'Biometric error',
          code: 'BIO_ERROR',
        );

        expect(failure.message, 'Biometric error');
        expect(failure.code, 'BIO_ERROR');
      });

      test('notAvailable factory creates correct failure', () {
        final failure = BiometricFailure.notAvailable();

        expect(
          failure.message,
          'Biometric authentication is not available on this device',
        );
        expect(failure.code, 'NOT_AVAILABLE');
      });

      test('failed factory creates correct failure', () {
        final failure = BiometricFailure.failed();

        expect(failure.message, 'Biometric authentication failed');
        expect(failure.code, 'AUTH_FAILED');
      });

      test('BiometricFailure is a Failure', () {
        const failure = BiometricFailure(message: 'Error');
        expect(failure, isA<Failure>());
      });
    });

    group('UnexpectedFailure', () {
      test('creates UnexpectedFailure with default values', () {
        const failure = UnexpectedFailure();

        expect(
          failure.message,
          'An unexpected error occurred. Please try again.',
        );
        expect(failure.code, 'UNEXPECTED_ERROR');
      });

      test('creates UnexpectedFailure with custom message', () {
        const failure = UnexpectedFailure(message: 'Custom unexpected error');

        expect(failure.message, 'Custom unexpected error');
      });

      test('UnexpectedFailure is a Failure', () {
        const failure = UnexpectedFailure();
        expect(failure, isA<Failure>());
      });
    });

    group('Equatable behavior', () {
      test('failures with same props are equal', () {
        const failure1 = ServerFailure(message: 'Error', code: 'ERR');
        const failure2 = ServerFailure(message: 'Error', code: 'ERR');

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });

      test('failures with different props are not equal', () {
        const failure1 = ServerFailure(message: 'Error 1');
        const failure2 = ServerFailure(message: 'Error 2');

        expect(failure1, isNot(equals(failure2)));
      });

      test('different failure types are not equal even with same message', () {
        const serverFailure = ServerFailure(message: 'Error');
        const cacheFailure = CacheFailure(message: 'Error');

        expect(serverFailure, isNot(equals(cacheFailure)));
      });
    });

    group('Failure hierarchy', () {
      test('all failure types extend Failure', () {
        expect(const ServerFailure(message: ''), isA<Failure>());
        expect(const NetworkFailure(), isA<Failure>());
        expect(const CacheFailure(message: ''), isA<Failure>());
        expect(const AuthFailure(message: ''), isA<Failure>());
        expect(const DatabaseFailure(message: ''), isA<Failure>());
        expect(const NotFoundFailure(message: ''), isA<Failure>());
        expect(const ValidationFailure(message: ''), isA<Failure>());
        expect(const StorageFailure(message: ''), isA<Failure>());
        expect(const BiometricFailure(message: ''), isA<Failure>());
        expect(const UnexpectedFailure(), isA<Failure>());
      });
    });
  });
}
