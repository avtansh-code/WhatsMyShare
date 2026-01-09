import 'package:equatable/equatable.dart';

/// User entity representing authenticated user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String defaultCurrency;
  final String locale;
  final String timezone;
  final bool notificationsEnabled;
  final bool contactSyncEnabled;
  final bool biometricAuthEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;
  final int totalOwed;
  final int totalOwing;
  final int groupCount;
  final String countryCode;
  final List<String> fcmTokens;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.defaultCurrency = 'INR',
    this.locale = 'en-IN',
    this.timezone = 'Asia/Kolkata',
    this.notificationsEnabled = true,
    this.contactSyncEnabled = false,
    this.biometricAuthEnabled = false,
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
    this.totalOwed = 0,
    this.totalOwing = 0,
    this.groupCount = 0,
    this.countryCode = 'IN',
    this.fcmTokens = const [],
  });

  /// Check if user has completed profile setup (must have name, email, and phone)
  bool get hasCompletedProfile =>
      displayName != null && 
      displayName!.isNotEmpty &&
      email.isNotEmpty &&
      phone != null && 
      phone!.isNotEmpty &&
      isPhoneVerified;

  /// Check if profile is partially complete (has name but missing phone)
  bool get needsPhoneVerification =>
      displayName != null && 
      displayName!.isNotEmpty &&
      (phone == null || phone!.isEmpty || !isPhoneVerified);

  /// Get display name or email as fallback
  String get displayNameOrEmail => displayName ?? email.split('@').first;

  /// Get initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Get net balance (positive = owed to user, negative = user owes)
  int get netBalance => totalOwed - totalOwing;

  /// Check if user has any outstanding balances
  bool get hasOutstandingBalance => totalOwed != 0 || totalOwing != 0;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    phone,
    isPhoneVerified,
    isEmailVerified,
    defaultCurrency,
    locale,
    timezone,
    notificationsEnabled,
    contactSyncEnabled,
    biometricAuthEnabled,
    createdAt,
    updatedAt,
    lastActiveAt,
    totalOwed,
    totalOwing,
    groupCount,
    countryCode,
    fcmTokens,
  ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
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
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
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
