import 'package:equatable/equatable.dart';

/// Status of a friend relationship
enum FriendStatus {
  pending, // Friend request sent, waiting for acceptance
  accepted, // Both users have accepted friendship
  blocked, // User blocked this friend
}

/// Friend entity - represents a friendship between two REGISTERED users
///
/// Backend storage: Only stores friendUserId (UID) as the identifier
/// Display properties (displayName, phone, photoUrl) are resolved from the
/// UserCacheService using the friendUserId
///
/// This approach ensures:
/// 1. No data staleness when friend updates their profile
/// 2. Reduced storage duplication
/// 3. Single source of truth for user data
class FriendEntity extends Equatable {
  /// Unique friend relationship ID
  final String id;

  /// The user who owns this friend list entry (the requester)
  final String userId;

  /// The friend's user ID - MUST be a registered user ID
  /// This is the PRIMARY identifier used to look up friend details
  final String friendUserId;

  /// Current status of the friendship
  final FriendStatus status;

  /// When the friendship was created
  final DateTime createdAt;

  /// When the friendship was last updated
  final DateTime updatedAt;

  /// Balance with this friend (positive = friend owes you, negative = you owe friend)
  /// Stored in paisa (smallest currency unit)
  final int balance;

  /// Currency for the balance
  final String currency;

  /// How the friend was added
  final FriendAddedVia addedVia;

  // ============================================
  // CACHED DISPLAY PROPERTIES (populated from UserCacheService)
  // These are NOT stored in the backend, only used for UI display
  // ============================================

  /// Display name of the friend (cached from user profile)
  final String? cachedDisplayName;

  /// Phone number of the friend (cached from user profile)
  final String? cachedPhone;

  /// Profile photo URL of the friend (cached from user profile)
  final String? cachedPhotoUrl;

  const FriendEntity({
    required this.id,
    required this.userId,
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.balance = 0,
    this.currency = 'INR',
    this.addedVia = FriendAddedVia.manual,
    // Cached display properties
    this.cachedDisplayName,
    this.cachedPhone,
    this.cachedPhotoUrl,
  });

  /// Check if the friend relationship is active (accepted)
  bool get isActive => status == FriendStatus.accepted;

  /// Check if the friend relationship is pending
  bool get isPending => status == FriendStatus.pending;

  /// Check if the friend is blocked
  bool get isBlocked => status == FriendStatus.blocked;

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
  String get phone => cachedPhone ?? '';

  /// Get photo URL
  String? get photoUrl => cachedPhotoUrl;

  /// Get masked phone for display (show last 4 digits)
  String get maskedPhone {
    final p = cachedPhone ?? '';
    if (p.length >= 4) {
      return '****${p.substring(p.length - 4)}';
    }
    return p;
  }

  /// Get user initials for avatar
  String get initials {
    if (cachedDisplayName != null && cachedDisplayName!.isNotEmpty) {
      final parts = cachedDisplayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return cachedDisplayName![0].toUpperCase();
    }
    if (cachedPhone != null && cachedPhone!.length >= 2) {
      return cachedPhone!.substring(cachedPhone!.length - 2);
    }
    return '??';
  }

  /// Check if cache is populated
  bool get hasCachedData =>
      cachedDisplayName != null ||
      cachedPhone != null ||
      cachedPhotoUrl != null;

  FriendEntity copyWith({
    String? id,
    String? userId,
    String? friendUserId,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? balance,
    String? currency,
    FriendAddedVia? addedVia,
    String? cachedDisplayName,
    String? cachedPhone,
    String? cachedPhotoUrl,
  }) {
    return FriendEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendUserId: friendUserId ?? this.friendUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      addedVia: addedVia ?? this.addedVia,
      cachedDisplayName: cachedDisplayName ?? this.cachedDisplayName,
      cachedPhone: cachedPhone ?? this.cachedPhone,
      cachedPhotoUrl: cachedPhotoUrl ?? this.cachedPhotoUrl,
    );
  }

  /// Create a copy with updated cached data
  FriendEntity withCachedData({
    String? displayName,
    String? phone,
    String? photoUrl,
  }) {
    return copyWith(
      cachedDisplayName: displayName,
      cachedPhone: phone,
      cachedPhotoUrl: photoUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    friendUserId,
    status,
    createdAt,
    updatedAt,
    balance,
    currency,
    addedVia,
  ];
}

/// How the friend was added
enum FriendAddedVia { contactSync, manual, group, invitation }

/// A registered user who can be added as a friend or to an expense
/// This ensures all participants in expenses are registered users
/// User UID is the primary identifier
class RegisteredUser extends Equatable {
  /// The user's unique ID in Firebase Auth (primary identifier)
  final String id;

  /// The user's display name (cached from user profile)
  final String displayName;

  /// The user's phone number (cached from user profile)
  final String phone;

  /// The user's profile photo URL (cached from user profile)
  final String? photoUrl;

  const RegisteredUser({
    required this.id,
    required this.displayName,
    required this.phone,
    this.photoUrl,
  });

  /// Get masked phone for display (show last 4 digits)
  String get maskedPhone {
    if (phone.length >= 4) {
      return '****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  /// Get user initials for avatar
  String get initials {
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    if (phone.length >= 2) {
      return phone.substring(phone.length - 2);
    }
    return '??';
  }

  @override
  List<Object?> get props => [id, displayName, phone, photoUrl];
}

/// Extension to convert FriendEntity to RegisteredUser for expense splits
extension FriendToUser on FriendEntity {
  RegisteredUser toRegisteredUser() {
    return RegisteredUser(
      id: friendUserId,
      displayName: displayName,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}
