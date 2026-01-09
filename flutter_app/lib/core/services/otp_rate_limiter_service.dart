import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'logging_service.dart';

/// Result of checking OTP rate limit
class OtpRateLimitResult {
  /// Whether OTP can be sent
  final bool canSend;

  /// Seconds remaining until next OTP can be sent (cooldown)
  final int cooldownSecondsRemaining;

  /// Number of OTP requests remaining in the current hour
  final int requestsRemaining;

  /// Whether the hourly limit has been reached
  final bool isHourlyLimitReached;

  /// Error message if any
  final String? errorMessage;

  const OtpRateLimitResult({
    required this.canSend,
    required this.cooldownSecondsRemaining,
    required this.requestsRemaining,
    required this.isHourlyLimitReached,
    this.errorMessage,
  });

  /// User-friendly message for rate limit status
  String get statusMessage {
    if (isHourlyLimitReached) {
      return 'You have reached the maximum OTP requests. Please try again in 1 hour.';
    }
    if (cooldownSecondsRemaining > 0) {
      return 'Please wait $cooldownSecondsRemaining seconds before requesting another OTP.';
    }
    return '';
  }
}

/// Service to manage OTP rate limiting
/// - 30 second cooldown between OTP requests
/// - Maximum 3 OTP requests per hour
class OtpRateLimiterService {
  static final OtpRateLimiterService _instance = OtpRateLimiterService._();
  factory OtpRateLimiterService() => _instance;
  OtpRateLimiterService._();

  final LoggingService _log = LoggingService();

  /// In-memory cache of last OTP request time per phone number
  final Map<String, DateTime> _lastOtpRequestTime = {};

  /// Storage key for OTP request timestamps
  String _getStorageKey(String phoneNumber) {
    // Normalize phone number by removing spaces and dashes
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    return '${AppConstants.keyOtpRequestTimestamps}_$normalizedPhone';
  }

  /// Get stored OTP request timestamps for a phone number
  Future<List<DateTime>> _getStoredTimestamps(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(phoneNumber);
      final storedData = prefs.getString(key);

      if (storedData == null || storedData.isEmpty) {
        return [];
      }

      final List<dynamic> timestamps = jsonDecode(storedData);
      return timestamps
          .map((ts) => DateTime.fromMillisecondsSinceEpoch(ts as int))
          .toList();
    } catch (e) {
      _log.warning(
        'Failed to get stored OTP timestamps',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      return [];
    }
  }

  /// Save OTP request timestamps for a phone number
  Future<void> _saveTimestamps(
    String phoneNumber,
    List<DateTime> timestamps,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(phoneNumber);
      final timestampMillis = timestamps
          .map((ts) => ts.millisecondsSinceEpoch)
          .toList();
      await prefs.setString(key, jsonEncode(timestampMillis));
    } catch (e) {
      _log.warning(
        'Failed to save OTP timestamps',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
    }
  }

