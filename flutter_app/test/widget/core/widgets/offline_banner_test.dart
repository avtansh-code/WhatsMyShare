import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/widgets/offline_banner.dart';
import 'package:whats_my_share/core/services/connectivity_service.dart';
import 'package:whats_my_share/core/services/offline_queue_manager.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('renders offline message when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              syncStatus: SyncStatus.idle,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.text("You're offline"), findsOneWidget);
    });

    testWidgets('does not show banner when online with no pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.idle,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.text("You're offline"), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows syncing state with progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.syncing,
              pendingCount: 3,
            ),
          ),
        ),
      );

      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows pending changes count when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              syncStatus: SyncStatus.idle,
              pendingCount: 5,
            ),
          ),
        ),
      );

      expect(find.textContaining('5 changes will sync'), findsOneWidget);
    });

    testWidgets('shows sync error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.error,
              pendingCount: 2,
            ),
          ),
        ),
      );

      expect(find.text('Sync failed'), findsOneWidget);
    });

    testWidgets('shows completed state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.completed,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.text('All synced!'), findsOneWidget);
    });

    testWidgets('shows offline icon when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              syncStatus: SyncStatus.idle,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows error icon when sync error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.error,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows sync button when online with pending changes', (
      tester,
    ) async {
      bool syncPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.idle,
              pendingCount: 3,
              onSyncPressed: () => syncPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('SYNC NOW'), findsOneWidget);

      await tester.tap(find.text('SYNC NOW'));
      await tester.pumpAndSettle();

      expect(syncPressed, isTrue);
    });

    testWidgets('hides sync button when syncing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.syncing,
              pendingCount: 3,
            ),
          ),
        ),
      );

      expect(find.text('SYNC NOW'), findsNothing);
    });

    testWidgets('hides sync button when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              syncStatus: SyncStatus.idle,
              pendingCount: 3,
            ),
          ),
        ),
      );

      expect(find.text('SYNC NOW'), findsNothing);
    });

    testWidgets('shows pending changes message when idle with pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.idle,
              pendingCount: 2,
            ),
          ),
        ),
      );

      expect(find.text('Pending changes'), findsOneWidget);
      expect(find.textContaining('2 changes waiting'), findsOneWidget);
    });

    testWidgets('singular text for 1 pending change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.online,
              syncStatus: SyncStatus.idle,
              pendingCount: 1,
            ),
          ),
        ),
      );

      expect(find.textContaining('1 change waiting'), findsOneWidget);
    });
  });

  group('SyncStatusIndicator', () {
    testWidgets('does not show when idle with no pending', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.idle,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows progress when syncing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.syncing,
              pendingCount: 1,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows badge with pending count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.idle,
              pendingCount: 5,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 9+ for large pending count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.idle,
              pendingCount: 15,
            ),
          ),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.idle,
              pendingCount: 3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows error icon when sync error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.error,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('shows done icon when completed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              syncStatus: SyncStatus.completed,
              pendingCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });
  });
}
