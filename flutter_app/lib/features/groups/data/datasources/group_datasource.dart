import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/group_entity.dart';
import '../models/group_model.dart';

/// Data source interface for group operations
abstract class GroupDataSource {
  /// Get all groups for the current user
  Future<List<GroupModel>> getGroups();

  /// Watch groups for real-time updates
  Stream<List<GroupModel>> watchGroups();

  /// Get a single group by ID
  Future<GroupModel> getGroupById(String groupId);

  /// Watch a single group
  Stream<GroupModel> watchGroupById(String groupId);

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required GroupType type,
    required String currency,
    bool simplifyDebts = true,
    List<String>? initialMemberIds,
  });

  /// Update group details
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? type,
    String? currency,
    bool? simplifyDebts,
  });

  /// Update group image
  Future<String> updateGroupImage({
    required String groupId,
    required File imageFile,
  });

  /// Delete group image
  Future<void> deleteGroupImage(String groupId);

  /// Delete a group
  Future<void> deleteGroup(String groupId);

  /// Add a member to the group
  Future<GroupModel> addMember({
    required String groupId,
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    MemberRole role = MemberRole.member,
  });

  /// Remove a member from the group
  Future<GroupModel> removeMember({
    required String groupId,
    required String userId,
  });

  /// Update a member's role
  Future<GroupModel> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  });

  /// Leave a group
  Future<void> leaveGroup(String groupId);
}

/// Firebase implementation of GroupDataSource
class GroupDataSourceImpl implements GroupDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  GroupDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth;

  /// Get current user ID or throw exception
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  /// Get groups collection reference
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  @override
  Future<List<GroupModel>> getGroups() async {
    try {
      final userId = _currentUserId;
      final snapshot = await _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to get groups: ${e.message}');
    }
  }

  @override
  Stream<List<GroupModel>> watchGroups() {
    try {
      final userId = _currentUserId;
      return _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => GroupModel.fromFirestore(doc))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to watch groups: ${e.message}');
    }
  }

  @override
  Future<GroupModel> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw const NotFoundException(message: 'Group not found');
      }
      return GroupModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to get group: ${e.message}');
    }
  }

  @override
  @override
  Stream<GroupModel> watchGroupById(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) {
        throw const NotFoundException(message: 'Group not found');
      }
      return GroupModel.fromFirestore(doc);
    });
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required GroupType type,
    required String currency,
    bool simplifyDebts = true,
    List<String>? initialMemberIds,
  }) async {
    try {
      final userId = _currentUserId;
      final user = _auth.currentUser!;

      // Create creator as first member
      final creatorMember = GroupMemberModel(
        userId: userId,
        displayName: user.displayName ?? 'Unknown',
        photoUrl: user.photoURL,
        email: user.email ?? '',
        joinedAt: DateTime.now(),
        role: MemberRole.admin,
      );

      final memberIds = [userId];
      final members = [creatorMember];
      final balances = <String, int>{userId: 0};

      // Add initial members if provided
      // Note: In a real app, you'd fetch user details for each member
      // For now, we just add their IDs
      if (initialMemberIds != null) {
        for (final memberId in initialMemberIds) {
          if (memberId != userId) {
            memberIds.add(memberId);
            balances[memberId] = 0;
          }
        }
      }

      final group = GroupModel(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        type: type,
        members: members,
        memberIds: memberIds,
        memberCount: memberIds.length,
        currency: currency,
        simplifyDebts: simplifyDebts,
        createdBy: userId,
        admins: [userId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalExpenses: 0,
        expenseCount: 0,
        balances: balances,
      );

      final docRef = await _groupsCollection.add(group.toFirestore());
      final newDoc = await docRef.get();
      return GroupModel.fromFirestore(newDoc);
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to create group: ${e.message}');
    }
  }

  @override
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? type,
    String? currency,
    bool? simplifyDebts,
  }) async {
    try {
      final updateMap = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateMap['name'] = name;
      if (description != null) updateMap['description'] = description;
      if (type != null) updateMap['type'] = type.name;
      if (currency != null) updateMap['currency'] = currency;
      if (simplifyDebts != null) updateMap['simplifyDebts'] = simplifyDebts;

      await _groupsCollection.doc(groupId).update(updateMap);
      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to update group: ${e.message}');
    }
  }

  @override
  Future<String> updateGroupImage({
    required String groupId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('groups/$groupId/cover/image.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _groupsCollection.doc(groupId).update({
        'imageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Failed to update group image: ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteGroupImage(String groupId) async {
    try {
      final ref = _storage.ref().child('groups/$groupId/cover/image.jpg');
      await ref.delete();

      await _groupsCollection.doc(groupId).update({
        'imageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Failed to delete group image: ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete the group document
      await _groupsCollection.doc(groupId).delete();

      // Note: In production, you'd also want to:
      // 1. Delete all expenses in the group
      // 2. Delete all settlements
      // 3. Delete the group image from storage
      // This should be handled by a Cloud Function for consistency
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to delete group: ${e.message}');
    }
  }

  @override
  Future<GroupModel> addMember({
    required String groupId,
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    MemberRole role = MemberRole.member,
  }) async {
    try {
      final newMember = GroupMemberModel(
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        email: email,
        joinedAt: DateTime.now(),
        role: role,
      );

      await _groupsCollection.doc(groupId).update({
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'balances.$userId': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to add member: ${e.message}');
    }
  }

  @override
  Future<GroupModel> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Get current group to find member data
      final group = await getGroupById(groupId);
      final member = group.members.firstWhere(
        (m) => m.userId == userId,
        orElse: () =>
            throw const NotFoundException(message: 'Member not found'),
      );

      final memberModel = GroupMemberModel.fromEntity(member);

      await _groupsCollection.doc(groupId).update({
        'members': FieldValue.arrayRemove([memberModel.toMap()]),
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
        'balances.$userId': FieldValue.delete(),
        'admins': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to remove member: ${e.message}');
    }
  }

  @override
  Future<GroupModel> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  }) async {
    try {
      // Get current group
      final group = await getGroupById(groupId);

      // Find and update the member
      final updatedMembers = group.members.map((m) {
        if (m.userId == userId) {
          return GroupMemberModel(
            userId: m.userId,
            displayName: m.displayName,
            photoUrl: m.photoUrl,
            email: m.email,
            joinedAt: m.joinedAt,
            role: newRole,
          );
        }
        return m;
      }).toList();

      // Update admins list
      List<String> updatedAdmins = List.from(group.admins);
      if (newRole == MemberRole.admin && !updatedAdmins.contains(userId)) {
        updatedAdmins.add(userId);
      } else if (newRole == MemberRole.member) {
        updatedAdmins.remove(userId);
      }

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers
            .map((m) => GroupMemberModel.fromEntity(m).toMap())
            .toList(),
        'admins': updatedAdmins,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Failed to update member role: ${e.message}',
      );
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final userId = _currentUserId;
    await removeMember(groupId: groupId, userId: userId);
  }
}
