import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Authentication repository interface
/// Supports ONLY phone-based authentication
abstract class AuthRepository {
  /// Get the currently authenticated user
  /// Returns null if no user is signed in
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;

  /// Start phone number verification
  /// Sends OTP to the provided phone number
  Future<Either<Failure, String>> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  /// Sign in with phone credential (OTP verification)
  Future<Either<Failure, UserEntity>> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  });

  /// Sign in with auto-retrieved credential (Android only)
  Future<Either<Failure, UserEntity>> signInWithAutoRetrievedCredential(
    firebase_auth.PhoneAuthCredential credential,
  );

  /// Update user profile after phone verification
  Future<Either<Failure, UserEntity>> updateProfile({
    required String displayName,
    String? photoUrl,
  });

  /// Complete user profile setup (for new users)
  Future<Either<Failure, UserEntity>> completeProfileSetup({
    required String displayName,
    String? photoUrl,
    String? defaultCurrency,
    String? countryCode,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Check if a phone number is already registered
  Future<Either<Failure, bool>> isPhoneNumberRegistered(String phoneNumber);

  /// Get user by phone number
  Future<Either<Failure, UserEntity?>> getUserByPhoneNumber(String phoneNumber);

  /// Update FCM token for push notifications
  Future<Either<Failure, void>> updateFcmToken(String token);

  /// Remove FCM token on sign out
  Future<Either<Failure, void>> removeFcmToken(String token);
}
