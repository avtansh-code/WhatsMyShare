import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'logging_service.dart';

/// Status of network connectivity
enum ConnectivityStatus { online, offline }

/// Service for monitoring network connectivity
abstract class ConnectivityService {
  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream;

  /// Check if currently connected
  Future<bool> get isConnected;

  /// Get current connectivity status
  Future<ConnectivityStatus> checkConnectivity();

  /// Dispose resources
  void dispose();
}

/// Implementation of connectivity service using connectivity_plus
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();
  final LoggingService _log = LoggingService();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initialize();
  }

  void _initialize() {
    _log.debug('Initializing connectivity service', tag: LogTags.network);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Check initial status
    checkConnectivity();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final newStatus = _mapResultsToStatus(results);
    if (newStatus != _currentStatus) {
      _log.info(
        'Connectivity changed',
        tag: LogTags.network,
        data: {
          'previousStatus': _currentStatus.name,
          'newStatus': newStatus.name,
          'results': results.map((r) => r.name).toList(),
        },
      );
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  ConnectivityStatus _mapResultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  @override
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> get isConnected async {
    final status = await checkConnectivity();
    return status == ConnectivityStatus.online;
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    _log.debug('Checking connectivity', tag: LogTags.network);
    final results = await _connectivity.checkConnectivity();
    _currentStatus = _mapResultsToStatus(results);
    _log.debug(
      'Connectivity check result',
      tag: LogTags.network,
      data: {'status': _currentStatus.name},
    );
    return _currentStatus;
  }

  @override
  void dispose() {
    _log.debug('Disposing connectivity service', tag: LogTags.network);
    _subscription?.cancel();
    _statusController.close();
  }
}
