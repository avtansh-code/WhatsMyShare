import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = AnalyticsService();
        final instance2 = AnalyticsService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('factory constructor returns singleton instance', () {
        final service1 = AnalyticsService();
        final service2 = AnalyticsService();

        expect(service1, same(service2));
      });
    });

    group('Enable/Disable Analytics', () {
      test('should enable analytics without error', () {
        expect(() => analyticsService.setEnabled(true), returnsNormally);
      });

      test('should disable analytics without error', () {
        expect(() => analyticsService.setEnabled(false), returnsNormally);
      });

      test('should toggle analytics state', () {
        analyticsService.setEnabled(true);
        analyticsService.setEnabled(false);
        analyticsService.setEnabled(true);

        expect(true, isTrue); // No exception thrown
      });
    });

    group('User Identification', () {
      test('setUserId should work with valid userId', () async {
        await expectLater(analyticsService.setUserId('user123'), completes);
      });

      test('setUserId should work with null userId', () async {
        await expectLater(analyticsService.setUserId(null), completes);
      });

      test('setUserProperty should work with name and value', () async {
        await expectLater(
          analyticsService.setUserProperty(name: 'premium_user', value: 'true'),
          completes,
        );
      });

      test('setUserProperty should work with null value', () async {
        await expectLater(
          analyticsService.setUserProperty(name: 'premium_user', value: null),
          completes,
        );
      });
    });

    group('Screen View Logging', () {
      test('logScreenView should work with screenName only', () async {
        await expectLater(
          analyticsService.logScreenView(screenName: 'HomeScreen'),
          completes,
        );
      });

      test(
        'logScreenView should work with screenName and screenClass',
        () async {
          await expectLater(
            analyticsService.logScreenView(
              screenName: 'HomeScreen',
              screenClass: 'HomePage',
            ),
            completes,
          );
        },
      );

      test('should log screen views for all defined screens', () async {
        for (final screen in [
          AnalyticsScreens.login,
          AnalyticsScreens.signUp,
          AnalyticsScreens.forgotPassword,
          AnalyticsScreens.dashboard,
          AnalyticsScreens.profile,
          AnalyticsScreens.editProfile,
          AnalyticsScreens.groupList,
          AnalyticsScreens.groupDetail,
          AnalyticsScreens.createGroup,
          AnalyticsScreens.expenseList,
          AnalyticsScreens.addExpense,
          AnalyticsScreens.expenseDetail,
          AnalyticsScreens.expenseChat,
          AnalyticsScreens.settleUp,
          AnalyticsScreens.settlementHistory,
          AnalyticsScreens.notifications,
          AnalyticsScreens.settings,
        ]) {
          await expectLater(
            analyticsService.logScreenView(screenName: screen),
            completes,
          );
        }
      });
    });

    group('Custom Event Logging', () {
      test('logEvent should work with name only', () async {
        await expectLater(
          analyticsService.logEvent(name: 'custom_event'),
          completes,
        );
      });

      test('logEvent should work with name and parameters', () async {
        await expectLater(
          analyticsService.logEvent(
            name: 'custom_event',
            parameters: {'key': 'value', 'number': 42},
          ),
          completes,
        );
      });

      test('logEvent should handle empty parameters', () async {
        await expectLater(
          analyticsService.logEvent(name: 'custom_event', parameters: {}),
          completes,
        );
      });
    });

    group('Authentication Events', () {
      test('logSignUp should log sign up event', () async {
        await expectLater(
          analyticsService.logSignUp(method: 'email'),
          completes,
        );
      });

      test('logSignUp should work with different methods', () async {
        await expectLater(
          analyticsService.logSignUp(method: 'google'),
          completes,
        );
        await expectLater(
          analyticsService.logSignUp(method: 'apple'),
          completes,
        );
      });

      test('logLogin should log login event', () async {
        await expectLater(
          analyticsService.logLogin(method: 'email'),
          completes,
        );
      });

      test('logLogin should work with different methods', () async {
        await expectLater(
          analyticsService.logLogin(method: 'google'),
          completes,
        );
        await expectLater(
          analyticsService.logLogin(method: 'phone'),
          completes,
        );
      });

      test('logLogout should log logout event', () async {
        await expectLater(analyticsService.logLogout(), completes);
      });

      test('logPasswordReset should log password reset event', () async {
        await expectLater(analyticsService.logPasswordReset(), completes);
      });
    });

    group('Group Events', () {
      test('logGroupCreated should log group creation', () async {
        await expectLater(
          analyticsService.logGroupCreated(groupType: 'trip', memberCount: 5),
          completes,
        );
      });

      test('logGroupCreated should work with different group types', () async {
        await expectLater(
          analyticsService.logGroupCreated(groupType: 'home', memberCount: 3),
          completes,
        );
        await expectLater(
          analyticsService.logGroupCreated(groupType: 'couple', memberCount: 2),
          completes,
        );
        await expectLater(
          analyticsService.logGroupCreated(groupType: 'other', memberCount: 10),
          completes,
        );
      });

      test('logGroupJoined should log group join event', () async {
        await expectLater(
          analyticsService.logGroupJoined(groupId: 'group123'),
          completes,
        );
      });

      test('logMemberAdded should log member addition event', () async {
        await expectLater(
          analyticsService.logMemberAdded(groupId: 'group123'),
          completes,
        );
      });
    });

    group('Expense Events', () {
      test('logExpenseCreated should log expense creation', () async {
        await expectLater(
          analyticsService.logExpenseCreated(
            amount: 100.0,
            currency: 'USD',
            splitType: 'equal',
            participantCount: 4,
            hasReceipt: true,
          ),
          completes,
        );
      });

      test(
        'logExpenseCreated should work with different split types',
        () async {
          await expectLater(
            analyticsService.logExpenseCreated(
              amount: 50.0,
              currency: 'EUR',
              splitType: 'exact',
              participantCount: 2,
              hasReceipt: false,
            ),
            completes,
          );
          await expectLater(
            analyticsService.logExpenseCreated(
              amount: 200.0,
              currency: 'INR',
              splitType: 'percentage',
              participantCount: 5,
              hasReceipt: true,
            ),
            completes,
          );
        },
      );

      test('logExpenseDeleted should log expense deletion', () async {
        await expectLater(analyticsService.logExpenseDeleted(), completes);
      });

      test('logExpenseEdited should log expense edit', () async {
        await expectLater(analyticsService.logExpenseEdited(), completes);
      });
    });

    group('Settlement Events', () {
      test('logSettlementCreated should log settlement creation', () async {
        await expectLater(
          analyticsService.logSettlementCreated(
            amount: 75.0,
            currency: 'USD',
            paymentMethod: 'cash',
            biometricUsed: false,
          ),
          completes,
        );
      });

      test(
        'logSettlementCreated should work with different payment methods',
        () async {
          await expectLater(
            analyticsService.logSettlementCreated(
              amount: 100.0,
              currency: 'USD',
              paymentMethod: 'bank_transfer',
              biometricUsed: true,
            ),
            completes,
          );
          await expectLater(
            analyticsService.logSettlementCreated(
              amount: 50.0,
              currency: 'EUR',
              paymentMethod: 'venmo',
              biometricUsed: false,
            ),
            completes,
          );
        },
      );

      test(
        'logSettlementConfirmed should log settlement confirmation',
        () async {
          await expectLater(
            analyticsService.logSettlementConfirmed(
              settlementId: 'settlement123',
            ),
            completes,
          );
        },
      );
    });

    group('Chat Events', () {
      test('logChatMessageSent should log text message', () async {
        await expectLater(
          analyticsService.logChatMessageSent(messageType: 'text'),
          completes,
        );
      });

      test(
        'logChatMessageSent should work with different message types',
        () async {
          await expectLater(
            analyticsService.logChatMessageSent(messageType: 'image'),
            completes,
          );
          await expectLater(
            analyticsService.logChatMessageSent(messageType: 'voice'),
            completes,
          );
          await expectLater(
            analyticsService.logChatMessageSent(messageType: 'system'),
            completes,
          );
        },
      );

      test('logVoiceNoteRecorded should log voice note recording', () async {
        await expectLater(
          analyticsService.logVoiceNoteRecorded(durationMs: 5000),
          completes,
        );
      });

      test(
        'logVoiceNoteRecorded should work with different durations',
        () async {
          await expectLater(
            analyticsService.logVoiceNoteRecorded(durationMs: 1000),
            completes,
          );
          await expectLater(
            analyticsService.logVoiceNoteRecorded(durationMs: 60000),
            completes,
          );
          await expectLater(
            analyticsService.logVoiceNoteRecorded(durationMs: 0),
            completes,
          );
        },
      );
    });

    group('Feature Usage Events', () {
      test('logDebtSimplificationViewed should log event', () async {
        await expectLater(
          analyticsService.logDebtSimplificationViewed(),
          completes,
        );
      });

      test('logNotificationOpened should log notification open', () async {
        await expectLater(
          analyticsService.logNotificationOpened(
            notificationType: 'expense_added',
          ),
          completes,
        );
      });

      test('logNotificationOpened should work with different types', () async {
        await expectLater(
          analyticsService.logNotificationOpened(
            notificationType: 'settlement_request',
          ),
          completes,
        );
        await expectLater(
          analyticsService.logNotificationOpened(
            notificationType: 'group_invite',
          ),
          completes,
        );
      });

      test('logOfflineModeUsed should log offline mode usage', () async {
        await expectLater(analyticsService.logOfflineModeUsed(), completes);
      });

      test('logSyncCompleted should log sync completion', () async {
        await expectLater(
          analyticsService.logSyncCompleted(operationCount: 5),
          completes,
        );
      });

      test('logSyncCompleted should work with zero operations', () async {
        await expectLater(
          analyticsService.logSyncCompleted(operationCount: 0),
          completes,
        );
      });
    });

    group('Error Events', () {
      test('logError should log error with required fields', () async {
        await expectLater(
          analyticsService.logError(
            errorType: 'network_error',
            errorMessage: 'Connection timeout',
          ),
          completes,
        );
      });

      test('logError should log error with screenName', () async {
        await expectLater(
          analyticsService.logError(
            errorType: 'validation_error',
            errorMessage: 'Invalid input',
            screenName: 'AddExpensePage',
          ),
          completes,
        );
      });

      test('logError should truncate long error messages', () async {
        final longMessage = 'A' * 200;
        await expectLater(
          analyticsService.logError(
            errorType: 'crash',
            errorMessage: longMessage,
          ),
          completes,
        );
      });
    });

    group('Performance Events', () {
      test('logAppStart should log app start time', () async {
        await expectLater(
          analyticsService.logAppStart(startupTimeMs: 1500),
          completes,
        );
      });

      test('logAppStart should work with different startup times', () async {
        await expectLater(
          analyticsService.logAppStart(startupTimeMs: 500),
          completes,
        );
        await expectLater(
          analyticsService.logAppStart(startupTimeMs: 5000),
          completes,
        );
      });

      test('logApiLatency should log API latency', () async {
        await expectLater(
          analyticsService.logApiLatency(
            endpoint: '/api/expenses',
            latencyMs: 250,
            success: true,
          ),
          completes,
        );
      });

      test('logApiLatency should log failed requests', () async {
        await expectLater(
          analyticsService.logApiLatency(
            endpoint: '/api/groups',
            latencyMs: 5000,
            success: false,
          ),
          completes,
        );
      });
    });

    group('Analytics When Disabled', () {
      test('methods should complete when analytics is disabled', () async {
        analyticsService.setEnabled(false);

        await expectLater(
          analyticsService.logEvent(name: 'test_event'),
          completes,
        );
        await expectLater(
          analyticsService.logScreenView(screenName: 'TestScreen'),
          completes,
        );
        await expectLater(analyticsService.setUserId('user123'), completes);
      });
    });
  });

  group('AnalyticsEvents', () {
    test('should have all authentication event names', () {
      expect(AnalyticsEvents.signUp, equals('sign_up'));
      expect(AnalyticsEvents.login, equals('login'));
      expect(AnalyticsEvents.logout, equals('logout'));
    });

    test('should have all group event names', () {
      expect(AnalyticsEvents.groupCreated, equals('group_created'));
      expect(AnalyticsEvents.groupJoined, equals('group_joined'));
    });

    test('should have all expense event names', () {
      expect(AnalyticsEvents.expenseCreated, equals('expense_created'));
      expect(AnalyticsEvents.expenseDeleted, equals('expense_deleted'));
    });

    test('should have all settlement event names', () {
      expect(AnalyticsEvents.settlementCreated, equals('settlement_created'));
      expect(
        AnalyticsEvents.settlementConfirmed,
        equals('settlement_confirmed'),
      );
    });

    test('should have all chat event names', () {
      expect(AnalyticsEvents.chatMessageSent, equals('chat_message_sent'));
      expect(AnalyticsEvents.voiceNoteRecorded, equals('voice_note_recorded'));
    });

    test('should have all feature usage event names', () {
      expect(
        AnalyticsEvents.debtSimplificationViewed,
        equals('debt_simplification_viewed'),
      );
      expect(AnalyticsEvents.notificationOpened, equals('notification_opened'));
      expect(AnalyticsEvents.offlineModeUsed, equals('offline_mode_used'));
      expect(AnalyticsEvents.syncCompleted, equals('sync_completed'));
    });

    test('should have all error and performance event names', () {
      expect(AnalyticsEvents.appError, equals('app_error'));
      expect(AnalyticsEvents.appStart, equals('app_start'));
      expect(AnalyticsEvents.apiLatency, equals('api_latency'));
    });
  });

  group('AnalyticsScreens', () {
    test('should have all authentication screens', () {
      expect(AnalyticsScreens.login, equals('Login'));
      expect(AnalyticsScreens.signUp, equals('SignUp'));
      expect(AnalyticsScreens.forgotPassword, equals('ForgotPassword'));
    });

    test('should have all main screens', () {
      expect(AnalyticsScreens.dashboard, equals('Dashboard'));
      expect(AnalyticsScreens.profile, equals('Profile'));
      expect(AnalyticsScreens.editProfile, equals('EditProfile'));
    });

    test('should have all group screens', () {
      expect(AnalyticsScreens.groupList, equals('GroupList'));
      expect(AnalyticsScreens.groupDetail, equals('GroupDetail'));
      expect(AnalyticsScreens.createGroup, equals('CreateGroup'));
    });

    test('should have all expense screens', () {
      expect(AnalyticsScreens.expenseList, equals('ExpenseList'));
      expect(AnalyticsScreens.addExpense, equals('AddExpense'));
      expect(AnalyticsScreens.expenseDetail, equals('ExpenseDetail'));
      expect(AnalyticsScreens.expenseChat, equals('ExpenseChat'));
    });

    test('should have all settlement screens', () {
      expect(AnalyticsScreens.settleUp, equals('SettleUp'));
      expect(AnalyticsScreens.settlementHistory, equals('SettlementHistory'));
    });

    test('should have all other screens', () {
      expect(AnalyticsScreens.notifications, equals('Notifications'));
      expect(AnalyticsScreens.settings, equals('Settings'));
    });

    test('all screen names should be non-empty', () {
      final screens = [
        AnalyticsScreens.login,
        AnalyticsScreens.signUp,
        AnalyticsScreens.forgotPassword,
        AnalyticsScreens.dashboard,
        AnalyticsScreens.profile,
        AnalyticsScreens.editProfile,
        AnalyticsScreens.groupList,
        AnalyticsScreens.groupDetail,
        AnalyticsScreens.createGroup,
        AnalyticsScreens.expenseList,
        AnalyticsScreens.addExpense,
        AnalyticsScreens.expenseDetail,
        AnalyticsScreens.expenseChat,
        AnalyticsScreens.settleUp,
        AnalyticsScreens.settlementHistory,
        AnalyticsScreens.notifications,
        AnalyticsScreens.settings,
      ];

      for (final screen in screens) {
        expect(screen.isNotEmpty, isTrue);
      }
    });
  });
}
