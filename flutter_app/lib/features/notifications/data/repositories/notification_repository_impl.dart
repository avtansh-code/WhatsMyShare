import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;
  final FirebaseAuth _auth;
  final LoggingService _log = LoggingService();

  NotificationRepositoryImpl({
    required NotificationDataSource dataSource,
    required FirebaseAuth auth,
  }) : _dataSource = dataSource,
       _auth = auth {
    _log.debug(
      'NotificationRepository initialized',
      tag: LogTags.notifications,
    );
  }

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      _log.warning('User not authenticated', tag: LogTags.notifications);
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int limit = 50,
    DateTime? before,
  }) async {
    _log.debug(
      'Getting notifications',
      tag: LogTags.notifications,
      data: {'limit': limit},
    );
    try {
      final notifications = await _dataSource.getNotifications(
        _currentUserId,
        limit: limit,
        before: before,
      );
      _log.info(
        'Notifications fetched',
        tag: LogTags.notifications,
        data: {'count': notifications.length},
      );
      return Right(notifications);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting notifications',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting notifications',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting notifications',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    _log.debug(
      'Setting up notifications stream',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    return _dataSource.watchNotifications(userId);
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    _log.debug(
      'Getting unread count',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final count = await _dataSource.getUnreadCount(userId);
      _log.info(
        'Unread count fetched',
        tag: LogTags.notifications,
        data: {'count': count},
      );
      return Right(count);
    } on ServerException catch (e) {
      _log.error(
        'Server error getting unread count',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting unread count',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    _log.debug(
      'Setting up unread count stream',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    return _dataSource.watchUnreadCount(userId);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    _log.info(
      'Marking notification as read',
      tag: LogTags.notifications,
      data: {'notificationId': notificationId},
    );
    try {
      await _dataSource.markAsRead(_currentUserId, notificationId);
      _log.info(
        'Notification marked as read',
        tag: LogTags.notifications,
        data: {'notificationId': notificationId},
      );
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error marking notification as read',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error marking notification as read',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error marking notification as read',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    _log.info(
      'Marking all notifications as read',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _dataSource.markAllAsRead(userId);
      _log.info(
        'All notifications marked as read',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error marking all as read',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error marking all as read',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
  ) async {
    _log.info(
      'Deleting notification',
      tag: LogTags.notifications,
      data: {'notificationId': notificationId},
    );
    try {
      await _dataSource.deleteNotification(_currentUserId, notificationId);
      _log.info(
        'Notification deleted',
        tag: LogTags.notifications,
        data: {'notificationId': notificationId},
      );
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error deleting notification',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting notification',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting notification',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReadNotifications(String userId) async {
    _log.info(
      'Deleting read notifications',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _dataSource.deleteReadNotifications(userId);
      _log.info(
        'Read notifications deleted',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting read notifications',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting read notifications',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> getPreferences(
    String userId,
  ) async {
    _log.debug(
      'Getting notification preferences',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final preferences = await _dataSource.getPreferences(userId);
      _log.info(
        'Notification preferences fetched',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return Right(preferences);
    } on ServerException catch (e) {
      _log.error(
        'Server error getting preferences',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting preferences',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    _log.info(
      'Updating notification preferences',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _dataSource.updatePreferences(userId, preferences);
      _log.info(
        'Notification preferences updated',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error updating preferences',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating preferences',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerFcmToken(
    String userId,
    String token,
  ) async {
    _log.info(
      'Registering FCM token',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _dataSource.registerFcmToken(userId, token);
      _log.info(
        'FCM token registered',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error registering FCM token',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error registering FCM token',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterFcmToken(
    String userId,
    String token,
  ) async {
    _log.info(
      'Unregistering FCM token',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _dataSource.unregisterFcmToken(userId, token);
      _log.info(
        'FCM token unregistered',
        tag: LogTags.notifications,
        data: {'userId': userId},
      );
      return const Right(null);
    } on ServerException catch (e) {
      _log.error(
        'Server error unregistering FCM token',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error unregistering FCM token',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityEntity>>> getGroupActivity(
    String groupId, {
    int limit = 50,
    DateTime? before,
  }) async {
    _log.debug(
      'Getting group activity',
      tag: LogTags.notifications,
      data: {'groupId': groupId, 'limit': limit},
    );
    try {
      final activities = await _dataSource.getGroupActivity(
        groupId,
        limit: limit,
        before: before,
      );
      _log.info(
        'Group activity fetched',
        tag: LogTags.notifications,
        data: {'groupId': groupId, 'count': activities.length},
      );
      return Right(activities);
    } on ServerException catch (e) {
      _log.error(
        'Server error getting group activity',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting group activity',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<ActivityEntity>> watchGroupActivity(String groupId) {
    _log.debug(
      'Setting up group activity stream',
      tag: LogTags.notifications,
      data: {'groupId': groupId},
    );
    return _dataSource.watchGroupActivity(groupId);
  }

  @override
  Future<Either<Failure, ActivityEntity>> createActivity(
    ActivityEntity activity,
  ) async {
    _log.info(
      'Creating activity',
      tag: LogTags.notifications,
      data: {'type': activity.type.name, 'groupId': activity.groupId},
    );
    try {
      final model = ActivityModel.fromEntity(activity);
      final created = await _dataSource.createActivity(model);
      _log.info(
        'Activity created',
        tag: LogTags.notifications,
        data: {'activityId': created.id},
      );
      return Right(created);
    } on ServerException catch (e) {
      _log.error(
        'Server error creating activity',
        tag: LogTags.notifications,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error creating activity',
        tag: LogTags.notifications,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
