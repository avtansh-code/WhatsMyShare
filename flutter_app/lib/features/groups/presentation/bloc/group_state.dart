import 'package:equatable/equatable.dart';

import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';

/// Status enum for group operations
enum GroupStatus {
  initial,
  loading,
  success,
  failure,
  creating,
  updating,
  deleting,
}

/// State class for group management
class GroupState extends Equatable {
  final GroupStatus status;
  final List<GroupEntity> groups;
  final GroupEntity? selectedGroup;
  final GroupStatistics? statistics;
  final String? errorMessage;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;

  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.selectedGroup,
    this.statistics,
    this.errorMessage,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  /// Initial state
  factory GroupState.initial() => const GroupState();

  /// Loading state
  factory GroupState.loading() => const GroupState(status: GroupStatus.loading);

  /// Success state with groups
  GroupState copyWith({
    GroupStatus? status,
    List<GroupEntity>? groups,
    GroupEntity? selectedGroup,
    GroupStatistics? statistics,
    String? errorMessage,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool clearSelectedGroup = false,
    bool clearError = false,
  }) {
    return GroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedGroup: clearSelectedGroup
          ? null
          : (selectedGroup ?? this.selectedGroup),
      statistics: statistics ?? this.statistics,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  /// Check if state is loading
  bool get isLoading => status == GroupStatus.loading;

  /// Check if state has error
  bool get hasError => status == GroupStatus.failure && errorMessage != null;

  /// Check if groups are loaded
  bool get isLoaded => status == GroupStatus.success;

  /// Check if there are any groups
  bool get hasGroups => groups.isNotEmpty;

  /// Get total number of groups
  int get groupCount => groups.length;

  /// Get groups where user owes money
  List<GroupEntity> get groupsWhereUserOwes {
    // This would need the current user ID to filter properly
    // For now, return groups with any negative balance
    return groups.where((g) => g.balances.values.any((b) => b < 0)).toList();
  }

  /// Get groups where user is owed money
  List<GroupEntity> get groupsWhereUserIsOwed {
    return groups.where((g) => g.balances.values.any((b) => b > 0)).toList();
  }

  /// Get settled groups
  List<GroupEntity> get settledGroups {
    return groups.where((g) => g.balances.values.every((b) => b == 0)).toList();
  }

  /// Get recent groups (sorted by last activity)
  List<GroupEntity> get recentGroups {
    final sorted = List<GroupEntity>.from(groups);
    sorted.sort((a, b) {
      final aActivity = a.lastActivityAt ?? a.createdAt;
      final bActivity = b.lastActivityAt ?? b.createdAt;
      return bActivity.compareTo(aActivity);
    });
    return sorted.take(5).toList();
  }

  @override
  List<Object?> get props => [
    status,
    groups,
    selectedGroup,
    statistics,
    errorMessage,
    isCreating,
    isUpdating,
    isDeleting,
  ];
}
