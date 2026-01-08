import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
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

  NotificationDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

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
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get notifications',
      );
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: false).count().get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get unread count');
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notificationsRef(userId).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to mark notification as read',
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadSnapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: false).get();

      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to mark all as read');
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationsRef(userId).doc(notificationId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete notification',
      );
    }
  }

  @override
  Future<void> deleteReadNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final readSnapshot = await _notificationsRef(
        userId,
      ).where('isRead', isEqualTo: true).get();

      for (final doc in readSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete read notifications',
      );
    }
  }

  @override
  Future<NotificationPreferences> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return const NotificationPreferences();
      }

      final data = doc.data();
      final preferencesData =
          data?['notificationPreferences'] as Map<String, dynamic>?;

      if (preferencesData == null) {
        return const NotificationPreferences();
      }

      return NotificationPreferences.fromMap(preferencesData);
    } on FirebaseException catch (e) {
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
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'notificationPreferences': preferences.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update notification preferences',
      );
    }
  }

  @override
  Future<void> registerFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to register FCM token',
      );
    }
  }

  @override
  Future<void> unregisterFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
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
      return snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get activity feed',
      );
    }
  }

  @override
  Stream<List<ActivityModel>> watchGroupActivity(String groupId) {
    return _activityRef(groupId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      final docRef = await _activityRef(
        activity.groupId,
      ).add(activity.toFirestoreCreate());

      final doc = await docRef.get();
      return ActivityModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to create activity');
    }
  }
}
