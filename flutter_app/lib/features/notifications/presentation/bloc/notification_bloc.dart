import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLoC for managing notifications and activity feed
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final LoggingService _log = LoggingService();

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _activitySubscription;

  NotificationBloc({required NotificationRepository repository})
    : _repository = repository,
      super(NotificationState.initial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<SubscribeToNotifications>(_onSubscribeToNotifications);
    on<NotificationsUpdated>(_onNotificationsUpdated);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteReadNotifications>(_onDeleteReadNotifications);
    on<LoadNotificationPreferences>(_onLoadPreferences);
    on<UpdateNotificationPreferences>(_onUpdatePreferences);
    on<LoadGroupActivity>(_onLoadGroupActivity);
    on<SubscribeToGroupActivity>(_onSubscribeToGroupActivity);
    on<ActivityUpdated>(_onActivityUpdated);

    _log.info('NotificationBloc initialized', tag: LogTags.notifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    _log.debug(
      'Loading notifications',
      tag: LogTags.notifications,
      data: {'limit': event.limit},
    );
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getNotifications(
      limit: event.limit,
      before: event.before,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to load notifications',
          tag: LogTags.notifications,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: ErrorMessages.notificationLoadFailed,
          ),
        );
      },
      (notifications) {
        _log.info(
          'Notifications loaded successfully',
          tag: LogTags.notifications,
          data: {'count': notifications.length},
        );
        emit(
          state.copyWith(
            isLoading: false,
            notifications: notifications,
            unreadCount: notifications.where((n) => !n.isRead).length,
          ),
        );
      },
    );
  }

  void _onSubscribeToNotifications(
    SubscribeToNotifications event,
    Emitter<NotificationState> emit,
  ) {
    _log.debug(
      'Subscribing to notifications',
      tag: LogTags.notifications,
      data: {'userId': event.userId},
    );
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _repository
        .watchNotifications(event.userId)
        .listen(
          (notifications) {
            _log.debug(
              'Notifications stream updated',
              tag: LogTags.notifications,
              data: {'count': notifications.length},
            );
            add(NotificationsUpdated(notifications));
          },
          onError: (error, stackTrace) {
            _log.error(
              'Notifications stream error',
              tag: LogTags.notifications,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _onNotificationsUpdated(
    NotificationsUpdated event,
    Emitter<NotificationState> emit,
  ) {
    emit(
      state.copyWith(
        notifications: event.notifications,
        unreadCount: event.notifications.where((n) => !n.isRead).length,
      ),
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    _log.debug(
      'Marking notification as read',
      tag: LogTags.notifications,
      data: {'notificationId': event.notificationId},
    );
    final result = await _repository.markAsRead(event.notificationId);

    result.fold(
      (failure) {
        _log.warning(
          'Failed to mark notification as read',
          tag: LogTags.notifications,
          data: {
            'notificationId': event.notificationId,
            'error': failure.message,
          },
        );
        emit(
          state.copyWith(errorMessage: ErrorMessages.notificationUpdateFailed),
        );
      },
      (_) {
        _log.debug('Notification marked as read', tag: LogTags.notifications);
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.markAsRead();
          }
          return n;
        }).toList();

        emit(
          state.copyWith(
            notifications: updatedNotifications,
            unreadCount: updatedNotifications.where((n) => !n.isRead).length,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    _log.info(
      'Marking all notifications as read',
      tag: LogTags.notifications,
      data: {'userId': event.userId},
    );
    final result = await _repository.markAllAsRead(event.userId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to mark all notifications as read',
          tag: LogTags.notifications,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(errorMessage: ErrorMessages.notificationUpdateFailed),
        );
      },
      (_) {
        _log.info(
          'All notifications marked as read',
          tag: LogTags.notifications,
        );
        // Update local state
        final updatedNotifications = state.notifications
            .map((n) => n.markAsRead())
            .toList();

        emit(
          state.copyWith(
            notifications: updatedNotifications,
            unreadCount: 0,
            successMessage: 'All notifications marked as read',
          ),
        );
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    _log.debug(
      'Deleting notification',
      tag: LogTags.notifications,
      data: {'notificationId': event.notificationId},
    );
    final result = await _repository.deleteNotification(event.notificationId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete notification',
          tag: LogTags.notifications,
          data: {
            'notificationId': event.notificationId,
            'error': failure.message,
          },
        );
        emit(
          state.copyWith(errorMessage: ErrorMessages.notificationDeleteFailed),
        );
      },
      (_) {
        _log.debug('Notification deleted', tag: LogTags.notifications);
        // Update local state
        final updatedNotifications = state.notifications
            .where((n) => n.id != event.notificationId)
            .toList();

        emit(
          state.copyWith(
            notifications: updatedNotifications,
            unreadCount: updatedNotifications.where((n) => !n.isRead).length,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteReadNotifications(
    DeleteReadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    _log.info(
      'Deleting read notifications',
      tag: LogTags.notifications,
      data: {'userId': event.userId},
    );
    final result = await _repository.deleteReadNotifications(event.userId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete read notifications',
          tag: LogTags.notifications,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(errorMessage: ErrorMessages.notificationDeleteFailed),
        );
      },
      (_) {
        _log.info('Read notifications deleted', tag: LogTags.notifications);
        // Update local state - keep only unread
        final updatedNotifications = state.notifications
            .where((n) => !n.isRead)
            .toList();

        emit(
          state.copyWith(
            notifications: updatedNotifications,
            successMessage: 'Read notifications cleared',
          ),
        );
      },
    );
  }

  Future<void> _onLoadPreferences(
    LoadNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    _log.debug(
      'Loading notification preferences',
      tag: LogTags.notifications,
      data: {'userId': event.userId},
    );
    emit(state.copyWith(isLoadingPreferences: true));

    final result = await _repository.getPreferences(event.userId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to load notification preferences',
          tag: LogTags.notifications,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(
            isLoadingPreferences: false,
            errorMessage: ErrorMessages.notificationPreferencesLoadFailed,
          ),
        );
      },
      (preferences) {
        _log.debug(
          'Notification preferences loaded',
          tag: LogTags.notifications,
        );
        emit(
          state.copyWith(isLoadingPreferences: false, preferences: preferences),
        );
      },
    );
  }

  Future<void> _onUpdatePreferences(
    UpdateNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    _log.info(
      'Updating notification preferences',
      tag: LogTags.notifications,
      data: {'userId': event.userId},
    );
    emit(state.copyWith(isLoadingPreferences: true));

    final result = await _repository.updatePreferences(
      event.userId,
      event.preferences,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to update notification preferences',
          tag: LogTags.notifications,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(
            isLoadingPreferences: false,
            errorMessage: ErrorMessages.notificationPreferencesSaveFailed,
          ),
        );
      },
      (_) {
        _log.info(
          'Notification preferences updated',
          tag: LogTags.notifications,
        );
        emit(
          state.copyWith(
            isLoadingPreferences: false,
            preferences: event.preferences,
            successMessage: 'Preferences updated',
          ),
        );
      },
    );
  }

  Future<void> _onLoadGroupActivity(
    LoadGroupActivity event,
    Emitter<NotificationState> emit,
  ) async {
    _log.debug(
      'Loading group activity',
      tag: LogTags.notifications,
      data: {'groupId': event.groupId, 'limit': event.limit},
    );
    emit(state.copyWith(isLoadingActivity: true, clearError: true));

    final result = await _repository.getGroupActivity(
      event.groupId,
      limit: event.limit,
      before: event.before,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to load group activity',
          tag: LogTags.notifications,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            isLoadingActivity: false,
            errorMessage: ErrorMessages.notificationActivityLoadFailed,
          ),
        );
      },
      (activities) {
        _log.info(
          'Group activity loaded',
          tag: LogTags.notifications,
          data: {'groupId': event.groupId, 'count': activities.length},
        );
        emit(state.copyWith(isLoadingActivity: false, activities: activities));
      },
    );
  }

  void _onSubscribeToGroupActivity(
    SubscribeToGroupActivity event,
    Emitter<NotificationState> emit,
  ) {
    _log.debug(
      'Subscribing to group activity',
      tag: LogTags.notifications,
      data: {'groupId': event.groupId},
    );
    _activitySubscription?.cancel();
    _activitySubscription = _repository
        .watchGroupActivity(event.groupId)
        .listen(
          (activities) {
            _log.debug(
              'Activity stream updated',
              tag: LogTags.notifications,
              data: {'count': activities.length},
            );
            add(ActivityUpdated(activities));
          },
          onError: (error, stackTrace) {
            _log.error(
              'Activity stream error',
              tag: LogTags.notifications,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _onActivityUpdated(
    ActivityUpdated event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(activities: event.activities));
  }

  @override
  Future<void> close() {
    _log.debug('NotificationBloc closing', tag: LogTags.notifications);
    _notificationsSubscription?.cancel();
    _activitySubscription?.cancel();
    return super.close();
  }
}
