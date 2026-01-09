import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friend_entity.dart';

/// Friend model for Firestore - stores only UID as the primary identifier
///
/// Backend storage strategy:
/// - Only stores friendUserId (UID) to identify the friend
/// - Does NOT store denormalized user data (displayName, phone, photoUrl)
/// - User details are fetched via UserCacheService when needed
///
/// This ensures user profile updates are always reflected correctly
class FriendModel {
  final String id;
  final String userId;
  final String friendUserId;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int balance;
  final String currency;
  final FriendAddedVia addedVia;

  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.balance = 0,
    this.currency = 'INR',
    this.addedVia = FriendAddedVia.manual,
  });

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      id: doc.id,
      userId: data['userId'] as String,
      friendUserId: data['friendUserId'] as String,
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      balance: data['balance'] as int? ?? 0,
      currency: data['currency'] as String? ?? 'INR',
      addedVia: _addedViaFromString(data['addedVia'] as String? ?? 'manual'),
    );
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FriendModel(
      id: id ?? map['id'] as String,
      userId: map['userId'] as String,
      friendUserId: map['friendUserId'] as String,
      status: _statusFromString(map['status'] as String? ?? 'pending'),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
      balance: map['balance'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'INR',
      addedVia: _addedViaFromString(map['addedVia'] as String? ?? 'manual'),
    );
  }

  /// Convert to Firestore document (UID-only storage)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendUserId': friendUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'balance': balance,
      'currency': currency,
      'addedVia': _addedViaToString(addedVia),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendUserId': friendUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'balance': balance,
      'currency': currency,
      'addedVia': _addedViaToString(addedVia),
    };
  }

  /// Convert to entity (without cached data - will be populated separately)
  FriendEntity toEntity() {
    return FriendEntity(
      id: id,
      userId: userId,
      friendUserId: friendUserId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      balance: balance,
      currency: currency,
      addedVia: addedVia,
      // Cached data is NOT set here - populated via UserCacheService
    );
  }

  /// Convert to entity with cached user data
  FriendEntity toEntityWithCache({
    String? displayName,
    String? phone,
    String? photoUrl,
  }) {
    return FriendEntity(
      id: id,
      userId: userId,
      friendUserId: friendUserId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      balance: balance,
      currency: currency,
      addedVia: addedVia,
      cachedDisplayName: displayName,
      cachedPhone: phone,
      cachedPhotoUrl: photoUrl,
    );
  }

  factory FriendModel.fromEntity(FriendEntity entity) {
    return FriendModel(
      id: entity.id,
      userId: entity.userId,
      friendUserId: entity.friendUserId,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      balance: entity.balance,
      currency: entity.currency,
      addedVia: entity.addedVia,
    );
  }

  FriendModel copyWith({
    String? id,
    String? userId,
    String? friendUserId,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? balance,
    String? currency,
    FriendAddedVia? addedVia,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendUserId: friendUserId ?? this.friendUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      addedVia: addedVia ?? this.addedVia,
    );
  }

  static FriendStatus _statusFromString(String value) {
    return FriendStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FriendStatus.pending,
    );
  }

  static FriendAddedVia _addedViaFromString(String value) {
    switch (value) {
      case 'contact_sync':
      case 'contactSync':
        return FriendAddedVia.contactSync;
      case 'group':
        return FriendAddedVia.group;
      case 'invitation':
        return FriendAddedVia.invitation;
      case 'manual':
      default:
        return FriendAddedVia.manual;
    }
  }

  static String _addedViaToString(FriendAddedVia addedVia) {
    switch (addedVia) {
      case FriendAddedVia.contactSync:
        return 'contact_sync';
      case FriendAddedVia.group:
        return 'group';
      case FriendAddedVia.invitation:
        return 'invitation';
      case FriendAddedVia.manual:
        return 'manual';
    }
  }
}

/// Registered user model for Firestore search results
/// Used when searching for users by phone to add as friends
class RegisteredUserModel {
  final String id;
  final String displayName;
  final String phone;
  final String? photoUrl;

  const RegisteredUserModel({
    required this.id,
    required this.displayName,
    required this.phone,
    this.photoUrl,
  });

  factory RegisteredUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegisteredUserModel(
      id: doc.id,
      displayName:
          data['displayName'] as String? ??
          data['name'] as String? ??
          'Unknown',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  factory RegisteredUserModel.fromMap(Map<String, dynamic> map) {
    return RegisteredUserModel(
      id: map['id'] as String,
      displayName:
          map['displayName'] as String? ?? map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  RegisteredUser toEntity() {
    return RegisteredUser(
      id: id,
      displayName: displayName,
      phone: phone,
      photoUrl: photoUrl,
    );
  }

  factory RegisteredUserModel.fromEntity(RegisteredUser entity) {
    return RegisteredUserModel(
      id: entity.id,
      displayName: entity.displayName,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
    );
  }
}
