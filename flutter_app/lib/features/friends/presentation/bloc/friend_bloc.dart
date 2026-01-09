import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/friend_repository.dart';
import 'friend_event.dart';
import 'friend_state.dart';

/// BLoC for managing friends
/// Friends are only registered users - no support for unregistered contacts
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepository repository;

  FriendBloc({required this.repository}) : super(const FriendInitial()) {
    on<LoadFriends>(_onLoadFriends);
    on<AddFriend>(_onAddFriend);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RemoveFriend>(_onRemoveFriend);
    on<BlockFriend>(_onBlockFriend);
    on<UnblockFriend>(_onUnblockFriend);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSearch>(_onClearSearch);
    on<LoadPendingRequests>(_onLoadPendingRequests);
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendLoading());

    final result = await repository.getFriends(event.userId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (friends) => emit(FriendsLoaded(friends: friends)),
    );
  }

  Future<void> _onAddFriend(
    AddFriend event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendOperationInProgress(message: 'Sending friend request...'));

    final result = await repository.addFriend(
      userId: event.userId,
      friendUserId: event.friendUserId,
    );

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (friend) => emit(FriendOperationSuccess(
        message: 'Friend request sent successfully',
        friend: friend,
      )),
    );
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendOperationInProgress(message: 'Accepting friend request...'));

    final result = await repository.acceptFriendRequest(event.friendId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (friend) => emit(FriendOperationSuccess(
        message: 'Friend request accepted',
        friend: friend,
      )),
    );
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendOperationInProgress(message: 'Removing friend...'));

    final result = await repository.removeFriend(event.friendId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (_) => emit(const FriendOperationSuccess(message: 'Friend removed')),
    );
  }

  Future<void> _onBlockFriend(
    BlockFriend event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendOperationInProgress(message: 'Blocking user...'));

    final result = await repository.blockFriend(event.friendId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (_) => emit(const FriendOperationSuccess(message: 'User blocked')),
    );
  }

  Future<void> _onUnblockFriend(
    UnblockFriend event,
    Emitter<FriendState> emit,
  ) async {
    emit(const FriendOperationInProgress(message: 'Unblocking user...'));

    final result = await repository.unblockFriend(event.friendId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (_) => emit(const FriendOperationSuccess(message: 'User unblocked')),
    );
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<FriendState> emit,
  ) async {
    emit(const UserSearchResults(users: [], isSearching: true));

    final result = await repository.searchUsers(event.query);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (users) => emit(UserSearchResults(users: users, isSearching: false)),
    );
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<FriendState> emit,
  ) {
    emit(const UserSearchResults(users: [], isSearching: false));
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequests event,
    Emitter<FriendState> emit,
  ) async {
    final currentState = state;
    
    final result = await repository.getPendingRequests(event.userId);

    result.fold(
      (failure) => emit(FriendError(message: failure.message)),
      (pendingRequests) {
        if (currentState is FriendsLoaded) {
          emit(currentState.copyWith(pendingRequests: pendingRequests));
        } else {
          emit(FriendsLoaded(friends: const [], pendingRequests: pendingRequests));
        }
      },
    );
  }
}
