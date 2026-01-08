import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_datasource.dart';

/// Implementation of GroupRepository using Firebase
class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;
  final LoggingService _log = LoggingService();

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource {
    _log.debug('GroupRepository initialized', tag: LogTags.groups);
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroups() async {
    _log.debug('Getting groups', tag: LogTags.groups);
    try {
      final groups = await _dataSource.getGroups();
      _log.info(
        'Groups fetched',
        tag: LogTags.groups,
        data: {'count': groups.length},
      );
      return Right(groups);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting groups',
        tag: LogTags.groups,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to get groups: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<GroupEntity>>> watchGroups() {
    _log.debug('Setting up groups watch stream', tag: LogTags.groups);
    return _dataSource
        .watchGroups()
        .map<Either<Failure, List<GroupEntity>>>((groups) {
          _log.debug(
            'Groups stream updated',
            tag: LogTags.groups,
            data: {'count': groups.length},
          );
          return Right(groups);
        })
        .handleError((error) {
          _log.error(
            'Error in groups stream',
            tag: LogTags.groups,
            data: {'error': error.toString()},
          );
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
    _log.debug(
      'Getting group by ID',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final group = await _dataSource.getGroupById(groupId);
      _log.info(
        'Group fetched',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'name': group.name},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to get group: $e'));
    }
  }

  @override
  Stream<Either<Failure, GroupEntity>> watchGroupById(String groupId) {
    _log.debug(
      'Setting up group watch stream',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    return _dataSource
        .watchGroupById(groupId)
        .map<Either<Failure, GroupEntity>>((group) => Right(group))
        .handleError((error) {
          _log.error(
            'Error in group stream',
            tag: LogTags.groups,
            data: {'groupId': groupId, 'error': error.toString()},
          );
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
    _log.info(
      'Creating group',
      tag: LogTags.groups,
      data: {'name': name, 'type': type.name, 'currency': currency},
    );
    try {
      final group = await _dataSource.createGroup(
        name: name,
        description: description,
        type: type,
        currency: currency,
        simplifyDebts: simplifyDebts,
        initialMemberIds: initialMemberIds,
      );
      _log.info(
        'Group created',
        tag: LogTags.groups,
        data: {'groupId': group.id, 'name': group.name},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error creating group',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error creating group',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error creating group',
        tag: LogTags.groups,
        data: {'error': e.toString()},
      );
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
    _log.info(
      'Updating group',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final group = await _dataSource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        type: type,
        currency: currency,
        simplifyDebts: simplifyDebts,
      );
      _log.info(
        'Group updated',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error updating group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found for update',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error updating group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to update group: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateGroupImage({
    required String groupId,
    required File imageFile,
  }) async {
    _log.info(
      'Updating group image',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final imageUrl = await _dataSource.updateGroupImage(
        groupId: groupId,
        imageFile: imageFile,
      );
      _log.info(
        'Group image updated',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Right(imageUrl);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error updating group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error updating group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to update group image: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroupImage(String groupId) async {
    _log.info(
      'Deleting group image',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      await _dataSource.deleteGroupImage(groupId);
      _log.info(
        'Group image deleted',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error deleting group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting group image',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to delete group image: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    _log.warning(
      'Deleting group',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      await _dataSource.deleteGroup(groupId);
      _log.info(
        'Group deleted',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error deleting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error deleting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error deleting group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
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
    _log.info(
      'Adding member to group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId, 'role': role.name},
    );
    try {
      final group = await _dataSource.addMember(
        groupId: groupId,
        userId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        role: role,
      );
      _log.info(
        'Member added',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error adding member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found for adding member',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error adding member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error adding member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to add member: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    _log.info(
      'Removing member from group',
      tag: LogTags.groups,
      data: {'groupId': groupId, 'userId': userId},
    );
    try {
      final group = await _dataSource.removeMember(
        groupId: groupId,
        userId: userId,
      );
      _log.info(
        'Member removed',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error removing member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group/member not found for removal',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error removing member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error removing member',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to remove member: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> updateMemberRole({
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
      final group = await _dataSource.updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );
      _log.info(
        'Member role updated',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'userId': userId},
      );
      return Right(group);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error updating member role',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group/member not found for role update',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error updating member role',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error updating member role',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to update member role: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(String groupId) async {
    _log.info('Leaving group', tag: LogTags.groups, data: {'groupId': groupId});
    try {
      await _dataSource.leaveGroup(groupId);
      _log.info('Left group', tag: LogTags.groups, data: {'groupId': groupId});
      return const Right(null);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error leaving group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found for leaving',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error leaving group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error leaving group',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to leave group: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SimplifiedDebt>>> getSimplifiedDebts(
    String groupId,
  ) async {
    _log.debug(
      'Getting simplified debts',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      final group = await _dataSource.getGroupById(groupId);
      _log.debug(
        'Simplified debts fetched',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'count': group.simplifiedDebts?.length ?? 0},
      );
      return Right(group.simplifiedDebts ?? []);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting simplified debts',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found for simplified debts',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting simplified debts',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting simplified debts',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to get simplified debts: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> canEditGroup(String groupId) async {
    _log.debug(
      'Checking edit permission',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      await _dataSource.getGroupById(groupId);
      // All members can edit groups in this implementation
      _log.debug(
        'Edit permission check complete',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'canEdit': true},
      );
      return const Right(true);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error checking edit permission',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      _log.warning(
        'Group not found for permission check',
        tag: LogTags.groups,
        data: {'groupId': groupId},
      );
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error checking edit permission',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error checking edit permission',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to check permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> canDeleteGroup(String groupId) async {
    _log.debug(
      'Checking delete permission',
      tag: LogTags.groups,
      data: {'groupId': groupId},
    );
    try {
      // This would need the current user ID to check admin status
      // For now, we return true and let Firestore rules handle it
      _log.debug(
        'Delete permission check complete',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'canDelete': true},
      );
      return const Right(true);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error checking delete permission',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error checking delete permission',
        tag: LogTags.groups,
        data: {'groupId': groupId, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to check permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> searchGroups(String query) async {
    _log.debug('Searching groups', tag: LogTags.groups, data: {'query': query});
    try {
      final groups = await _dataSource.getGroups();
      final filtered = groups
          .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _log.info(
        'Groups search complete',
        tag: LogTags.groups,
        data: {'query': query, 'results': filtered.length},
      );
      return Right(filtered);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error searching groups',
        tag: LogTags.groups,
        data: {'query': query, 'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error searching groups',
        tag: LogTags.groups,
        data: {'query': query, 'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error searching groups',
        tag: LogTags.groups,
        data: {'query': query, 'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to search groups: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getRecentGroups({
    int limit = 5,
  }) async {
    _log.debug(
      'Getting recent groups',
      tag: LogTags.groups,
      data: {'limit': limit},
    );
    try {
      final groups = await _dataSource.getGroups();
      // Already sorted by lastActivityAt from datasource
      final recent = groups.take(limit).toList();
      _log.info(
        'Recent groups fetched',
        tag: LogTags.groups,
        data: {'count': recent.length},
      );
      return Right(recent);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting recent groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting recent groups',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting recent groups',
        tag: LogTags.groups,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to get recent groups: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupStatistics>> getGroupStatistics() async {
    _log.debug('Getting group statistics', tag: LogTags.groups);
    try {
      final groups = await _dataSource.getGroups();

      // This would need proper user ID to calculate accurate statistics
      // For now, we return basic counts
      final stats = GroupStatistics(
        totalGroups: groups.length,
        totalOwed: 0, // Would need user-specific calculation
        totalOwing: 0,
        netBalance: 0,
        groupsWhereYouOwe: 0,
        groupsWhereYouAreOwed: 0,
        settledGroups: groups
            .where((g) => g.balances.values.every((b) => b == 0))
            .length,
      );
      _log.info(
        'Group statistics fetched',
        tag: LogTags.groups,
        data: {
          'totalGroups': stats.totalGroups,
          'settledGroups': stats.settledGroups,
        },
      );
      return Right(stats);
    } on AuthException catch (e) {
      _log.warning(
        'Auth error getting statistics',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      _log.error(
        'Server error getting statistics',
        tag: LogTags.groups,
        data: {'error': e.message},
      );
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.error(
        'Unexpected error getting statistics',
        tag: LogTags.groups,
        data: {'error': e.toString()},
      );
      return Left(ServerFailure(message: 'Failed to get statistics: $e'));
    }
  }
}
