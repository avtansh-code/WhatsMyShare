import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/offline_operation.dart';
import 'connectivity_service.dart';
import 'logging_service.dart';

/// Sync status for the queue
enum SyncStatus { idle, syncing, error, completed }

/// Manages offline operations queue with Hive persistence
abstract class OfflineQueueManager {
  /// Stream of sync status changes
  Stream<SyncStatus> get syncStatusStream;

  /// Current sync status
  SyncStatus get currentStatus;

  /// Number of pending operations
  int get pendingCount;

  /// List of pending operations
  List<OfflineOperation> get pendingOperations;

  /// List of failed operations
  List<OfflineOperation> get failedOperations;

  /// Enqueue a new operation
  Future<String> enqueue(
    OperationType type,
    Map<String, dynamic> data, {
    String? entityId,
    String? groupId,
  });

  /// Process all pending operations
  Future<void> processQueue();

  /// Retry a specific failed operation
  Future<void> retryOperation(String operationId);

  /// Clear all completed operations
  Future<void> clearCompleted();

  /// Clear a specific failed operation
  Future<void> clearFailed(String operationId);

  /// Initialize the queue
  Future<void> initialize();

  /// Dispose resources
  void dispose();
}

/// Implementation of offline queue manager using Hive
class OfflineQueueManagerImpl implements OfflineQueueManager {
  static const String _boxName = 'offline_operations';

  final ConnectivityService _connectivityService;
  final Future<void> Function(OfflineOperation operation) _operationExecutor;
  final LoggingService _log = LoggingService();

  Box<String>? _box;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = SyncStatus.idle;
  final _uuid = const Uuid();

  OfflineQueueManagerImpl({
    required ConnectivityService connectivityService,
    required Future<void> Function(OfflineOperation operation)
    operationExecutor,
  }) : _connectivityService = connectivityService,
       _operationExecutor = operationExecutor {
    _log.debug('OfflineQueueManager created', tag: LogTags.sync);
  }

  @override
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  int get pendingCount =>
      _getOperationsByStatus(OperationStatus.pending).length;

  @override
  List<OfflineOperation> get pendingOperations =>
      _getOperationsByStatus(OperationStatus.pending);

  @override
  List<OfflineOperation> get failedOperations =>
      _getOperationsByStatus(OperationStatus.failed);

