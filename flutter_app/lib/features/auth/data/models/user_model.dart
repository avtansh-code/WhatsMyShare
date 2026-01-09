import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

/// User model for data layer - handles Firestore serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.phone,
    super.displayName,
    super.photoUrl,
    super.isPhoneVerified,
    super.isEmailVerified,
    super.defaultCurrency,
    super.locale,
    super.timezone,
    super.notificationsEnabled,
    super.contactSyncEnabled,
    super.biometricAuthEnabled,
    super.createdAt,
    super.updatedAt,
    super.lastActiveAt,
    super.totalOwed,
    super.totalOwing,
    super.groupCount,
    super.countryCode,
    super.fcmTokens,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: (data['email'] as String?) ?? '',
      phone: data['phone'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      defaultCurrency: data['defaultCurrency'] as String? ?? 'INR',
      locale: data['locale'] as String? ?? 'en-IN',
      timezone: data['timezone'] as String? ?? 'Asia/Kolkata',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      contactSyncEnabled: data['contactSyncEnabled'] as bool? ?? false,
      biometricAuthEnabled: data['biometricAuthEnabled'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      totalOwed: data['totalOwed'] as int? ?? 0,
      totalOwing: data['totalOwing'] as int? ?? 0,
      groupCount: data['groupCount'] as int? ?? 0,
      countryCode: data['countryCode'] as String? ?? 'IN',
      fcmTokens:
          (data['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Create UserModel from a Map (for local storage)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      phone: map['phone'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      defaultCurrency: map['defaultCurrency'] as String? ?? 'INR',
      locale: map['locale'] as String? ?? 'en-IN',
      timezone: map['timezone'] as String? ?? 'Asia/Kolkata',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      contactSyncEnabled: map['contactSyncEnabled'] as bool? ?? false,
      biometricAuthEnabled: map['biometricAuthEnabled'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.parse(map['lastActiveAt'] as String)
          : null,
      totalOwed: map['totalOwed'] as int? ?? 0,
      totalOwing: map['totalOwing'] as int? ?? 0,
      groupCount: map['groupCount'] as int? ?? 0,
      countryCode: map['countryCode'] as String? ?? 'IN',
      fcmTokens:
          (map['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Create UserModel from UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      phone: entity.phone,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isPhoneVerified: entity.isPhoneVerified,
      isEmailVerified: entity.isEmailVerified,
      defaultCurrency: entity.defaultCurrency,
      locale: entity.locale,
      timezone: entity.timezone,
      notificationsEnabled: entity.notificationsEnabled,
      contactSyncEnabled: entity.contactSyncEnabled,
      biometricAuthEnabled: entity.biometricAuthEnabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
      totalOwed: entity.totalOwed,
      totalOwing: entity.totalOwing,
      groupCount: entity.groupCount,
      countryCode: entity.countryCode,
      fcmTokens: entity.fcmTokens,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'defaultCurrency': defaultCurrency,
      'locale': locale,
      'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      'contactSyncEnabled': contactSyncEnabled,
      'biometricAuthEnabled': biometricAuthEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'totalOwed': totalOwed,
      'totalOwing': totalOwing,
      'groupCount': groupCount,
      'countryCode': countryCode,
      'fcmTokens': fcmTokens,
    };
  }

  /// Convert to Firestore document data for new user creation
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPhoneVerified': false,
      'isEmailVerified': false,
      'defaultCurrency': defaultCurrency,
      'locale': locale,
      'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      'contactSyncEnabled': contactSyncEnabled,
      'biometricAuthEnabled': biometricAuthEnabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'totalOwed': 0,
      'totalOwing': 0,
      'groupCount': 0,
      'countryCode': countryCode,
      'fcmTokens': fcmTokens,
    };
  }

  /// Convert to Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'defaultCurrency': defaultCurrency,
      'locale': locale,
      'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      'contactSyncEnabled': contactSyncEnabled,
      'biometricAuthEnabled': biometricAuthEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'totalOwed': totalOwed,
      'totalOwing': totalOwing,
      'groupCount': groupCount,
      'countryCode': countryCode,
      'fcmTokens': fcmTokens,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWithModel({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? contactSyncEnabled,
    bool? biometricAuthEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    int? totalOwed,
    int? totalOwing,
    int? groupCount,
    String? countryCode,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      contactSyncEnabled: contactSyncEnabled ?? this.contactSyncEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalOwed: totalOwed ?? this.totalOwed,
      totalOwing: totalOwing ?? this.totalOwing,
      groupCount: groupCount ?? this.groupCount,
      countryCode: countryCode ?? this.countryCode,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
