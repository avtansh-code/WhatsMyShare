/// Application configuration settings
class AppConfig {
  /// App name
  static const String appName = "What's My Share";

  /// App version
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  /// Default currency code
  static const String defaultCurrency = 'INR';

  /// Default locale
  static const String defaultLocale = 'en-IN';

  /// Default timezone
  static const String defaultTimezone = 'Asia/Kolkata';

  /// Maximum group size
  static const int maxGroupSize = 50;

  /// Maximum expense amount (in paisa) - ₹1,00,000
  static const int maxExpenseAmount = 10000000;

  /// Biometric threshold (in paisa) - ₹5,000
  static const int biometricThreshold = 500000;

  /// Supported currencies
  static const List<String> supportedCurrencies = ['INR', 'USD', 'EUR', 'GBP'];

  /// Supported locales
  static const List<String> supportedLocales = ['en-IN', 'hi-IN'];

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Cache duration for user profile
  static const Duration userProfileCacheDuration = Duration(hours: 1);

  /// Cache duration for group list
  static const Duration groupListCacheDuration = Duration(minutes: 5);

  /// Offline sync retry count
  static const int offlineSyncRetryCount = 3;
}

/// Environment types
enum Environment { development, staging, production }

/// Environment-specific configuration
class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  /// Get current environment
  static Environment get current => _currentEnvironment;

  /// Set current environment
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Check if running in debug mode
  static bool get isDebug => _currentEnvironment == Environment.development;

  /// Check if running in production
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Get API base URL based on environment
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://localhost:8080/api/v1';
      case Environment.staging:
        return 'https://api-staging.whatsmyshare.com/v1';
      case Environment.production:
        return 'https://api.whatsmyshare.com/v1';
    }
  }

  /// Get Firebase project ID based on environment
  static String get firebaseProjectId {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'whatsmyshare-dev';
      case Environment.staging:
        return 'whatsmyshare-staging';
      case Environment.production:
        return 'whatsmyshare-prod';
    }
  }
}
