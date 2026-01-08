import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLoC for managing notifications and activity feed
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

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
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getNotifications(
      limit: event.limit,
      before: event.before,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (notifications) => emit(
        state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: notifications.where((n) => !n.isRead).length,
        ),
      ),
    );
  }

  void _onSubscribeToNotifications(
    SubscribeToNotifications event,
    Emitter<NotificationState> emit,
  ) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _repository
        .watchNotifications(event.userId)
        .listen((notifications) {
          add(NotificationsUpdated(notifications));
        });
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
    final result = await _repository.markAsRead(event.notificationId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
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
    final result = await _repository.markAllAsRead(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
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
    final result = await _repository.deleteNotification(event.notificationId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
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
    final result = await _repository.deleteReadNotifications(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
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
    emit(state.copyWith(isLoadingPreferences: true));

    final result = await _repository.getPreferences(event.userId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingPreferences: false,
          errorMessage: failure.message,
        ),
      ),
      (preferences) => emit(
        state.copyWith(isLoadingPreferences: false, preferences: preferences),
      ),
    );
  }

  Future<void> _onUpdatePreferences(
    UpdateNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoadingPreferences: true));

    final result = await _repository.updatePreferences(
      event.userId,
      event.preferences,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingPreferences: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isLoadingPreferences: false,
          preferences: event.preferences,
          successMessage: 'Preferences updated',
        ),
      ),
    );
  }

  Future<void> _onLoadGroupActivity(
    LoadGroupActivity event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoadingActivity: true, clearError: true));

    final result = await _repository.getGroupActivity(
      event.groupId,
      limit: event.limit,
      before: event.before,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingActivity: false, errorMessage: failure.message),
      ),
      (activities) => emit(
        state.copyWith(isLoadingActivity: false, activities: activities),
      ),
    );
  }

  void _onSubscribeToGroupActivity(
    SubscribeToGroupActivity event,
    Emitter<NotificationState> emit,
  ) {
    _activitySubscription?.cancel();
    _activitySubscription = _repository
        .watchGroupActivity(event.groupId)
        .listen((activities) {
          add(ActivityUpdated(activities));
        });
  }

  void _onActivityUpdated(
    ActivityUpdated event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(activities: event.activities));
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _activitySubscription?.cancel();
    return super.close();
  }
}
