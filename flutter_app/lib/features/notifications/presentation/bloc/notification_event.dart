import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_entity.dart';

/// Base class for notification events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications
class LoadNotifications extends NotificationEvent {
  final int limit;
  final DateTime? before;

  const LoadNotifications({this.limit = 50, this.before});

  @override
  List<Object?> get props => [limit, before];
}

/// Subscribe to notifications stream
class SubscribeToNotifications extends NotificationEvent {
  final String userId;

  const SubscribeToNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Mark a notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Delete a notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Delete all read notifications
class DeleteReadNotifications extends NotificationEvent {
  final String userId;

  const DeleteReadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load notification preferences
class LoadNotificationPreferences extends NotificationEvent {
  final String userId;

  const LoadNotificationPreferences(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update notification preferences
class UpdateNotificationPreferences extends NotificationEvent {
  final String userId;
  final NotificationPreferences preferences;

  const UpdateNotificationPreferences(this.userId, this.preferences);

  @override
  List<Object?> get props => [userId, preferences];
}

/// Load activity feed for a group
class LoadGroupActivity extends NotificationEvent {
  final String groupId;
  final int limit;
  final DateTime? before;

  const LoadGroupActivity(this.groupId, {this.limit = 50, this.before});

  @override
  List<Object?> get props => [groupId, limit, before];
}

/// Subscribe to activity feed
class SubscribeToGroupActivity extends NotificationEvent {
  final String groupId;

  const SubscribeToGroupActivity(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Internal event: Notifications updated from stream
class NotificationsUpdated extends NotificationEvent {
  final List<NotificationEntity> notifications;

  const NotificationsUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

/// Internal event: Activity updated from stream
class ActivityUpdated extends NotificationEvent {
  final List<ActivityEntity> activities;

  const ActivityUpdated(this.activities);

  @override
  List<Object?> get props => [activities];
}
