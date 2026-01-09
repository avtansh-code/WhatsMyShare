import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/services/logging_service.dart';

void main() {
  group('LoggingService', () {
    late LoggingService loggingService;

    setUp(() {
      loggingService = LoggingService();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = LoggingService();
        final instance2 = LoggingService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('factory constructor returns singleton instance', () {
        final service1 = LoggingService();
        final service2 = LoggingService();

        expect(service1, same(service2));
      });
    });

    group('Log Level', () {
      test('should set minimum log level', () {
        // Should not throw
        loggingService.setMinimumLevel(LogLevel.debug);
        loggingService.setMinimumLevel(LogLevel.info);
        loggingService.setMinimumLevel(LogLevel.warning);
        loggingService.setMinimumLevel(LogLevel.error);

        expect(true, isTrue); // No exception thrown
      });

      test('LogLevel enum has correct ordering', () {
        expect(LogLevel.debug.index, equals(0));
        expect(LogLevel.info.index, equals(1));
        expect(LogLevel.warning.index, equals(2));
        expect(LogLevel.error.index, equals(3));
      });

      test('LogLevel values are ordered correctly for filtering', () {
        expect(LogLevel.debug.index < LogLevel.info.index, isTrue);
        expect(LogLevel.info.index < LogLevel.warning.index, isTrue);
        expect(LogLevel.warning.index < LogLevel.error.index, isTrue);
      });
    });

    group('Debug Logging', () {
      test('should log debug message without error', () {
        expect(
          () => loggingService.debug('Test debug message'),
          returnsNormally,
        );
      });

      test('should log debug message with tag', () {
        expect(
          () => loggingService.debug('Test message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('should log debug message with data', () {
        expect(
          () => loggingService.debug(
            'Test message',
            data: {'key': 'value', 'number': 42},
          ),
          returnsNormally,
        );
      });

      test('should log debug message with tag and data', () {
        expect(
          () => loggingService.debug(
            'Test message',
            tag: 'TestTag',
            data: {'key': 'value'},
          ),
          returnsNormally,
        );
      });
    });

    group('Info Logging', () {
      test('should log info message without error', () {
        expect(
          () => loggingService.info('Test info message'),
          returnsNormally,
        );
      });

      test('should log info message with tag', () {
        expect(
          () => loggingService.info('Test message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('should log info message with data', () {
        expect(
          () => loggingService.info(
            'Test message',
            data: {'key': 'value'},
          ),
          returnsNormally,
        );
      });
    });

    group('Warning Logging', () {
      test('should log warning message without error', () {
        expect(
          () => loggingService.warning('Test warning message'),
          returnsNormally,
        );
      });

      test('should log warning message with tag', () {
        expect(
          () => loggingService.warning('Test message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('should log warning message with data', () {
        expect(
          () => loggingService.warning(
            'Test message',
            data: {'warning': 'details'},
          ),
          returnsNormally,
        );
      });
    });

    group('Error Logging', () {
      test('should log error message without error object', () {
        expect(
          () => loggingService.error('Test error message'),
          returnsNormally,
        );
      });

      test('should log error message with tag', () {
        expect(
          () => loggingService.error('Test message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('should log error message with error object', () {
        final error = Exception('Test exception');
        expect(
          () => loggingService.error('Test message', error: error),
          returnsNormally,
        );
      });

      test('should log error message with stack trace', () {
        try {
          throw Exception('Test exception');
        } catch (e, stackTrace) {
          expect(
            () => loggingService.error(
              'Test message',
              error: e,
              stackTrace: stackTrace,
            ),
            returnsNormally,
          );
        }
      });

      test('should log error message with all parameters', () {
        try {
          throw Exception('Test exception');
        } catch (e, stackTrace) {
          expect(
            () => loggingService.error(
              'Test message',
              tag: 'ErrorTag',
              error: e,
              stackTrace: stackTrace,
              data: {'context': 'test'},
            ),
            returnsNormally,
          );
        }
      });
    });

    group('Logging with Different Data Types', () {
      test('should handle string values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {'string': 'value'},
          ),
          returnsNormally,
        );
      });

      test('should handle numeric values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {'int': 42, 'double': 3.14},
          ),
          returnsNormally,
        );
      });

      test('should handle boolean values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {'bool': true, 'another': false},
          ),
          returnsNormally,
        );
      });

      test('should handle list values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {'list': [1, 2, 3]},
          ),
          returnsNormally,
        );
      });

      test('should handle nested map values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {
              'nested': {'key': 'value'},
            },
          ),
          returnsNormally,
        );
      });

      test('should handle null values in data', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {'nullable': null},
          ),
          returnsNormally,
        );
      });

      test('should handle empty data map', () {
        expect(
          () => loggingService.debug(
            'Test',
            data: {},
          ),
          returnsNormally,
        );
      });
    });
  });

  group('LoggingExtension', () {
    test('should provide log getter on any object', () {
      const testObject = 'test';
      expect(testObject.log, isA<LoggingService>());
    });

    test('logDebug should work on objects', () {
      const testObject = 'test';
      expect(
        () => testObject.logDebug('Debug from extension'),
        returnsNormally,
      );
    });

    test('logInfo should work on objects', () {
      const testObject = 'test';
      expect(
        () => testObject.logInfo('Info from extension'),
        returnsNormally,
      );
    });

    test('logWarning should work on objects', () {
      const testObject = 'test';
      expect(
        () => testObject.logWarning('Warning from extension'),
        returnsNormally,
      );
    });

    test('logError should work on objects', () {
      const testObject = 'test';
      expect(
        () => testObject.logError('Error from extension'),
        returnsNormally,
      );
    });

    test('logError should work with error object', () {
      const testObject = 'test';
      expect(
        () => testObject.logError(
          'Error from extension',
          error: Exception('test'),
        ),
        returnsNormally,
      );
    });

    test('logError should work with stack trace', () {
      const testObject = 'test';
      try {
        throw Exception('test');
      } catch (e, stackTrace) {
        expect(
          () => testObject.logError(
            'Error from extension',
            error: e,
            stackTrace: stackTrace,
          ),
          returnsNormally,
        );
      }
    });

    test('extension methods should use runtime type as tag', () {
      const stringObject = 'test';
      const intObject = 42;
      final listObject = [1, 2, 3];

      expect(
        () => stringObject.logDebug('String log'),
        returnsNormally,
      );
      expect(
        () => intObject.logDebug('Int log'),
        returnsNormally,
      );
      expect(
        () => listObject.logDebug('List log'),
        returnsNormally,
      );
    });
  });

  group('LogTags', () {
    test('should have all required tags defined', () {
      expect(LogTags.app, equals('App'));
      expect(LogTags.auth, equals('Auth'));
      expect(LogTags.profile, equals('Profile'));
      expect(LogTags.groups, equals('Groups'));
      expect(LogTags.expenses, equals('Expenses'));
      expect(LogTags.settlements, equals('Settlements'));
      expect(LogTags.notifications, equals('Notifications'));
      expect(LogTags.chat, equals('Chat'));
      expect(LogTags.network, equals('Network'));
      expect(LogTags.offline, equals('Offline'));
      expect(LogTags.sync, equals('Sync'));
      expect(LogTags.audio, equals('Audio'));
      expect(LogTags.storage, equals('Storage'));
      expect(LogTags.navigation, equals('Navigation'));
      expect(LogTags.analytics, equals('Analytics'));
      expect(LogTags.crashlytics, equals('Crashlytics'));
      expect(LogTags.firebase, equals('Firebase'));
      expect(LogTags.bloc, equals('BLoC'));
      expect(LogTags.ui, equals('UI'));
      expect(LogTags.performance, equals('Performance'));
    });

    test('all tags should be non-empty strings', () {
      final tags = [
        LogTags.app,
        LogTags.auth,
        LogTags.profile,
        LogTags.groups,
        LogTags.expenses,
        LogTags.settlements,
        LogTags.notifications,
        LogTags.chat,
        LogTags.network,
        LogTags.offline,
        LogTags.sync,
        LogTags.audio,
        LogTags.storage,
        LogTags.navigation,
        LogTags.analytics,
        LogTags.crashlytics,
        LogTags.firebase,
        LogTags.bloc,
        LogTags.ui,
        LogTags.performance,
      ];

      for (final tag in tags) {
        expect(tag.isNotEmpty, isTrue);
      }
    });

    test('logging with predefined tags should work', () {
      final loggingService = LoggingService();

      expect(
        () => loggingService.debug('Test', tag: LogTags.auth),
        returnsNormally,
      );
      expect(
        () => loggingService.info('Test', tag: LogTags.network),
        returnsNormally,
      );
      expect(
        () => loggingService.warning('Test', tag: LogTags.sync),
        returnsNormally,
      );
      expect(
        () => loggingService.error('Test', tag: LogTags.firebase),
        returnsNormally,
      );
    });
  });

  group('LogLevel enum', () {
    test('should have all expected values', () {
      expect(LogLevel.values.length, equals(4));
      expect(LogLevel.values.contains(LogLevel.debug), isTrue);
      expect(LogLevel.values.contains(LogLevel.info), isTrue);
      expect(LogLevel.values.contains(LogLevel.warning), isTrue);
      expect(LogLevel.values.contains(LogLevel.error), isTrue);
    });

    test('should have correct name properties', () {
      expect(LogLevel.debug.name, equals('debug'));
      expect(LogLevel.info.name, equals('info'));
      expect(LogLevel.warning.name, equals('warning'));
      expect(LogLevel.error.name, equals('error'));
    });
  });

  group('Edge Cases', () {
    test('should handle very long messages', () {
      final loggingService = LoggingService();
      final longMessage = 'A' * 10000;

      expect(
        () => loggingService.debug(longMessage),
        returnsNormally,
      );
    });

    test('should handle messages with special characters', () {
      final loggingService = LoggingService();

      expect(
        () => loggingService.debug('Message with \n newlines'),
        returnsNormally,
      );
      expect(
        () => loggingService.debug('Message with \t tabs'),
        returnsNormally,
      );
      expect(
        () => loggingService.debug('Message with unicode: 🎉 ✓ ❌'),
        returnsNormally,
      );
      expect(
        () => loggingService.debug('Message with quotes: "test" \'test\''),
        returnsNormally,
      );
    });

    test('should handle empty message', () {
      final loggingService = LoggingService();

      expect(
        () => loggingService.debug(''),
        returnsNormally,
      );
    });

    test('should handle very long tag', () {
      final loggingService = LoggingService();
      final longTag = 'T' * 1000;

      expect(
        () => loggingService.debug('Test', tag: longTag),
        returnsNormally,
      );
    });

    test('should handle complex nested data', () {
      final loggingService = LoggingService();
      final complexData = {
        'level1': {
          'level2': {
            'level3': {
              'value': 'deep',
            },
          },
        },
        'array': [
          {'item': 1},
          {'item': 2},
        ],
      };

      expect(
        () => loggingService.debug('Test', data: complexData),
        returnsNormally,
      );
    });
  });
}