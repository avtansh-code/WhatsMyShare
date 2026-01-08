import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling
/// Used with Either<Failure, Success> pattern from dartz
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server failure (API errors)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Network failure (connectivity issues)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Cache failure (local storage issues)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Invalid email or password',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'User not found',
        code: 'USER_NOT_FOUND',
      );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
        message: 'Email is already registered',
        code: 'EMAIL_ALREADY_IN_USE',
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'Password is too weak. Use at least 8 characters.',
        code: 'WEAK_PASSWORD',
      );

  factory AuthFailure.sessionExpired() => const AuthFailure(
        message: 'Session expired. Please login again.',
        code: 'SESSION_EXPIRED',
      );

  factory AuthFailure.unauthorized() => const AuthFailure(
        message: 'You are not authorized to perform this action',
        code: 'UNAUTHORIZED',
      );
}

/// Firestore/Database failure
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
  });

  factory DatabaseFailure.notFound(String item) => DatabaseFailure(
        message: '$item not found',
        code: 'NOT_FOUND',
      );

  factory DatabaseFailure.permissionDenied() => const DatabaseFailure(
        message: 'You do not have permission to access this data',
        code: 'PERMISSION_DENIED',
      );
}

/// Validation failure
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Storage failure (file upload/download)
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
  });

  factory StorageFailure.uploadFailed() => const StorageFailure(
        message: 'Failed to upload file. Please try again.',
        code: 'UPLOAD_FAILED',
      );

  factory StorageFailure.fileTooLarge() => const StorageFailure(
        message: 'File size exceeds the maximum limit',
        code: 'FILE_TOO_LARGE',
      );
}

/// Biometric authentication failure
class BiometricFailure extends Failure {
  const BiometricFailure({
    required super.message,
    super.code,
  });

  factory BiometricFailure.notAvailable() => const BiometricFailure(
        message: 'Biometric authentication is not available on this device',
        code: 'NOT_AVAILABLE',
      );

  factory BiometricFailure.failed() => const BiometricFailure(
        message: 'Biometric authentication failed',
        code: 'AUTH_FAILED',
      );
}

/// Unknown/unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNEXPECTED_ERROR',
  });
}