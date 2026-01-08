import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/features/notifications/domain/entities/notification_entity.dart';
import 'package:whats_my_share/features/notifications/domain/repositories/notification_repository.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_event.dart';
import 'package:whats_my_share/features/notifications/presentation/bloc/notification_state.dart';

// Mock classes
class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;
  late NotificationBloc notificationBloc;

  final testDate = DateTime(2024, 1, 15, 10, 30);

  final testNotifications = [
    NotificationEntity(
      id: 'notif-1',
      userId: 'user-123',
      type: NotificationType.expenseAdded,
      title: 'New Expense',
      body: 'John added an expense',
      isRead: false,
      createdAt: testDate,
    ),
    NotificationEntity(
      id: 'notif-2',
      userId: 'user-123',
      type: NotificationType.settlementRequest,
      title: 'Settlement Request',
      body: 'Jane requested settlement',
      isRead: true,
      createdAt: testDate.subtract(const Duration(hours: 1)),
    ),
  ];

  final testActivities = [
    ActivityEntity(
      id: 'act-1',
      groupId: 'group-123',
      type: ActivityType.expenseAdded,
      actorId: 'user-1',
      actorName: 'John',
      title: 'New Expense',
      description: 'added a new expense',
      createdAt: testDate,
    ),
  ];

  final testPreferences = NotificationPreferences(
    expenseNotifications: true,
    settlementNotifications: true,
    reminderNotifications: true,
    groupNotifications: true,
    emailNotifications: false,
    pushEnabled: true,
  );

  setUp(() {
    mockRepository = MockNotificationRepository();
    notificationBloc = NotificationBloc(repository: mockRepository);
  });

  tearDown(() {
    notificationBloc.close();
  });

  group('NotificationBloc', () {
    test('initial state is correct', () {
      expect(notificationBloc.state.notifications, isEmpty);
      expect(notificationBloc.state.unreadCount, 0);
      expect(notificationBloc.state.isLoading, isFalse);
    });

    group('LoadNotifications', () {
      blocTest<NotificationBloc, NotificationState>(
        'emits [loading, loaded] when loading succeeds',
        build: () {
          when(
            () => mockRepository.getNotifications(
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            ),
          ).thenAnswer((_) async => Right(testNotifications));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoading,
            'isLoading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.notifications.length, 'notifications', 2)
              .having((s) => s.unreadCount, 'unreadCount', 1),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getNotifications(
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            ),
          ).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits [loading, error] when loading fails',
        build: () {
          when(
            () => mockRepository.getNotifications(
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            ),
          ).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoading,
            'isLoading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('MarkNotificationAsRead', () {
      blocTest<NotificationBloc, NotificationState>(
        'marks notification as read when succeeds',
        seed: () =>
            NotificationState(notifications: testNotifications, unreadCount: 1),
        build: () {
          when(
            () => mockRepository.markAsRead(any()),
          ).thenAnswer((_) async => const Right(null));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const MarkNotificationAsRead('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.unreadCount, 'unreadCount', 0)
              .having(
                (s) =>
                    s.notifications.firstWhere((n) => n.id == 'notif-1').isRead,
                'isRead',
                true,
              ),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when marking fails',
        seed: () => NotificationState(notifications: testNotifications),
        build: () {
          when(() => mockRepository.markAsRead(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const MarkNotificationAsRead('notif-1')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('MarkAllNotificationsAsRead', () {
      blocTest<NotificationBloc, NotificationState>(
        'marks all as read when succeeds',
        seed: () =>
            NotificationState(notifications: testNotifications, unreadCount: 1),
        build: () {
          when(
            () => mockRepository.markAllAsRead(any()),
          ).thenAnswer((_) async => const Right(null));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const MarkAllNotificationsAsRead('user-123')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.unreadCount, 'unreadCount', 0)
              .having(
                (s) => s.notifications.every((n) => n.isRead),
                'allRead',
                true,
              )
              .having((s) => s.successMessage, 'successMessage', isNotNull),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when marking all fails',
        seed: () => NotificationState(notifications: testNotifications),
        build: () {
          when(() => mockRepository.markAllAsRead(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const MarkAllNotificationsAsRead('user-123')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('DeleteNotification', () {
      blocTest<NotificationBloc, NotificationState>(
        'deletes notification when succeeds',
        seed: () => NotificationState(notifications: testNotifications),
        build: () {
          when(
            () => mockRepository.deleteNotification(any()),
          ).thenAnswer((_) async => const Right(null));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const DeleteNotification('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.length, 'count', 1)
              .having(
                (s) => s.notifications.any((n) => n.id == 'notif-1'),
                'exists',
                false,
              ),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when delete fails',
        seed: () => NotificationState(notifications: testNotifications),
        build: () {
          when(() => mockRepository.deleteNotification(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const DeleteNotification('notif-1')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ],
      );
    });

    group('DeleteReadNotifications', () {
      blocTest<NotificationBloc, NotificationState>(
        'deletes read notifications when succeeds',
        seed: () => NotificationState(notifications: testNotifications),
        build: () {
          when(
            () => mockRepository.deleteReadNotifications(any()),
          ).thenAnswer((_) async => const Right(null));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const DeleteReadNotifications('user-123')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.length, 'count', 1)
              .having(
                (s) => s.notifications.every((n) => !n.isRead),
                'unread',
                true,
              )
              .having((s) => s.successMessage, 'successMessage', isNotNull),
        ],
      );
    });

    group('LoadNotificationPreferences', () {
      blocTest<NotificationBloc, NotificationState>(
        'loads preferences when succeeds',
        build: () {
          when(
            () => mockRepository.getPreferences(any()),
          ).thenAnswer((_) async => Right(testPreferences));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadNotificationPreferences('user-123')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoadingPreferences,
            'loading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoadingPreferences, 'loading', false)
              .having((s) => s.preferences, 'preferences', isNotNull),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when loading preferences fails',
        build: () {
          when(() => mockRepository.getPreferences(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadNotificationPreferences('user-123')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoadingPreferences,
            'loading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoadingPreferences, 'loading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('UpdateNotificationPreferences', () {
      blocTest<NotificationBloc, NotificationState>(
        'updates preferences when succeeds',
        build: () {
          when(
            () => mockRepository.updatePreferences('user-123', testPreferences),
          ).thenAnswer((_) async => const Right(null));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(
          UpdateNotificationPreferences('user-123', testPreferences),
        ),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoadingPreferences,
            'loading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoadingPreferences, 'loading', false)
              .having((s) => s.preferences, 'preferences', testPreferences)
              .having((s) => s.successMessage, 'successMessage', isNotNull),
        ],
      );
    });

    group('LoadGroupActivity', () {
      blocTest<NotificationBloc, NotificationState>(
        'loads activities when succeeds',
        build: () {
          when(
            () => mockRepository.getGroupActivity(
              'group-123',
              limit: 50,
              before: null,
            ),
          ).thenAnswer((_) async => Right(testActivities));
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadGroupActivity('group-123')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoadingActivity,
            'loading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoadingActivity, 'loading', false)
              .having((s) => s.activities.length, 'activities', 1),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when loading activity fails',
        build: () {
          when(
            () => mockRepository.getGroupActivity(
              'group-123',
              limit: 50,
              before: null,
            ),
          ).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return notificationBloc;
        },
        act: (bloc) => bloc.add(const LoadGroupActivity('group-123')),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.isLoadingActivity,
            'loading',
            true,
          ),
          isA<NotificationState>()
              .having((s) => s.isLoadingActivity, 'loading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('NotificationsUpdated', () {
      blocTest<NotificationBloc, NotificationState>(
        'updates notifications from stream',
        build: () => notificationBloc,
        act: (bloc) => bloc.add(NotificationsUpdated(testNotifications)),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.length, 'count', 2)
              .having((s) => s.unreadCount, 'unreadCount', 1),
        ],
      );
    });

    group('ActivityUpdated', () {
      blocTest<NotificationBloc, NotificationState>(
        'updates activities from stream',
        build: () => notificationBloc,
        act: (bloc) => bloc.add(ActivityUpdated(testActivities)),
        expect: () => [
          isA<NotificationState>().having(
            (s) => s.activities.length,
            'count',
            1,
          ),
        ],
      );
    });
  });

  group('NotificationState', () {
    test('initial state has correct defaults', () {
      final state = NotificationState.initial();
      expect(state.notifications, isEmpty);
      expect(state.activities, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('hasUnread returns true when unreadCount > 0', () {
      const state = NotificationState(unreadCount: 5);
      expect(state.hasUnread, isTrue);
    });

    test('hasUnread returns false when unreadCount is 0', () {
      const state = NotificationState(unreadCount: 0);
      expect(state.hasUnread, isFalse);
    });

    test('calculatedUnreadCount counts unread notifications', () {
      final state = NotificationState(notifications: testNotifications);
      expect(state.calculatedUnreadCount, 1);
    });

    test('copyWith creates copy with new values', () {
      final state = NotificationState.initial();
      final newState = state.copyWith(isLoading: true);
      expect(newState.isLoading, isTrue);
    });

    test('copyWith clearError clears errorMessage', () {
      const state = NotificationState(errorMessage: 'Error');
      final newState = state.copyWith(clearError: true);
      expect(newState.errorMessage, isNull);
    });

    test('copyWith clearSuccess clears successMessage', () {
      const state = NotificationState(successMessage: 'Success');
      final newState = state.copyWith(clearSuccess: true);
      expect(newState.successMessage, isNull);
    });

    test('props contain all state fields', () {
      final state = NotificationState(
        notifications: testNotifications,
        activities: testActivities,
        preferences: testPreferences,
        unreadCount: 1,
        isLoading: true,
        errorMessage: 'Error',
      );
      expect(state.props.length, 9);
    });
  });

  group('NotificationEvent', () {
    test('LoadNotifications props contain limit', () {
      const event = LoadNotifications(limit: 100);
      expect(event.props, contains(100));
    });

    test('SubscribeToNotifications props contain userId', () {
      const event = SubscribeToNotifications('user-123');
      expect(event.props, contains('user-123'));
    });

    test('MarkNotificationAsRead props contain notificationId', () {
      const event = MarkNotificationAsRead('notif-1');
      expect(event.props, contains('notif-1'));
    });

    test('DeleteNotification props contain notificationId', () {
      const event = DeleteNotification('notif-1');
      expect(event.props, contains('notif-1'));
    });

    test('LoadGroupActivity props contain groupId', () {
      const event = LoadGroupActivity('group-123');
      expect(event.props, contains('group-123'));
    });

    test('UpdateNotificationPreferences props contain preferences', () {
      final event = UpdateNotificationPreferences('user-123', testPreferences);
      expect(event.props, contains(testPreferences));
    });
  });
}
