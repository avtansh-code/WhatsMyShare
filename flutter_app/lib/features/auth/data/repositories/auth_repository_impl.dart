import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Implementation of AuthRepository for phone-based authentication ONLY
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;
  final LoggingService _loggingService;

  AuthRepositoryImpl({
    required FirebaseAuthDataSource dataSource,
    required LoggingService loggingService,
  }) : _dataSource = dataSource,
       _loggingService = loggingService;

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      _loggingService.error('Server error getting current user', error: e);
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error getting current user', error: e);
      return Left(ServerFailure(message: 'Failed to get current user'));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<Either<Failure, String>> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      await _dataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken,
      );
      // Return success - actual verification ID comes via codeSent callback
      return const Right('Verification started');
    } on AuthException catch (e) {
      _loggingService.error('Auth error verifying phone', error: e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error verifying phone', error: e);
      return Left(AuthFailure(message: 'Failed to verify phone number'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = await _dataSource.signInWithPhoneCredential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return Right(user);
    } on AuthException catch (e) {
      _loggingService.error('Auth error signing in with phone', error: e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error signing in with phone', error: e);
      return Left(AuthFailure(message: 'Failed to sign in'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithAutoRetrievedCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    try {
      final user = await _dataSource.signInWithAutoRetrievedCredential(
        credential,
      );
      return Right(user);
    } on AuthException catch (e) {
      _loggingService.error(
        'Auth error with auto-retrieved credential',
        error: e,
      );
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _loggingService.error(
        'Unexpected error with auto-retrieved credential',
        error: e,
      );
      return Left(AuthFailure(message: 'Failed to sign in'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final user = await _dataSource.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(user);
    } on ServerException catch (e) {
      _loggingService.error('Server error updating profile', error: e);
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error updating profile', error: e);
      return Left(ServerFailure(message: 'Failed to update profile'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> completeProfileSetup({
    required String displayName,
    String? photoUrl,
    String? defaultCurrency,
    String? countryCode,
  }) async {
    try {
      final user = await _dataSource.completeProfileSetup(
        displayName: displayName,
        photoUrl: photoUrl,
        defaultCurrency: defaultCurrency,
        countryCode: countryCode,
      );
      return Right(user);
    } on ServerException catch (e) {
      _loggingService.error('Server error completing profile', error: e);
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error completing profile', error: e);
      return Left(ServerFailure(message: 'Failed to complete profile setup'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      _loggingService.error('Auth error signing out', error: e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error signing out', error: e);
      return Left(AuthFailure(message: 'Failed to sign out'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      _loggingService.error('Auth error deleting account', error: e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error deleting account', error: e);
      return Left(AuthFailure(message: 'Failed to delete account'));
    }
  }

  @override
  Future<Either<Failure, bool>> isPhoneNumberRegistered(
    String phoneNumber,
  ) async {
    try {
      final isRegistered = await _dataSource.isPhoneNumberRegistered(
        phoneNumber,
      );
      return Right(isRegistered);
    } on ServerException catch (e) {
      _loggingService.error(
        'Server error checking phone registration',
        error: e,
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _loggingService.error(
        'Unexpected error checking phone registration',
        error: e,
      );
      return Left(ServerFailure(message: 'Failed to check phone registration'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getUserByPhoneNumber(
    String phoneNumber,
  ) async {
    try {
      final user = await _dataSource.getUserByPhoneNumber(phoneNumber);
      return Right(user);
    } on ServerException catch (e) {
      _loggingService.error('Server error getting user by phone', error: e);
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _loggingService.error('Unexpected error getting user by phone', error: e);
      return Left(ServerFailure(message: 'Failed to get user'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken(String token) async {
    try {
      await _dataSource.updateFcmToken(token);
      return const Right(null);
    } catch (e) {
      _loggingService.error('Error updating FCM token', error: e);
      // Don't fail silently for FCM token updates
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> removeFcmToken(String token) async {
    try {
      await _dataSource.removeFcmToken(token);
      return const Right(null);
    } catch (e) {
      _loggingService.error('Error removing FCM token', error: e);
      return const Right(null);
    }
  }
}
