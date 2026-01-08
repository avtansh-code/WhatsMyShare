import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;
  final FirebaseAuth _auth;

  NotificationRepositoryImpl({
    required NotificationDataSource dataSource,
    required FirebaseAuth auth,
  }) : _dataSource = dataSource,
       _auth = auth;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final notifications = await _dataSource.getNotifications(
        _currentUserId,
        limit: limit,
        before: before,
      );
      return Right(notifications);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _dataSource.watchNotifications(userId);
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await _dataSource.getUnreadCount(userId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _dataSource.watchUnreadCount(userId);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(_currentUserId, notificationId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await _dataSource.markAllAsRead(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
  ) async {
    try {
      await _dataSource.deleteNotification(_currentUserId, notificationId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReadNotifications(String userId) async {
    try {
      await _dataSource.deleteReadNotifications(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> getPreferences(
    String userId,
  ) async {
    try {
      final preferences = await _dataSource.getPreferences(userId);
      return Right(preferences);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _dataSource.updatePreferences(userId, preferences);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerFcmToken(
    String userId,
    String token,
  ) async {
    try {
      await _dataSource.registerFcmToken(userId, token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterFcmToken(
    String userId,
    String token,
  ) async {
    try {
      await _dataSource.unregisterFcmToken(userId, token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityEntity>>> getGroupActivity(
    String groupId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final activities = await _dataSource.getGroupActivity(
        groupId,
        limit: limit,
        before: before,
      );
      return Right(activities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<ActivityEntity>> watchGroupActivity(String groupId) {
    return _dataSource.watchGroupActivity(groupId);
  }

  @override
  Future<Either<Failure, ActivityEntity>> createActivity(
    ActivityEntity activity,
  ) async {
    try {
      final model = ActivityModel.fromEntity(activity);
      final created = await _dataSource.createActivity(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
