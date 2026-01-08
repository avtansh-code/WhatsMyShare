import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile_entity.dart';

/// User profile model for Firestore serialization
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.phone,
    super.defaultCurrency,
    super.locale,
    super.timezone,
    super.notificationsEnabled,
    super.contactSyncEnabled,
    super.biometricAuthEnabled,
    super.totalOwed,
    super.totalOwing,
    super.groupCount,
    super.countryCode,
    required super.createdAt,
    required super.updatedAt,
    super.lastActiveAt,
  });

  /// Create from Firestore document
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String?,
      defaultCurrency: data['defaultCurrency'] as String? ?? 'INR',
      locale: data['locale'] as String? ?? 'en-IN',
      timezone: data['timezone'] as String? ?? 'Asia/Kolkata',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      contactSyncEnabled: data['contactSyncEnabled'] as bool? ?? false,
      biometricAuthEnabled: data['biometricAuthEnabled'] as bool? ?? false,
      totalOwed: data['totalOwed'] as int? ?? 0,
      totalOwing: data['totalOwing'] as int? ?? 0,
      groupCount: data['groupCount'] as int? ?? 0,
      countryCode: data['countryCode'] as String? ?? 'IN',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      phone: entity.phone,
      defaultCurrency: entity.defaultCurrency,
      locale: entity.locale,
      timezone: entity.timezone,
      notificationsEnabled: entity.notificationsEnabled,
      contactSyncEnabled: entity.contactSyncEnabled,
      biometricAuthEnabled: entity.biometricAuthEnabled,
      totalOwed: entity.totalOwed,
      totalOwing: entity.totalOwing,
      groupCount: entity.groupCount,
      countryCode: entity.countryCode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'defaultCurrency': defaultCurrency,
      'locale': locale,
      'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      'contactSyncEnabled': contactSyncEnabled,
      'biometricAuthEnabled': biometricAuthEnabled,
      'totalOwed': totalOwed,
      'totalOwing': totalOwing,
      'groupCount': groupCount,
      'countryCode': countryCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
    };
  }

  /// Create document for new user profile
  Map<String, dynamic> toCreateFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'defaultCurrency': defaultCurrency,
      'locale': locale,
      'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      'contactSyncEnabled': contactSyncEnabled,
      'biometricAuthEnabled': biometricAuthEnabled,
      'totalOwed': 0,
      'totalOwing': 0,
      'groupCount': 0,
      'countryCode': countryCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'fcmTokens': <String>[],
    };
  }

  /// Convert to entity
  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      phone: phone,
      defaultCurrency: defaultCurrency,
      locale: locale,
      timezone: timezone,
      notificationsEnabled: notificationsEnabled,
      contactSyncEnabled: contactSyncEnabled,
      biometricAuthEnabled: biometricAuthEnabled,
      totalOwed: totalOwed,
      totalOwing: totalOwing,
      groupCount: groupCount,
      countryCode: countryCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
    );
  }
}
