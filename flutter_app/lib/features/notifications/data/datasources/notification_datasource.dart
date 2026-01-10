import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

/// Remote data source for notifications using Firestore
abstract class NotificationDataSource {
  /// Get notifications for a user
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
    DateTime? before,
  });

  /// Watch notifications for a user (real-time)
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Get unread notification count
  Future<int> getUnreadCount(String userId);

  /// Watch unread notification count
  Stream<int> watchUnreadCount(String userId);

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId);

  /// Delete all read notifications
  Future<void> deleteReadNotifications(String userId);

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences(String userId);

  /// Update notification preferences
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  );

  /// Register FCM token
  Future<void> registerFcmToken(String userId, String token);

  /// Unregister FCM token
  Future<void> unregisterFcmToken(String userId, String token);

  /// Get activity feed for a group
  Future<List<ActivityModel>> getGroupActivity(
    String groupId, {
    int limit = 50,
    DateTime? before,
  });

  /// Watch activity feed for a group
  Stream<List<ActivityModel>> watchGroupActivity(String groupId);

  /// Create an activity entry
  Future<ActivityModel> createActivity(ActivityModel activity);
}

/// Implementation using Firebase Firestore
class NotificationDataSourceImpl implements NotificationDataSource {
  final FirebaseFirestore _firestore;
  final LoggingService _log = LoggingService();

  NotificationDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore {
    _log.debug(
      'NotificationDataSource initialized',
      tag: LogTags.notifications,
    );
  }

