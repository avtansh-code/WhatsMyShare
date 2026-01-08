import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

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

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initialize();
  }

  void _initialize() {
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
    final results = await _connectivity.checkConnectivity();
    _currentStatus = _mapResultsToStatus(results);
    return _currentStatus;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
