import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense_entity.dart';

/// Payer info model for Firestore
class PayerInfoModel {
  final String userId;
  final String displayName;
  final int amount;

  const PayerInfoModel({
    required this.userId,
    required this.displayName,
    required this.amount,
  });

  factory PayerInfoModel.fromMap(Map<String, dynamic> map) {
    return PayerInfoModel(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      amount: map['amount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'displayName': displayName, 'amount': amount};
  }

  PayerInfo toEntity() {
    return PayerInfo(userId: userId, displayName: displayName, amount: amount);
  }

  factory PayerInfoModel.fromEntity(PayerInfo entity) {
    return PayerInfoModel(
      userId: entity.userId,
      displayName: entity.displayName,
      amount: entity.amount,
    );
  }
}

/// Friend split participant model for Firestore
class FriendSplitParticipantModel {
  final String? userId;
  final String? email;
  final String? phone;
  final String displayName;
  final String? photoUrl;

  const FriendSplitParticipantModel({
    this.userId,
    this.email,
    this.phone,
    required this.displayName,
    this.photoUrl,
  });

  factory FriendSplitParticipantModel.fromMap(Map<String, dynamic> map) {
    return FriendSplitParticipantModel(
      userId: map['userId'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      displayName: map['displayName'] as String? ?? 'Unknown',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  FriendSplitParticipant toEntity() {
    return FriendSplitParticipant(
      userId: userId,
      email: email,
      phone: phone,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  factory FriendSplitParticipantModel.fromEntity(FriendSplitParticipant entity) {
    return FriendSplitParticipantModel(
      userId: entity.userId,
      email: entity.email,
      phone: entity.phone,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
    );
  }
}

/// Split context model for Firestore
class SplitContextModel {
  final SplitContextType type;
  final String? groupId;
  final List<FriendSplitParticipantModel>? friendParticipants;

  const SplitContextModel({
    required this.type,
    this.groupId,
    this.friendParticipants,
  });

  factory SplitContextModel.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'group';
    final type = typeStr == 'friends' ? SplitContextType.friends : SplitContextType.group;
    
    List<FriendSplitParticipantModel>? participants;
    if (map['friendParticipants'] != null) {
      participants = (map['friendParticipants'] as List<dynamic>)
          .map((p) => FriendSplitParticipantModel.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    return SplitContextModel(
      type: type,
      groupId: map['groupId'] as String?,
      friendParticipants: participants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      if (groupId != null) 'groupId': groupId,
      if (friendParticipants != null)
        'friendParticipants': friendParticipants!.map((p) => p.toMap()).toList(),
    };
  }

  SplitContext toEntity() {
    return SplitContext(
      type: type,
      groupId: groupId,
      friendParticipants: friendParticipants?.map((p) => p.toEntity()).toList(),
    );
  }

  factory SplitContextModel.fromEntity(SplitContext entity) {
    return SplitContextModel(
      type: entity.type,
      groupId: entity.groupId,
      friendParticipants: entity.friendParticipants
          ?.map((p) => FriendSplitParticipantModel.fromEntity(p))
          .toList(),
    );
  }
}

/// Expense split model for Firestore
class ExpenseSplitModel {
  final String userId;
  final String displayName;
  final int amount;
  final double? percentage;
  final int? shares;
  final bool isPaid;
  final DateTime? paidAt;

  const ExpenseSplitModel({
    required this.userId,
    required this.displayName,
    required this.amount,
    this.percentage,
    this.shares,
    this.isPaid = false,
    this.paidAt,
  });

  factory ExpenseSplitModel.fromMap(Map<String, dynamic> map) {
    return ExpenseSplitModel(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      amount: map['amount'] as int,
      percentage: map['percentage'] as double?,
      shares: map['shares'] as int?,
      isPaid: map['isPaid'] as bool? ?? false,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'amount': amount,
      if (percentage != null) 'percentage': percentage,
      if (shares != null) 'shares': shares,
      'isPaid': isPaid,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }

  ExpenseSplit toEntity() {
    return ExpenseSplit(
      userId: userId,
      displayName: displayName,
      amount: amount,
      percentage: percentage,
      shares: shares,
      isPaid: isPaid,
      paidAt: paidAt,
    );
  }

  factory ExpenseSplitModel.fromEntity(ExpenseSplit entity) {
    return ExpenseSplitModel(
      userId: entity.userId,
      displayName: entity.displayName,
      amount: entity.amount,
      percentage: entity.percentage,
      shares: entity.shares,
      isPaid: entity.isPaid,
      paidAt: entity.paidAt,
    );
  }
}

/// Expense model for Firestore
class ExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final int amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final List<PayerInfoModel> paidBy;
  final SplitType splitType;
  final List<ExpenseSplitModel> splits;
  final List<String>? receiptUrls;
  final String? notes;
  final String createdBy;
  final ExpenseStatus status;
  final int chatMessageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final SplitContextModel? splitContext;

  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    this.receiptUrls,
    this.notes,
    required this.createdBy,
    required this.status,
    this.chatMessageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.splitContext,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      description: data['description'] as String,
      amount: data['amount'] as int,
      currency: data['currency'] as String? ?? 'INR',
      category: _categoryFromString(data['category'] as String? ?? 'other'),
      date: (data['date'] as Timestamp).toDate(),
      paidBy: (data['paidBy'] as List<dynamic>)
          .map((p) => PayerInfoModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      splitType: _splitTypeFromString(data['splitType'] as String? ?? 'equal'),
      splits: (data['splits'] as List<dynamic>)
          .map((s) => ExpenseSplitModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      receiptUrls: (data['receiptUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String,
      status: _statusFromString(data['status'] as String? ?? 'active'),
      chatMessageCount: data['chatMessageCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      deletedBy: data['deletedBy'] as String?,
      splitContext: data['splitContext'] != null
          ? SplitContextModel.fromMap(data['splitContext'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy.map((p) => p.toMap()).toList(),
      'splitType': splitType.name,
      'splits': splits.map((s) => s.toMap()).toList(),
      if (receiptUrls != null) 'receiptUrls': receiptUrls,
      if (notes != null) 'notes': notes,
      'createdBy': createdBy,
      'status': status.name,
      'chatMessageCount': chatMessageCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      if (deletedBy != null) 'deletedBy': deletedBy,
      if (splitContext != null) 'splitContext': splitContext!.toMap(),
    };
  }

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      groupId: groupId,
      description: description,
      amount: amount,
      currency: currency,
      category: category,
      date: date,
      paidBy: paidBy.map((p) => p.toEntity()).toList(),
      splitType: splitType,
      splits: splits.map((s) => s.toEntity()).toList(),
      receiptUrls: receiptUrls,
      notes: notes,
      createdBy: createdBy,
      status: status,
      chatMessageCount: chatMessageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      splitContext: splitContext?.toEntity(),
    );
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      groupId: entity.groupId,
      description: entity.description,
      amount: entity.amount,
      currency: entity.currency,
      category: entity.category,
      date: entity.date,
      paidBy: entity.paidBy.map((p) => PayerInfoModel.fromEntity(p)).toList(),
      splitType: entity.splitType,
      splits: entity.splits
          .map((s) => ExpenseSplitModel.fromEntity(s))
          .toList(),
      receiptUrls: entity.receiptUrls,
      notes: entity.notes,
      createdBy: entity.createdBy,
      status: entity.status,
      chatMessageCount: entity.chatMessageCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
      splitContext: entity.splitContext != null
          ? SplitContextModel.fromEntity(entity.splitContext!)
          : null,
    );
  }

  static ExpenseCategory _categoryFromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }

  static SplitType _splitTypeFromString(String value) {
    return SplitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SplitType.equal,
    );
  }

  static ExpenseStatus _statusFromString(String value) {
    return ExpenseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseStatus.active,
    );
  }
}
