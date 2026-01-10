/// Integration test helper for Firebase Emulator Suite
///
/// This helper provides utilities for connecting to Firebase emulators
/// and setting up test data for integration tests.
///
/// NOTE: True Firebase integration tests require running on a device/emulator
/// using the `integration_test` package. These tests use mock packages to
/// simulate Firebase behavior in unit tests.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Emulator configuration
class EmulatorConfig {
  static const String host = 'localhost';
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;

  /// Whether to use emulators (set to false for production tests)
  static const bool useEmulators = true;

  /// Check if emulators are running
  static Future<bool> areEmulatorsRunning() async {
    try {
      final socket = await Socket.connect(
        host,
        authPort,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Mock Firebase instances for testing
/// These work in pure Dart VM without platform channels
class MockFirebaseInstances {
  static FakeFirebaseFirestore? _firestore;
  static MockFirebaseAuth? _auth;

  /// Get or create mock Firestore instance
  static FakeFirebaseFirestore get firestore {
    _firestore ??= FakeFirebaseFirestore();
    return _firestore!;
  }

  /// Get or create mock Auth instance
  static MockFirebaseAuth get auth {
    _auth ??= MockFirebaseAuth();
    return _auth!;
  }

  /// Reset all mock instances
  static void reset() {
    _firestore = FakeFirebaseFirestore();
    _auth = MockFirebaseAuth();
  }
}

/// Initializes Firebase for integration tests
/// Uses mock implementations that work in VM
Future<void> initializeFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // No actual Firebase initialization needed for mocks
}

/// Connects all Firebase services to local emulators
/// For mock tests, this is a no-op since we use fake implementations
Future<bool> connectToEmulators() async {
  // Check if emulators are running (informational only)
  final running = await EmulatorConfig.areEmulatorsRunning();
  if (running) {
    // Emulators are running, but we use mocks in VM tests
    // To use real emulators, tests must run on device with integration_test
  }
  return true; // Mocks are always "connected"
}

/// Skip test if emulators are not running
void skipIfEmulatorsNotRunning() {
  setUpAll(() async {
    final running = await EmulatorConfig.areEmulatorsRunning();
    if (!running) {
      markTestSkipped(
        'Firebase emulators not running. Run: firebase emulators:start',
      );
    }
  });
}

/// Test user credentials for integration tests
class TestUsers {
  static const testUser1 = TestUserCredentials(
    email: 'testuser1@example.com',
    password: 'Test123!@#',
    displayName: 'Test User One',
  );

  static const testUser2 = TestUserCredentials(
    email: 'testuser2@example.com',
    password: 'Test456!@#',
    displayName: 'Test User Two',
  );

  static const testUser3 = TestUserCredentials(
    email: 'testuser3@example.com',
    password: 'Test789!@#',
    displayName: 'Test User Three',
  );
}

/// Test user credentials container
class TestUserCredentials {
  final String email;
  final String password;
  final String displayName;

  const TestUserCredentials({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// Seed data for Firestore
class SeedData {
  /// Creates a test group in Firestore
  static Future<String> createTestGroup({
    required FirebaseFirestore firestore,
    required String name,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    final groupRef = firestore.collection('groups').doc();
    final now = DateTime.now();

    await groupRef.set({
      'name': name,
      'description': 'Test group for integration tests',
      'creatorId': creatorId,
      'memberIds': memberIds,
      'currency': 'INR',
      'imageUrl': null,
      'totalExpenses': 0.0,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return groupRef.id;
  }

  /// Creates a test expense in Firestore
  static Future<String> createTestExpense({
    required FirebaseFirestore firestore,
    required String groupId,
    required String description,
    required double amount,
    required String paidById,
    required Map<String, double> splitAmounts,
  }) async {
    final expenseRef = firestore.collection('expenses').doc();
    final now = DateTime.now();

    await expenseRef.set({
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'currency': 'INR',
      'paidById': paidById,
      'splitType': 'equal',
      'splitAmounts': splitAmounts,
      'category': 'general',
      'date': Timestamp.fromDate(now),
      'receiptUrl': null,
      'notes': null,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return expenseRef.id;
  }

  /// Creates a test settlement in Firestore
  static Future<String> createTestSettlement({
    required FirebaseFirestore firestore,
    required String groupId,
    required String payerId,
    required String receiverId,
    required double amount,
  }) async {
    final settlementRef = firestore.collection('settlements').doc();
    final now = DateTime.now();

    await settlementRef.set({
      'groupId': groupId,
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
      'currency': 'INR',
      'status': 'pending',
      'notes': null,
      'createdAt': Timestamp.fromDate(now),
      'settledAt': null,
    });

    return settlementRef.id;
  }

  /// Creates a test user profile in Firestore
  static Future<void> createTestUserProfile({
    required FirebaseFirestore firestore,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final now = DateTime.now();

    await firestore.collection('users').doc(userId).set({
      'email': email,
      'displayName': displayName,
      'photoUrl': null,
      'phone': null,
      'defaultCurrency': 'INR',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }
}

/// Cleanup utilities for tests
class TestCleanup {
  /// Deletes all documents in a collection
  static Future<void> clearCollection(
    FirebaseFirestore firestore,
    String collectionPath,
  ) async {
    final snapshot = await firestore.collection(collectionPath).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Clears all test data from Firestore
  static Future<void> clearAllTestData(FirebaseFirestore firestore) async {
    await clearCollection(firestore, 'users');
    await clearCollection(firestore, 'groups');
    await clearCollection(firestore, 'expenses');
    await clearCollection(firestore, 'settlements');
    await clearCollection(firestore, 'notifications');
    await clearCollection(firestore, 'chat_messages');
  }

  /// Signs out current user (for mock auth)
  static Future<void> cleanupCurrentUser(MockFirebaseAuth auth) async {
    await auth.signOut();
  }

  /// Signs out current user (generic version for any auth type)
  static Future<void> signOutUser(dynamic auth) async {
    await auth.signOut();
  }
}

/// Integration test assertions
class IntegrationAssertions {
  /// Verifies that a document exists in Firestore
  static Future<bool> documentExists(
    FirebaseFirestore firestore,
    String collectionPath,
    String docId,
  ) async {
    final doc = await firestore.collection(collectionPath).doc(docId).get();
    return doc.exists;
  }

  /// Verifies that a user exists in Firebase Auth
  static Future<bool> userExists(MockFirebaseAuth auth, String email) async {
    // Mock implementation - check if current user has this email
    final user = auth.currentUser;
    return user?.email == email;
  }

  /// Gets the count of documents in a collection
  static Future<int> collectionCount(
    FirebaseFirestore firestore,
    String collectionPath,
  ) async {
    final snapshot = await firestore.collection(collectionPath).get();
    return snapshot.docs.length;
  }
}
