import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/models/offline_operation.dart';
import 'package:whats_my_share/core/services/connectivity_service.dart';
import 'package:whats_my_share/core/services/offline_queue_manager.dart';

// Mock classes
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('SyncStatus', () {
    test('should have all expected statuses', () {
      expect(SyncStatus.values.length, equals(4));
      expect(SyncStatus.values.contains(SyncStatus.idle), isTrue);
      expect(SyncStatus.values.contains(SyncStatus.syncing), isTrue);
      expect(SyncStatus.values.contains(SyncStatus.error), isTrue);
      expect(SyncStatus.values.contains(SyncStatus.completed), isTrue);
    });

    test('should have correct names', () {
      expect(SyncStatus.idle.name, equals('idle'));
      expect(SyncStatus.syncing.name, equals('syncing'));
      expect(SyncStatus.error.name, equals('error'));
      expect(SyncStatus.completed.name, equals('completed'));
    });

    test('should have correct indices', () {
      expect(SyncStatus.idle.index, equals(0));
      expect(SyncStatus.syncing.index, equals(1));
      expect(SyncStatus.error.index, equals(2));
      expect(SyncStatus.completed.index, equals(3));
    });
  });

  group('OfflineQueueManager interface', () {
    test('should define required properties', () {
      // Test interface contract via mock
      final mock = _MockOfflineQueueManager();

      expect(mock.syncStatusStream, isNotNull);
      expect(mock.currentStatus, isNotNull);
      expect(mock.pendingCount, isNotNull);
      expect(mock.pendingOperations, isNotNull);
      expect(mock.failedOperations, isNotNull);

      mock.dispose();
    });

    test('should define required methods', () async {
      final mock = _MockOfflineQueueManager();

      // These should not throw - test async methods separately
      await expectLater(mock.initialize(), completes);
      await expectLater(mock.processQueue(), completes);
      await expectLater(mock.clearCompleted(), completes);

      // Dispose at the end
      mock.dispose();
    });
  });

  group('SyncStatus enum usage', () {
    test('can compare statuses', () {
      expect(SyncStatus.idle == SyncStatus.idle, isTrue);
      expect(SyncStatus.idle == SyncStatus.syncing, isFalse);
    });

    test('can switch on status', () {
      const status = SyncStatus.syncing;
      String result;

      switch (status) {
        case SyncStatus.idle:
          result = 'idle';
          break;
        case SyncStatus.syncing:
          result = 'syncing';
          break;
        case SyncStatus.error:
          result = 'error';
          break;
        case SyncStatus.completed:
          result = 'completed';
          break;
      }

      expect(result, equals('syncing'));
    });

    test('can be used in collections', () {
      final statuses = <SyncStatus>{SyncStatus.idle, SyncStatus.completed};

      expect(statuses.contains(SyncStatus.idle), isTrue);
      expect(statuses.contains(SyncStatus.syncing), isFalse);
    });
  });

  group('OfflineQueueManager Status Flow', () {
    test('idle should be the initial state', () {
      expect(SyncStatus.idle.index, equals(0));
    });

    test('status progression should be logical', () {
      // idle -> syncing -> completed/error -> idle
      expect(SyncStatus.idle.index < SyncStatus.syncing.index, isTrue);
    });

    test('error status should be different from completed', () {
      expect(SyncStatus.error, isNot(equals(SyncStatus.completed)));
    });
  });

  group('Queue Operation Types', () {
    test('should support expense operations', () {
      expect(OperationType.createExpense, isNotNull);
      expect(OperationType.updateExpense, isNotNull);
      expect(OperationType.deleteExpense, isNotNull);
    });

    test('should support group operations', () {
      expect(OperationType.createGroup, isNotNull);
      expect(OperationType.updateGroup, isNotNull);
    });

    test('should support settlement operations', () {
      expect(OperationType.createSettlement, isNotNull);
      expect(OperationType.updateSettlement, isNotNull);
    });

    test('should support profile operations', () {
      expect(OperationType.updateProfile, isNotNull);
    });

    test('should support member operations', () {
      expect(OperationType.addGroupMember, isNotNull);
      expect(OperationType.removeGroupMember, isNotNull);
    });
  });

  group('Queue Manager Behavior Patterns', () {
    test('pending count should be non-negative', () {
      final mock = _MockOfflineQueueManager();
      expect(mock.pendingCount >= 0, isTrue);
    });

    test('pending operations should be a list', () {
      final mock = _MockOfflineQueueManager();
      expect(mock.pendingOperations, isA<List<OfflineOperation>>());
    });

    test('failed operations should be a list', () {
      final mock = _MockOfflineQueueManager();
      expect(mock.failedOperations, isA<List<OfflineOperation>>());
    });
  });

  group('Operation Status Integration', () {
    test('operation statuses should align with queue flow', () {
      // Operations go: pending -> inProgress -> completed/failed
      expect(OperationStatus.pending.index, equals(0));
      expect(OperationStatus.inProgress.index, equals(1));
      expect(OperationStatus.completed.index, equals(2));
      expect(OperationStatus.failed.index, equals(3));
    });

    test('pending operations should have pending status', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {'test': 'data'},
        createdAt: DateTime.now(),
      );

      expect(operation.status, equals(OperationStatus.pending));
    });
  });

  group('Stream Behavior', () {
    test('sync status stream should be available', () {
      final mock = _MockOfflineQueueManager();
      expect(mock.syncStatusStream, isA<Stream<SyncStatus>>());
    });

    test('can listen to sync status stream multiple times', () {
      final mock = _MockOfflineQueueManager();

      final listener1 = mock.syncStatusStream.listen((_) {});
      final listener2 = mock.syncStatusStream.listen((_) {});

      expect(listener1, isNotNull);
      expect(listener2, isNotNull);

      listener1.cancel();
      listener2.cancel();
    });
  });

  group('Enqueue Operation', () {
    test('should return operation id', () async {
      final mock = _MockOfflineQueueManager();
      final id = await mock.enqueue(OperationType.createExpense, {
        'test': 'data',
      });

      expect(id, isNotEmpty);
    });

    test('should support optional entityId', () async {
      final mock = _MockOfflineQueueManager();
      final id = await mock.enqueue(OperationType.updateExpense, {
        'test': 'data',
      }, entityId: 'expense-123');

      expect(id, isNotEmpty);
    });

    test('should support optional groupId', () async {
      final mock = _MockOfflineQueueManager();
      final id = await mock.enqueue(OperationType.createExpense, {
        'test': 'data',
      }, groupId: 'group-123');

      expect(id, isNotEmpty);
    });

    test('should support both entityId and groupId', () async {
      final mock = _MockOfflineQueueManager();
      final id = await mock.enqueue(
        OperationType.updateExpense,
        {'test': 'data'},
        entityId: 'expense-123',
        groupId: 'group-123',
      );

      expect(id, isNotEmpty);
    });
  });

  group('Retry Operation', () {
    test('should accept operation id', () async {
      final mock = _MockOfflineQueueManager();

      // Should not throw
      await expectLater(mock.retryOperation('operation-123'), completes);
    });
  });

  group('Clear Operations', () {
    test('clearCompleted should complete', () async {
      final mock = _MockOfflineQueueManager();

      await expectLater(mock.clearCompleted(), completes);
    });

    test('clearFailed should accept operation id', () async {
      final mock = _MockOfflineQueueManager();

      await expectLater(mock.clearFailed('operation-123'), completes);
    });
  });

  group('Initialize and Dispose', () {
    test('initialize should complete', () async {
      final mock = _MockOfflineQueueManager();

      await expectLater(mock.initialize(), completes);
    });

    test('dispose should not throw', () {
      final mock = _MockOfflineQueueManager();

      expect(() => mock.dispose(), returnsNormally);
    });
  });
}

