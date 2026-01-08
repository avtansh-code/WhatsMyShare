import 'package:equatable/equatable.dart';

/// Status of an offline operation
enum OperationStatus { pending, inProgress, completed, failed }

/// Type of offline operation
enum OperationType {
  createExpense,
  updateExpense,
  deleteExpense,
  createGroup,
  updateGroup,
  createSettlement,
  updateSettlement,
  updateProfile,
  addGroupMember,
  removeGroupMember,
}

/// Represents an operation queued for offline sync
class OfflineOperation extends Equatable {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final OperationStatus status;
  final String? errorMessage;
  final String? entityId;
  final String? groupId;

  const OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.status = OperationStatus.pending,
    this.errorMessage,
    this.entityId,
    this.groupId,
  });

  /// Create a copy with updated values
  OfflineOperation copyWith({
    String? id,
    OperationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    OperationStatus? status,
    String? errorMessage,
    String? entityId,
    String? groupId,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      entityId: entityId ?? this.entityId,
      groupId: groupId ?? this.groupId,
    );
  }

  /// Increment retry count
  OfflineOperation incrementRetry() {
    return copyWith(retryCount: retryCount + 1);
  }

  /// Mark as in progress
  OfflineOperation markInProgress() {
    return copyWith(status: OperationStatus.inProgress);
  }

  /// Mark as completed
  OfflineOperation markCompleted() {
    return copyWith(status: OperationStatus.completed);
  }

  /// Mark as failed with error message
  OfflineOperation markFailed(String error) {
    return copyWith(status: OperationStatus.failed, errorMessage: error);
  }

  /// Check if max retries exceeded
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Max retry attempts
  static const int maxRetries = 3;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'errorMessage': errorMessage,
      'entityId': entityId,
      'groupId': groupId,
    };
  }

  /// Create from JSON
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.createExpense,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      status: OperationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OperationStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
      entityId: json['entityId'] as String?,
      groupId: json['groupId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    data,
    createdAt,
    retryCount,
    status,
    errorMessage,
    entityId,
    groupId,
  ];

  @override
  String toString() {
    return 'OfflineOperation(id: $id, type: $type, status: $status, retryCount: $retryCount)';
  }
}
