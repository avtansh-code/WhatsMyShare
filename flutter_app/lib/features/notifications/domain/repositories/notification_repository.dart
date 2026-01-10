import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

/// Repository interface for notifications and activity feed
abstract class NotificationRepository {
  /// Get all notifications for the current user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int limit = 50,
    DateTime? before,
  });

  /// Watch notifications for real-time updates
  Stream<List<NotificationEntity>> watchNotifications(String userId);

  /// Get unread notification count
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Watch unread notification count
  Stream<int> watchUnreadCount(String userId);

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Delete all read notifications
  Future<Either<Failure, void>> deleteReadNotifications(String userId);

  /// Get notification preferences
  Future<Either<Failure, NotificationPreferences>> getPreferences(
    String userId,
  );

  /// Update notification preferences
  Future<Either<Failure, void>> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  );

  /// Register FCM token for push notifications
  Future<Either<Failure, void>> registerFcmToken(String userId, String token);

  /// Unregister FCM token
  Future<Either<Failure, void>> unregisterFcmToken(String userId, String token);

  /// Get activity feed for a group
  Future<Either<Failure, List<ActivityEntity>>> getGroupActivity(
    String groupId, {
    int limit = 50,
    DateTime? before,
  });

  /// Watch activity feed for a group
  Stream<List<ActivityEntity>> watchGroupActivity(String groupId);

  /// Create an activity entry (typically called after actions)
  Future<Either<Failure, ActivityEntity>> createActivity(
    ActivityEntity activity,
  );
}
