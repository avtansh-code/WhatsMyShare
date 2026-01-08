import 'package:equatable/equatable.dart';

/// Types of notifications
enum NotificationType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  settlementRequest,
  settlementConfirmed,
  settlementRejected,
  groupInvitation,
  memberAdded,
  memberRemoved,
  reminder,
  system,
}

/// Extension methods for NotificationType
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.expenseAdded:
        return 'expense_added';
      case NotificationType.expenseUpdated:
        return 'expense_updated';
      case NotificationType.expenseDeleted:
        return 'expense_deleted';
      case NotificationType.settlementRequest:
        return 'settlement_request';
      case NotificationType.settlementConfirmed:
        return 'settlement_confirmed';
      case NotificationType.settlementRejected:
        return 'settlement_rejected';
      case NotificationType.groupInvitation:
        return 'group_invitation';
      case NotificationType.memberAdded:
        return 'member_added';
      case NotificationType.memberRemoved:
        return 'member_removed';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'expense_added':
        return NotificationType.expenseAdded;
      case 'expense_updated':
        return NotificationType.expenseUpdated;
      case 'expense_deleted':
        return NotificationType.expenseDeleted;
      case 'settlement_request':
        return NotificationType.settlementRequest;
      case 'settlement_confirmed':
        return NotificationType.settlementConfirmed;
      case 'settlement_rejected':
        return NotificationType.settlementRejected;
      case 'group_invitation':
        return NotificationType.groupInvitation;
      case 'member_added':
        return NotificationType.memberAdded;
      case 'member_removed':
        return NotificationType.memberRemoved;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  /// Get icon for notification type
  String get icon {
    switch (this) {
      case NotificationType.expenseAdded:
        return '💰';
      case NotificationType.expenseUpdated:
        return '✏️';
      case NotificationType.expenseDeleted:
        return '🗑️';
      case NotificationType.settlementRequest:
        return '💸';
      case NotificationType.settlementConfirmed:
        return '✅';
      case NotificationType.settlementRejected:
        return '❌';
      case NotificationType.groupInvitation:
        return '👥';
      case NotificationType.memberAdded:
        return '➕';
      case NotificationType.memberRemoved:
        return '➖';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.system:
        return '📢';
    }
  }
}

/// Notification entity representing an in-app notification
class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? deepLink;
  final String? groupId;
  final String? groupName;
  final String? senderId;
  final String? senderName;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    this.groupId,
    this.groupName,
    this.senderId,
    this.senderName,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.metadata,
  });

  /// Create a copy with updated fields
  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? deepLink,
    String? groupId,
    String? groupName,
    String? senderId,
    String? senderName,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      deepLink: deepLink ?? this.deepLink,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Mark notification as read
  NotificationEntity markAsRead() {
    return copyWith(isRead: true, readAt: DateTime.now());
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    deepLink,
    groupId,
    senderId,
    isRead,
    readAt,
    createdAt,
  ];
}

/// Activity item for activity feed
class ActivityEntity extends Equatable {
  final String id;
  final String groupId;
  final ActivityType type;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String? targetId;
  final String? targetType;
  final String title;
  final String? description;
  final int? amount;
  final String? currency;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const ActivityEntity({
    required this.id,
    required this.groupId,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    this.targetId,
    this.targetType,
    required this.title,
    this.description,
    this.amount,
    this.currency,
    required this.createdAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    type,
    actorId,
    targetId,
    title,
    createdAt,
  ];
}

/// Types of activities
enum ActivityType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  settlementCreated,
  settlementConfirmed,
  settlementRejected,
  memberAdded,
  memberRemoved,
  groupCreated,
  groupUpdated,
}

