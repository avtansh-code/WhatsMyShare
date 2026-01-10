import 'package:equatable/equatable.dart';

import '../../domain/entities/friend_entity.dart';

/// Base state for friend BLoC
abstract class FriendState extends Equatable {
  const FriendState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FriendInitial extends FriendState {
  const FriendInitial();
}

/// Loading state
class FriendLoading extends FriendState {
  const FriendLoading();
}

/// Friends loaded state
class FriendsLoaded extends FriendState {
  final List<FriendEntity> friends;
  final List<FriendEntity> pendingRequests;
  final List<RegisteredUser> searchResults;

  const FriendsLoaded({
    required this.friends,
    this.pendingRequests = const [],
    this.searchResults = const [],
  });

  FriendsLoaded copyWith({
    List<FriendEntity>? friends,
    List<FriendEntity>? pendingRequests,
    List<RegisteredUser>? searchResults,
  }) {
    return FriendsLoaded(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [friends, pendingRequests, searchResults];
}

/// Friend operation in progress (adding, removing, etc.)
class FriendOperationInProgress extends FriendState {
  final String message;

  const FriendOperationInProgress({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Friend operation success
class FriendOperationSuccess extends FriendState {
  final String message;
  final FriendEntity? friend;

  const FriendOperationSuccess({required this.message, this.friend});

  @override
  List<Object?> get props => [message, friend];
}

/// Error state
class FriendError extends FriendState {
  final String message;

  const FriendError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// User search results state
class UserSearchResults extends FriendState {
  final List<RegisteredUser> users;
  final bool isSearching;

  const UserSearchResults({required this.users, this.isSearching = false});

  @override
  List<Object?> get props => [users, isSearching];
}
