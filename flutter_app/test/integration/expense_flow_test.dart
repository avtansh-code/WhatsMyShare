/// Integration tests for expense management flow
///
/// These tests verify the complete expense management flow including:
/// - Expense creation with different split types
/// - Expense updates
/// - Expense deletion
/// - Balance calculations
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

    // Create a test group for expenses
    testGroupId = await SeedData.createTestGroup(
      firestore: firestore,
      name: 'Expense Test Group',
      creatorId: testUserId,
      memberIds: [testUserId, 'member2', 'member3'],
    );
  });

  tearDown(() async {
    await TestCleanup.clearCollection(firestore, 'expenses');
    await TestCleanup.clearCollection(firestore, 'groups');
    await TestCleanup.cleanupCurrentUser(auth);
  });

  group('Expense Creation Flow', () {
    test('should create expense with equal split', () async {
      // Arrange
      const amount = 300.0;
      final splitAmounts = {
        testUserId: 100.0,
        'member2': 100.0,
        'member3': 100.0,
      };

      // Act
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Dinner',
        amount: amount,
        paidById: testUserId,
        splitAmounts: splitAmounts,
      );

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      expect(expenseDoc.exists, isTrue);
      expect(expenseDoc.data()!['amount'], equals(amount));
      expect(expenseDoc.data()!['paidById'], equals(testUserId));

      final splits = Map<String, dynamic>.from(
        expenseDoc.data()!['splitAmounts'],
      );
      expect(splits.length, equals(3));
      expect(splits[testUserId], equals(100.0));
    });

    test('should create expense with custom split', () async {
      // Arrange - Custom split where one person pays more
      const amount = 100.0;
      final splitAmounts = {testUserId: 50.0, 'member2': 30.0, 'member3': 20.0};

      // Act
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Custom Split Expense',
        amount: amount,
        paidById: testUserId,
        splitAmounts: splitAmounts,
      );

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      final splits = Map<String, dynamic>.from(
        expenseDoc.data()!['splitAmounts'],
      );

      expect(splits[testUserId], equals(50.0));
      expect(splits['member2'], equals(30.0));
      expect(splits['member3'], equals(20.0));
    });

    test('should associate expense with group', () async {
      // Act
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Group Expense',
        amount: 150.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 75.0, 'member2': 75.0},
      );

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      expect(expenseDoc.data()!['groupId'], equals(testGroupId));
    });
  });

  group('Expense Query Flow', () {
    test('should fetch all expenses for a group', () async {
      // Arrange - Create multiple expenses
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Expense 1',
        amount: 100.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 50.0, 'member2': 50.0},
      );
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Expense 2',
        amount: 200.0,
        paidById: 'member2',
        splitAmounts: {testUserId: 100.0, 'member2': 100.0},
      );

      // Act
      final snapshot = await firestore
          .collection('expenses')
          .where('groupId', isEqualTo: testGroupId)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(2));
    });

    test('should fetch only active expenses', () async {
      // Arrange
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Active Expense',
        amount: 100.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 50.0, 'member2': 50.0},
      );

      // Create deleted expense
      await firestore.collection('expenses').add({
        'groupId': testGroupId,
        'description': 'Deleted Expense',
        'amount': 50.0,
        'paidById': testUserId,
        'splitAmounts': {testUserId: 25.0, 'member2': 25.0},
        'isActive': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Act
      final snapshot = await firestore
          .collection('expenses')
          .where('groupId', isEqualTo: testGroupId)
          .where('isActive', isEqualTo: true)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(1));
    });
  });

  group('Expense Update Flow', () {
    test('should update expense amount', () async {
      // Arrange
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Original Expense',
        amount: 100.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 50.0, 'member2': 50.0},
      );

      // Act
      await firestore.collection('expenses').doc(expenseId).update({
        'amount': 150.0,
        'splitAmounts': {testUserId: 75.0, 'member2': 75.0},
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      expect(expenseDoc.data()!['amount'], equals(150.0));
    });

    test('should update expense description', () async {
      // Arrange
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Original Description',
        amount: 100.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 50.0, 'member2': 50.0},
      );

      // Act
      await firestore.collection('expenses').doc(expenseId).update({
        'description': 'Updated Description',
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      expect(expenseDoc.data()!['description'], equals('Updated Description'));
    });
  });

  group('Expense Deletion Flow', () {
    test('should soft delete expense', () async {
      // Arrange
      final expenseId = await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Expense to Delete',
        amount: 100.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 50.0, 'member2': 50.0},
      );

      // Act
      await firestore.collection('expenses').doc(expenseId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final expenseDoc = await firestore
          .collection('expenses')
          .doc(expenseId)
          .get();
      expect(expenseDoc.exists, isTrue);
      expect(expenseDoc.data()!['isActive'], isFalse);
    });
  });

  group('Balance Calculation Flow', () {
    test('should calculate correct balances after expense', () async {
      // Arrange - User pays 300, split equally among 3
      await SeedData.createTestExpense(
        firestore: firestore,
        groupId: testGroupId,
        description: 'Group Dinner',
        amount: 300.0,
        paidById: testUserId,
        splitAmounts: {testUserId: 100.0, 'member2': 100.0, 'member3': 100.0},
      );

      // Act - Query expenses to calculate balances
      final snapshot = await firestore
          .collection('expenses')
          .where('groupId', isEqualTo: testGroupId)
          .where('isActive', isEqualTo: true)
          .get();

      // Calculate balances
      final balances = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final paidBy = data['paidById'] as String;
        final amount = (data['amount'] as num).toDouble();
        final splits = Map<String, dynamic>.from(data['splitAmounts']);

        // Add to payer's balance (they are owed)
        balances[paidBy] = (balances[paidBy] ?? 0) + amount;

        // Subtract each person's share
        splits.forEach((userId, share) {
          balances[userId] =
              (balances[userId] ?? 0) - (share as num).toDouble();
        });
      }

      // Assert
      // testUser paid 300, owes 100 -> net +200
      // member2 paid 0, owes 100 -> net -100
      // member3 paid 0, owes 100 -> net -100
      expect(balances[testUserId], equals(200.0));
      expect(balances['member2'], equals(-100.0));
      expect(balances['member3'], equals(-100.0));
    });
  });
}
