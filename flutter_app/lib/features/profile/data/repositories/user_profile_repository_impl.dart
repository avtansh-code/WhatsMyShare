import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_datasource.dart';

/// Implementation of UserProfileRepository
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource _dataSource;

  UserProfileRepositoryImpl({required UserProfileDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(
    String userId,
  ) async {
    try {
      final profile = await _dataSource.getUserProfile(userId);
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getCurrentUserProfile() async {
    try {
      final profile = await _dataSource.getCurrentUserProfile();
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<UserProfileEntity?> watchCurrentUserProfile() {
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
    try {
      final profile = await _dataSource.createUserProfile(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
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
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (phone != null) data['phone'] = phone;
      if (defaultCurrency != null) data['defaultCurrency'] = defaultCurrency;
      if (locale != null) data['locale'] = locale;
      if (timezone != null) data['timezone'] = timezone;
      if (countryCode != null) data['countryCode'] = countryCode;

      final profile = await _dataSource.updateUserProfile(
        userId: userId,
        data: data,
      );
      return Right(profile.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final url = await _dataSource.uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String userId) async {
    try {
      await _dataSource.deleteProfilePhoto(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'notificationsEnabled': enabled},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateContactSyncSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'contactSyncEnabled': enabled},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBiometricAuthSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      await _dataSource.updateUserProfile(
        userId: userId,
        data: {'biometricAuthEnabled': enabled},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastActive(String userId) async {
    try {
      await _dataSource.updateLastActive(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> userProfileExists(String userId) async {
    try {
      final exists = await _dataSource.profileExists(userId);
      return Right(exists);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserProfile(String userId) async {
    try {
      await _dataSource.deleteUserProfile(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