/// Mock implementation for testing the interface
class _MockOfflineQueueManager implements OfflineQueueManager {
  final _streamController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;
  final List<OfflineOperation> _pending = [];
  final List<OfflineOperation> _failed = [];

  @override
  Stream<SyncStatus> get syncStatusStream => _streamController.stream;

  @override
  SyncStatus get currentStatus => _status;

  @override
  int get pendingCount => _pending.length;

  @override
  List<OfflineOperation> get pendingOperations => List.unmodifiable(_pending);

  @override
  List<OfflineOperation> get failedOperations => List.unmodifiable(_failed);

  @override
  Future<String> enqueue(
    OperationType type,
    Map<String, dynamic> data, {
    String? entityId,
    String? groupId,
  }) async {
    final operation = OfflineOperation(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      data: data,
      createdAt: DateTime.now(),
      entityId: entityId,
      groupId: groupId,
    );
    _pending.add(operation);
    return operation.id;
  }

  @override
  Future<void> processQueue() async {
    _status = SyncStatus.syncing;
    _streamController.add(_status);

    await Future.delayed(const Duration(milliseconds: 10));

    _status = SyncStatus.completed;
    _streamController.add(_status);
  }

  @override
  Future<void> retryOperation(String operationId) async {
    // Mock retry
  }

  @override
  Future<void> clearCompleted() async {
    // Mock clear
  }

  @override
  Future<void> clearFailed(String operationId) async {
    // Mock clear failed
  }

  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
