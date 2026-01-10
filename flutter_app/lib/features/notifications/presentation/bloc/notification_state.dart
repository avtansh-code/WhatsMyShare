import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_entity.dart';

/// State for notifications
class NotificationState extends Equatable {
  final List<NotificationEntity> notifications;
  final List<ActivityEntity> activities;
  final NotificationPreferences? preferences;
  final int unreadCount;
  final bool isLoading;
  final bool isLoadingPreferences;
  final bool isLoadingActivity;
  final String? errorMessage;
  final String? successMessage;

  const NotificationState({
    this.notifications = const [],
    this.activities = const [],
    this.preferences,
    this.unreadCount = 0,
    this.isLoading = false,
    this.isLoadingPreferences = false,
    this.isLoadingActivity = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Initial state
  factory NotificationState.initial() {
    return const NotificationState();
  }

  /// Copy with
  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    List<ActivityEntity>? activities,
    NotificationPreferences? preferences,
    int? unreadCount,
    bool? isLoading,
    bool? isLoadingPreferences,
    bool? isLoadingActivity,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      activities: activities ?? this.activities,
      preferences: preferences ?? this.preferences,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingPreferences: isLoadingPreferences ?? this.isLoadingPreferences,
      isLoadingActivity: isLoadingActivity ?? this.isLoadingActivity,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  /// Calculate unread count from notifications
  int get calculatedUnreadCount => notifications.where((n) => !n.isRead).length;

  /// Check if has unread notifications
  bool get hasUnread => unreadCount > 0 || calculatedUnreadCount > 0;

  @override
  List<Object?> get props => [
    notifications,
    activities,
    preferences,
    unreadCount,
    isLoading,
    isLoadingPreferences,
    isLoadingActivity,
    errorMessage,
    successMessage,
  ];
}
