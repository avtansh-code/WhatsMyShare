import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/group_entity.dart';

/// Repository interface for group operations
abstract class GroupRepository {
  /// Get all groups for the current user
  Future<Either<Failure, List<GroupEntity>>> getGroups();

  /// Get a stream of groups for real-time updates
  Stream<Either<Failure, List<GroupEntity>>> watchGroups();

  /// Get a single group by ID
  Future<Either<Failure, GroupEntity>> getGroupById(String groupId);

  /// Get a stream of a single group for real-time updates
  Stream<Either<Failure, GroupEntity>> watchGroupById(String groupId);

  /// Create a new group
  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    String? description,
    required GroupType type,
    required String currency,
    bool simplifyDebts = true,
    List<String>? initialMemberIds,
  });

  /// Update group details
  Future<Either<Failure, GroupEntity>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? type,
    String? currency,
    bool? simplifyDebts,
  });

  /// Update group image
  Future<Either<Failure, String>> updateGroupImage({
    required String groupId,
    required File imageFile,
  });

  /// Delete group image
  Future<Either<Failure, void>> deleteGroupImage(String groupId);

  /// Delete a group (admin only)
  Future<Either<Failure, void>> deleteGroup(String groupId);

  /// Add a member to the group
  Future<Either<Failure, GroupEntity>> addMember({
    required String groupId,
    required String userId,
    required String displayName,
    String? phone,
    String? photoUrl,
    MemberRole role = MemberRole.member,
  });

  /// Remove a member from the group
  Future<Either<Failure, GroupEntity>> removeMember({
    required String groupId,
    required String userId,
  });

  /// Update a member's role
  Future<Either<Failure, GroupEntity>> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  });

  /// Leave a group (current user)
  Future<Either<Failure, void>> leaveGroup(String groupId);

  /// Get simplified debts for a group
  Future<Either<Failure, List<SimplifiedDebt>>> getSimplifiedDebts(
    String groupId,
  );

  /// Check if current user can edit group
  Future<Either<Failure, bool>> canEditGroup(String groupId);

  /// Check if current user can delete group
  Future<Either<Failure, bool>> canDeleteGroup(String groupId);

  /// Search groups by name
  Future<Either<Failure, List<GroupEntity>>> searchGroups(String query);

  /// Get recent groups (sorted by last activity)
  Future<Either<Failure, List<GroupEntity>>> getRecentGroups({int limit = 5});

  /// Get group statistics for current user
  Future<Either<Failure, GroupStatistics>> getGroupStatistics();
}

/// Group statistics data class
class GroupStatistics {
  final int totalGroups;
  final int totalOwed; // Amount others owe you (in paisa)
  final int totalOwing; // Amount you owe others (in paisa)
  final int netBalance; // totalOwed - totalOwing
  final int groupsWhereYouOwe;
  final int groupsWhereYouAreOwed;
  final int settledGroups;

  const GroupStatistics({
    required this.totalGroups,
    required this.totalOwed,
    required this.totalOwing,
    required this.netBalance,
    required this.groupsWhereYouOwe,
    required this.groupsWhereYouAreOwed,
    required this.settledGroups,
  });

  /// Create empty statistics
  factory GroupStatistics.empty() => const GroupStatistics(
    totalGroups: 0,
    totalOwed: 0,
    totalOwing: 0,
    netBalance: 0,
    groupsWhereYouOwe: 0,
    groupsWhereYouAreOwed: 0,
    settledGroups: 0,
  );
}
