import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_profile_entity.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  /// Get user profile by ID
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId);

  /// Get current authenticated user's profile
  Future<Either<Failure, UserProfileEntity>> getCurrentUserProfile();

  /// Stream of current user's profile (real-time updates)
  Stream<UserProfileEntity?> watchCurrentUserProfile();

  /// Create a new user profile
  Future<Either<Failure, UserProfileEntity>> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  });

  /// Update user profile
  Future<Either<Failure, UserProfileEntity>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    String? countryCode,
  });

  /// Update profile photo
  Future<Either<Failure, String>> updateProfilePhoto({
    required String userId,
    required File imageFile,
  });

  /// Delete profile photo
  Future<Either<Failure, void>> deleteProfilePhoto(String userId);

  /// Update notification settings
  Future<Either<Failure, void>> updateNotificationSettings({
    required String userId,
    required bool enabled,
  });

  /// Update contact sync settings
  Future<Either<Failure, void>> updateContactSyncSettings({
    required String userId,
    required bool enabled,
  });

  /// Update biometric auth settings
  Future<Either<Failure, void>> updateBiometricAuthSettings({
    required String userId,
    required bool enabled,
  });

  /// Update last active timestamp
  Future<Either<Failure, void>> updateLastActive(String userId);

  /// Check if user profile exists
  Future<Either<Failure, bool>> userProfileExists(String userId);

  /// Delete user profile (for account deletion)
  Future<Either<Failure, void>> deleteUserProfile(String userId);
}