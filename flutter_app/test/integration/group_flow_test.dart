/// Integration tests for group management flow
///
/// These tests verify the complete group management flow including:
/// - Group creation
/// - Member management
/// - Group updates
/// - Group deletion
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
  });

  tearDown(() async {
    // Clean up after each test
    await TestCleanup.clearCollection(firestore, 'groups');
    await TestCleanup.cleanupCurrentUser(auth);
  });

  group('Group Creation Flow', () {
    test('should successfully create a new group', () async {
      // Act
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Test Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Assert
      expect(groupId, isNotEmpty);

      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.exists, isTrue);
      expect(groupDoc.data()!['name'], equals('Test Group'));
      expect(groupDoc.data()!['creatorId'], equals(testUserId));
    });

    test('should create group with multiple members', () async {
      // Arrange
      const member2Id = 'member2_id';
      const member3Id = 'member3_id';

      // Act
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Multi-Member Group',
        creatorId: testUserId,
        memberIds: [testUserId, member2Id, member3Id],
      );

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      final memberIds = List<String>.from(groupDoc.data()!['memberIds']);

      expect(memberIds.length, equals(3));
      expect(memberIds, contains(testUserId));
      expect(memberIds, contains(member2Id));
      expect(memberIds, contains(member3Id));
    });

    test('should set creator as first member automatically', () async {
      // Act
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Creator First Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      final memberIds = List<String>.from(groupDoc.data()!['memberIds']);

      expect(memberIds.first, equals(testUserId));
    });

    test('should set default currency when creating group', () async {
      // Act
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Currency Test Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.data()!['currency'], equals('INR'));
    });
  });

  group('Group Query Flow', () {
    test('should fetch all groups for a user', () async {
      // Arrange - Create multiple groups
      await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Group 1',
        creatorId: testUserId,
        memberIds: [testUserId],
      );
      await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Group 2',
        creatorId: testUserId,
        memberIds: [testUserId],
      );
      await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Group 3',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Act
      final snapshot = await firestore
          .collection('groups')
          .where('memberIds', arrayContains: testUserId)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(3));
    });

    test('should fetch only active groups', () async {
      // Arrange - Create active group
      await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Active Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Create inactive group directly
      await firestore.collection('groups').add({
        'name': 'Inactive Group',
        'creatorId': testUserId,
        'memberIds': [testUserId],
        'isActive': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Act
      final snapshot = await firestore
          .collection('groups')
          .where('memberIds', arrayContains: testUserId)
          .where('isActive', isEqualTo: true)
          .get();

      // Assert
      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.data()['name'], equals('Active Group'));
    });
  });

  group('Group Update Flow', () {
    test('should update group name', () async {
      // Arrange
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Original Name',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Act
      await firestore.collection('groups').doc(groupId).update({
        'name': 'Updated Name',
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.data()!['name'], equals('Updated Name'));
    });

    test('should update group description', () async {
      // Arrange
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Test Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Act
      await firestore.collection('groups').doc(groupId).update({
        'description': 'New description for the group',
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(
        groupDoc.data()!['description'],
        equals('New description for the group'),
      );
    });
  });

  group('Member Management Flow', () {
    test('should add a new member to group', () async {
      // Arrange
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Add Member Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      const newMemberId = 'new_member_id';

      // Act - Use FieldValue.arrayUnion for fake_cloud_firestore
      final doc = await firestore.collection('groups').doc(groupId).get();
      final currentMembers = List<String>.from(doc.data()!['memberIds']);
      currentMembers.add(newMemberId);
      await firestore.collection('groups').doc(groupId).update({
        'memberIds': currentMembers,
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      final memberIds = List<String>.from(groupDoc.data()!['memberIds']);

      expect(memberIds.length, equals(2));
      expect(memberIds, contains(newMemberId));
    });

    test('should remove a member from group', () async {
      // Arrange
      const memberToRemove = 'member_to_remove';
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Remove Member Group',
        creatorId: testUserId,
        memberIds: [testUserId, memberToRemove],
      );

      // Act
      final doc = await firestore.collection('groups').doc(groupId).get();
      final currentMembers = List<String>.from(doc.data()!['memberIds']);
      currentMembers.remove(memberToRemove);
      await firestore.collection('groups').doc(groupId).update({
        'memberIds': currentMembers,
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      final memberIds = List<String>.from(groupDoc.data()!['memberIds']);

      expect(memberIds.length, equals(1));
      expect(memberIds, isNot(contains(memberToRemove)));
    });
  });

  group('Group Deletion Flow', () {
    test('should soft delete a group by setting isActive to false', () async {
      // Arrange
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Group To Delete',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Act
      await firestore.collection('groups').doc(groupId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // Assert
      final groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.exists, isTrue);
      expect(groupDoc.data()!['isActive'], isFalse);
    });

    test('should hard delete a group document', () async {
      // Arrange
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Group To Hard Delete',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // Verify group exists
      var groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.exists, isTrue);

      // Act
      await firestore.collection('groups').doc(groupId).delete();

      // Assert
      groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.exists, isFalse);
    });
  });

  group('Complete Group Flow', () {
    test('should complete full group lifecycle', () async {
      // 1. Create group
      final groupId = await SeedData.createTestGroup(
        firestore: firestore,
        name: 'Lifecycle Group',
        creatorId: testUserId,
        memberIds: [testUserId],
      );

      // 2. Verify creation
      var groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.exists, isTrue);
      expect(groupDoc.data()!['name'], equals('Lifecycle Group'));

      // 3. Add members
      await firestore.collection('groups').doc(groupId).update({
        'memberIds': [testUserId, 'member2', 'member3'],
      });

      groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(
        List<String>.from(groupDoc.data()!['memberIds']).length,
        equals(3),
      );

      // 4. Update group info
      await firestore.collection('groups').doc(groupId).update({
        'name': 'Updated Lifecycle Group',
        'description': 'Updated description',
      });

      groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.data()!['name'], equals('Updated Lifecycle Group'));

      // 5. Remove a member
      await firestore.collection('groups').doc(groupId).update({
        'memberIds': [testUserId, 'member2'],
      });

      groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(
        List<String>.from(groupDoc.data()!['memberIds']).length,
        equals(2),
      );

      // 6. Deactivate group
      await firestore.collection('groups').doc(groupId).update({
        'isActive': false,
      });

      groupDoc = await firestore.collection('groups').doc(groupId).get();
      expect(groupDoc.data()!['isActive'], isFalse);
    });
  });
}
