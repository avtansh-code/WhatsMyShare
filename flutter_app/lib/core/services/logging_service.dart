import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for structured logging
enum LogLevel { debug, info, warning, error }

/// Structured logging service for the application
/// Provides consistent logging across all features with different levels
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  /// Minimum log level to display (debug in debug mode, info in release)
  LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Set minimum log level
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }

  /// Log a debug message
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log an info message
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log a warning message
  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log an error message with optional error and stack trace
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Skip if below minimum level
    if (level.index < _minimumLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag]' : '';

    // Build log message
    final buffer = StringBuffer();
    buffer.write('$timestamp $levelStr $tagStr $message');

    // Add data if present
    if (data != null && data.isNotEmpty) {
      buffer.write('\n  Data: $data');
    }

    // Add error if present
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    // Add stack trace if present
    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n$stackTrace');
    }

    final logMessage = buffer.toString();

    // Output based on environment
    if (kDebugMode) {
      // Print to console (shows in Xcode/terminal)
      // ignore: avoid_print
      print(logMessage);

      // Also use developer.log for DevTools
      developer.log(
        logMessage,
        name: tag ?? 'WhatsMyShare',
        level: _getDeveloperLogLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In release mode, only log warnings and errors
      if (level.index >= LogLevel.warning.index) {
        // In production, you might want to send to a remote logging service
        // For now, we'll use print (which goes to system log)
        // ignore: avoid_print
        print(logMessage);
      }
    }
  }

  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO ]';
      case LogLevel.warning:
        return '[WARN ]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }

  int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500; // FINE
      case LogLevel.info:
        return 800; // INFO
      case LogLevel.warning:
        return 900; // WARNING
      case LogLevel.error:
        return 1000; // SEVERE
    }
  }
}

/// Extension for convenient logging from any class
extension LoggingExtension on Object {
  LoggingService get log => LoggingService();

  void logDebug(String message, {Map<String, dynamic>? data}) {
    LoggingService().debug(message, tag: runtimeType.toString(), data: data);
  }

  void logInfo(String message, {Map<String, dynamic>? data}) {
    LoggingService().info(message, tag: runtimeType.toString(), data: data);
  }

  void logWarning(String message, {Map<String, dynamic>? data}) {
    LoggingService().warning(message, tag: runtimeType.toString(), data: data);
  }

  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    LoggingService().error(
      message,
      tag: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}

/// Predefined tags for common logging categories
class LogTags {
  static const String app = 'App';
  static const String auth = 'Auth';
  static const String profile = 'Profile';
  static const String groups = 'Groups';
  static const String expenses = 'Expenses';
  static const String settlements = 'Settlements';
  static const String notifications = 'Notifications';
  static const String chat = 'Chat';
  static const String network = 'Network';
  static const String offline = 'Offline';
  static const String sync = 'Sync';
  static const String audio = 'Audio';
  static const String storage = 'Storage';
  static const String encryption = 'Encryption';
  static const String navigation = 'Navigation';
  static const String analytics = 'Analytics';
  static const String crashlytics = 'Crashlytics';
  static const String firebase = 'Firebase';
  static const String bloc = 'BLoC';
  static const String ui = 'UI';
  static const String performance = 'Performance';
}
