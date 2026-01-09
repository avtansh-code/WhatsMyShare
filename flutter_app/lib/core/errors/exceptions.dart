/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Exception thrown when there's a network connectivity issue
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when cache operations fail
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown for authentication errors
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() => const AuthException(
    message: 'Invalid credentials',
    code: 'INVALID_CREDENTIALS',
  );

  factory AuthException.userNotFound() =>
      const AuthException(message: 'User not found', code: 'USER_NOT_FOUND');

  factory AuthException.phoneAlreadyInUse() => const AuthException(
    message: 'Phone number is already registered',
    code: 'PHONE_ALREADY_IN_USE',
  );

  factory AuthException.invalidPhoneNumber() => const AuthException(
    message: 'Invalid phone number',
    code: 'INVALID_PHONE_NUMBER',
  );

  factory AuthException.invalidOtp() => const AuthException(
    message: 'Invalid verification code',
    code: 'INVALID_OTP',
  );

  factory AuthException.sessionExpired() => const AuthException(
    message: 'Session expired. Please login again',
    code: 'SESSION_EXPIRED',
  );

  factory AuthException.unauthorized() => const AuthException(
    message: 'You are not authorized to perform this action',
    code: 'UNAUTHORIZED',
  );

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Exception thrown for Firestore operations
class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory FirestoreException.notFound(String document) =>
      FirestoreException(message: '$document not found', code: 'NOT_FOUND');

  factory FirestoreException.permissionDenied() => const FirestoreException(
    message: 'Permission denied',
    code: 'PERMISSION_DENIED',
  );

  factory FirestoreException.alreadyExists(String document) =>
      FirestoreException(
        message: '$document already exists',
        code: 'ALREADY_EXISTS',
      );

  @override
  String toString() => 'FirestoreException: $message (code: $code)';
}

/// Exception thrown for validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'ValidationException: $message (fields: $fieldErrors)';
}

/// Exception thrown for storage operations
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory StorageException.uploadFailed() => const StorageException(
    message: 'Failed to upload file',
    code: 'UPLOAD_FAILED',
  );

  factory StorageException.downloadFailed() => const StorageException(
    message: 'Failed to download file',
    code: 'DOWNLOAD_FAILED',
  );

  factory StorageException.fileTooLarge() => const StorageException(
    message: 'File size exceeds limit',
    code: 'FILE_TOO_LARGE',
  );

  @override
  String toString() => 'StorageException: $message (code: $code)';
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception thrown for biometric authentication
class BiometricException extends AppException {
  const BiometricException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory BiometricException.notAvailable() => const BiometricException(
    message: 'Biometric authentication not available',
    code: 'NOT_AVAILABLE',
  );

  factory BiometricException.notEnrolled() => const BiometricException(
    message: 'No biometrics enrolled on device',
    code: 'NOT_ENROLLED',
  );

  factory BiometricException.failed() => const BiometricException(
    message: 'Biometric authentication failed',
    code: 'AUTH_FAILED',
  );

  @override
  String toString() => 'BiometricException: $message (code: $code)';
}
