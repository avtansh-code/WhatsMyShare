import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_datasource.dart';

/// Implementation of UserProfileRepository
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource _dataSource;
  final LoggingService _log = LoggingService();

  UserProfileRepositoryImpl({required UserProfileDataSource dataSource})
    : _dataSource = dataSource {
    _log.debug('UserProfileRepository initialized', tag: LogTags.profile);
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(
    String userId,
  ) async {
    _log.debug(
      'Getting user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final profile = await _dataSource.getUserProfile(userId);
      _log.info(
        'User profile fetched',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      _log.error(
        'Server error getting profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getCurrentUserProfile() async {
    _log.debug('Getting current user profile', tag: LogTags.profile);
    try {
      final profile = await _dataSource.getCurrentUserProfile();
      _log.info(
        'Current user profile fetched',
        tag: LogTags.profile,
        data: {'userId': profile.id},
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      _log.error(
        'Server error getting current profile',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting current profile',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting current profile',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<UserProfileEntity?> watchCurrentUserProfile() {
    _log.debug('Setting up current user profile stream', tag: LogTags.profile);
    return _dataSource.watchCurrentUserProfile().map(
      (model) => model?.toEntity(),
    );
  }

  @override
  Future<Either<Failure, UserProfileEntity>> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    _log.info(
      'Creating user profile',
      tag: LogTags.profile,
      data: {'userId': userId, 'email': email},
    );
    try {
      final profile = await _dataSource.createUserProfile(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _log.info(
        'User profile created',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      _log.error(
        'Server error creating profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error creating profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    String? countryCode,
  }) async {
    _log.info(
      'Updating user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (phone != null) data['phone'] = phone;
      if (defaultCurrency != null) data['defaultCurrency'] = defaultCurrency;
      if (locale != null) data['locale'] = locale;
      if (timezone != null) data['timezone'] = timezone;
      if (countryCode != null) data['countryCode'] = countryCode;

      _log.debug(
        'Profile update fields',
        tag: LogTags.profile,
        data: {'fieldsUpdated': data.keys.toList()},
      );

      final profile = await _dataSource.updateUserProfile(
        userId: userId,
        data: data,
      );
      _log.info(
        'User profile updated',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      _log.error(
        'Server error updating profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    // Gather file info for logging
    bool fileExists = false;
    int fileSize = 0;
    String extension = '';
    
    try {
      fileExists = await imageFile.exists();
      if (fileExists) {
        fileSize = await imageFile.length();
      }
      extension = imageFile.path.split('.').last.toLowerCase();
    } catch (e) {
      _log.warning(
        'Could not read file info',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
    }
    
    _log.info(
      'Repository: Starting profile photo update',
      tag: LogTags.profile,
      data: {
        'userId': userId,
        'filePath': imageFile.path,
        'fileExists': fileExists,
        'fileSizeBytes': fileSize,
        'fileSizeMB': (fileSize / (1024 * 1024)).toStringAsFixed(2),
        'extension': extension,
      },
    );
    
    if (!fileExists) {
      _log.error(
        'Repository: Image file does not exist',
        tag: LogTags.profile,
        data: {'path': imageFile.path},
      );
      return Left(ServerFailure(message: 'Image file not found'));
    }
    
    try {
      _log.debug(
        'Repository: Calling datasource uploadProfilePhoto',
        tag: LogTags.profile,
      );
      
      final url = await _dataSource.uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );
      
      _log.info(
        'Repository: Profile photo updated successfully',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'photoUrl': url,
        },
      );
      return Right(url);
    } on ServerException catch (e) {
      _log.error(
        'Repository: Server exception updating photo',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'exceptionMessage': e.message,
        },
      );
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      _log.error(
        'Repository: Auth exception updating photo',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'exceptionMessage': e.message,
        },
      );
      return Left(AuthFailure(message: e.message));
    } catch (e, stackTrace) {
      _log.error(
        'Repository: Unexpected error updating photo',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      return Left(ServerFailure(message: 'Failed to upload photo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String userId) async {
    _log.info(
      'Deleting profile photo',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      await _dataSource.deleteProfilePhoto(userId);
      _log.info(
        'Profile photo deleted',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting photo',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting photo',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationSettings({
    required String userId,
    required bool enabled,
  }) async {
    _log.info(
      'Updating notification settings',
      tag: LogTags.profile,
      data: {'userId': userId, 'enabled': enabled},
    );
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'notificationsEnabled': enabled},
      );
      _log.info(
        'Notification settings updated',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error updating notification settings',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating notification settings',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateContactSyncSettings({
    required String userId,
    required bool enabled,
  }) async {
    _log.info(
      'Updating contact sync settings',
      tag: LogTags.profile,
      data: {'userId': userId, 'enabled': enabled},
    );
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'contactSyncEnabled': enabled},
      );
      _log.info(
        'Contact sync settings updated',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error updating contact sync settings',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating contact sync settings',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBiometricAuthSettings({
    required String userId,
    required bool enabled,
  }) async {
    _log.info(
      'Updating biometric auth settings',
      tag: LogTags.profile,
      data: {'userId': userId, 'enabled': enabled},
    );
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'biometricAuthEnabled': enabled},
      );
      _log.info(
        'Biometric auth settings updated',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error updating biometric settings',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating biometric settings',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastActive(String userId) async {
    _log.debug(
      'Updating last active',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      await _dataSource.updateLastActive(userId);
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error updating last active',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating last active',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> userProfileExists(String userId) async {
    _log.debug(
      'Checking if profile exists',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final exists = await _dataSource.profileExists(userId);
      _log.debug(
        'Profile exists check',
        tag: LogTags.profile,
        data: {'userId': userId, 'exists': exists},
      );
      return Right(exists);
    } on ServerException catch (e) {
      _log.error(
        'Server error checking profile exists',
        tag: LogTags.profile,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error checking profile exists',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserProfile(String userId) async {
    _log.warning(
      'Deleting user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      await _dataSource.deleteUserProfile(userId);
      _log.info(
        'User profile deleted',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