  /// Check if OTP can be sent for the given phone number
  Future<OtpRateLimitResult> checkCanSendOtp(String phoneNumber) async {
    final now = DateTime.now();
    final cooldownDuration = Duration(
      seconds: AppConstants.otpResendCooldownSeconds,
    );
    final rateLimitWindow = Duration(
      minutes: AppConstants.otpRateLimitWindowMinutes,
    );

    // Get stored timestamps and filter to only those within the rate limit window
    final allTimestamps = await _getStoredTimestamps(phoneNumber);
    final windowStart = now.subtract(rateLimitWindow);
    final validTimestamps =
        allTimestamps.where((ts) => ts.isAfter(windowStart)).toList()..sort();

    // Check hourly limit
    final requestsInWindow = validTimestamps.length;
    final requestsRemaining =
        AppConstants.otpMaxRequestsPerHour - requestsInWindow;
    final isHourlyLimitReached = requestsRemaining <= 0;

    if (isHourlyLimitReached) {
      _log.warning(
        'OTP hourly limit reached',
        tag: LogTags.auth,
        data: {
          'phoneNumber': phoneNumber,
          'requestsInWindow': requestsInWindow,
        },
      );
      return OtpRateLimitResult(
        canSend: false,
        cooldownSecondsRemaining: 0,
        requestsRemaining: 0,
        isHourlyLimitReached: true,
        errorMessage:
            'You have reached the maximum OTP requests. Please try again in 1 hour.',
      );
    }

    // Check cooldown (use in-memory cache for more accurate timing)
    int cooldownSecondsRemaining = 0;
    final lastRequest = _lastOtpRequestTime[phoneNumber];
    if (lastRequest != null) {
      final timeSinceLastRequest = now.difference(lastRequest);
      if (timeSinceLastRequest < cooldownDuration) {
        cooldownSecondsRemaining =
            (cooldownDuration - timeSinceLastRequest).inSeconds;
      }
    } else if (validTimestamps.isNotEmpty) {
      // Fall back to stored timestamps if no in-memory cache
      final lastStoredRequest = validTimestamps.last;
      final timeSinceLastRequest = now.difference(lastStoredRequest);
      if (timeSinceLastRequest < cooldownDuration) {
        cooldownSecondsRemaining =
            (cooldownDuration - timeSinceLastRequest).inSeconds;
      }
    }

    final canSend = cooldownSecondsRemaining <= 0;

    _log.debug(
      'OTP rate limit check',
      tag: LogTags.auth,
      data: {
        'phoneNumber': phoneNumber,
        'canSend': canSend,
        'cooldownSecondsRemaining': cooldownSecondsRemaining,
        'requestsRemaining': requestsRemaining,
        'requestsInWindow': requestsInWindow,
      },
    );

    return OtpRateLimitResult(
      canSend: canSend,
      cooldownSecondsRemaining: cooldownSecondsRemaining,
      requestsRemaining: requestsRemaining,
      isHourlyLimitReached: false,
      errorMessage: canSend
          ? null
          : 'Please wait $cooldownSecondsRemaining seconds before requesting another OTP.',
    );
  }

  /// Record an OTP request for the given phone number
  Future<void> recordOtpRequest(String phoneNumber) async {
    final now = DateTime.now();

    // Update in-memory cache
    _lastOtpRequestTime[phoneNumber] = now;

    // Get existing timestamps and add the new one
    final timestamps = await _getStoredTimestamps(phoneNumber);
    timestamps.add(now);

    // Clean up old timestamps (older than 1 hour)
    final rateLimitWindow = Duration(
      minutes: AppConstants.otpRateLimitWindowMinutes,
    );
    final windowStart = now.subtract(rateLimitWindow);
    final validTimestamps = timestamps
        .where((ts) => ts.isAfter(windowStart))
        .toList();

    // Save updated timestamps
    await _saveTimestamps(phoneNumber, validTimestamps);

    _log.info(
      'OTP request recorded',
      tag: LogTags.auth,
      data: {
        'phoneNumber': phoneNumber,
        'totalRequestsInWindow': validTimestamps.length,
      },
    );
  }

  /// Get the number of seconds remaining until the cooldown expires
  Future<int> getCooldownSecondsRemaining(String phoneNumber) async {
    final result = await checkCanSendOtp(phoneNumber);
    return result.cooldownSecondsRemaining;
  }

  /// Get the number of OTP requests remaining in the current hour
  Future<int> getRequestsRemaining(String phoneNumber) async {
    final result = await checkCanSendOtp(phoneNumber);
    return result.requestsRemaining;
  }

  /// Clear rate limit data for a phone number (useful for testing)
  Future<void> clearRateLimitData(String phoneNumber) async {
    _lastOtpRequestTime.remove(phoneNumber);
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(phoneNumber);
    await prefs.remove(key);

    _log.debug(
      'OTP rate limit data cleared',
      tag: LogTags.auth,
      data: {'phoneNumber': phoneNumber},
    );
  }

  /// Clear all rate limit data (useful for testing)
  Future<void> clearAllRateLimitData() async {
    _lastOtpRequestTime.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith(AppConstants.keyOtpRequestTimestamps),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }

    _log.debug('All OTP rate limit data cleared', tag: LogTags.auth);
  }
}