/// Extension methods for ActivityType
extension ActivityTypeExtension on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.expenseAdded:
        return 'expense_added';
      case ActivityType.expenseUpdated:
        return 'expense_updated';
      case ActivityType.expenseDeleted:
        return 'expense_deleted';
      case ActivityType.settlementCreated:
        return 'settlement_created';
      case ActivityType.settlementConfirmed:
        return 'settlement_confirmed';
      case ActivityType.settlementRejected:
        return 'settlement_rejected';
      case ActivityType.memberAdded:
        return 'member_added';
      case ActivityType.memberRemoved:
        return 'member_removed';
      case ActivityType.groupCreated:
        return 'group_created';
      case ActivityType.groupUpdated:
        return 'group_updated';
    }
  }

  static ActivityType fromString(String value) {
    switch (value) {
      case 'expense_added':
        return ActivityType.expenseAdded;
      case 'expense_updated':
        return ActivityType.expenseUpdated;
      case 'expense_deleted':
        return ActivityType.expenseDeleted;
      case 'settlement_created':
        return ActivityType.settlementCreated;
      case 'settlement_confirmed':
        return ActivityType.settlementConfirmed;
      case 'settlement_rejected':
        return ActivityType.settlementRejected;
      case 'member_added':
        return ActivityType.memberAdded;
      case 'member_removed':
        return ActivityType.memberRemoved;
      case 'group_created':
        return ActivityType.groupCreated;
      case 'group_updated':
      default:
        return ActivityType.groupUpdated;
    }
  }

  /// Get icon for activity type
  String get icon {
    switch (this) {
      case ActivityType.expenseAdded:
        return '💰';
      case ActivityType.expenseUpdated:
        return '✏️';
      case ActivityType.expenseDeleted:
        return '🗑️';
      case ActivityType.settlementCreated:
        return '💸';
      case ActivityType.settlementConfirmed:
        return '✅';
      case ActivityType.settlementRejected:
        return '❌';
      case ActivityType.memberAdded:
        return '👤';
      case ActivityType.memberRemoved:
        return '👤';
      case ActivityType.groupCreated:
        return '🎉';
      case ActivityType.groupUpdated:
        return '✏️';
    }
  }
}

/// Notification preferences for a user
class NotificationPreferences extends Equatable {
  final bool pushEnabled;
  final bool expenseNotifications;
  final bool settlementNotifications;
  final bool groupNotifications;
  final bool reminderNotifications;
  final bool emailNotifications;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.expenseNotifications = true,
    this.settlementNotifications = true,
    this.groupNotifications = true,
    this.reminderNotifications = true,
    this.emailNotifications = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? expenseNotifications,
    bool? settlementNotifications,
    bool? groupNotifications,
    bool? reminderNotifications,
    bool? emailNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      expenseNotifications: expenseNotifications ?? this.expenseNotifications,
      settlementNotifications:
          settlementNotifications ?? this.settlementNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  /// Check if a notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    if (!pushEnabled) return false;

    switch (type) {
      case NotificationType.expenseAdded:
      case NotificationType.expenseUpdated:
      case NotificationType.expenseDeleted:
        return expenseNotifications;
      case NotificationType.settlementRequest:
      case NotificationType.settlementConfirmed:
      case NotificationType.settlementRejected:
        return settlementNotifications;
      case NotificationType.groupInvitation:
      case NotificationType.memberAdded:
      case NotificationType.memberRemoved:
        return groupNotifications;
      case NotificationType.reminder:
        return reminderNotifications;
      case NotificationType.system:
        return true;
    }
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'expenseNotifications': expenseNotifications,
      'settlementNotifications': settlementNotifications,
      'groupNotifications': groupNotifications,
      'reminderNotifications': reminderNotifications,
      'emailNotifications': emailNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  /// Create from map
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      pushEnabled: map['pushEnabled'] ?? true,
      expenseNotifications: map['expenseNotifications'] ?? true,
      settlementNotifications: map['settlementNotifications'] ?? true,
      groupNotifications: map['groupNotifications'] ?? true,
      reminderNotifications: map['reminderNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      quietHoursStart: map['quietHoursStart'],
      quietHoursEnd: map['quietHoursEnd'],
    );
  }

  @override
  List<Object?> get props => [
    pushEnabled,
    expenseNotifications,
    settlementNotifications,
    groupNotifications,
    reminderNotifications,
    emailNotifications,
    quietHoursStart,
    quietHoursEnd,
  ];
}
