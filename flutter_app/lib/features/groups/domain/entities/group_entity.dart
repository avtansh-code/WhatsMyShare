import 'package:equatable/equatable.dart';

/// Group type enumeration
enum GroupType { trip, home, couple, other }

/// Member role enumeration
enum MemberRole { admin, member }

/// Group member entity - stores only UID, display properties come from cache
///
/// Backend storage: Only stores userId (UID) and role
/// Display properties (displayName, phone, photoUrl) are resolved from the
/// UserCacheService using the userId
class GroupMember extends Equatable {
  /// The member's user ID (PRIMARY identifier)
  final String userId;

  /// The member's role in the group
  final MemberRole role;

  /// When the member joined the group
  final DateTime joinedAt;

  // ============================================
  // CACHED DISPLAY PROPERTIES (populated from UserCacheService)
  // These are NOT stored in the backend, only used for UI display
  // ============================================

  /// Display name (cached from user profile)
  final String? cachedDisplayName;

  /// Phone number (cached from user profile)
  final String? cachedPhone;

  /// Photo URL (cached from user profile)
  final String? cachedPhotoUrl;

  const GroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.cachedDisplayName,
    this.cachedPhone,
    this.cachedPhotoUrl,
  });

  /// Check if member is admin
  bool get isAdmin => role == MemberRole.admin;

  /// Get display name or fallback
  String get displayName {
    if (cachedDisplayName != null && cachedDisplayName!.isNotEmpty) {
      return cachedDisplayName!;
    }
    if (cachedPhone != null && cachedPhone!.length >= 4) {
      return '****${cachedPhone!.substring(cachedPhone!.length - 4)}';
    }
    return 'Unknown';
  }

  /// Get phone number
  String? get phone => cachedPhone;

  /// Get photo URL
  String? get photoUrl => cachedPhotoUrl;

  /// Get initials for avatar
  String get initials {
    if (cachedDisplayName != null && cachedDisplayName!.isNotEmpty) {
      final parts = cachedDisplayName!.trim().split(' ');
      if (parts.isEmpty) return '?';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    if (cachedPhone != null && cachedPhone!.length >= 2) {
      return cachedPhone!.substring(cachedPhone!.length - 2);
    }
    return '??';
  }

  /// Get masked phone for display (show last 4 digits)
  String get maskedPhone {
    if (cachedPhone == null || cachedPhone!.isEmpty) return '';
    if (cachedPhone!.length >= 4) {
      return '****${cachedPhone!.substring(cachedPhone!.length - 4)}';
    }
    return cachedPhone!;
  }

  /// Check if cache is populated
  bool get hasCachedData =>
      cachedDisplayName != null ||
      cachedPhone != null ||
      cachedPhotoUrl != null;

  /// Create a copy with updated cached data
  GroupMember withCachedData({
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

  GroupMember copyWith({
    String? userId,
    MemberRole? role,
    DateTime? joinedAt,
    String? cachedDisplayName,
    String? cachedPhone,
    String? cachedPhotoUrl,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      cachedDisplayName: cachedDisplayName ?? this.cachedDisplayName,
      cachedPhone: cachedPhone ?? this.cachedPhone,
      cachedPhotoUrl: cachedPhotoUrl ?? this.cachedPhotoUrl,
    );
  }

  @override
  List<Object?> get props => [userId, role, joinedAt];
}

/// Simplified debt between two users
class SimplifiedDebt extends Equatable {
  final String fromUserId;
  final String toUserId;
  final int amount; // in paisa

  // Cached display names (populated from UserCacheService)
  final String? cachedFromUserName;
  final String? cachedToUserName;

  const SimplifiedDebt({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.cachedFromUserName,
    this.cachedToUserName,
  });

  String get fromUserName => cachedFromUserName ?? 'Unknown';
  String get toUserName => cachedToUserName ?? 'Unknown';

  SimplifiedDebt withCachedNames({String? fromUserName, String? toUserName}) {
    return SimplifiedDebt(
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      cachedFromUserName: fromUserName,
      cachedToUserName: toUserName,
    );
  }

  @override
  List<Object?> get props => [fromUserId, toUserId, amount];
}

/// Group entity representing a bill-splitting group
class GroupEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final GroupType type;
  final List<GroupMember> members;
  final List<String> memberIds;
  final int memberCount;
  final String currency;
  final bool simplifyDebts;
  final String createdBy;
  final List<String> admins;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalExpenses; // in paisa
  final int expenseCount;
  final DateTime? lastActivityAt;
  final Map<String, int> balances; // userId -> balance in paisa
  final List<SimplifiedDebt>? simplifiedDebts;

  const GroupEntity({
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

  /// Get the group type icon
  String get typeIcon {
    switch (type) {
      case GroupType.trip:
        return '✈️';
      case GroupType.home:
        return '🏠';
      case GroupType.couple:
        return '💑';
      case GroupType.other:
        return '👥';
    }
  }

  /// Get the group type display name
  String get typeDisplayName {
    switch (type) {
      case GroupType.trip:
        return 'Trip';
      case GroupType.home:
        return 'Home';
      case GroupType.couple:
        return 'Couple';
      case GroupType.other:
        return 'Other';
    }
  }

  /// Check if a user is an admin
  bool isUserAdmin(String userId) => admins.contains(userId);

  /// Check if a user is the creator
  bool isUserCreator(String userId) => createdBy == userId;

  /// Check if a user is a member
  bool isUserMember(String userId) => memberIds.contains(userId);

  /// Get a member by user ID
  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get balance for a specific user
  int getBalanceForUser(String userId) => balances[userId] ?? 0;

  /// Check if user owes money (negative balance)
  bool doesUserOwe(String userId) => getBalanceForUser(userId) < 0;

  /// Check if user is owed money (positive balance)
  bool isUserOwed(String userId) => getBalanceForUser(userId) > 0;

  /// Check if user is settled up (zero balance)
  bool isUserSettled(String userId) => getBalanceForUser(userId) == 0;

  /// Get total amount this user owes in this group
  int getTotalOwedByUser(String userId) {
    final balance = getBalanceForUser(userId);
    return balance < 0 ? -balance : 0;
  }

  /// Get total amount owed to this user in this group
  int getTotalOwedToUser(String userId) {
    final balance = getBalanceForUser(userId);
    return balance > 0 ? balance : 0;
  }

  /// Create a copy with updated fields
  GroupEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    GroupType? type,
    List<GroupMember>? members,
    List<String>? memberIds,
    int? memberCount,
    String? currency,
    bool? simplifyDebts,
    String? createdBy,
    List<String>? admins,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalExpenses,
    int? expenseCount,
    DateTime? lastActivityAt,
    Map<String, int>? balances,
    List<SimplifiedDebt>? simplifiedDebts,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      currency: currency ?? this.currency,
      simplifyDebts: simplifyDebts ?? this.simplifyDebts,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expenseCount: expenseCount ?? this.expenseCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      balances: balances ?? this.balances,
      simplifiedDebts: simplifiedDebts ?? this.simplifiedDebts,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    memberIds,
    balances,
    totalExpenses,
    expenseCount,
  ];
}