  List<OfflineOperation> _getOperationsByStatus(OperationStatus status) {
    if (_box == null) return [];
    return _box!.values
        .map((json) => OfflineOperation.fromJson(jsonDecode(json)))
        .where((op) => op.status == status)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<OfflineOperation> get _allOperations {
    if (_box == null) return [];
    return _box!.values
        .map((json) => OfflineOperation.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> initialize() async {
    _log.info('Initializing offline queue', tag: LogTags.sync);
    _box = await Hive.openBox<String>(_boxName);
    _log.debug(
      'Hive box opened',
      tag: LogTags.sync,
      data: {'pendingCount': pendingCount},
    );

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.statusStream.listen((
      status,
    ) {
      _log.debug(
        'Connectivity status in queue',
        tag: LogTags.sync,
        data: {'status': status.name},
      );
      if (status == ConnectivityStatus.online) {
        processQueue();
      }
    });
  }

  @override
  Future<String> enqueue(
    OperationType type,
    Map<String, dynamic> data, {
    String? entityId,
    String? groupId,
  }) async {
    final operation = OfflineOperation(
      id: _uuid.v4(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
      entityId: entityId,
      groupId: groupId,
    );

    _log.info(
      'Enqueueing operation',
      tag: LogTags.sync,
      data: {
        'operationId': operation.id,
        'type': type.name,
        'entityId': entityId,
        'groupId': groupId,
      },
    );

    await _saveOperation(operation);

    // Try to process immediately if online
    final isOnline = await _connectivityService.isConnected;
    if (isOnline) {
      _log.debug('Online, processing queue immediately', tag: LogTags.sync);
      processQueue();
    } else {
      _log.debug('Offline, operation queued for later', tag: LogTags.sync);
    }

    return operation.id;
  }

  @override
  Future<void> processQueue() async {
    if (_currentStatus == SyncStatus.syncing) {
      _log.debug('Already syncing, skipping', tag: LogTags.sync);
      return;
    }

    final isOnline = await _connectivityService.isConnected;
    if (!isOnline) {
      _log.debug('Offline, cannot process queue', tag: LogTags.sync);
      return;
    }

    final pending = pendingOperations;
    if (pending.isEmpty) {
      _log.debug('No pending operations', tag: LogTags.sync);
      return;
    }

    _log.info(
      'Processing queue',
      tag: LogTags.sync,
      data: {'pendingCount': pending.length},
    );
    _updateStatus(SyncStatus.syncing);

    bool hasErrors = false;
    int successCount = 0;
    int failCount = 0;

    for (final operation in pending) {
      try {
        _log.debug(
          'Processing operation',
          tag: LogTags.sync,
          data: {'operationId': operation.id, 'type': operation.type.name},
        );

        // Mark as in progress
        await _saveOperation(operation.markInProgress());

        // Execute the operation
        await _operationExecutor(operation);

        // Mark as completed
        await _saveOperation(operation.markCompleted());
        successCount++;
        _log.debug(
          'Operation completed',
          tag: LogTags.sync,
          data: {'operationId': operation.id},
        );
      } catch (e) {
        hasErrors = true;
        failCount++;
        _log.error(
          'Operation failed',
          tag: LogTags.sync,
          data: {
            'operationId': operation.id,
            'error': e.toString(),
            'retryCount': operation.retryCount,
          },
        );

        final updated = operation.incrementRetry();

        if (updated.hasExceededMaxRetries) {
          _log.warning(
            'Operation exceeded max retries, marking as failed',
            tag: LogTags.sync,
            data: {'operationId': operation.id},
          );
          await _saveOperation(updated.markFailed(e.toString()));
        } else {
          _log.debug(
            'Operation will be retried',
            tag: LogTags.sync,
            data: {
              'operationId': operation.id,
              'nextRetry': updated.retryCount,
            },
          );
          // Reset to pending for retry
          await _saveOperation(
            updated.copyWith(status: OperationStatus.pending),
          );
        }
      }
    }

    _log.info(
      'Queue processing complete',
      tag: LogTags.sync,
      data: {'successCount': successCount, 'failCount': failCount},
    );
    _updateStatus(hasErrors ? SyncStatus.error : SyncStatus.completed);

    // Reset to idle after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentStatus != SyncStatus.syncing) {
        _updateStatus(SyncStatus.idle);
      }
    });
  }

  @override
  Future<void> retryOperation(String operationId) async {
    _log.info(
      'Retrying operation',
      tag: LogTags.sync,
      data: {'operationId': operationId},
    );

    final operations = _allOperations;
    final operation = operations.firstWhere(
      (op) => op.id == operationId,
      orElse: () => throw Exception('Operation not found'),
    );

    // Reset to pending
    await _saveOperation(
      operation.copyWith(
        status: OperationStatus.pending,
        retryCount: 0,
        errorMessage: null,
      ),
    );

    // Try to process
    processQueue();
  }

  @override
  Future<void> clearCompleted() async {
    if (_box == null) return;

    final completed = _getOperationsByStatus(OperationStatus.completed);
    _log.info(
      'Clearing completed operations',
      tag: LogTags.sync,
      data: {'count': completed.length},
    );
    for (final op in completed) {
      await _box!.delete(op.id);
    }
  }

  @override
  Future<void> clearFailed(String operationId) async {
    if (_box == null) return;
    _log.info(
      'Clearing failed operation',
      tag: LogTags.sync,
      data: {'operationId': operationId},
    );
    await _box!.delete(operationId);
  }

  Future<void> _saveOperation(OfflineOperation operation) async {
    if (_box == null) return;
    await _box!.put(operation.id, jsonEncode(operation.toJson()));
  }

  void _updateStatus(SyncStatus status) {
    _log.debug(
      'Sync status updated',
      tag: LogTags.sync,
      data: {'status': status.name},
    );
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  void dispose() {
    _log.debug('Disposing offline queue manager', tag: LogTags.sync);
    _connectivitySubscription?.cancel();
    _statusController.close();
    _box?.close();
  }
}
