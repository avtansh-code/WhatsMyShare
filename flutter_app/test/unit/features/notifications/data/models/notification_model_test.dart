import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/notifications/data/models/notification_model.dart';
import 'package:whats_my_share/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationModel', () {
    final testCreatedAt = DateTime(2026, 1, 9, 10, 0, 0);
    final testReadAt = DateTime(2026, 1, 9, 12, 0, 0);

    group('fromEntity', () {
      test(
        'creates NotificationModel from NotificationEntity with all fields',
        () {
          final entity = NotificationEntity(
            id: 'notif-123',
            userId: 'user-456',
            type: NotificationType.expenseAdded,
            title: 'New Expense',
            body: 'John added a new expense',
            deepLink: '/groups/g1/expenses/e1',
            groupId: 'group-789',
            groupName: 'Trip Group',
            senderId: 'sender-111',
            senderName: 'John Doe',
            isRead: false,
            readAt: null,
            createdAt: testCreatedAt,
            metadata: {'amount': 5000},
          );

          final model = NotificationModel.fromEntity(entity);

          expect(model.id, equals('notif-123'));
          expect(model.userId, equals('user-456'));
          expect(model.type, equals(NotificationType.expenseAdded));
          expect(model.title, equals('New Expense'));
          expect(model.body, equals('John added a new expense'));
          expect(model.deepLink, equals('/groups/g1/expenses/e1'));
          expect(model.groupId, equals('group-789'));
          expect(model.groupName, equals('Trip Group'));
          expect(model.senderId, equals('sender-111'));
          expect(model.senderName, equals('John Doe'));
          expect(model.isRead, isFalse);
          expect(model.metadata?['amount'], equals(5000));
        },
      );

      test('creates NotificationModel from read notification', () {
        final entity = NotificationEntity(
          id: 'notif-123',
          userId: 'user-456',
          type: NotificationType.system,
          title: 'System Update',
          body: 'App updated',
          isRead: true,
          readAt: testReadAt,
          createdAt: testCreatedAt,
        );

        final model = NotificationModel.fromEntity(entity);

        expect(model.isRead, isTrue);
        expect(model.readAt, equals(testReadAt));
      });
    });

    group('toFirestoreCreate', () {
      test('converts NotificationModel to Firestore map for creation', () {
        final model = NotificationModel(
          id: 'notif-123',
          userId: 'user-456',
          type: NotificationType.settlementRequest,
          title: 'Settlement Request',
          body: 'John requested a settlement',
          deepLink: '/settlements/s1',
          groupId: 'group-789',
          groupName: 'Trip Group',
          senderId: 'sender-111',
          senderName: 'John Doe',
          isRead: false,
          createdAt: testCreatedAt,
          metadata: {'settlementId': 's1'},
        );

        final map = model.toFirestoreCreate();

        expect(map['userId'], equals('user-456'));
        expect(map['type'], equals('settlement_request'));
        expect(map['title'], equals('Settlement Request'));
        expect(map['body'], equals('John requested a settlement'));
        expect(map['deepLink'], equals('/settlements/s1'));
        expect(map['groupId'], equals('group-789'));
        expect(map['groupName'], equals('Trip Group'));
        expect(map['senderId'], equals('sender-111'));
        expect(map['senderName'], equals('John Doe'));
        expect(map['isRead'], isFalse);
        expect(map['readAt'], isNull);
        expect(map['metadata'], isNotNull);
      });

      test('converts notification type to string correctly', () {
        for (final type in NotificationType.values) {
          final model = NotificationModel(
            id: 'id',
            userId: 'uid',
            type: type,
            title: 'Title',
            body: 'Body',
            createdAt: testCreatedAt,
          );

          final map = model.toFirestoreCreate();
          expect(map['type'], equals(type.value));
        }
      });
    });

    group('toFirestoreUpdate', () {
      test('includes only read status in update map', () {
        final model = NotificationModel(
          id: 'notif-123',
          userId: 'user-456',
          type: NotificationType.expenseAdded,
          title: 'Title',
          body: 'Body',
          isRead: true,
          readAt: testReadAt,
          createdAt: testCreatedAt,
        );

        final map = model.toFirestoreUpdate();

        expect(map['isRead'], isTrue);
        expect(map.containsKey('readAt'), isTrue);
        expect(map.containsKey('title'), isFalse);
        expect(map.containsKey('body'), isFalse);
      });
    });
  });

  group('NotificationEntity', () {
    final testCreatedAt = DateTime(2026, 1, 9, 10, 0, 0);

    test('copyWith creates copy with updated fields', () {
      final original = NotificationEntity(
        id: 'notif-123',
        userId: 'user-456',
        type: NotificationType.expenseAdded,
        title: 'Original Title',
        body: 'Original Body',
        isRead: false,
        createdAt: testCreatedAt,
      );

      final updated = original.copyWith(title: 'Updated Title', isRead: true);

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.isRead, isTrue);
      expect(updated.body, equals(original.body));
    });

    test('markAsRead sets isRead to true and readAt to current time', () {
      final notification = NotificationEntity(
        id: 'notif-123',
        userId: 'user-456',
        type: NotificationType.system,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: testCreatedAt,
      );

      final read = notification.markAsRead();

      expect(read.isRead, isTrue);
      expect(read.readAt, isNotNull);
    });
  });

  group('NotificationTypeExtension', () {
    test('value returns correct string for each type', () {
      expect(NotificationType.expenseAdded.value, equals('expense_added'));
      expect(NotificationType.expenseUpdated.value, equals('expense_updated'));
      expect(NotificationType.expenseDeleted.value, equals('expense_deleted'));
      expect(
        NotificationType.settlementRequest.value,
        equals('settlement_request'),
      );
      expect(
        NotificationType.settlementConfirmed.value,
        equals('settlement_confirmed'),
      );
      expect(
        NotificationType.settlementRejected.value,
        equals('settlement_rejected'),
      );
      expect(
        NotificationType.groupInvitation.value,
        equals('group_invitation'),
      );
      expect(NotificationType.memberAdded.value, equals('member_added'));
      expect(NotificationType.memberRemoved.value, equals('member_removed'));
      expect(NotificationType.reminder.value, equals('reminder'));
      expect(NotificationType.system.value, equals('system'));
    });

    test('fromString parses all notification types', () {
      expect(
        NotificationTypeExtension.fromString('expense_added'),
        equals(NotificationType.expenseAdded),
      );
      expect(
        NotificationTypeExtension.fromString('expense_updated'),
        equals(NotificationType.expenseUpdated),
      );
      expect(
        NotificationTypeExtension.fromString('expense_deleted'),
        equals(NotificationType.expenseDeleted),
      );
      expect(
        NotificationTypeExtension.fromString('settlement_request'),
        equals(NotificationType.settlementRequest),
      );
      expect(
        NotificationTypeExtension.fromString('settlement_confirmed'),
        equals(NotificationType.settlementConfirmed),
      );
      expect(
        NotificationTypeExtension.fromString('settlement_rejected'),
        equals(NotificationType.settlementRejected),
      );
      expect(
        NotificationTypeExtension.fromString('group_invitation'),
        equals(NotificationType.groupInvitation),
      );
      expect(
        NotificationTypeExtension.fromString('member_added'),
        equals(NotificationType.memberAdded),
      );
      expect(
        NotificationTypeExtension.fromString('member_removed'),
        equals(NotificationType.memberRemoved),
      );
      expect(
        NotificationTypeExtension.fromString('reminder'),
        equals(NotificationType.reminder),
      );
      expect(
        NotificationTypeExtension.fromString('system'),
        equals(NotificationType.system),
      );
    });

    test('fromString defaults to system for unknown type', () {
      expect(
        NotificationTypeExtension.fromString('unknown_type'),
        equals(NotificationType.system),
      );
    });

    test('icon returns emoji for each type', () {
      expect(NotificationType.expenseAdded.icon, equals('💰'));
      expect(NotificationType.settlementRequest.icon, equals('💸'));
      expect(NotificationType.settlementConfirmed.icon, equals('✅'));
      expect(NotificationType.settlementRejected.icon, equals('❌'));
      expect(NotificationType.groupInvitation.icon, equals('👥'));
      expect(NotificationType.reminder.icon, equals('⏰'));
      expect(NotificationType.system.icon, equals('📢'));
    });
  });

  group('ActivityModel', () {
    final testCreatedAt = DateTime(2026, 1, 9, 10, 0, 0);

    group('fromEntity', () {
      test('creates ActivityModel from ActivityEntity', () {
        final entity = ActivityEntity(
          id: 'activity-123',
          groupId: 'group-456',
          type: ActivityType.expenseAdded,
          actorId: 'user-789',
          actorName: 'John Doe',
          actorPhotoUrl: 'https://example.com/photo.jpg',
          targetId: 'expense-111',
          targetType: 'expense',
          title: 'John added Dinner',
          description: '₹500.00',
          amount: 50000,
          currency: 'INR',
          createdAt: testCreatedAt,
          metadata: {'category': 'food'},
        );

        final model = ActivityModel.fromEntity(entity);

        expect(model.id, equals('activity-123'));
        expect(model.groupId, equals('group-456'));
        expect(model.type, equals(ActivityType.expenseAdded));
        expect(model.actorId, equals('user-789'));
        expect(model.actorName, equals('John Doe'));
        expect(model.actorPhotoUrl, equals('https://example.com/photo.jpg'));
        expect(model.targetId, equals('expense-111'));
        expect(model.amount, equals(50000));
        expect(model.currency, equals('INR'));
      });
    });

    group('toFirestoreCreate', () {
      test('converts ActivityModel to Firestore map', () {
        final model = ActivityModel(
          id: 'activity-123',
          groupId: 'group-456',
          type: ActivityType.settlementConfirmed,
          actorId: 'user-789',
          actorName: 'Jane Smith',
          title: 'Settlement Confirmed',
          description: 'Jane confirmed payment',
          amount: 10000,
          currency: 'INR',
          createdAt: testCreatedAt,
        );

        final map = model.toFirestoreCreate();

        expect(map['groupId'], equals('group-456'));
        expect(map['type'], equals('settlement_confirmed'));
        expect(map['actorId'], equals('user-789'));
        expect(map['actorName'], equals('Jane Smith'));
        expect(map['title'], equals('Settlement Confirmed'));
        expect(map['amount'], equals(10000));
        expect(map['currency'], equals('INR'));
      });
    });
  });

  group('ActivityTypeExtension', () {
    test('value returns correct string for each type', () {
      expect(ActivityType.expenseAdded.value, equals('expense_added'));
      expect(ActivityType.expenseUpdated.value, equals('expense_updated'));
      expect(ActivityType.expenseDeleted.value, equals('expense_deleted'));
      expect(
        ActivityType.settlementCreated.value,
        equals('settlement_created'),
      );
      expect(
        ActivityType.settlementConfirmed.value,
        equals('settlement_confirmed'),
      );
      expect(
        ActivityType.settlementRejected.value,
        equals('settlement_rejected'),
      );
      expect(ActivityType.memberAdded.value, equals('member_added'));
      expect(ActivityType.memberRemoved.value, equals('member_removed'));
      expect(ActivityType.groupCreated.value, equals('group_created'));
      expect(ActivityType.groupUpdated.value, equals('group_updated'));
    });

    test('fromString parses all activity types', () {
      expect(
        ActivityTypeExtension.fromString('expense_added'),
        equals(ActivityType.expenseAdded),
      );
      expect(
        ActivityTypeExtension.fromString('expense_updated'),
        equals(ActivityType.expenseUpdated),
      );
      expect(
        ActivityTypeExtension.fromString('settlement_created'),
        equals(ActivityType.settlementCreated),
      );
      expect(
        ActivityTypeExtension.fromString('settlement_confirmed'),
        equals(ActivityType.settlementConfirmed),
      );
      expect(
        ActivityTypeExtension.fromString('member_added'),
        equals(ActivityType.memberAdded),
      );
      expect(
        ActivityTypeExtension.fromString('group_created'),
        equals(ActivityType.groupCreated),
      );
    });

    test('fromString defaults to groupUpdated for unknown type', () {
      expect(
        ActivityTypeExtension.fromString('unknown_type'),
        equals(ActivityType.groupUpdated),
      );
    });

    test('icon returns emoji for each type', () {
      expect(ActivityType.expenseAdded.icon, equals('💰'));
      expect(ActivityType.settlementConfirmed.icon, equals('✅'));
      expect(ActivityType.groupCreated.icon, equals('🎉'));
    });
  });

  group('NotificationPreferences', () {
    test('default values are correct', () {
      const prefs = NotificationPreferences();

      expect(prefs.pushEnabled, isTrue);
      expect(prefs.expenseNotifications, isTrue);
      expect(prefs.settlementNotifications, isTrue);
      expect(prefs.groupNotifications, isTrue);
      expect(prefs.reminderNotifications, isTrue);
      expect(prefs.emailNotifications, isFalse);
      expect(prefs.quietHoursStart, isNull);
      expect(prefs.quietHoursEnd, isNull);
    });

    test('copyWith creates copy with updated fields', () {
      const original = NotificationPreferences();

      final updated = original.copyWith(
        pushEnabled: false,
        expenseNotifications: false,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      expect(updated.pushEnabled, isFalse);
      expect(updated.expenseNotifications, isFalse);
      expect(updated.settlementNotifications, isTrue);
      expect(updated.quietHoursStart, equals('22:00'));
      expect(updated.quietHoursEnd, equals('08:00'));
    });

    test('isTypeEnabled returns false when pushEnabled is false', () {
      const prefs = NotificationPreferences(pushEnabled: false);

      expect(prefs.isTypeEnabled(NotificationType.expenseAdded), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.system), isFalse);
    });

    test('isTypeEnabled checks expenseNotifications for expense types', () {
      const prefs = NotificationPreferences(expenseNotifications: false);

      expect(prefs.isTypeEnabled(NotificationType.expenseAdded), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.expenseUpdated), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.expenseDeleted), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.settlementRequest), isTrue);
    });

    test(
      'isTypeEnabled checks settlementNotifications for settlement types',
      () {
        const prefs = NotificationPreferences(settlementNotifications: false);

        expect(
          prefs.isTypeEnabled(NotificationType.settlementRequest),
          isFalse,
        );
        expect(
          prefs.isTypeEnabled(NotificationType.settlementConfirmed),
          isFalse,
        );
        expect(
          prefs.isTypeEnabled(NotificationType.settlementRejected),
          isFalse,
        );
        expect(prefs.isTypeEnabled(NotificationType.expenseAdded), isTrue);
      },
    );

    test('isTypeEnabled checks groupNotifications for group types', () {
      const prefs = NotificationPreferences(groupNotifications: false);

      expect(prefs.isTypeEnabled(NotificationType.groupInvitation), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.memberAdded), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.memberRemoved), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.expenseAdded), isTrue);
    });

    test('isTypeEnabled checks reminderNotifications for reminder', () {
      const prefs = NotificationPreferences(reminderNotifications: false);

      expect(prefs.isTypeEnabled(NotificationType.reminder), isFalse);
      expect(prefs.isTypeEnabled(NotificationType.system), isTrue);
    });

    test('isTypeEnabled always returns true for system notifications', () {
      const prefs = NotificationPreferences();

      expect(prefs.isTypeEnabled(NotificationType.system), isTrue);
    });

    test('toMap converts to map correctly', () {
      const prefs = NotificationPreferences(
        pushEnabled: true,
        expenseNotifications: false,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      final map = prefs.toMap();

      expect(map['pushEnabled'], isTrue);
      expect(map['expenseNotifications'], isFalse);
      expect(map['quietHoursStart'], equals('22:00'));
      expect(map['quietHoursEnd'], equals('08:00'));
    });

    test('fromMap creates from map correctly', () {
      final map = {
        'pushEnabled': true,
        'expenseNotifications': false,
        'settlementNotifications': true,
        'groupNotifications': true,
        'reminderNotifications': false,
        'emailNotifications': true,
        'quietHoursStart': '23:00',
        'quietHoursEnd': '07:00',
      };

      final prefs = NotificationPreferences.fromMap(map);

      expect(prefs.pushEnabled, isTrue);
      expect(prefs.expenseNotifications, isFalse);
      expect(prefs.settlementNotifications, isTrue);
      expect(prefs.reminderNotifications, isFalse);
      expect(prefs.emailNotifications, isTrue);
      expect(prefs.quietHoursStart, equals('23:00'));
    });

    test('fromMap uses defaults for missing fields', () {
      final prefs = NotificationPreferences.fromMap({});

      expect(prefs.pushEnabled, isTrue);
      expect(prefs.expenseNotifications, isTrue);
      expect(prefs.emailNotifications, isFalse);
    });
  });
}
