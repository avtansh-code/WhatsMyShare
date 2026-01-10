import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_datasource.dart';

/// Implementation of FriendRepository
class FriendRepositoryImpl implements FriendRepository {
  final FriendDatasource datasource;
  final ConnectivityService connectivityService;

  FriendRepositoryImpl({
    required this.datasource,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends(String userId) async {
    try {
      final models = await datasource.getFriends(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendEntity>> getFriendById(String friendId) async {
    try {
      final model = await datasource.getFriendById(friendId);
      if (model == null) {
        return const Left(NotFoundFailure(message: 'Friend not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendEntity>> addFriend({
    required String userId,
    required String friendUserId,
  }) async {
    try {
      final model = await datasource.addFriend(
        userId: userId,
        friendUserId: friendUserId,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendEntity>> acceptFriendRequest(
    String friendId,
  ) async {
    try {
      final model = await datasource.acceptFriendRequest(friendId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend(String friendId) async {
    try {
      await datasource.removeFriend(friendId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockFriend(String friendId) async {
    try {
      await datasource.blockFriend(friendId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unblockFriend(String friendId) async {
    try {
      await datasource.unblockFriend(friendId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RegisteredUser>>> searchUsers(
    String query,
  ) async {
    try {
      final models = await datasource.searchUsers(query);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getPendingRequests(
    String userId,
  ) async {
    try {
      final models = await datasource.getPendingRequests(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<FriendEntity>> watchFriends(String userId) {
    return datasource
        .watchFriends(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
