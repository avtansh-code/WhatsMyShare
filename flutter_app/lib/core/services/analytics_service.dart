import 'package:flutter/foundation.dart';
import 'logging_service.dart';

/// Analytics service for tracking user actions and app events
/// Uses Firebase Analytics in production
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _log = LoggingService();
  bool _enabled = true;

  /// Enable or disable analytics
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _log.info(
      'Analytics ${enabled ? "enabled" : "disabled"}',
      tag: LogTags.analytics,
    );
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    if (!_enabled) return;

    _log.debug(
      'Set user ID: ${userId != null ? "***" : "null"}',
      tag: LogTags.analytics,
    );

    // In production, use Firebase Analytics:
    // await FirebaseAnalytics.instance.setUserId(id: userId);
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_enabled) return;

    _log.debug('Set user property: $name = $value', tag: LogTags.analytics);

    // In production:
    // await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;

    _log.debug(
      'Screen view: $screenName',
      tag: LogTags.analytics,
      data: {'screenClass': screenClass},
    );

    // In production:
    // await FirebaseAnalytics.instance.logScreenView(
    //   screenName: screenName,
    //   screenClass: screenClass,
    // );
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_enabled) return;

    _log.debug(
      'Event: $name',
      tag: LogTags.analytics,
      data: parameters?.cast<String, dynamic>(),
    );

    // In production:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: parameters,
    // );
  }

  // ==================== Authentication Events ====================

  Future<void> logSignUp({required String method}) async {
    await logEvent(name: 'sign_up', parameters: {'method': method});
  }

  Future<void> logLogin({required String method}) async {
    await logEvent(name: 'login', parameters: {'method': method});
  }

  Future<void> logLogout() async {
    await logEvent(name: 'logout');
  }

  Future<void> logPasswordReset() async {
    await logEvent(name: 'password_reset');
  }

  // ==================== Group Events ====================

  Future<void> logGroupCreated({
    required String groupType,
    required int memberCount,
  }) async {
    await logEvent(
      name: 'group_created',
      parameters: {'group_type': groupType, 'member_count': memberCount},
    );
  }

  Future<void> logGroupJoined({required String groupId}) async {
    await logEvent(name: 'group_joined', parameters: {'group_id': groupId});
  }

  Future<void> logMemberAdded({required String groupId}) async {
    await logEvent(name: 'member_added', parameters: {'group_id': groupId});
  }

  // ==================== Expense Events ====================

  Future<void> logExpenseCreated({
    required double amount,
    required String currency,
    required String splitType,
    required int participantCount,
    required bool hasReceipt,
  }) async {
    await logEvent(
      name: 'expense_created',
      parameters: {
        'amount': amount,
        'currency': currency,
        'split_type': splitType,
        'participant_count': participantCount,
        'has_receipt': hasReceipt,
      },
    );
  }

  Future<void> logExpenseDeleted() async {
    await logEvent(name: 'expense_deleted');
  }

  Future<void> logExpenseEdited() async {
    await logEvent(name: 'expense_edited');
  }

  // ==================== Settlement Events ====================

  Future<void> logSettlementCreated({
    required double amount,
    required String currency,
    required String paymentMethod,
    required bool biometricUsed,
  }) async {
    await logEvent(
      name: 'settlement_created',
      parameters: {
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'biometric_used': biometricUsed,
      },
    );
  }

  Future<void> logSettlementConfirmed({required String settlementId}) async {
    await logEvent(
      name: 'settlement_confirmed',
      parameters: {'settlement_id': settlementId},
    );
  }

  // ==================== Chat Events ====================

  Future<void> logChatMessageSent({required String messageType}) async {
    await logEvent(
      name: 'chat_message_sent',
      parameters: {'message_type': messageType},
    );
  }

  Future<void> logVoiceNoteRecorded({required int durationMs}) async {
    await logEvent(
      name: 'voice_note_recorded',
      parameters: {'duration_ms': durationMs},
    );
  }

  // ==================== Feature Usage Events ====================

  Future<void> logDebtSimplificationViewed() async {
    await logEvent(name: 'debt_simplification_viewed');
  }

  Future<void> logNotificationOpened({required String notificationType}) async {
    await logEvent(
      name: 'notification_opened',
      parameters: {'notification_type': notificationType},
    );
  }

  Future<void> logOfflineModeUsed() async {
    await logEvent(name: 'offline_mode_used');
  }

  Future<void> logSyncCompleted({required int operationCount}) async {
    await logEvent(
      name: 'sync_completed',
      parameters: {'operation_count': operationCount},
    );
  }

  // ==================== Error Events ====================

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.length > 100
            ? errorMessage.substring(0, 100)
            : errorMessage,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  // ==================== Performance Events ====================

  Future<void> logAppStart({required int startupTimeMs}) async {
    await logEvent(
      name: 'app_start',
      parameters: {'startup_time_ms': startupTimeMs},
    );
  }

  Future<void> logApiLatency({
    required String endpoint,
    required int latencyMs,
    required bool success,
  }) async {
    if (!kDebugMode) {
      await logEvent(
        name: 'api_latency',
        parameters: {
          'endpoint': endpoint,
          'latency_ms': latencyMs,
          'success': success,
        },
      );
    }
  }
}

/// Analytics event names for consistency
class AnalyticsEvents {
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String groupCreated = 'group_created';
  static const String groupJoined = 'group_joined';
  static const String expenseCreated = 'expense_created';
  static const String expenseDeleted = 'expense_deleted';
  static const String settlementCreated = 'settlement_created';
  static const String settlementConfirmed = 'settlement_confirmed';
  static const String chatMessageSent = 'chat_message_sent';
  static const String voiceNoteRecorded = 'voice_note_recorded';
  static const String debtSimplificationViewed = 'debt_simplification_viewed';
  static const String notificationOpened = 'notification_opened';
  static const String offlineModeUsed = 'offline_mode_used';
  static const String syncCompleted = 'sync_completed';
  static const String appError = 'app_error';
  static const String appStart = 'app_start';
  static const String apiLatency = 'api_latency';
}

/// Screen names for analytics
class AnalyticsScreens {
  static const String login = 'Login';
  static const String signUp = 'SignUp';
  static const String forgotPassword = 'ForgotPassword';
  static const String dashboard = 'Dashboard';
  static const String profile = 'Profile';
  static const String editProfile = 'EditProfile';
  static const String groupList = 'GroupList';
  static const String groupDetail = 'GroupDetail';
  static const String createGroup = 'CreateGroup';
  static const String expenseList = 'ExpenseList';
  static const String addExpense = 'AddExpense';
  static const String expenseDetail = 'ExpenseDetail';
  static const String expenseChat = 'ExpenseChat';
  static const String settleUp = 'SettleUp';
  static const String settlementHistory = 'SettlementHistory';
  static const String notifications = 'Notifications';
  static const String settings = 'Settings';
}
