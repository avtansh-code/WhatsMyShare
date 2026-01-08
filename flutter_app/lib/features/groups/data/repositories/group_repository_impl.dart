import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_datasource.dart';

/// Implementation of GroupRepository using Firebase
class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroups() async {
    try {
      final groups = await _dataSource.getGroups();
      return Right(groups);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get groups: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<GroupEntity>>> watchGroups() {
    return _dataSource
        .watchGroups()
        .map<Either<Failure, List<GroupEntity>>>((groups) => Right(groups))
        .handleError((error) {
          if (error is AuthException) {
            return Left(AuthFailure(message: error.message));
          } else if (error is ServerException) {
            return Left(ServerFailure(message: error.message));
          }
          return Left(ServerFailure(message: 'Failed to watch groups: $error'));
        });
  }

  @override
  Future<Either<Failure, GroupEntity>> getGroupById(String groupId) async {
    try {
      final group = await _dataSource.getGroupById(groupId);
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get group: $e'));
    }
  }

  @override
  Stream<Either<Failure, GroupEntity>> watchGroupById(String groupId) {
    return _dataSource
        .watchGroupById(groupId)
        .map<Either<Failure, GroupEntity>>((group) => Right(group))
        .handleError((error) {
          if (error is AuthException) {
            return Left(AuthFailure(message: error.message));
          } else if (error is NotFoundException) {
            return Left(NotFoundFailure(message: error.message));
          } else if (error is ServerException) {
            return Left(ServerFailure(message: error.message));
          }
          return Left(ServerFailure(message: 'Failed to watch group: $error'));
        });
  }

  @override
  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    String? description,
    required GroupType type,
    required String currency,
    bool simplifyDebts = true,
    List<String>? initialMemberIds,
  }) async {
    try {
      final group = await _dataSource.createGroup(
        name: name,
        description: description,
        type: type,
        currency: currency,
        simplifyDebts: simplifyDebts,
        initialMemberIds: initialMemberIds,
      );
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create group: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? type,
    String? currency,
    bool? simplifyDebts,
  }) async {
    try {
      final group = await _dataSource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        type: type,
        currency: currency,
        simplifyDebts: simplifyDebts,
      );
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update group: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateGroupImage({
    required String groupId,
    required File imageFile,
  }) async {
    try {
      final imageUrl = await _dataSource.updateGroupImage(
        groupId: groupId,
        imageFile: imageFile,
      );
      return Right(imageUrl);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update group image: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroupImage(String groupId) async {
    try {
      await _dataSource.deleteGroupImage(groupId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete group image: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    try {
      await _dataSource.deleteGroup(groupId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete group: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> addMember({
    required String groupId,
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    MemberRole role = MemberRole.member,
  }) async {
    try {
      final group = await _dataSource.addMember(
        groupId: groupId,
        userId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        role: role,
      );
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to add member: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final group = await _dataSource.removeMember(
        groupId: groupId,
        userId: userId,
      );
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to remove member: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  }) async {
    try {
      final group = await _dataSource.updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );
      return Right(group);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update member role: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(String groupId) async {
    try {
      await _dataSource.leaveGroup(groupId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to leave group: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SimplifiedDebt>>> getSimplifiedDebts(
    String groupId,
  ) async {
    try {
      final group = await _dataSource.getGroupById(groupId);
      return Right(group.simplifiedDebts ?? []);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get simplified debts: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> canEditGroup(String groupId) async {
    try {
      await _dataSource.getGroupById(groupId);
      // All members can edit groups in this implementation
      return const Right(true);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to check permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> canDeleteGroup(String groupId) async {
    try {
      // This would need the current user ID to check admin status
      // For now, we return true and let Firestore rules handle it
      return const Right(true);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to check permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> searchGroups(String query) async {
    try {
      final groups = await _dataSource.getGroups();
      final filtered = groups
          .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return Right(filtered);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search groups: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getRecentGroups({
    int limit = 5,
  }) async {
    try {
      final groups = await _dataSource.getGroups();
      // Already sorted by lastActivityAt from datasource
      return Right(groups.take(limit).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get recent groups: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupStatistics>> getGroupStatistics() async {
    try {
      final groups = await _dataSource.getGroups();

      // This would need proper user ID to calculate accurate statistics
      // For now, we return basic counts
      return Right(
        GroupStatistics(
          totalGroups: groups.length,
          totalOwed: 0, // Would need user-specific calculation
          totalOwing: 0,
          netBalance: 0,
          groupsWhereYouOwe: 0,
          groupsWhereYouAreOwed: 0,
          settledGroups: groups
              .where((g) => g.balances.values.every((b) => b == 0))
              .length,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get statistics: $e'));
    }
  }
}
