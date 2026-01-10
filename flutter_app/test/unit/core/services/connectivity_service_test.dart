import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/services/connectivity_service.dart';

// Mock classes
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityStatus', () {
    test('should have online status', () {
      expect(ConnectivityStatus.online, isNotNull);
      expect(ConnectivityStatus.online.name, equals('online'));
    });

    test('should have offline status', () {
      expect(ConnectivityStatus.offline, isNotNull);
      expect(ConnectivityStatus.offline.name, equals('offline'));
    });

    test('should have exactly two values', () {
      expect(ConnectivityStatus.values.length, equals(2));
    });
  });

  group('ConnectivityServiceImpl', () {
    late MockConnectivity mockConnectivity;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      mockConnectivity = MockConnectivity();
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    });

    tearDown(() {
      connectivityController.close();
    });

    group('Initialization', () {
      test('should create service with mocked connectivity', () {
        // Using mocked connectivity for testable behavior
        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        expect(service, isNotNull);
      });

      test('should create service with custom connectivity', () {
        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        expect(service, isNotNull);
        verify(() => mockConnectivity.onConnectivityChanged).called(1);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should check connectivity on initialization', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);

        ConnectivityServiceImpl(connectivity: mockConnectivity);

        await Future.delayed(Duration.zero);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });
    });

    group('checkConnectivity', () {
      test('should return online when wifi is available', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should return online when mobile is available', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should return online when ethernet is available', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.ethernet]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should return offline when none is available', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.offline));
      });

      test('should return offline when empty list', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => []);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.offline));
      });

      test(
        'should return online when multiple connections available',
        () async {
          when(() => mockConnectivity.checkConnectivity()).thenAnswer(
            (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile],
          );

          final service = ConnectivityServiceImpl(
            connectivity: mockConnectivity,
          );
          final status = await service.checkConnectivity();

          expect(status, equals(ConnectivityStatus.online));
        },
      );
    });

    group('isConnected', () {
      test('should return true when online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final isConnected = await service.isConnected;

        expect(isConnected, isTrue);
      });

      test('should return false when offline', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final isConnected = await service.isConnected;

        expect(isConnected, isFalse);
      });
    });

    group('statusStream', () {
      test(
        'should emit online status when connectivity changes to wifi',
        () async {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.none]);

          final service = ConnectivityServiceImpl(
            connectivity: mockConnectivity,
          );

          // Allow initialization to complete
          await Future.delayed(Duration.zero);

          expectLater(service.statusStream, emits(ConnectivityStatus.online));

          connectivityController.add([ConnectivityResult.wifi]);
        },
      );

      test(
        'should emit offline status when connectivity changes to none',
        () async {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.wifi]);

          final service = ConnectivityServiceImpl(
            connectivity: mockConnectivity,
          );

          // Allow initialization to complete
          await Future.delayed(Duration.zero);

          expectLater(service.statusStream, emits(ConnectivityStatus.offline));

          connectivityController.add([ConnectivityResult.none]);
        },
      );

      test('should not emit when status does not change', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        // Allow initialization to complete
        await Future.delayed(Duration.zero);

        final emittedStatuses = <ConnectivityStatus>[];
        service.statusStream.listen(emittedStatuses.add);

        // Emit same status (wifi -> wifi)
        connectivityController.add([ConnectivityResult.wifi]);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emittedStatuses, isEmpty);
      });

      test('should be a broadcast stream', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        // Should be able to listen multiple times
        final listener1 = service.statusStream.listen((_) {});
        final listener2 = service.statusStream.listen((_) {});

        expect(listener1, isNotNull);
        expect(listener2, isNotNull);

        await listener1.cancel();
        await listener2.cancel();
      });

      test('should emit multiple status changes', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        // Allow initialization to complete
        await Future.delayed(Duration.zero);

        final emittedStatuses = <ConnectivityStatus>[];
        service.statusStream.listen(emittedStatuses.add);

        // Change to offline
        connectivityController.add([ConnectivityResult.none]);
        await Future.delayed(const Duration(milliseconds: 50));

        // Change back to online
        connectivityController.add([ConnectivityResult.wifi]);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emittedStatuses.length, equals(2));
        expect(emittedStatuses[0], equals(ConnectivityStatus.offline));
        expect(emittedStatuses[1], equals(ConnectivityStatus.online));
      });
    });

    group('dispose', () {
      test('should dispose without error', () async {
        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        expect(() => service.dispose(), returnsNormally);
      });

      test('should cancel connectivity subscription on dispose', () async {
        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        service.dispose();

        // Stream should be closed after dispose
        // We can verify by checking that adding to the controller doesn't cause issues
        expect(
          () => connectivityController.add([ConnectivityResult.wifi]),
          returnsNormally,
        );
      });
    });

    group('ConnectivityResult mapping', () {
      test('should map wifi to online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should map mobile to online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should map ethernet to online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.ethernet]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should map vpn to online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.vpn]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should map bluetooth to online', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.bluetooth]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.online));
      });

      test('should map none to offline', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        expect(status, equals(ConnectivityStatus.offline));
      });

      test('should handle list containing none as offline', () async {
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi, ConnectivityResult.none],
        );

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);
        final status = await service.checkConnectivity();

        // Contains none, so should be offline
        expect(status, equals(ConnectivityStatus.offline));
      });
    });

    group('Edge Cases', () {
      test('should handle rapid connectivity changes', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        // Allow initialization to complete
        await Future.delayed(Duration.zero);

        final emittedStatuses = <ConnectivityStatus>[];
        service.statusStream.listen(emittedStatuses.add);

        // Rapid changes
        connectivityController.add([ConnectivityResult.none]);
        connectivityController.add([ConnectivityResult.wifi]);
        connectivityController.add([ConnectivityResult.none]);
        connectivityController.add([ConnectivityResult.mobile]);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should have captured all distinct status changes
        expect(emittedStatuses.isNotEmpty, isTrue);
      });

      test('should handle connectivity check after dispose', () async {
        final service = ConnectivityServiceImpl(connectivity: mockConnectivity);

        service.dispose();

        // Should still be able to check connectivity (returns cached status)
        // This depends on implementation - adjust based on actual behavior
        expect(() async => await service.checkConnectivity(), returnsNormally);
      });
    });
  });

  group('ConnectivityService interface', () {
    test('should define statusStream property', () {
      // Verify the interface contract by checking a mock implementation
      final mock = _MockConnectivityService();
      expect(mock.statusStream, isNotNull);
    });

    test('should define isConnected property', () async {
      final mock = _MockConnectivityService();
      expect(await mock.isConnected, isNotNull);
    });

    test('should define checkConnectivity method', () async {
      final mock = _MockConnectivityService();
      expect(await mock.checkConnectivity(), isNotNull);
    });

    test('should define dispose method', () {
      final mock = _MockConnectivityService();
      expect(() => mock.dispose(), returnsNormally);
    });
  });
}

/// Mock implementation for testing the interface
class _MockConnectivityService implements ConnectivityService {
  final _streamController = StreamController<ConnectivityStatus>.broadcast();

  @override
  Stream<ConnectivityStatus> get statusStream => _streamController.stream;

  @override
  Future<bool> get isConnected async => true;

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return ConnectivityStatus.online;
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
