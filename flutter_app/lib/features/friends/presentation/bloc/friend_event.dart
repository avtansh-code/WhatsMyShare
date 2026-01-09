import 'package:equatable/equatable.dart';

/// Base event for friend BLoC
abstract class FriendEvent extends Equatable {
  const FriendEvent();

  @override
  List<Object?> get props => [];
}

/// Load friends list
class LoadFriends extends FriendEvent {
  final String userId;

  const LoadFriends({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Add a friend by their user ID (must be a registered user)
class AddFriend extends FriendEvent {
  final String userId;
  final String friendUserId;

  const AddFriend({required this.userId, required this.friendUserId});

  @override
  List<Object?> get props => [userId, friendUserId];
}

/// Accept a friend request
class AcceptFriendRequest extends FriendEvent {
  final String friendId;

  const AcceptFriendRequest({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}

/// Remove a friend
class RemoveFriend extends FriendEvent {
  final String friendId;

  const RemoveFriend({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}

/// Block a friend
class BlockFriend extends FriendEvent {
  final String friendId;

  const BlockFriend({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}

/// Unblock a friend
class UnblockFriend extends FriendEvent {
  final String friendId;

  const UnblockFriend({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}

/// Search for registered users
class SearchUsers extends FriendEvent {
  final String query;

  const SearchUsers({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Clear search results
class ClearSearch extends FriendEvent {
  const ClearSearch();
}

/// Load pending friend requests
class LoadPendingRequests extends FriendEvent {
  final String userId;

  const LoadPendingRequests({required this.userId});

  @override
  List<Object?> get props => [userId];
}
