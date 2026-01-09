import 'package:equatable/equatable.dart';

/// User entity representing authenticated user
/// Authentication is ONLY via phone number
class UserEntity extends Equatable {
  final String id;
  final String? displayName;
  final String? photoUrl;
  final String phone;
  final bool isPhoneVerified;
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
    required this.phone,
    this.displayName,
    this.photoUrl,
    this.isPhoneVerified = false,
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

  /// Check if user has completed profile setup (must have name and verified phone)
  bool get hasCompletedProfile =>
      displayName != null &&
      displayName!.isNotEmpty &&
      phone.isNotEmpty &&
      isPhoneVerified;

  /// Check if profile needs name to be set
  bool get needsProfileCompletion =>
      displayName == null || displayName!.isEmpty;

  /// Get display name or phone as fallback
  String get displayNameOrPhone => displayName ?? _formatPhone(phone);

  /// Format phone number for display
  String _formatPhone(String phone) {
    if (phone.length >= 10) {
      // Show last 4 digits
      return '****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  /// Get initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    // Use phone number last 2 digits as fallback
    if (phone.length >= 2) {
      return phone.substring(phone.length - 2);
    }
    return '?';
  }

  /// Get net balance (positive = owed to user, negative = user owes)
  int get netBalance => totalOwed - totalOwing;

  /// Check if user has any outstanding balances
  bool get hasOutstandingBalance => totalOwed != 0 || totalOwing != 0;

  @override
  List<Object?> get props => [
    id,
    displayName,
    photoUrl,
    phone,
    isPhoneVerified,
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
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isPhoneVerified,
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
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
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
