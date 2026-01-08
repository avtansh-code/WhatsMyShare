import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('App Info', () {
      test('appName is not empty', () {
        expect(AppConfig.appName.isNotEmpty, isTrue);
        expect(AppConfig.appName, "What's My Share");
      });

      test('appVersion is not empty', () {
        expect(AppConfig.appVersion.isNotEmpty, isTrue);
      });

      test('buildNumber is positive', () {
        expect(AppConfig.buildNumber, greaterThan(0));
      });
    });

    group('Currency Settings', () {
      test('defaultCurrency is INR', () {
        expect(AppConfig.defaultCurrency, 'INR');
      });

      test('supportedCurrencies is not empty', () {
        expect(AppConfig.supportedCurrencies.isNotEmpty, isTrue);
      });

      test('supportedCurrencies contains INR', () {
        expect(AppConfig.supportedCurrencies.contains('INR'), isTrue);
      });

      test('supportedCurrencies contains common currencies', () {
        expect(AppConfig.supportedCurrencies.contains('USD'), isTrue);
        expect(AppConfig.supportedCurrencies.contains('EUR'), isTrue);
        expect(AppConfig.supportedCurrencies.contains('GBP'), isTrue);
      });
    });

    group('Locale Settings', () {
      test('defaultLocale is en-IN', () {
        expect(AppConfig.defaultLocale, 'en-IN');
      });

      test('supportedLocales is not empty', () {
        expect(AppConfig.supportedLocales.isNotEmpty, isTrue);
      });

      test('supportedLocales contains default locale', () {
        expect(AppConfig.supportedLocales.contains('en-IN'), isTrue);
      });
    });

    group('Timezone Settings', () {
      test('defaultTimezone is Asia/Kolkata', () {
        expect(AppConfig.defaultTimezone, 'Asia/Kolkata');
      });
    });

    group('Group Settings', () {
      test('maxGroupSize is reasonable', () {
        expect(AppConfig.maxGroupSize, greaterThan(0));
        expect(AppConfig.maxGroupSize, lessThanOrEqualTo(100));
      });

      test('maxGroupSize is 50', () {
        expect(AppConfig.maxGroupSize, 50);
      });
    });

    group('Expense Settings', () {
      test('maxExpenseAmount is positive', () {
        expect(AppConfig.maxExpenseAmount, greaterThan(0));
      });

      test('maxExpenseAmount is 1 lakh in paisa', () {
        // 10000000 paisa = ₹1,00,000
        expect(AppConfig.maxExpenseAmount, 10000000);
      });
    });

    group('Biometric Settings', () {
      test('biometricThreshold is positive', () {
        expect(AppConfig.biometricThreshold, greaterThan(0));
      });

      test('biometricThreshold is less than maxExpenseAmount', () {
        expect(
          AppConfig.biometricThreshold,
          lessThan(AppConfig.maxExpenseAmount),
        );
      });

      test('biometricThreshold is 5000 rupees in paisa', () {
        // 500000 paisa = ₹5,000
        expect(AppConfig.biometricThreshold, 500000);
      });
    });

    group('API Settings', () {
      test('apiTimeout is positive', () {
        expect(AppConfig.apiTimeout.inSeconds, greaterThan(0));
      });

      test('apiTimeout is 30 seconds', () {
        expect(AppConfig.apiTimeout.inSeconds, 30);
      });
    });

    group('Cache Settings', () {
      test('userProfileCacheDuration is positive', () {
        expect(AppConfig.userProfileCacheDuration.inMinutes, greaterThan(0));
      });

      test('userProfileCacheDuration is 1 hour', () {
        expect(AppConfig.userProfileCacheDuration.inHours, 1);
      });

      test('groupListCacheDuration is positive', () {
        expect(AppConfig.groupListCacheDuration.inMinutes, greaterThan(0));
      });

      test('groupListCacheDuration is 5 minutes', () {
        expect(AppConfig.groupListCacheDuration.inMinutes, 5);
      });
    });

    group('Offline Sync Settings', () {
      test('offlineSyncRetryCount is positive', () {
        expect(AppConfig.offlineSyncRetryCount, greaterThan(0));
      });

      test('offlineSyncRetryCount is 3', () {
        expect(AppConfig.offlineSyncRetryCount, 3);
      });
    });
  });

  group('Environment', () {
    test('has development value', () {
      expect(Environment.development.name, 'development');
    });

    test('has staging value', () {
      expect(Environment.staging.name, 'staging');
    });

    test('has production value', () {
      expect(Environment.production.name, 'production');
    });
  });

  group('EnvironmentConfig', () {
    setUp(() {
      // Reset to development before each test
      EnvironmentConfig.setEnvironment(Environment.development);
    });

    group('Environment Detection', () {
      test('default environment is development', () {
        EnvironmentConfig.setEnvironment(Environment.development);
        expect(EnvironmentConfig.current, Environment.development);
      });

      test('can set staging environment', () {
        EnvironmentConfig.setEnvironment(Environment.staging);
        expect(EnvironmentConfig.current, Environment.staging);
      });

      test('can set production environment', () {
        EnvironmentConfig.setEnvironment(Environment.production);
        expect(EnvironmentConfig.current, Environment.production);
      });
    });

    group('Debug Mode', () {
      test('isDebug is true in development', () {
        EnvironmentConfig.setEnvironment(Environment.development);
        expect(EnvironmentConfig.isDebug, isTrue);
      });

      test('isDebug is false in staging', () {
        EnvironmentConfig.setEnvironment(Environment.staging);
        expect(EnvironmentConfig.isDebug, isFalse);
      });

      test('isDebug is false in production', () {
        EnvironmentConfig.setEnvironment(Environment.production);
        expect(EnvironmentConfig.isDebug, isFalse);
      });
    });

    group('Production Mode', () {
      test('isProduction is false in development', () {
        EnvironmentConfig.setEnvironment(Environment.development);
        expect(EnvironmentConfig.isProduction, isFalse);
      });

      test('isProduction is false in staging', () {
        EnvironmentConfig.setEnvironment(Environment.staging);
        expect(EnvironmentConfig.isProduction, isFalse);
      });

      test('isProduction is true in production', () {
        EnvironmentConfig.setEnvironment(Environment.production);
        expect(EnvironmentConfig.isProduction, isTrue);
      });
    });

    group('API Base URL', () {
      test('returns localhost in development', () {
        EnvironmentConfig.setEnvironment(Environment.development);
        expect(EnvironmentConfig.apiBaseUrl.contains('localhost'), isTrue);
      });

      test('returns staging URL in staging', () {
        EnvironmentConfig.setEnvironment(Environment.staging);
        expect(EnvironmentConfig.apiBaseUrl.contains('staging'), isTrue);
      });

      test('returns production URL in production', () {
        EnvironmentConfig.setEnvironment(Environment.production);
        expect(
          EnvironmentConfig.apiBaseUrl.contains('api.whatsmyshare'),
          isTrue,
        );
        expect(EnvironmentConfig.apiBaseUrl.contains('staging'), isFalse);
      });
    });

    group('Firebase Project ID', () {
      test('returns dev project in development', () {
        EnvironmentConfig.setEnvironment(Environment.development);
        expect(EnvironmentConfig.firebaseProjectId.contains('dev'), isTrue);
      });

      test('returns staging project in staging', () {
        EnvironmentConfig.setEnvironment(Environment.staging);
        expect(EnvironmentConfig.firebaseProjectId.contains('staging'), isTrue);
      });

      test('returns prod project in production', () {
        EnvironmentConfig.setEnvironment(Environment.production);
        expect(EnvironmentConfig.firebaseProjectId.contains('prod'), isTrue);
      });
    });
  });
}
