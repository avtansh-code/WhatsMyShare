import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friend_entity.dart';

/// Friend model for Firestore - only stores registered users
class FriendModel {
  final String id;
  final String userId;
  final String friendUserId;
  final String displayName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendModel({
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

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      id: doc.id,
      userId: data['userId'] as String,
      friendUserId: data['friendUserId'] as String,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FriendModel(
      id: id ?? map['id'] as String,
      userId: map['userId'] as String,
      friendUserId: map['friendUserId'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      status: _statusFromString(map['status'] as String? ?? 'pending'),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendUserId': friendUserId,
      'displayName': displayName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendUserId': friendUserId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FriendEntity toEntity() {
    return FriendEntity(
      id: id,
      userId: userId,
      friendUserId: friendUserId,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FriendModel.fromEntity(FriendEntity entity) {
    return FriendModel(
      id: entity.id,
      userId: entity.userId,
      friendUserId: entity.friendUserId,
      displayName: entity.displayName,
      email: entity.email,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  FriendModel copyWith({
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
    return FriendModel(
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

  static FriendStatus _statusFromString(String value) {
    return FriendStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FriendStatus.pending,
    );
  }
}

/// Registered user model for Firestore search results
class RegisteredUserModel {
  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final String? photoUrl;

  const RegisteredUserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    this.photoUrl,
  });

  factory RegisteredUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegisteredUserModel(
      id: doc.id,
      displayName: data['displayName'] as String? ?? data['name'] as String? ?? 'Unknown',
      email: data['email'] as String,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  factory RegisteredUserModel.fromMap(Map<String, dynamic> map) {
    return RegisteredUserModel(
      id: map['id'] as String,
      displayName: map['displayName'] as String? ?? map['name'] as String? ?? 'Unknown',
      email: map['email'] as String,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  RegisteredUser toEntity() {
    return RegisteredUser(
      id: id,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }

  factory RegisteredUserModel.fromEntity(RegisteredUser entity) {
    return RegisteredUserModel(
      id: entity.id,
      displayName: entity.displayName,
      email: entity.email,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
    );
  }
}