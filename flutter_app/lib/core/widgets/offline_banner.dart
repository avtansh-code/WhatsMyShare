import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/offline_queue_manager.dart';

/// Banner widget that displays when the app is offline
class OfflineBanner extends StatelessWidget {
  final ConnectivityStatus status;
  final SyncStatus syncStatus;
  final int pendingCount;
  final VoidCallback? onSyncPressed;

  const OfflineBanner({
    super.key,
    required this.status,
    required this.syncStatus,
    required this.pendingCount,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if online and no pending operations
    if (status == ConnectivityStatus.online &&
        pendingCount == 0 &&
        syncStatus == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _shouldShow ? null : 0,
      child: Material(
        color: _backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_subtitle != null)
                        Text(
                          _subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_showSyncButton)
                  TextButton(
                    onPressed: onSyncPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('SYNC NOW'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _shouldShow {
    if (status == ConnectivityStatus.offline) return true;
    if (syncStatus == SyncStatus.syncing) return true;
    if (syncStatus == SyncStatus.error) return true;
    if (pendingCount > 0) return true;
    return false;
  }

  Color get _backgroundColor {
    if (status == ConnectivityStatus.offline) {
      return Colors.grey[800]!;
    }
    switch (syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue[700]!;
      case SyncStatus.error:
        return Colors.red[700]!;
      case SyncStatus.completed:
        return Colors.green[700]!;
      case SyncStatus.idle:
        if (pendingCount > 0) {
          return Colors.orange[700]!;
        }
        return Colors.grey[800]!;
    }
  }

  Widget _buildIcon() {
    if (status == ConnectivityStatus.offline) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 20);
    }
    switch (syncStatus) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.error:
        return const Icon(Icons.error_outline, color: Colors.white, size: 20);
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.white, size: 20);
      case SyncStatus.idle:
        if (pendingCount > 0) {
          return const Icon(Icons.sync, color: Colors.white, size: 20);
        }
        return const Icon(Icons.cloud_done, color: Colors.white, size: 20);
    }
  }

  String get _title {
    if (status == ConnectivityStatus.offline) {
      return 'You\'re offline';
    }
    switch (syncStatus) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.completed:
        return 'All synced!';
      case SyncStatus.idle:
        if (pendingCount > 0) {
          return 'Pending changes';
        }
        return 'Connected';
    }
  }

  String? get _subtitle {
    if (status == ConnectivityStatus.offline) {
      if (pendingCount > 0) {
        return '$pendingCount change${pendingCount > 1 ? 's' : ''} will sync when online';
      }
      return 'Changes will sync when back online';
    }
    switch (syncStatus) {
      case SyncStatus.syncing:
        return 'Uploading $pendingCount change${pendingCount > 1 ? 's' : ''}...';
      case SyncStatus.error:
        return 'Some changes could not be synced';
      case SyncStatus.completed:
        return null;
      case SyncStatus.idle:
        if (pendingCount > 0) {
          return '$pendingCount change${pendingCount > 1 ? 's' : ''} waiting to sync';
        }
        return null;
    }
  }

  bool get _showSyncButton {
    if (status == ConnectivityStatus.offline) return false;
    if (syncStatus == SyncStatus.syncing) return false;
    if (syncStatus == SyncStatus.error) return true;
    if (pendingCount > 0 && syncStatus == SyncStatus.idle) return true;
    return false;
  }
}

/// A more compact sync status indicator for app bars
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus syncStatus;
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    required this.syncStatus,
    required this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (syncStatus == SyncStatus.idle && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            _buildIcon(context),
            if (pendingCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    pendingCount > 9 ? '9+' : '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    switch (syncStatus) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.error:
        return Icon(Icons.sync_problem, color: Colors.red[400], size: 24);
      case SyncStatus.completed:
        return Icon(Icons.cloud_done, color: Colors.green[400], size: 24);
      case SyncStatus.idle:
        return Icon(
          Icons.sync,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        );
    }
  }
}
