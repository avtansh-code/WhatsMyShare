import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import 'group_event.dart';
import 'group_state.dart';

/// BLoC for managing group state
class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;
  final LoggingService _log = LoggingService();
  StreamSubscription<Either<Failure, List<GroupEntity>>>? _groupsSubscription;
  StreamSubscription<Either<Failure, GroupEntity>>? _singleGroupSubscription;

  GroupBloc({required GroupRepository groupRepository})
    : _groupRepository = groupRepository,
      super(GroupState.initial()) {
    on<GroupLoadAllRequested>(_onLoadAllRequested);
    on<GroupLoadByIdRequested>(_onLoadByIdRequested);
    on<GroupCreateRequested>(_onCreateRequested);
    on<GroupUpdateRequested>(_onUpdateRequested);
    on<GroupImageUpdateRequested>(_onImageUpdateRequested);
    on<GroupImageDeleteRequested>(_onImageDeleteRequested);
    on<GroupDeleteRequested>(_onDeleteRequested);
    on<GroupMemberAddRequested>(_onMemberAddRequested);
    on<GroupMemberRemoveRequested>(_onMemberRemoveRequested);
    on<GroupMemberRoleUpdateRequested>(_onMemberRoleUpdateRequested);
    on<GroupLeaveRequested>(_onLeaveRequested);
    on<GroupUpdated>(_onGroupUpdated);
    on<SingleGroupUpdated>(_onSingleGroupUpdated);

    _log.info('GroupBloc initialized', tag: LogTags.groups);
  }

  /// Handle load all groups request
  Future<void> _onLoadAllRequested(
    GroupLoadAllRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.debug('Loading all groups...', tag: LogTags.groups);
    emit(state.copyWith(status: GroupStatus.loading));

    // Cancel existing subscription
    await _groupsSubscription?.cancel();

    // Subscribe to real-time updates
    _groupsSubscription = _groupRepository.watchGroups().listen(
      (result) {
        result.fold(
          (failure) {
            _log.error(
              'Failed to load groups',
              tag: LogTags.groups,
              data: {'error': failure.message},
            );
            emit(
              state.copyWith(
                status: GroupStatus.failure,
                errorMessage: ErrorMessages.groupLoadFailed,
              ),
            );
          },
          (groups) {
            _log.info(
              'Groups loaded successfully',
              tag: LogTags.groups,
              data: {'count': groups.length},
            );
            add(GroupUpdated(groups));
          },
        );
      },
      onError: (error, stackTrace) {
        _log.error(
          'Groups stream error',
          tag: LogTags.groups,
          error: error,
          stackTrace: stackTrace,
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupLoadFailed,
          ),
        );
      },
    );
  }

  /// Handle load single group by ID
  Future<void> _onLoadByIdRequested(
    GroupLoadByIdRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.debug(
      'Loading group by ID',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(status: GroupStatus.loading));

    // Cancel existing single group subscription
    await _singleGroupSubscription?.cancel();

    // Subscribe to single group updates
    _singleGroupSubscription = _groupRepository
        .watchGroupById(event.groupId)
        .listen(
          (result) {
            result.fold(
              (failure) {
                _log.error(
                  'Failed to load group',
                  tag: LogTags.groups,
                  data: {'groupId': event.groupId, 'error': failure.message},
                );
                emit(
                  state.copyWith(
                    status: GroupStatus.failure,
                    errorMessage: ErrorMessages.groupNotFound,
                  ),
                );
              },
              (group) {
                _log.debug(
                  'Group loaded',
                  tag: LogTags.groups,
                  data: {'groupId': group.id, 'name': group.name},
                );
                add(SingleGroupUpdated(group));
              },
            );
          },
          onError: (error, stackTrace) {
            _log.error(
              'Group stream error',
              tag: LogTags.groups,
              error: error,
              stackTrace: stackTrace,
            );
            emit(
              state.copyWith(
                status: GroupStatus.failure,
                errorMessage: ErrorMessages.groupLoadFailed,
              ),
            );
          },
        );
  }

  /// Handle create group request
  Future<void> _onCreateRequested(
    GroupCreateRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Creating group',
      tag: LogTags.groups,
      data: {'name': event.name},
    );
    emit(state.copyWith(status: GroupStatus.creating, isCreating: true));

    final result = await _groupRepository.createGroup(
      name: event.name,
      description: event.description,
      type: event.type,
      currency: event.currency,
      simplifyDebts: event.simplifyDebts,
      initialMemberIds: event.initialMemberIds,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to create group',
          tag: LogTags.groups,
          data: {'name': event.name, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupCreateFailed,
            isCreating: false,
          ),
        );
      },
      (group) {
        _log.info(
          'Group created successfully',
          tag: LogTags.groups,
          data: {'groupId': group.id, 'name': group.name},
        );
        // Add new group to the list
        final updatedGroups = [group, ...state.groups];
        emit(
          state.copyWith(
            status: GroupStatus.success,
            groups: updatedGroups,
            selectedGroup: group,
            isCreating: false,
            clearError: true,
          ),
        );
      },
    );
  }

  /// Handle update group request
  Future<void> _onUpdateRequested(
    GroupUpdateRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Updating group',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(status: GroupStatus.updating, isUpdating: true));

    final result = await _groupRepository.updateGroup(
      groupId: event.groupId,
      name: event.name,
      description: event.description,
      type: event.type,
      currency: event.currency,
      simplifyDebts: event.simplifyDebts,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to update group',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupUpdateFailed,
            isUpdating: false,
          ),
        );
      },
      (group) {
        _log.info(
          'Group updated successfully',
          tag: LogTags.groups,
          data: {'groupId': group.id},
        );
        // Update group in the list
        final updatedGroups = state.groups.map((g) {
          return g.id == group.id ? group : g;
        }).toList();
        emit(
          state.copyWith(
            status: GroupStatus.success,
            groups: updatedGroups,
            selectedGroup: group,
            isUpdating: false,
            clearError: true,
          ),
        );
      },
    );
  }

  /// Handle image update request
  Future<void> _onImageUpdateRequested(
    GroupImageUpdateRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Updating group image',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.updateGroupImage(
      groupId: event.groupId,
      imageFile: event.imageFile,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to update group image',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.storageUploadFailed,
            isUpdating: false,
          ),
        );
      },
      (imageUrl) {
        _log.info(
          'Group image updated',
          tag: LogTags.groups,
          data: {'groupId': event.groupId},
        );
        // Refresh the group to get updated data
        add(GroupLoadByIdRequested(event.groupId));
        emit(state.copyWith(isUpdating: false, clearError: true));
      },
    );
  }

  /// Handle image delete request
  Future<void> _onImageDeleteRequested(
    GroupImageDeleteRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Deleting group image',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.deleteGroupImage(event.groupId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete group image',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.storageDeleteFailed,
            isUpdating: false,
          ),
        );
      },
      (_) {
        _log.info(
          'Group image deleted',
          tag: LogTags.groups,
          data: {'groupId': event.groupId},
        );
        // Refresh the group
        add(GroupLoadByIdRequested(event.groupId));
        emit(state.copyWith(isUpdating: false, clearError: true));
      },
    );
  }

  /// Handle delete group request
  Future<void> _onDeleteRequested(
    GroupDeleteRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Deleting group',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(status: GroupStatus.deleting, isDeleting: true));

    final result = await _groupRepository.deleteGroup(event.groupId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete group',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupDeleteFailed,
            isDeleting: false,
          ),
        );
      },
      (_) {
        _log.info(
          'Group deleted successfully',
          tag: LogTags.groups,
          data: {'groupId': event.groupId},
        );
        // Remove group from list
        final updatedGroups = state.groups
            .where((g) => g.id != event.groupId)
            .toList();
        emit(
          state.copyWith(
            status: GroupStatus.success,
            groups: updatedGroups,
            clearSelectedGroup: true,
            isDeleting: false,
            clearError: true,
          ),
        );
      },
    );
  }

  /// Handle add member request
  Future<void> _onMemberAddRequested(
    GroupMemberAddRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Adding member to group',
      tag: LogTags.groups,
      data: {'groupId': event.groupId, 'userId': event.userId},
    );
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.addMember(
      groupId: event.groupId,
      userId: event.userId,
      displayName: event.displayName,
      phone: event.phone,
      photoUrl: event.photoUrl,
      role: event.role,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to add member',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupMemberAddFailed,
            isUpdating: false,
          ),
        );
      },
      (group) {
        _log.info('Member added successfully', tag: LogTags.groups);
        _updateGroupInState(emit, group);
        emit(state.copyWith(isUpdating: false, clearError: true));
      },
    );
  }

  /// Handle remove member request
  Future<void> _onMemberRemoveRequested(
    GroupMemberRemoveRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Removing member from group',
      tag: LogTags.groups,
      data: {'groupId': event.groupId, 'userId': event.userId},
    );
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.removeMember(
      groupId: event.groupId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to remove member',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: ErrorMessages.groupMemberRemoveFailed,
            isUpdating: false,
          ),
        );
      },
      (group) {
        _log.info('Member removed successfully', tag: LogTags.groups);
        _updateGroupInState(emit, group);
        emit(state.copyWith(isUpdating: false, clearError: true));
      },
    );
  }

  /// Handle update member role request
  Future<void> _onMemberRoleUpdateRequested(
    GroupMemberRoleUpdateRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Updating member role',
      tag: LogTags.groups,
      data: {
        'groupId': event.groupId,
        'userId': event.userId,
        'newRole': event.newRole,
      },
    );
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.updateMemberRole(
      groupId: event.groupId,
      userId: event.userId,
      newRole: event.newRole,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to update member role',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: failure.message,
            isUpdating: false,
          ),
        );
      },
      (group) {
        _log.info('Member role updated successfully', tag: LogTags.groups);
        _updateGroupInState(emit, group);
        emit(state.copyWith(isUpdating: false, clearError: true));
      },
    );
  }

  /// Handle leave group request
  Future<void> _onLeaveRequested(
    GroupLeaveRequested event,
    Emitter<GroupState> emit,
  ) async {
    _log.info(
      'Leaving group',
      tag: LogTags.groups,
      data: {'groupId': event.groupId},
    );
    emit(state.copyWith(isDeleting: true));

    final result = await _groupRepository.leaveGroup(event.groupId);

    result.fold(
      (failure) {
        _log.error(
          'Failed to leave group',
          tag: LogTags.groups,
          data: {'groupId': event.groupId, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: failure.message,
            isDeleting: false,
          ),
        );
      },
      (_) {
        _log.info(
          'Left group successfully',
          tag: LogTags.groups,
          data: {'groupId': event.groupId},
        );
        // Remove group from list
        final updatedGroups = state.groups
            .where((g) => g.id != event.groupId)
            .toList();
        emit(
          state.copyWith(
            status: GroupStatus.success,
            groups: updatedGroups,
            clearSelectedGroup: true,
            isDeleting: false,
            clearError: true,
          ),
        );
      },
    );
  }

  /// Handle real-time group updates
  void _onGroupUpdated(GroupUpdated event, Emitter<GroupState> emit) {
    _log.debug(
      'Groups updated via stream',
      tag: LogTags.groups,
      data: {'count': event.groups.length},
    );
    emit(
      state.copyWith(
        status: GroupStatus.success,
        groups: event.groups,
        clearError: true,
      ),
    );
  }

  /// Handle single group real-time update
  void _onSingleGroupUpdated(
    SingleGroupUpdated event,
    Emitter<GroupState> emit,
  ) {
    _log.debug(
      'Single group updated via stream',
      tag: LogTags.groups,
      data: {'groupId': event.group.id},
    );
    // Update in list if exists
    final updatedGroups = state.groups.map((g) {
      return g.id == event.group.id ? event.group : g;
    }).toList();

    emit(
      state.copyWith(
        status: GroupStatus.success,
        groups: updatedGroups,
        selectedGroup: event.group,
        clearError: true,
      ),
    );
  }

  /// Helper to update a group in the state
  void _updateGroupInState(Emitter<GroupState> emit, GroupEntity group) {
    final updatedGroups = state.groups.map((g) {
      return g.id == group.id ? group : g;
    }).toList();

    emit(
      state.copyWith(
        groups: updatedGroups,
        selectedGroup: state.selectedGroup?.id == group.id
            ? group
            : state.selectedGroup,
      ),
    );
  }

  @override
  Future<void> close() {
    _log.debug('GroupBloc closing', tag: LogTags.groups);
    _groupsSubscription?.cancel();
    _singleGroupSubscription?.cancel();
    return super.close();
  }
}
