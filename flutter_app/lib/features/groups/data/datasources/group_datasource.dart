import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/group_entity.dart';
import '../models/group_model.dart';

/// Pagination result with cursor for next page
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}

/// Data source interface for group operations
abstract class GroupDataSource {
  /// Get all groups for the current user
  Future<List<GroupModel>> getGroups();

  /// Get paginated groups for the current user
  Future<PaginatedResult<GroupModel>> getGroupsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  });

  /// Watch groups for real-time updates
  Stream<List<GroupModel>> watchGroups();

  /// Watch paginated groups for real-time updates
  Stream<List<GroupModel>> watchGroupsPaginated({int limit = 20});

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
  final LoggingService _log = LoggingService();

  GroupDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth {
    _log.debug('GroupDataSource initialized', tag: LogTags.groups);
  }

  /// Get current user ID or throw exception
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      _log.error(
        'User not authenticated when accessing groups',
        tag: LogTags.groups,
      );
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  /// Get groups collection reference
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  @override
  Future<List<GroupModel>> getGroups() async {
    _log.debug('Fetching user groups', tag: LogTags.groups);
    try {
      final userId = _currentUserId;
      final snapshot = await _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .get();

      final groups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      _log.info(
        'Groups fetched successfully',
        tag: LogTags.groups,
        data: {'count': groups.length},
      );
      return groups;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      throw ServerException(message: 'Failed to get groups: ${e.message}');
    }
  }

  @override
  Future<PaginatedResult<GroupModel>> getGroupsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    _log.debug(
      'Fetching paginated groups',
      tag: LogTags.groups,
      data: {'limit': limit, 'hasStartAfter': startAfter != null},
    );
    try {
      final userId = _currentUserId;
      Query<Map<String, dynamic>> query = _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .limit(limit + 1); // Fetch one extra to check if there are more

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

      final groups = docs.map((doc) => GroupModel.fromFirestore(doc)).toList();

      _log.info(
        'Paginated groups fetched successfully',
        tag: LogTags.groups,
        data: {'count': groups.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: groups,
        lastDocument: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get paginated groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      throw ServerException(
        message: 'Failed to get paginated groups: ${e.message}',
      );
    }
  }

  @override
  Stream<List<GroupModel>> watchGroups() {
    _log.debug('Setting up groups stream', tag: LogTags.groups);
    try {
      final userId = _currentUserId;
      return _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .snapshots()
          .map((snapshot) {
            _log.debug(
              'Groups stream updated',
              tag: LogTags.groups,
              data: {'count': snapshot.docs.length},
            );
            return snapshot.docs
                .map((doc) => GroupModel.fromFirestore(doc))
                .toList();
          });
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to watch groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      throw ServerException(message: 'Failed to watch groups: ${e.message}');
    }
  }

  @override
  Stream<List<GroupModel>> watchGroupsPaginated({int limit = 20}) {
    _log.debug(
      'Setting up paginated groups stream',
      tag: LogTags.groups,
      data: {'limit': limit},
    );
    try {
      final userId = _currentUserId;
      return _groupsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('lastActivityAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            _log.debug(
              'Paginated groups stream updated',
              tag: LogTags.groups,
              data: {'count': snapshot.docs.length},
            );
            return snapshot.docs
                .map((doc) => GroupModel.fromFirestore(doc))
                .toList();
          });
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to watch paginated groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      throw ServerException(
        message: 'Failed to watch paginated groups: ${e.message}',
      );
    }
  }

  @override
  Future<GroupModel> getGroupById(String groupId) async {
    _log.debug(
      'Fetching group by ID',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        _log.warning(
          'Group not found',
          tag: LogTags.groups,
          data: {'groupId': groupId},
        );
        throw const NotFoundException(message: 'Group not found');
      }
      _log.debug(
        'Group fetched successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return GroupModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(message: 'Failed to get group: ${e.message}');
    }
  }

  @override
  Stream<GroupModel> watchGroupById(String groupId) {
    _log.debug(
      'Setting up single group stream',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) {
        _log.warning(
          'Watched group not found',
          tag: LogTags.groups,
          data: {'groupId': groupId},
        );
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
    _log.info(
      'Creating new group',
      tag: LogTags.groups,
      data: {'name': name, 'type': type.name, 'currency': currency},
    );
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
      if (initialMemberIds != null) {
        for (final memberId in initialMemberIds) {
          if (memberId != userId) {
            memberIds.add(memberId);
            balances[memberId] = 0;
          }
        }
        _log.debug(
          'Initial members added',
          tag: LogTags.groups,
          data: {'count': memberIds.length},
        );
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
      _log.info(
        'Group created successfully',
        tag: LogTags.groups,
        data: {'groupId': docRef.id, 'name': name},
      );
      return GroupModel.fromFirestore(newDoc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to create group',
        tag: LogTags.groups,
        data: {'name': name, 'error': e.message},
      );
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
    _log.info(
      'Updating group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'name': name},
    );
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
      _log.info(
        'Group updated successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(message: 'Failed to update group: ${e.message}');
    }
  }

  @override
  Future<String> updateGroupImage({
    required String groupId,
    required File imageFile,
  }) async {
    _log.info(
      'Updating group image',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final ref = _storage.ref().child('groups/$groupId/cover/image.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _groupsCollection.doc(groupId).update({
        'imageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log.info(
        'Group image updated successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return downloadUrl;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(
        message: 'Failed to update group image: ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteGroupImage(String groupId) async {
    _log.info(
      'Deleting group image',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final ref = _storage.ref().child('groups/$groupId/cover/image.jpg');
      await ref.delete();

      await _groupsCollection.doc(groupId).update({
        'imageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.info(
        'Group image deleted successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      throw ServerException(
        message: 'Failed to delete group image: ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _log.warning(
      'Deleting group',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      // Delete the group document
      await _groupsCollection.doc(groupId).delete();
      _log.info(
        'Group deleted successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );

      // Note: In production, you'd also want to:
      // 1. Delete all expenses in the group
      // 2. Delete all settlements
      // 3. Delete the group image from storage
      // This should be handled by a Cloud Function for consistency
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
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
    _log.info(
      'Adding member to group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId, 'displayName': displayName},
    );
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

      _log.info(
        'Member added successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId},
      );
      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to add member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId, 'error': e.message},
      );
      throw ServerException(message: 'Failed to add member: ${e.message}');
    }
  }

  @override
  Future<GroupModel> removeMember({
    required String groupId,
    required String userId,
  }) async {
    _log.info(
      'Removing member from group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId},
    );
    try {
      // Get current group to find member data
      final group = await getGroupById(groupId);
      final member = group.members.firstWhere(
        (m) => m.userId == userId,
        orElse: () {
          _log.warning(
            'Member not found in group',
            tag: LogTags.groups,
            data: {'groupId': groupId, 'userId': userId},
          );
          throw const NotFoundException(message: 'Member not found');
        },
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

      _log.info(
        'Member removed successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId},
      );
      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to remove member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId, 'error': e.message},
      );
      throw ServerException(message: 'Failed to remove member: ${e.message}');
    }
  }

  @override
  Future<GroupModel> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  }) async {
    _log.info(
      'Updating member role',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId, 'newRole': newRole.name},
    );
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

      _log.info(
        'Member role updated successfully',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId, 'newRole': newRole.name},
      );
      return await getGroupById(groupId);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update member role',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: 'Failed to update member role: ${e.message}',
      );
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final userId = _currentUserId;
    _log.info(
      'User leaving group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId},
    );
    await removeMember(groupId: groupId, userId: userId);
  }
}
