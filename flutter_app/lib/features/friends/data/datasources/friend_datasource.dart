import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/logging_service.dart';
import '../models/friend_model.dart';

/// Abstract interface for friend data operations
abstract class FriendDatasource {
  /// Get all friends for a user
  Future<List<FriendModel>> getFriends(String userId);

  /// Get a specific friend by ID
  Future<FriendModel?> getFriendById(String friendId);

  /// Add a friend (must be a registered user)
  Future<FriendModel> addFriend({
    required String userId,
    required String friendUserId,
  });

  /// Accept a friend request
  Future<FriendModel> acceptFriendRequest(String friendId);

  /// Remove a friend
  Future<void> removeFriend(String friendId);

  /// Block a friend
  Future<void> blockFriend(String friendId);

  /// Unblock a friend
  Future<void> unblockFriend(String friendId);

  /// Search for registered users by phone or name
  Future<List<RegisteredUserModel>> searchUsers(String query);

  /// Get pending friend requests
  Future<List<FriendModel>> getPendingRequests(String userId);

  /// Watch friends list for real-time updates
  Stream<List<FriendModel>> watchFriends(String userId);
}

/// Firebase implementation of FriendDatasource
class FriendDatasourceImpl implements FriendDatasource {
  final FirebaseFirestore firestore;
  final LoggingService loggingService;

  FriendDatasourceImpl({required this.firestore, required this.loggingService});

  CollectionReference<Map<String, dynamic>> get _friendsCollection =>
      firestore.collection('friends');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection('users');

  @override
  Future<List<FriendModel>> getFriends(String userId) async {
    loggingService.debug(
      'Getting friends for user: $userId',
      tag: LogTags.friends,
    );

    final querySnapshot = await _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return querySnapshot.docs
        .map((doc) => FriendModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<FriendModel?> getFriendById(String friendId) async {
    loggingService.debug(
      'Getting friend by ID: $friendId',
      tag: LogTags.friends,
    );

    final doc = await _friendsCollection.doc(friendId).get();
    if (!doc.exists) return null;

    return FriendModel.fromFirestore(doc);
  }

  @override
  Future<FriendModel> addFriend({
    required String userId,
    required String friendUserId,
  }) async {
    loggingService.info(
      'Adding friend: $friendUserId for user: $userId',
      tag: LogTags.friends,
    );

    // Verify the friend is a registered user
    final friendUserDoc = await _usersCollection.doc(friendUserId).get();
    if (!friendUserDoc.exists) {
      throw Exception(
        'User not found. Only registered users can be added as friends.',
      );
    }

    final friendUserData = friendUserDoc.data()!;
    final now = DateTime.now();

    // Check if friendship already exists
    final existingFriendship = await _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('friendUserId', isEqualTo: friendUserId)
        .get();

    if (existingFriendship.docs.isNotEmpty) {
      throw Exception('Friend request already exists.');
    }

    // Create the friend document
    final friendData = {
      'userId': userId,
      'friendUserId': friendUserId,
      'displayName':
          friendUserData['displayName'] ?? friendUserData['name'] ?? 'Unknown',
      'phone': friendUserData['phone'] ?? '',
      'photoUrl': friendUserData['photoUrl'],
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final docRef = await _friendsCollection.add(friendData);
    final doc = await docRef.get();

    return FriendModel.fromFirestore(doc);
  }

  @override
  Future<FriendModel> acceptFriendRequest(String friendId) async {
    loggingService.info(
      'Accepting friend request: $friendId',
      tag: LogTags.friends,
    );

    final now = DateTime.now();

    await _friendsCollection.doc(friendId).update({
      'status': 'accepted',
      'updatedAt': Timestamp.fromDate(now),
    });

    final doc = await _friendsCollection.doc(friendId).get();
    return FriendModel.fromFirestore(doc);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    loggingService.info('Removing friend: $friendId', tag: LogTags.friends);
    await _friendsCollection.doc(friendId).delete();
  }

  @override
  Future<void> blockFriend(String friendId) async {
    loggingService.info('Blocking friend: $friendId', tag: LogTags.friends);

    await _friendsCollection.doc(friendId).update({
      'status': 'blocked',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> unblockFriend(String friendId) async {
    loggingService.info('Unblocking friend: $friendId', tag: LogTags.friends);

    await _friendsCollection.doc(friendId).update({
      'status': 'accepted',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<List<RegisteredUserModel>> searchUsers(String query) async {
    loggingService.debug(
      'Searching users with query: $query',
      tag: LogTags.friends,
    );

    if (query.isEmpty || query.length < 2) {
      return [];
    }

    final queryLower = query.toLowerCase();

    // Combine and deduplicate results
    final userMap = <String, RegisteredUserModel>{};

    // Search by phone number (exact match or prefix)
    if (RegExp(r'^\+?[0-9]+$').hasMatch(query)) {
      // It's a phone number search
      String normalizedPhone = query;
      if (!query.startsWith('+')) {
        normalizedPhone = '+91$query'; // Default to India
      }

      final phoneResults = await _usersCollection
          .where('phone', isEqualTo: normalizedPhone)
          .limit(10)
          .get();

      for (final doc in phoneResults.docs) {
        userMap[doc.id] = RegisteredUserModel.fromFirestore(doc);
      }
    }

    // Search by display name (prefix match)
    final nameResults = await _usersCollection
        .where('displayNameLower', isGreaterThanOrEqualTo: queryLower)
        .where('displayNameLower', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(10)
        .get();

    for (final doc in nameResults.docs) {
      if (!userMap.containsKey(doc.id)) {
        userMap[doc.id] = RegisteredUserModel.fromFirestore(doc);
      }
    }

    return userMap.values.toList();
  }

  @override
  Future<List<FriendModel>> getPendingRequests(String userId) async {
    loggingService.debug(
      'Getting pending requests for user: $userId',
      tag: LogTags.friends,
    );

    // Get requests where this user is the friend (incoming requests)
    final querySnapshot = await _friendsCollection
        .where('friendUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return querySnapshot.docs
        .map((doc) => FriendModel.fromFirestore(doc))
        .toList();
  }

  @override
  Stream<List<FriendModel>> watchFriends(String userId) {
    loggingService.debug(
      'Watching friends for user: $userId',
      tag: LogTags.friends,
    );

    return _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromFirestore(doc))
              .toList(),
        );
  }
}
