import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../domain/entities/group_entity.dart';

/// Base class for all group events
abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all groups for the current user
class GroupLoadAllRequested extends GroupEvent {
  const GroupLoadAllRequested();
}

/// Event to load a single group by ID
class GroupLoadByIdRequested extends GroupEvent {
  final String groupId;

  const GroupLoadByIdRequested(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event to create a new group
class GroupCreateRequested extends GroupEvent {
  final String name;
  final String? description;
  final GroupType type;
  final String currency;
  final bool simplifyDebts;
  final List<String>? initialMemberIds;

  const GroupCreateRequested({
    required this.name,
    this.description,
    required this.type,
    required this.currency,
    this.simplifyDebts = true,
    this.initialMemberIds,
  });

  @override
  List<Object?> get props => [name, description, type, currency, simplifyDebts, initialMemberIds];
}

/// Event to update a group
class GroupUpdateRequested extends GroupEvent {
  final String groupId;
  final String? name;
  final String? description;
  final GroupType? type;
  final String? currency;
  final bool? simplifyDebts;

  const GroupUpdateRequested({
    required this.groupId,
    this.name,
    this.description,
    this.type,
    this.currency,
    this.simplifyDebts,
  });

  @override
  List<Object?> get props => [groupId, name, description, type, currency, simplifyDebts];
}

/// Event to update group image
class GroupImageUpdateRequested extends GroupEvent {
  final String groupId;
  final File imageFile;

  const GroupImageUpdateRequested({
    required this.groupId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [groupId, imageFile];
}

/// Event to delete group image
class GroupImageDeleteRequested extends GroupEvent {
  final String groupId;

  const GroupImageDeleteRequested(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event to delete a group
class GroupDeleteRequested extends GroupEvent {
  final String groupId;

  const GroupDeleteRequested(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event to add a member to a group
class GroupMemberAddRequested extends GroupEvent {
  final String groupId;
  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final MemberRole role;

  const GroupMemberAddRequested({
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.role = MemberRole.member,
  });

  @override
  List<Object?> get props => [groupId, userId, displayName, email, photoUrl, role];
}

/// Event to remove a member from a group
class GroupMemberRemoveRequested extends GroupEvent {
  final String groupId;
  final String userId;

  const GroupMemberRemoveRequested({
    required this.groupId,
    required this.userId,
  });

  @override
  List<Object?> get props => [groupId, userId];
}

/// Event to update a member's role
class GroupMemberRoleUpdateRequested extends GroupEvent {
  final String groupId;
  final String userId;
  final MemberRole newRole;

  const GroupMemberRoleUpdateRequested({
    required this.groupId,
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [groupId, userId, newRole];
}

/// Event to leave a group
class GroupLeaveRequested extends GroupEvent {
  final String groupId;

  const GroupLeaveRequested(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event for real-time group updates
class GroupUpdated extends GroupEvent {
  final List<GroupEntity> groups;

  const GroupUpdated(this.groups);

  @override
  List<Object?> get props => [groups];
}

/// Event for single group real-time update
class SingleGroupUpdated extends GroupEvent {
  final GroupEntity group;

  const SingleGroupUpdated(this.group);

  @override
  List<Object?> get props => [group];
}