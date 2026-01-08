import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    group('ServerException', () {
      test('creates ServerException with all fields', () {
        final originalException = Exception('Original');
        final stackTrace = StackTrace.current;

        final exception = ServerException(
          message: 'Server error',
          code: 'SERVER_ERROR',
          statusCode: 500,
          originalException: originalException,
          stackTrace: stackTrace,
        );

        expect(exception.message, 'Server error');
        expect(exception.code, 'SERVER_ERROR');
        expect(exception.statusCode, 500);
        expect(exception.originalException, originalException);
        expect(exception.stackTrace, stackTrace);
      });

      test('creates ServerException with minimal fields', () {
        const exception = ServerException(message: 'Error');

        expect(exception.message, 'Error');
        expect(exception.code, isNull);
        expect(exception.statusCode, isNull);
        expect(exception.originalException, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('ServerException is an AppException', () {
        const exception = ServerException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('ServerException is an Exception', () {
        const exception = ServerException(message: 'Error');
        expect(exception, isA<Exception>());
      });

      test('toString returns formatted message', () {
        const exception = ServerException(
          message: 'Server error',
          statusCode: 500,
        );

        expect(
          exception.toString(),
          'ServerException: Server error (status: 500)',
        );
      });
    });

    group('NetworkException', () {
      test('creates NetworkException with default values', () {
        const exception = NetworkException();

        expect(exception.message, 'No internet connection');
        expect(exception.code, 'NETWORK_ERROR');
      });

      test('creates NetworkException with custom message', () {
        const exception = NetworkException(message: 'Connection timeout');

        expect(exception.message, 'Connection timeout');
      });

      test('NetworkException is an AppException', () {
        const exception = NetworkException();
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = NetworkException(message: 'No connection');

        expect(exception.toString(), 'NetworkException: No connection');
      });
    });

    group('CacheException', () {
      test('creates CacheException with required message', () {
        const exception = CacheException(message: 'Cache read failed');

        expect(exception.message, 'Cache read failed');
        expect(exception.code, 'CACHE_ERROR');
      });

      test('CacheException is an AppException', () {
        const exception = CacheException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = CacheException(message: 'Cache miss');

        expect(exception.toString(), 'CacheException: Cache miss');
      });
    });

    group('AuthException', () {
      test('creates AuthException with message and code', () {
        const exception = AuthException(
          message: 'Auth error',
          code: 'AUTH_ERROR',
        );

        expect(exception.message, 'Auth error');
        expect(exception.code, 'AUTH_ERROR');
      });

      test('invalidCredentials factory creates correct exception', () {
        final exception = AuthException.invalidCredentials();

        expect(exception.message, 'Invalid email or password');
        expect(exception.code, 'INVALID_CREDENTIALS');
      });

      test('userNotFound factory creates correct exception', () {
        final exception = AuthException.userNotFound();

        expect(exception.message, 'User not found');
        expect(exception.code, 'USER_NOT_FOUND');
      });

      test('emailAlreadyInUse factory creates correct exception', () {
        final exception = AuthException.emailAlreadyInUse();

        expect(exception.message, 'Email is already registered');
        expect(exception.code, 'EMAIL_ALREADY_IN_USE');
      });

      test('weakPassword factory creates correct exception', () {
        final exception = AuthException.weakPassword();

        expect(exception.message, 'Password is too weak');
        expect(exception.code, 'WEAK_PASSWORD');
      });

      test('invalidEmail factory creates correct exception', () {
        final exception = AuthException.invalidEmail();

        expect(exception.message, 'Invalid email address');
        expect(exception.code, 'INVALID_EMAIL');
      });

      test('sessionExpired factory creates correct exception', () {
        final exception = AuthException.sessionExpired();

        expect(exception.message, 'Session expired. Please login again');
        expect(exception.code, 'SESSION_EXPIRED');
      });

      test('unauthorized factory creates correct exception', () {
        final exception = AuthException.unauthorized();

        expect(
          exception.message,
          'You are not authorized to perform this action',
        );
        expect(exception.code, 'UNAUTHORIZED');
      });

      test('AuthException is an AppException', () {
        const exception = AuthException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = AuthException(
          message: 'Auth failed',
          code: 'AUTH_FAILED',
        );

        expect(
          exception.toString(),
          'AuthException: Auth failed (code: AUTH_FAILED)',
        );
      });
    });

    group('FirestoreException', () {
      test('creates FirestoreException with message and code', () {
        const exception = FirestoreException(
          message: 'Firestore error',
          code: 'FS_ERROR',
        );

        expect(exception.message, 'Firestore error');
        expect(exception.code, 'FS_ERROR');
      });

      test('notFound factory creates correct exception', () {
        final exception = FirestoreException.notFound('User');

        expect(exception.message, 'User not found');
        expect(exception.code, 'NOT_FOUND');
      });

      test('permissionDenied factory creates correct exception', () {
        final exception = FirestoreException.permissionDenied();

        expect(exception.message, 'Permission denied');
        expect(exception.code, 'PERMISSION_DENIED');
      });

      test('alreadyExists factory creates correct exception', () {
        final exception = FirestoreException.alreadyExists('Document');

        expect(exception.message, 'Document already exists');
        expect(exception.code, 'ALREADY_EXISTS');
      });

      test('FirestoreException is an AppException', () {
        const exception = FirestoreException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = FirestoreException(
          message: 'Not found',
          code: 'NOT_FOUND',
        );

        expect(
          exception.toString(),
          'FirestoreException: Not found (code: NOT_FOUND)',
        );
      });
    });

    group('ValidationException', () {
      test('creates ValidationException with message only', () {
        const exception = ValidationException(message: 'Invalid input');

        expect(exception.message, 'Invalid input');
        expect(exception.code, 'VALIDATION_ERROR');
        expect(exception.fieldErrors, isNull);
      });

      test('creates ValidationException with field errors', () {
        const exception = ValidationException(
          message: 'Validation failed',
          fieldErrors: {
            'email': 'Invalid email format',
            'password': 'Password too short',
          },
        );

        expect(exception.fieldErrors, isNotNull);
        expect(exception.fieldErrors!['email'], 'Invalid email format');
        expect(exception.fieldErrors!['password'], 'Password too short');
      });

      test('ValidationException is an AppException', () {
        const exception = ValidationException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString includes field errors', () {
        const exception = ValidationException(
          message: 'Validation error',
          fieldErrors: {'field': 'error'},
        );

        expect(exception.toString(), contains('Validation error'));
        expect(exception.toString(), contains('field'));
      });
    });

    group('StorageException', () {
      test('creates StorageException with message and code', () {
        const exception = StorageException(
          message: 'Storage error',
          code: 'STORAGE_ERROR',
        );

        expect(exception.message, 'Storage error');
        expect(exception.code, 'STORAGE_ERROR');
      });

      test('uploadFailed factory creates correct exception', () {
        final exception = StorageException.uploadFailed();

        expect(exception.message, 'Failed to upload file');
        expect(exception.code, 'UPLOAD_FAILED');
      });

      test('downloadFailed factory creates correct exception', () {
        final exception = StorageException.downloadFailed();

        expect(exception.message, 'Failed to download file');
        expect(exception.code, 'DOWNLOAD_FAILED');
      });

      test('fileTooLarge factory creates correct exception', () {
        final exception = StorageException.fileTooLarge();

        expect(exception.message, 'File size exceeds limit');
        expect(exception.code, 'FILE_TOO_LARGE');
      });

      test('StorageException is an AppException', () {
        const exception = StorageException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = StorageException(
          message: 'Upload failed',
          code: 'UPLOAD_FAILED',
        );

        expect(
          exception.toString(),
          'StorageException: Upload failed (code: UPLOAD_FAILED)',
        );
      });
    });

    group('NotFoundException', () {
      test('creates NotFoundException with default code', () {
        const exception = NotFoundException(message: 'Item not found');

        expect(exception.message, 'Item not found');
        expect(exception.code, 'NOT_FOUND');
      });

      test('NotFoundException is an AppException', () {
        const exception = NotFoundException(message: 'Not found');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = NotFoundException(message: 'Resource not found');

        expect(exception.toString(), 'NotFoundException: Resource not found');
      });
    });

    group('BiometricException', () {
      test('creates BiometricException with message and code', () {
        const exception = BiometricException(
          message: 'Biometric error',
          code: 'BIO_ERROR',
        );

        expect(exception.message, 'Biometric error');
        expect(exception.code, 'BIO_ERROR');
      });

      test('notAvailable factory creates correct exception', () {
        final exception = BiometricException.notAvailable();

        expect(exception.message, 'Biometric authentication not available');
        expect(exception.code, 'NOT_AVAILABLE');
      });

      test('notEnrolled factory creates correct exception', () {
        final exception = BiometricException.notEnrolled();

        expect(exception.message, 'No biometrics enrolled on device');
        expect(exception.code, 'NOT_ENROLLED');
      });

      test('failed factory creates correct exception', () {
        final exception = BiometricException.failed();

        expect(exception.message, 'Biometric authentication failed');
        expect(exception.code, 'AUTH_FAILED');
      });

      test('BiometricException is an AppException', () {
        const exception = BiometricException(message: 'Error');
        expect(exception, isA<AppException>());
      });

      test('toString returns formatted message', () {
        const exception = BiometricException(
          message: 'Biometric failed',
          code: 'AUTH_FAILED',
        );

        expect(
          exception.toString(),
          'BiometricException: Biometric failed (code: AUTH_FAILED)',
        );
      });
    });

    group('Exception hierarchy', () {
      test('all exception types extend AppException', () {
        expect(const ServerException(message: ''), isA<AppException>());
        expect(const NetworkException(), isA<AppException>());
        expect(const CacheException(message: ''), isA<AppException>());
        expect(const AuthException(message: ''), isA<AppException>());
        expect(const FirestoreException(message: ''), isA<AppException>());
        expect(const ValidationException(message: ''), isA<AppException>());
        expect(const StorageException(message: ''), isA<AppException>());
        expect(const NotFoundException(message: ''), isA<AppException>());
        expect(const BiometricException(message: ''), isA<AppException>());
      });

      test('all exception types implement Exception', () {
        expect(const ServerException(message: ''), isA<Exception>());
        expect(const NetworkException(), isA<Exception>());
        expect(const CacheException(message: ''), isA<Exception>());
        expect(const AuthException(message: ''), isA<Exception>());
        expect(const FirestoreException(message: ''), isA<Exception>());
        expect(const ValidationException(message: ''), isA<Exception>());
        expect(const StorageException(message: ''), isA<Exception>());
        expect(const NotFoundException(message: ''), isA<Exception>());
        expect(const BiometricException(message: ''), isA<Exception>());
      });
    });

    group('Original exception and stack trace', () {
      test('can capture original exception', () {
        final original = Exception('Original error');
        final exception = ServerException(
          message: 'Wrapped error',
          originalException: original,
        );

        expect(exception.originalException, original);
      });

      test('can capture stack trace', () {
        final trace = StackTrace.current;
        final exception = ServerException(
          message: 'Error with trace',
          stackTrace: trace,
        );

        expect(exception.stackTrace, trace);
      });
    });
  });
}
