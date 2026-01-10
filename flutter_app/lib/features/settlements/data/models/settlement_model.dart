import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/settlement_entity.dart';

/// Firestore model for Settlement
class SettlementModel extends SettlementEntity {
  const SettlementModel({
    required super.id,
    required super.groupId,
    required super.fromUserId,
    required super.fromUserName,
    required super.toUserId,
    required super.toUserName,
    required super.amount,
    super.currency,
    super.status,
    super.paymentMethod,
    super.paymentReference,
    super.requiresBiometric,
    super.biometricVerified,
    super.notes,
    required super.createdAt,
    super.confirmedAt,
    super.confirmedBy,
  });

  /// Create from Firestore document
  factory SettlementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SettlementModel(
      id: doc.id,
      groupId: data['groupId'] as String,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      toUserId: data['toUserId'] as String,
      toUserName: data['toUserName'] as String,
      amount: data['amount'] as int,
      currency: data['currency'] as String? ?? 'INR',
      status: _parseStatus(data['status'] as String?),
      paymentMethod: _parsePaymentMethod(data['paymentMethod'] as String?),
      paymentReference: data['paymentReference'] as String?,
      requiresBiometric: data['requiresBiometric'] as bool? ?? false,
      biometricVerified: data['biometricVerified'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      confirmedBy: data['confirmedBy'] as String?,
    );
  }

  /// Create from entity
  factory SettlementModel.fromEntity(SettlementEntity entity) {
    return SettlementModel(
      id: entity.id,
      groupId: entity.groupId,
      fromUserId: entity.fromUserId,
      fromUserName: entity.fromUserName,
      toUserId: entity.toUserId,
      toUserName: entity.toUserName,
      amount: entity.amount,
      currency: entity.currency,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      paymentReference: entity.paymentReference,
      requiresBiometric: entity.requiresBiometric,
      biometricVerified: entity.biometricVerified,
      notes: entity.notes,
      createdAt: entity.createdAt,
      confirmedAt: entity.confirmedAt,
      confirmedBy: entity.confirmedBy,
    );
  }

  /// Convert to Firestore document data for creation
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'groupId': groupId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
      'currency': currency,
      'status': _statusToString(status),
      'paymentMethod': paymentMethod != null
          ? _paymentMethodToString(paymentMethod!)
          : null,
      'paymentReference': paymentReference,
      'requiresBiometric': requiresBiometric,
      'biometricVerified': biometricVerified,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
      'confirmedBy': null,
    };
  }

  /// Convert to Firestore document data for updates
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'status': _statusToString(status),
      'paymentMethod': paymentMethod != null
          ? _paymentMethodToString(paymentMethod!)
          : null,
      'paymentReference': paymentReference,
      'biometricVerified': biometricVerified,
      'notes': notes,
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
    };
  }

  static SettlementStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return SettlementStatus.confirmed;
      case 'rejected':
        return SettlementStatus.rejected;
      case 'pending':
      default:
        return SettlementStatus.pending;
    }
  }

  static String _statusToString(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.confirmed:
        return 'confirmed';
      case SettlementStatus.rejected:
        return 'rejected';
      case SettlementStatus.pending:
        return 'pending';
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? method) {
    if (method == null) return null;
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'other':
        return PaymentMethod.other;
      default:
        return null;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.other:
        return 'other';
    }
  }
}
