import 'package:equatable/equatable.dart';

/// Status of a friend relationship
enum FriendStatus {
  pending,    // Friend request sent, waiting for acceptance
  accepted,   // Both users have accepted friendship
  blocked,    // User blocked this friend
}

/// Friend entity - represents a friendship between two REGISTERED users
/// Both the user and friend must be registered in the app
class FriendEntity extends Equatable {
  /// Unique friend relationship ID
  final String id;

  /// The user who owns this friend list entry (the requester)
  final String userId;

  /// The friend's user ID - MUST be a registered user ID
  final String friendUserId;

  /// Display name of the friend (from their profile)
  final String displayName;

  /// Email of the friend (from their profile)
  final String email;

  /// Phone number of the friend (optional, from their profile)
  final String? phone;

  /// Profile photo URL of the friend
  final String? photoUrl;

  /// Current status of the friendship
  final FriendStatus status;

  /// When the friendship was created
  final DateTime createdAt;

  /// When the friendship was last updated
  final DateTime updatedAt;

  const FriendEntity({
    required this.id,
    required this.userId,
    required this.friendUserId,
    required this.displayName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if the friend relationship is active (accepted)
  bool get isActive => status == FriendStatus.accepted;

  /// Check if the friend relationship is pending
  bool get isPending => status == FriendStatus.pending;

  /// Check if the friend is blocked
  bool get isBlocked => status == FriendStatus.blocked;

  FriendEntity copyWith({
    String? id,
    String? userId,
    String? friendUserId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendUserId: friendUserId ?? this.friendUserId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        friendUserId,
        displayName,
        email,
        phone,
        photoUrl,
        status,
        createdAt,
        updatedAt,
      ];
}

/// A registered user who can be added as a friend or to an expense
/// This ensures all participants in expenses are registered users
class RegisteredUser extends Equatable {
  /// The user's unique ID in Firebase Auth
  final String id;

  /// The user's display name
  final String displayName;

  /// The user's email (always present for registered users)
  final String email;

  /// The user's phone number (optional)
  final String? phone;

  /// The user's profile photo URL
  final String? photoUrl;

  const RegisteredUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, displayName, email, phone, photoUrl];
}

/// Extension to convert FriendEntity to RegisteredUser for expense splits
extension FriendToUser on FriendEntity {
  RegisteredUser toRegisteredUser() {
    return RegisteredUser(
      id: friendUserId,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}