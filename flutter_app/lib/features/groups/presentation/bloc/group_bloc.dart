import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import 'group_event.dart';
import 'group_state.dart';

/// BLoC for managing group state
class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;
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
  }

  /// Handle load all groups request
  Future<void> _onLoadAllRequested(
    GroupLoadAllRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(status: GroupStatus.loading));

    // Cancel existing subscription
    await _groupsSubscription?.cancel();

    // Subscribe to real-time updates
    _groupsSubscription = _groupRepository.watchGroups().listen(
      (result) {
        result.fold(
          (failure) => emit(
            state.copyWith(
              status: GroupStatus.failure,
              errorMessage: failure.message,
            ),
          ),
          (groups) => add(GroupUpdated(groups)),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: GroupStatus.failure,
            errorMessage: error.toString(),
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
    emit(state.copyWith(status: GroupStatus.loading));

    // Cancel existing single group subscription
    await _singleGroupSubscription?.cancel();

    // Subscribe to single group updates
    _singleGroupSubscription = _groupRepository
        .watchGroupById(event.groupId)
        .listen(
          (result) {
            result.fold(
              (failure) => emit(
                state.copyWith(
                  status: GroupStatus.failure,
                  errorMessage: failure.message,
                ),
              ),
              (group) => add(SingleGroupUpdated(group)),
            );
          },
          onError: (error) {
            emit(
              state.copyWith(
                status: GroupStatus.failure,
                errorMessage: error.toString(),
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
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isCreating: false,
        ),
      ),
      (group) {
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
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (group) {
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
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.updateGroupImage(
      groupId: event.groupId,
      imageFile: event.imageFile,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (imageUrl) {
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
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.deleteGroupImage(event.groupId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (_) {
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
    emit(state.copyWith(status: GroupStatus.deleting, isDeleting: true));

    final result = await _groupRepository.deleteGroup(event.groupId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isDeleting: false,
        ),
      ),
      (_) {
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
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.addMember(
      groupId: event.groupId,
      userId: event.userId,
      displayName: event.displayName,
      email: event.email,
      photoUrl: event.photoUrl,
      role: event.role,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (group) {
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
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.removeMember(
      groupId: event.groupId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (group) {
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
    emit(state.copyWith(isUpdating: true));

    final result = await _groupRepository.updateMemberRole(
      groupId: event.groupId,
      userId: event.userId,
      newRole: event.newRole,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isUpdating: false,
        ),
      ),
      (group) {
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
    emit(state.copyWith(isDeleting: true));

    final result = await _groupRepository.leaveGroup(event.groupId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupStatus.failure,
          errorMessage: failure.message,
          isDeleting: false,
        ),
      ),
      (_) {
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
    _groupsSubscription?.cancel();
    _singleGroupSubscription?.cancel();
    return super.close();
  }
}
