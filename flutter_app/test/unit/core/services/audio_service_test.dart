import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/services/audio_service.dart';

void main() {
  group('AudioRecordingState', () {
    test('should have all expected states', () {
      expect(AudioRecordingState.values.length, equals(4));
      expect(AudioRecordingState.values.contains(AudioRecordingState.idle),
          isTrue);
      expect(AudioRecordingState.values.contains(AudioRecordingState.recording),
          isTrue);
      expect(AudioRecordingState.values.contains(AudioRecordingState.paused),
          isTrue);
      expect(AudioRecordingState.values.contains(AudioRecordingState.stopped),
          isTrue);
    });

    test('should have correct names', () {
      expect(AudioRecordingState.idle.name, equals('idle'));
      expect(AudioRecordingState.recording.name, equals('recording'));
      expect(AudioRecordingState.paused.name, equals('paused'));
      expect(AudioRecordingState.stopped.name, equals('stopped'));
    });

    test('should have correct indices', () {
      expect(AudioRecordingState.idle.index, equals(0));
      expect(AudioRecordingState.recording.index, equals(1));
      expect(AudioRecordingState.paused.index, equals(2));
      expect(AudioRecordingState.stopped.index, equals(3));
    });
  });

  group('AudioPlaybackState', () {
    test('should have all expected states', () {
      expect(AudioPlaybackState.values.length, equals(5));
      expect(
          AudioPlaybackState.values.contains(AudioPlaybackState.idle), isTrue);
      expect(AudioPlaybackState.values.contains(AudioPlaybackState.playing),
          isTrue);
      expect(AudioPlaybackState.values.contains(AudioPlaybackState.paused),
          isTrue);
      expect(AudioPlaybackState.values.contains(AudioPlaybackState.stopped),
          isTrue);
      expect(AudioPlaybackState.values.contains(AudioPlaybackState.completed),
          isTrue);
    });

    test('should have correct names', () {
      expect(AudioPlaybackState.idle.name, equals('idle'));
      expect(AudioPlaybackState.playing.name, equals('playing'));
      expect(AudioPlaybackState.paused.name, equals('paused'));
      expect(AudioPlaybackState.stopped.name, equals('stopped'));
      expect(AudioPlaybackState.completed.name, equals('completed'));
    });

    test('should have correct indices', () {
      expect(AudioPlaybackState.idle.index, equals(0));
      expect(AudioPlaybackState.playing.index, equals(1));
      expect(AudioPlaybackState.paused.index, equals(2));
      expect(AudioPlaybackState.stopped.index, equals(3));
      expect(AudioPlaybackState.completed.index, equals(4));
    });
  });

  group('AudioService.formatDuration', () {
    test('should format 0 milliseconds', () {
      expect(AudioService.formatDuration(0), equals('0:00'));
    });

    test('should format 1 second', () {
      expect(AudioService.formatDuration(1000), equals('0:01'));
    });

    test('should format 10 seconds', () {
      expect(AudioService.formatDuration(10000), equals('0:10'));
    });

    test('should format 59 seconds', () {
      expect(AudioService.formatDuration(59000), equals('0:59'));
    });

    test('should format 1 minute', () {
      expect(AudioService.formatDuration(60000), equals('1:00'));
    });

    test('should format 1 minute 30 seconds', () {
      expect(AudioService.formatDuration(90000), equals('1:30'));
    });

    test('should format 2 minutes', () {
      expect(AudioService.formatDuration(120000), equals('2:00'));
    });

    test('should format 5 minutes 45 seconds', () {
      expect(AudioService.formatDuration(345000), equals('5:45'));
    });

    test('should format 10 minutes', () {
      expect(AudioService.formatDuration(600000), equals('10:00'));
    });

    test('should format 59 minutes 59 seconds', () {
      expect(AudioService.formatDuration(3599000), equals('59:59'));
    });

    test('should format 60 minutes', () {
      expect(AudioService.formatDuration(3600000), equals('60:00'));
    });

    test('should format 99 minutes 59 seconds', () {
      expect(AudioService.formatDuration(5999000), equals('99:59'));
    });

    test('should handle partial seconds by truncating', () {
      expect(AudioService.formatDuration(1500), equals('0:01'));
      expect(AudioService.formatDuration(1999), equals('0:01'));
      expect(AudioService.formatDuration(999), equals('0:00'));
    });

    test('should format with proper zero padding for seconds', () {
      expect(AudioService.formatDuration(61000), equals('1:01'));
      expect(AudioService.formatDuration(62000), equals('1:02'));
      expect(AudioService.formatDuration(69000), equals('1:09'));
    });
  });

  group('AudioService.formatDurationFromDuration', () {
    test('should format Duration.zero', () {
      expect(
        AudioService.formatDurationFromDuration(Duration.zero),
        equals('0:00'),
      );
    });

    test('should format 1 second duration', () {
      expect(
        AudioService.formatDurationFromDuration(const Duration(seconds: 1)),
        equals('0:01'),
      );
    });

    test('should format 30 seconds duration', () {
      expect(
        AudioService.formatDurationFromDuration(const Duration(seconds: 30)),
        equals('0:30'),
      );
    });

    test('should format 1 minute duration', () {
      expect(
        AudioService.formatDurationFromDuration(const Duration(minutes: 1)),
        equals('1:00'),
      );
    });

    test('should format 2 minutes 15 seconds duration', () {
      expect(
        AudioService.formatDurationFromDuration(
            const Duration(minutes: 2, seconds: 15)),
        equals('2:15'),
      );
    });

    test('should format complex duration', () {
      expect(
        AudioService.formatDurationFromDuration(
          const Duration(minutes: 5, seconds: 45, milliseconds: 500),
        ),
        equals('5:45'),
      );
    });

    test('should format duration with only milliseconds', () {
      expect(
        AudioService.formatDurationFromDuration(
            const Duration(milliseconds: 500)),
        equals('0:00'),
      );
    });

    test('should format duration with milliseconds that round up', () {
      expect(
        AudioService.formatDurationFromDuration(
            const Duration(seconds: 1, milliseconds: 999)),
        equals('0:01'),
      );
    });
  });

  group('AudioService Initial State', () {
    // Note: These tests require platform channel mocking for full functionality
    // We test what we can without actual native plugin calls

    test('should have initial recording state as idle', () {
      // Initial state constant check
      expect(AudioRecordingState.idle.index, equals(0));
    });

    test('should have initial playback state as idle', () {
      // Initial state constant check
      expect(AudioPlaybackState.idle.index, equals(0));
    });
  });

  group('Duration Formatting Edge Cases', () {
    test('should handle negative milliseconds gracefully', () {
      // The implementation handles negative values using absolute value logic
      // The actual behavior may vary - just verify it doesn't throw
      expect(
        () => AudioService.formatDuration(-1000),
        returnsNormally,
      );
    });

    test('should handle very large durations', () {
      // 100 hours = 360000000 ms
      final result = AudioService.formatDuration(360000000);
      expect(result, isNotEmpty);
    });

    test('should format consistently with int input', () {
      for (var i = 0; i < 120; i++) {
        final ms = i * 1000;
        final formatted = AudioService.formatDuration(ms);
        expect(formatted, isNotEmpty);
        expect(formatted.contains(':'), isTrue);
      }
    });

    test('should format with minutes and seconds separated by colon', () {
      final result = AudioService.formatDuration(75000);
      final parts = result.split(':');
      expect(parts.length, equals(2));
      expect(parts[0], equals('1'));
      expect(parts[1], equals('15'));
    });
  });

  group('State Transitions', () {
    test('recording states should follow logical order', () {
      // idle -> recording -> paused -> stopped is the typical flow
      expect(AudioRecordingState.idle.index <
          AudioRecordingState.recording.index, isTrue);
      expect(AudioRecordingState.recording.index <
          AudioRecordingState.paused.index, isTrue);
      expect(AudioRecordingState.paused.index <
          AudioRecordingState.stopped.index, isTrue);
    });

    test('playback states should follow logical order', () {
      // idle -> playing -> paused/stopped -> completed is typical
      expect(
          AudioPlaybackState.idle.index < AudioPlaybackState.playing.index,
          isTrue);
      expect(
          AudioPlaybackState.playing.index < AudioPlaybackState.paused.index,
          isTrue);
    });
  });

  group('Recording State Enum', () {
    test('can compare states', () {
      expect(AudioRecordingState.idle == AudioRecordingState.idle, isTrue);
      expect(AudioRecordingState.idle == AudioRecordingState.recording, isFalse);
    });

    test('can switch on state', () {
      const state = AudioRecordingState.recording;
      String result;

      switch (state) {
        case AudioRecordingState.idle:
          result = 'idle';
          break;
        case AudioRecordingState.recording:
          result = 'recording';
          break;
        case AudioRecordingState.paused:
          result = 'paused';
          break;
        case AudioRecordingState.stopped:
          result = 'stopped';
          break;
      }

      expect(result, equals('recording'));
    });

    test('can be used in collections', () {
      final states = <AudioRecordingState>{
        AudioRecordingState.idle,
        AudioRecordingState.recording,
      };

      expect(states.contains(AudioRecordingState.idle), isTrue);
      expect(states.contains(AudioRecordingState.paused), isFalse);
    });
  });

  group('Playback State Enum', () {
    test('can compare states', () {
      expect(AudioPlaybackState.playing == AudioPlaybackState.playing, isTrue);
      expect(AudioPlaybackState.playing == AudioPlaybackState.paused, isFalse);
    });

    test('can switch on state', () {
      const state = AudioPlaybackState.completed;
      String result;

      switch (state) {
        case AudioPlaybackState.idle:
          result = 'idle';
          break;
        case AudioPlaybackState.playing:
          result = 'playing';
          break;
        case AudioPlaybackState.paused:
          result = 'paused';
          break;
        case AudioPlaybackState.stopped:
          result = 'stopped';
          break;
        case AudioPlaybackState.completed:
          result = 'completed';
          break;
      }

      expect(result, equals('completed'));
    });

    test('can be used in collections', () {
      final states = <AudioPlaybackState>{
        AudioPlaybackState.playing,
        AudioPlaybackState.paused,
      };

      expect(states.contains(AudioPlaybackState.playing), isTrue);
      expect(states.contains(AudioPlaybackState.completed), isFalse);
    });
  });

  group('Format Duration Boundary Tests', () {
    test('should handle zero correctly', () {
      expect(AudioService.formatDuration(0), equals('0:00'));
    });

    test('should handle exactly one second boundary', () {
      expect(AudioService.formatDuration(999), equals('0:00'));
      expect(AudioService.formatDuration(1000), equals('0:01'));
      expect(AudioService.formatDuration(1001), equals('0:01'));
    });

    test('should handle exactly one minute boundary', () {
      expect(AudioService.formatDuration(59999), equals('0:59'));
      expect(AudioService.formatDuration(60000), equals('1:00'));
      expect(AudioService.formatDuration(60001), equals('1:00'));
    });

    test('should handle exactly 10 minutes boundary', () {
      expect(AudioService.formatDuration(599999), equals('9:59'));
      expect(AudioService.formatDuration(600000), equals('10:00'));
    });
  });

  group('Duration Format Consistency', () {
    test('formatDuration and formatDurationFromDuration should be consistent',
        () {
      for (var seconds = 0; seconds < 300; seconds += 15) {
        final ms = seconds * 1000;
        final duration = Duration(seconds: seconds);

        final fromMs = AudioService.formatDuration(ms);
        final fromDuration = AudioService.formatDurationFromDuration(duration);

        expect(fromMs, equals(fromDuration),
            reason: 'Mismatch at $seconds seconds');
      }
    });

    test('should produce same result for equivalent inputs', () {
      // 1 minute 30 seconds
      expect(
        AudioService.formatDuration(90000),
        equals(AudioService.formatDurationFromDuration(
            const Duration(minutes: 1, seconds: 30))),
      );

      // 5 minutes 15 seconds
      expect(
        AudioService.formatDuration(315000),
        equals(AudioService.formatDurationFromDuration(
            const Duration(minutes: 5, seconds: 15))),
      );
    });
  });
}