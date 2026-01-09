import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend_entity.dart';

/// Repository interface for friend management
/// All friends must be registered users of the app
abstract class FriendRepository {
  /// Get all friends for a user
  Future<Either<Failure, List<FriendEntity>>> getFriends(String userId);

  /// Get a specific friend by ID
  Future<Either<Failure, FriendEntity>> getFriendById(String friendId);

  /// Add a friend by their user ID (must be a registered user)
  Future<Either<Failure, FriendEntity>> addFriend({
    required String userId,
    required String friendUserId,
  });

  /// Accept a friend request
  Future<Either<Failure, FriendEntity>> acceptFriendRequest(String friendId);

  /// Remove a friend
  Future<Either<Failure, void>> removeFriend(String friendId);

  /// Block a friend
  Future<Either<Failure, void>> blockFriend(String friendId);

  /// Unblock a friend
  Future<Either<Failure, void>> unblockFriend(String friendId);

  /// Search for registered users by phone or name
  Future<Either<Failure, List<RegisteredUser>>> searchUsers(String query);

  /// Get pending friend requests for a user
  Future<Either<Failure, List<FriendEntity>>> getPendingRequests(String userId);

  /// Watch friends list for real-time updates
  Stream<List<FriendEntity>> watchFriends(String userId);
}
