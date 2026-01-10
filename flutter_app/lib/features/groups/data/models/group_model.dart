import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/group_entity.dart';

/// Group member model for Firestore - stores only UID and role
/// Display properties are resolved via UserCacheService
class GroupMemberModel {
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  /// Create from Firestore map (UID-only storage)
  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      userId: map['userId'] as String,
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
      role: entity.role,
      joinedAt: entity.joinedAt,
    );
  }

  /// Convert to Firestore map (UID-only storage)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role.name,
    };
  }

  /// Convert to entity (without cached data)
  GroupMember toEntity() {
    return GroupMember(userId: userId, role: role, joinedAt: joinedAt);
  }

  /// Convert to entity with cached user data
  GroupMember toEntityWithCache({
    String? displayName,
    String? phone,
    String? photoUrl,
  }) {
    return GroupMember(
      userId: userId,
      role: role,
      joinedAt: joinedAt,
      cachedDisplayName: displayName,
      cachedPhone: phone,
      cachedPhotoUrl: photoUrl,
    );
  }
}

/// Simplified debt model for Firestore - stores only UIDs
class SimplifiedDebtModel {
  final String fromUserId;
  final String toUserId;
  final int amount;

  const SimplifiedDebtModel({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  /// Create from Firestore map
  factory SimplifiedDebtModel.fromMap(Map<String, dynamic> map) {
    return SimplifiedDebtModel(
      fromUserId: map['from'] as String,
      toUserId: map['to'] as String,
      amount: map['amount'] as int,
    );
  }

  /// Create from entity
  factory SimplifiedDebtModel.fromEntity(SimplifiedDebt entity) {
    return SimplifiedDebtModel(
      fromUserId: entity.fromUserId,
      toUserId: entity.toUserId,
      amount: entity.amount,
    );
  }

  /// Convert to Firestore map (UID-only)
  Map<String, dynamic> toMap() {
    return {'from': fromUserId, 'to': toUserId, 'amount': amount};
  }

  /// Convert to entity (without cached names)
  SimplifiedDebt toEntity() {
    return SimplifiedDebt(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
    );
  }

  /// Convert to entity with cached user names
  SimplifiedDebt toEntityWithCache({String? fromUserName, String? toUserName}) {
    return SimplifiedDebt(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      cachedFromUserName: fromUserName,
      cachedToUserName: toUserName,
    );
  }
}

/// Group model for Firestore serialization
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final GroupType type;
  final List<GroupMemberModel> members;
  final List<String> memberIds;
  final int memberCount;
  final String currency;
  final bool simplifyDebts;
  final String createdBy;
  final List<String> admins;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalExpenses;
  final int expenseCount;
  final DateTime? lastActivityAt;
  final Map<String, int> balances;
  final List<SimplifiedDebtModel>? simplifiedDebts;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.type,
    required this.members,
    required this.memberIds,
    required this.memberCount,
    required this.currency,
    required this.simplifyDebts,
    required this.createdBy,
    required this.admins,
    required this.createdAt,
    required this.updatedAt,
    required this.totalExpenses,
    required this.expenseCount,
    this.lastActivityAt,
    required this.balances,
    this.simplifiedDebts,
  });

  /// Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse members (UID-only)
    final membersData = data['members'] as List<dynamic>? ?? [];
    final members = membersData
        .map((m) => GroupMemberModel.fromMap(m as Map<String, dynamic>))
        .toList();

    // Parse balances
    final balancesData = data['balances'] as Map<String, dynamic>? ?? {};
    final balances = balancesData.map(
      (key, value) => MapEntry(key, value as int),
    );

    // Parse simplified debts (UID-only)
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
      members: entity.members
          .map((m) => GroupMemberModel.fromEntity(m))
          .toList(),
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
      simplifiedDebts: entity.simplifiedDebts
          ?.map((d) => SimplifiedDebtModel.fromEntity(d))
          .toList(),
    );
  }

  /// Convert to entity (without cached data)
  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      type: type,
      members: members.map((m) => m.toEntity()).toList(),
      memberIds: memberIds,
      memberCount: memberCount,
      currency: currency,
      simplifyDebts: simplifyDebts,
      createdBy: createdBy,
      admins: admins,
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalExpenses: totalExpenses,
      expenseCount: expenseCount,
      lastActivityAt: lastActivityAt,
      balances: balances,
      simplifiedDebts: simplifiedDebts?.map((d) => d.toEntity()).toList(),
    );
  }

  /// Convert to Firestore map for creating a new group
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'members': members.map((m) => m.toMap()).toList(),
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
      'simplifiedDebts': simplifiedDebts?.map((d) => d.toMap()).toList(),
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
