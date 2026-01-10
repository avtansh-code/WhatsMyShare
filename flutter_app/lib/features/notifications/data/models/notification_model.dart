import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_entity.dart';

/// Firestore model for NotificationEntity
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    super.deepLink,
    super.groupId,
    super.groupName,
    super.senderId,
    super.senderName,
    super.isRead = false,
    super.readAt,
    required super.createdAt,
    super.metadata,
  });

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationTypeExtension.fromString(data['type'] ?? 'system'),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      deepLink: data['deepLink'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      title: entity.title,
      body: entity.body,
      deepLink: entity.deepLink,
      groupId: entity.groupId,
      groupName: entity.groupName,
      senderId: entity.senderId,
      senderName: entity.senderName,
      isRead: entity.isRead,
      readAt: entity.readAt,
      createdAt: entity.createdAt,
      metadata: entity.metadata,
    );
  }

  /// Convert to Firestore map for creating
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'deepLink': deepLink,
      'groupId': groupId,
      'groupName': groupName,
      'senderId': senderId,
      'senderName': senderName,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  /// Convert to Firestore map for updating
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}

/// Firestore model for ActivityEntity
class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    required super.groupId,
    required super.type,
    required super.actorId,
    required super.actorName,
    super.actorPhotoUrl,
    super.targetId,
    super.targetType,
    required super.title,
    super.description,
    super.amount,
    super.currency,
    required super.createdAt,
    super.metadata,
  });

  /// Create from Firestore document
  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      type: ActivityTypeExtension.fromString(data['type'] ?? 'group_updated'),
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorPhotoUrl: data['actorPhotoUrl'],
      targetId: data['targetId'],
      targetType: data['targetType'],
      title: data['title'] ?? '',
      description: data['description'],
      amount: data['amount'],
      currency: data['currency'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from entity
  factory ActivityModel.fromEntity(ActivityEntity entity) {
    return ActivityModel(
      id: entity.id,
      groupId: entity.groupId,
      type: entity.type,
      actorId: entity.actorId,
      actorName: entity.actorName,
      actorPhotoUrl: entity.actorPhotoUrl,
      targetId: entity.targetId,
      targetType: entity.targetType,
      title: entity.title,
      description: entity.description,
      amount: entity.amount,
      currency: entity.currency,
      createdAt: entity.createdAt,
      metadata: entity.metadata,
    );
  }

  /// Convert to Firestore map for creating
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'groupId': groupId,
      'type': type.value,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'targetId': targetId,
      'targetType': targetType,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }
}
