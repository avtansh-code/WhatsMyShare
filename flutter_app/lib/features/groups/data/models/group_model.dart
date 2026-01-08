import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/group_entity.dart';

/// Group member model for Firestore
class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.userId,
    required super.displayName,
    super.photoUrl,
    required super.email,
    required super.joinedAt,
    required super.role,
  });

  /// Create from Firestore map
  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      email: map['email'] as String,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      role: MemberRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MemberRole.member,
      ),
    );
  }

  /// Create from entity
  factory GroupMemberModel.fromEntity(GroupMember entity) {
    return GroupMemberModel(
      userId: entity.userId,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      email: entity.email,
      joinedAt: entity.joinedAt,
      role: entity.role,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'email': email,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role.name,
    };
  }
}

/// Simplified debt model for Firestore
class SimplifiedDebtModel extends SimplifiedDebt {
  const SimplifiedDebtModel({
    required super.fromUserId,
    required super.fromUserName,
    required super.toUserId,
    required super.toUserName,
    required super.amount,
  });

  /// Create from Firestore map
  factory SimplifiedDebtModel.fromMap(Map<String, dynamic> map) {
    return SimplifiedDebtModel(
      fromUserId: map['from'] as String,
      fromUserName: map['fromName'] as String? ?? '',
      toUserId: map['to'] as String,
      toUserName: map['toName'] as String? ?? '',
      amount: map['amount'] as int,
    );
  }

  /// Create from entity
  factory SimplifiedDebtModel.fromEntity(SimplifiedDebt entity) {
    return SimplifiedDebtModel(
      fromUserId: entity.fromUserId,
      fromUserName: entity.fromUserName,
      toUserId: entity.toUserId,
      toUserName: entity.toUserName,
      amount: entity.amount,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'from': fromUserId,
      'fromName': fromUserName,
      'to': toUserId,
      'toName': toUserName,
      'amount': amount,
    };
  }
}

/// Group model for Firestore serialization
class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    super.description,
    super.imageUrl,
    required super.type,
    required super.members,
    required super.memberIds,
    required super.memberCount,
    required super.currency,
    required super.simplifyDebts,
    required super.createdBy,
    required super.admins,
    required super.createdAt,
    required super.updatedAt,
    required super.totalExpenses,
    required super.expenseCount,
    super.lastActivityAt,
    required super.balances,
    super.simplifiedDebts,
  });

  /// Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse members
    final membersData = data['members'] as List<dynamic>? ?? [];
    final members = membersData
        .map((m) => GroupMemberModel.fromMap(m as Map<String, dynamic>))
        .toList();

    // Parse balances
    final balancesData = data['balances'] as Map<String, dynamic>? ?? {};
    final balances = balancesData.map(
      (key, value) => MapEntry(key, value as int),
    );

    // Parse simplified debts
    final simplifiedDebtsData = data['simplifiedDebts'] as List<dynamic>?;
    final simplifiedDebts = simplifiedDebtsData
        ?.map((d) => SimplifiedDebtModel.fromMap(d as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      type: GroupType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GroupType.other,
      ),
      members: members,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] as int? ?? members.length,
      currency: data['currency'] as String? ?? 'INR',
      simplifyDebts: data['simplifyDebts'] as bool? ?? true,
      createdBy: data['createdBy'] as String,
      admins: List<String>.from(data['admins'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalExpenses: data['totalExpenses'] as int? ?? 0,
      expenseCount: data['expenseCount'] as int? ?? 0,
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
      balances: balances,
      simplifiedDebts: simplifiedDebts,
    );
  }

  /// Create from entity
  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      type: entity.type,
      members: entity.members,
      memberIds: entity.memberIds,
      memberCount: entity.memberCount,
      currency: entity.currency,
      simplifyDebts: entity.simplifyDebts,
      createdBy: entity.createdBy,
      admins: entity.admins,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      totalExpenses: entity.totalExpenses,
      expenseCount: entity.expenseCount,
      lastActivityAt: entity.lastActivityAt,
      balances: entity.balances,
      simplifiedDebts: entity.simplifiedDebts,
    );
  }

  /// Convert to Firestore map for creating a new group
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'members': members
          .map((m) => GroupMemberModel.fromEntity(m).toMap())
          .toList(),
      'memberIds': memberIds,
      'memberCount': memberCount,
      'currency': currency,
      'simplifyDebts': simplifyDebts,
      'createdBy': createdBy,
      'admins': admins,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'totalExpenses': totalExpenses,
      'expenseCount': expenseCount,
      'lastActivityAt': lastActivityAt != null
          ? Timestamp.fromDate(lastActivityAt!)
          : FieldValue.serverTimestamp(),
      'balances': balances,
      'simplifiedDebts': simplifiedDebts
          ?.map((d) => SimplifiedDebtModel.fromEntity(d).toMap())
          .toList(),
    };
  }

  /// Convert to Firestore map for updating
  Map<String, dynamic> toUpdateMap({
    String? name,
    String? description,
    String? imageUrl,
    GroupType? type,
    String? currency,
    bool? simplifyDebts,
  }) {
    final map = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (type != null) map['type'] = type.name;
    if (currency != null) map['currency'] = currency;
    if (simplifyDebts != null) map['simplifyDebts'] = simplifyDebts;

    return map;
  }
}
