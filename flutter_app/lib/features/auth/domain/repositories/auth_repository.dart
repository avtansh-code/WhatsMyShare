import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations
/// Implementations will handle Firebase Auth and Firestore
abstract class AuthRepository {
  /// Stream of authentication state changes
  /// Emits null when user signs out, UserEntity when signed in
  Stream<UserEntity?> get authStateChanges;

  /// Get currently authenticated user
  /// Returns null if not authenticated
  Future<UserEntity?> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google OAuth
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  });

  /// Update user preferences
  Future<Either<Failure, UserEntity>> updatePreferences({
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
  });

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Check if email is already registered
  Future<Either<Failure, bool>> isEmailRegistered(String email);

  /// Verify current password (for sensitive operations)
  Future<Either<Failure, bool>> verifyPassword(String password);

  /// Update password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}