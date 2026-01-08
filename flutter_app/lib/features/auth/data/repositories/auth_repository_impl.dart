import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;
  final LoggingService _log = LoggingService();

  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
    : _dataSource = dataSource {
    _log.debug('AuthRepository initialized', tag: LogTags.auth);
  }

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<UserEntity?> getCurrentUser() async {
    _log.debug('Getting current user', tag: LogTags.auth);
    return await _dataSource.getCurrentUser();
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _log.info(
      'Sign in with email attempt',
      tag: LogTags.auth,
      data: {'email': email},
    );
    try {
      final user = await _dataSource.signInWithEmail(email, password);
      _log.info(
        'Sign in with email successful',
        tag: LogTags.auth,
        data: {'userId': user.id},
      );
      return Right(user);
    } on AuthException catch (e) {
      _log.warning(
        'Sign in with email failed',
        tag: LogTags.auth,
        data: {'email': email, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      _log.error(
        'Server error during sign in',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error during sign in',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _log.info(
      'Sign up with email attempt',
      tag: LogTags.auth,
      data: {'email': email, 'displayName': displayName},
    );
    try {
      final user = await _dataSource.signUpWithEmail(
        email,
        password,
        displayName,
      );
      _log.info(
        'Sign up with email successful',
        tag: LogTags.auth,
        data: {'userId': user.id},
      );
      return Right(user);
    } on AuthException catch (e) {
      _log.warning(
        'Sign up with email failed',
        tag: LogTags.auth,
        data: {'email': email, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      _log.error(
        'Server error during sign up',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error during sign up',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    _log.info('Sign in with Google attempt', tag: LogTags.auth);
    try {
      final user = await _dataSource.signInWithGoogle();
      _log.info(
        'Sign in with Google successful',
        tag: LogTags.auth,
        data: {'userId': user.id},
      );
      return Right(user);
    } on AuthException catch (e) {
      _log.warning(
        'Sign in with Google failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      _log.error(
        'Server error during Google sign in',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error during Google sign in',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _log.info('Sign out attempt', tag: LogTags.auth);
    try {
      await _dataSource.signOut();
      _log.info('Sign out successful', tag: LogTags.auth);
      return const Right(null);
    } catch (e) {
      _log.error(
        'Sign out failed',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    _log.info(
      'Password reset request',
      tag: LogTags.auth,
      data: {'email': email},
    );
    try {
      await _dataSource.sendPasswordResetEmail(email);
      _log.info(
        'Password reset email sent',
        tag: LogTags.auth,
        data: {'email': email},
      );
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Password reset failed',
        tag: LogTags.auth,
        data: {'email': email, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.error(
        'Unexpected error during password reset',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    _log.info('Update profile attempt', tag: LogTags.auth);
    try {
      final user = await _dataSource.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
        phone: phone,
      );
      _log.info(
        'Profile updated successfully',
        tag: LogTags.auth,
        data: {'userId': user.id},
      );
      return Right(user);
    } on AuthException catch (e) {
      _log.warning(
        'Update profile failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      _log.error(
        'Server error during profile update',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error during profile update',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updatePreferences({
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
  }) async {
    _log.info('Update preferences attempt', tag: LogTags.auth);
    try {
      final user = await _dataSource.updatePreferences(
        defaultCurrency: defaultCurrency,
        locale: locale,
        timezone: timezone,
        notificationsEnabled: notificationsEnabled,
        biometricAuthEnabled: biometricAuthEnabled,
      );
      _log.info(
        'Preferences updated successfully',
        tag: LogTags.auth,
        data: {'userId': user.id},
      );
      return Right(user);
    } on AuthException catch (e) {
      _log.warning(
        'Update preferences failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      _log.error(
        'Server error during preferences update',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error during preferences update',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    _log.warning('Delete account attempt', tag: LogTags.auth);
    try {
      await _dataSource.deleteAccount();
      _log.info('Account deleted successfully', tag: LogTags.auth);
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Delete account failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.error(
        'Unexpected error during account deletion',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    _log.debug(
      'Checking if email is registered',
      tag: LogTags.auth,
      data: {'email': email},
    );
    try {
      final isRegistered = await _dataSource.isEmailRegistered(email);
      _log.debug(
        'Email registration check complete',
        tag: LogTags.auth,
        data: {'isRegistered': isRegistered},
      );
      return Right(isRegistered);
    } catch (e) {
      _log.error(
        'Error checking email registration',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPassword(String password) async {
    _log.debug('Verifying password', tag: LogTags.auth);
    try {
      final isValid = await _dataSource.verifyPassword(password);
      _log.debug(
        'Password verification complete',
        tag: LogTags.auth,
        data: {'isValid': isValid},
      );
      return Right(isValid);
    } on AuthException catch (e) {
      _log.warning(
        'Password verification failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.error(
        'Error verifying password',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _log.info('Update password attempt', tag: LogTags.auth);
    try {
      await _dataSource.updatePassword(currentPassword, newPassword);
      _log.info('Password updated successfully', tag: LogTags.auth);
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Update password failed',
        tag: LogTags.auth,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.error(
        'Error updating password',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