  /// Reference to user's notifications subcollection
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.notificationsCollection);
  }

  /// Reference to group's activity subcollection
  CollectionReference<Map<String, dynamic>> _activityRef(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.activityCollection);
  }

  @override
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
    DateTime? before,
  }) async {
    _log.debug(
      'Fetching notifications',
      tag: LogTags.notifications,
      data: {'userId': userId, 'limit': limit},
    );
    try {
      Query<Map<String, dynamic>> query = _notificationsRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit);

      if (before != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }

      final snapshot = await query.get();
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _log.info(
        'Notifications fetched successfully',
        tag: LogTags.notifications,
        data: {'count': notifications.length},
      );
      return notifications;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get notifications',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to get notifications',
      );
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    _log.debug(
      'Setting up notifications stream',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          _log.debug(
            'Notifications stream updated',
            tag: LogTags.notifications,
            data: {'count': snapshot.docs.length},
          );
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    _log.debug(
      'Getting unread notification count',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final snapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: false).count().get();

      final count = snapshot.count ?? 0;
      _log.debug(
        'Unread count fetched',
        tag: LogTags.notifications,
        data: {'count': count},
      );
      return count;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get unread count',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get unread count');
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    _log.debug(
      'Setting up unread count stream',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    _log.info(
      'Marking notification as read',
      tag: LogTags.notifications,
      data: {'userId': userId, 'notificationId': notificationId},
    );
    try {
      await _notificationsRef(userId).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      _log.debug('Notification marked as read', tag: LogTags.notifications);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to mark notification as read',
        tag: LogTags.notifications,
        data: {'notificationId': notificationId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to mark notification as read',
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    _log.info(
      'Marking all notifications as read',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final batch = _firestore.batch();
      final unreadSnapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: false).get();

      _log.debug(
        'Found unread notifications',
        tag: LogTags.notifications,
        data: {'count': unreadSnapshot.docs.length},
      );
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _log.info('All notifications marked as read', tag: LogTags.notifications);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to mark all as read',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to mark all as read');
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    _log.info(
      'Deleting notification',
      tag: LogTags.notifications,
      data: {'userId': userId, 'notificationId': notificationId},
    );
    try {
      await _notificationsRef(userId).doc(notificationId).delete();
      _log.debug('Notification deleted', tag: LogTags.notifications);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete notification',
        tag: LogTags.notifications,
        data: {'notificationId': notificationId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to delete notification',
      );
    }
  }

  @override
  Future<void> deleteReadNotifications(String userId) async {
    _log.info(
      'Deleting read notifications',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final batch = _firestore.batch();
      final readSnapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: true).get();

      _log.debug(
        'Found read notifications to delete',
        tag: LogTags.notifications,
        data: {'count': readSnapshot.docs.length},
      );
      for (final doc in readSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _log.info('Read notifications deleted', tag: LogTags.notifications);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete read notifications',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to delete read notifications',
      );
    }
  }

  @override
  Future<NotificationPreferences> getPreferences(String userId) async {
    _log.debug(
      'Getting notification preferences',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        _log.debug(
          'User document not found, returning defaults',
          tag: LogTags.notifications,
        );
        return const NotificationPreferences();
      }

      final data = doc.data();
      final preferencesData =
          data?['notificationPreferences'] as Map<String, dynamic>?;

      if (preferencesData == null) {
        _log.debug(
          'No preferences found, returning defaults',
          tag: LogTags.notifications,
        );
        return const NotificationPreferences();
      }

      _log.debug(
        'Preferences fetched successfully',
        tag: LogTags.notifications,
      );
      return NotificationPreferences.fromMap(preferencesData);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get notification preferences',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to get notification preferences',
      );
    }
  }

  @override
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    _log.info(
      'Updating notification preferences',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'notificationPreferences': preferences.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _log.info('Preferences updated successfully', tag: LogTags.notifications);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update notification preferences',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to update notification preferences',
      );
    }
  }

  @override
  Future<void> registerFcmToken(String userId, String token) async {
    _log.info(
      'Registering FCM token',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _log.info(
        'FCM token registered successfully',
        tag: LogTags.notifications,
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to register FCM token',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to register FCM token',
      );
    }
  }

  @override
  Future<void> unregisterFcmToken(String userId, String token) async {
    _log.info(
      'Unregistering FCM token',
      tag: LogTags.notifications,
      data: {'userId': userId},
    );
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _log.info(
        'FCM token unregistered successfully',
        tag: LogTags.notifications,
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to unregister FCM token',
        tag: LogTags.notifications,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to unregister FCM token',
      );
    }
  }

  @override
  Future<List<ActivityModel>> getGroupActivity(
    String groupId, {
    int limit = 50,
    DateTime? before,
  }) async {
    _log.debug(
      'Fetching group activity',
      tag: LogTags.notifications,
      data: {'groupId': groupId, 'limit': limit},
    );
    try {
      Query<Map<String, dynamic>> query = _activityRef(
        groupId,
      ).orderBy('createdAt', descending: true).limit(limit);

      if (before != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }

      final snapshot = await query.get();
      final activities = snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .toList();
      _log.info(
        'Activity fetched successfully',
        tag: LogTags.notifications,
        data: {'groupId': groupId, 'count': activities.length},
      );
      return activities;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get activity feed',
        tag: LogTags.notifications,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to get activity feed',
      );
    }
  }

  @override
  Stream<List<ActivityModel>> watchGroupActivity(String groupId) {
    _log.debug(
      'Setting up activity stream',
      tag: LogTags.notifications,
      data: {'groupId': groupId},
    );
    return _activityRef(groupId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          _log.debug(
            'Activity stream updated',
            tag: LogTags.notifications,
            data: {'count': snapshot.docs.length},
          );
          return snapshot.docs
              .map((doc) => ActivityModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    _log.info(
      'Creating activity',
      tag: LogTags.notifications,
      data: {'groupId': activity.groupId, 'type': activity.type.name},
    );
    try {
      final docRef = await _activityRef(
        activity.groupId,
      ).add(activity.toFirestoreCreate());

      final doc = await docRef.get();
      _log.info(
        'Activity created successfully',
        tag: LogTags.notifications,
        data: {'activityId': docRef.id},
      );
      return ActivityModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to create activity',
        tag: LogTags.notifications,
        data: {'groupId': activity.groupId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to create activity');
    }
  }
}
