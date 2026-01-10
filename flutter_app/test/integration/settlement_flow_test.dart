/// Integration tests for settlement flow
///
/// These tests verify the complete settlement flow including:
/// - Settlement creation
/// - Settlement confirmation
/// - Balance updates after settlement
///
/// Requirements:
/// - Uses mock Firebase implementations for VM testing
@Tags(['integration'])
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helper.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late String testUserId;
  late String testGroupId;

  setUpAll(() async {
    await initializeFirebaseForTests();
  });

  setUp(() async {
    // Create fresh mock instances for each test
    MockFirebaseInstances.reset();
    auth = MockFirebaseInstances.auth;
    firestore = MockFirebaseInstances.firestore;

    // Create and sign in test user
    final credentials = TestUsers.testUser1;
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: credentials.email,
      password: credentials.password,
    );
    testUserId = userCredential.user!.uid;

    // Create a test group
    testGroupId = await SeedData.createTestGroup(
      firestore: firestore,
      name: 'Settlement Test Group',
      creatorId: testUserId,
      memberIds: [testUserId, 'member2', 'member3'],
    );
  });

  tearDown(() async {
    await TestCleanup.clearCollection(firestore, 'settlements');
    await TestCleanup.clearCollection(firestore, 'expenses');
    await TestCleanup.clearCollection(firestore, 'groups');
    await TestCleanup.cleanupCurrentUser(auth);
  });

  group('Settlement Creation Flow', () {
    test('should create a pending settlement', () async {
      // Act
      final settlementId = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      // Assert
      final settlementDoc = await firestore
          .collection('settlements')
          .doc(settlementId)
          .get();
      expect(settlementDoc.exists, isTrue);
      expect(settlementDoc.data()!['status'], equals('pending'));
      expect(settlementDoc.data()!['amount'], equals(100.0));
      expect(settlementDoc.data()!['payerId'], equals('member2'));
      expect(settlementDoc.data()!['receiverId'], equals(testUserId));
    });

    test('should associate settlement with group', () async {
      // Act
      final settlementId = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 50.0,
      );

      // Assert
      final settlementDoc = await firestore
          .collection('settlements')
          .doc(settlementId)
          .get();
      expect(settlementDoc.data()!['groupId'], equals(testGroupId));
    });
  });

  group('Settlement Query Flow', () {
    test('should fetch all settlements for a group', () async {
      // Arrange
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member3',
        receiverId: testUserId,
        amount: 50.0,
      );

      // Act
      final snapshot = await firestore
          .collection('settlements')
          .where('groupId', isEqualTo: testGroupId)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(2));
    });

    test('should fetch pending settlements only', () async {
      // Arrange
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      // Create completed settlement
      await firestore.collection('settlements').add({
        'groupId': testGroupId,
        'payerId': 'member3',
        'receiverId': testUserId,
        'amount': 50.0,
        'status': 'completed',
        'createdAt': Timestamp.now(),
        'settledAt': Timestamp.now(),
      });

      // Act
      final snapshot = await firestore
          .collection('settlements')
          .where('groupId', isEqualTo: testGroupId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Assert
      expect(snapshot.docs.length, equals(1));
    });

    test('should fetch settlements for a specific user', () async {
      // Arrange
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member3',
        receiverId: 'member2',
        amount: 50.0,
      );

      // Act - Fetch settlements where testUser is receiver
      final snapshot = await firestore
          .collection('settlements')
          .where('receiverId', isEqualTo: testUserId)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(1));
    });
  });

  group('Settlement Confirmation Flow', () {
    test('should mark settlement as completed', () async {
      // Arrange
      final settlementId = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      // Act
      await firestore.collection('settlements').doc(settlementId).update({
        'status': 'completed',
        'settledAt': Timestamp.now(),
      });

      // Assert
      final settlementDoc = await firestore
          .collection('settlements')
          .doc(settlementId)
          .get();
      expect(settlementDoc.data()!['status'], equals('completed'));
      expect(settlementDoc.data()!['settledAt'], isNotNull);
    });

    test('should mark settlement as rejected', () async {
      // Arrange
      final settlementId = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      // Act
      await firestore.collection('settlements').doc(settlementId).update({
        'status': 'rejected',
        'notes': 'Payment not received',
      });

      // Assert
      final settlementDoc = await firestore
          .collection('settlements')
          .doc(settlementId)
          .get();
      expect(settlementDoc.data()!['status'], equals('rejected'));
      expect(settlementDoc.data()!['notes'], equals('Payment not received'));
    });
  });

  group('Balance After Settlement Flow', () {
    test('should clear balance after full settlement', () async {
      // Arrange - Create expense first
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Test Expense',
        amount: 200.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 100.0, 'member2': 100.0},
      );

      // Create settlement
      await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      // Calculate balances including settlements
      final expenseSnapshot = await firestore
          .collection('expenses')
          .where('groupId', isEqualTo: testGroupId)
          .where('isActive', isEqualTo: true)
          .get();

      final settlementSnapshot = await firestore
          .collection('settlements')
          .where('groupId', isEqualTo: testGroupId)
          .get();

      // Calculate expense balances
      final balances = <String, double>{};
      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();
        final paidBy = data['paidById'] as String;
        final amount = (data['amount'] as num).toDouble();
        final splits = Map<String, dynamic>.from(data['splitAmounts']);

        balances[paidBy] = (balances[paidBy] ?? 0) + amount;
        splits.forEach((userId, share) {
          balances[userId] =
              (balances[userId] ?? 0) - (share as num).toDouble();
        });
      }

      // Apply settlements
      for (final doc in settlementSnapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String;
        final receiverId = data['receiverId'] as String;
        final amount = (data['amount'] as num).toDouble();

        balances[payerId] = (balances[payerId] ?? 0) + amount;
        balances[receiverId] = (balances[receiverId] ?? 0) - amount;
      }

      // Assert
      // testUser: paid 200, owes 100, receives 100 settlement -> net 0
      // member2: paid 0, owes 100, pays 100 settlement -> net 0
      expect(balances[testUserId], equals(0.0));
      expect(balances['member2'], equals(0.0));
    });
  });

  group('Complete Settlement Flow', () {
    test('should complete full settlement lifecycle', () async {
      // 1. Create an expense
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Group Dinner',
        amount: 300.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 100.0, 'member2': 100.0, 'member3': 100.0},
      );

      // 2. Create settlements for member2 and member3
      final settlement1Id = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member2',
        receiverId: testUserId,
        amount: 100.0,
      );

      final settlement2Id = await SeedData.createTestSettlement(
        firestore: firestore,
        groupId: testGroupId,
        payerId: 'member3',
        receiverId: testUserId,
        amount: 100.0,
      );

      // 3. Verify both are pending
      var settlement1 = await firestore
          .collection('settlements')
          .doc(settlement1Id)
          .get();
      var settlement2 = await firestore
          .collection('settlements')
          .doc(settlement2Id)
          .get();
      expect(settlement1.data()!['status'], equals('pending'));
      expect(settlement2.data()!['status'], equals('pending'));

      // 4. Mark first settlement as completed
      await firestore.collection('settlements').doc(settlement1Id).update({
        'status': 'completed',
        'settledAt': Timestamp.now(),
      });

      // 5. Mark second settlement as completed
      await firestore.collection('settlements').doc(settlement2Id).update({
        'status': 'completed',
        'settledAt': Timestamp.now(),
      });

      // 6. Verify all completed
      settlement1 = await firestore
          .collection('settlements')
          .doc(settlement1Id)
          .get();
      settlement2 = await firestore
          .collection('settlements')
          .doc(settlement2Id)
          .get();
      expect(settlement1.data()!['status'], equals('completed'));
      expect(settlement2.data()!['status'], equals('completed'));

      // 7. Verify no pending settlements
      final pendingSnapshot = await firestore
          .collection('settlements')
          .where('groupId', isEqualTo: testGroupId)
          .where('status', isEqualTo: 'pending')
          .get();
      expect(pendingSnapshot.docs.length, equals(0));
    });
  });
}
