import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// User entity representing authenticated user
/// Authentication is ONLY via phone number
/// India-only app - currency, timezone, locale are hardcoded
class UserEntity extends Equatable {
  final String id;
  final String? displayName;
  final String? photoUrl;
  final String phone;
  final bool isPhoneVerified;
  final bool notificationsEnabled;
  final bool contactSyncEnabled;
  final bool biometricAuthEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;
  final int totalOwed;
  final int totalOwing;
  final int groupCount;
  final List<String> fcmTokens;

  const UserEntity({
    required this.id,
    required this.phone,
    this.displayName,
    this.photoUrl,
    this.isPhoneVerified = false,
    this.notificationsEnabled = true,
    this.contactSyncEnabled = false,
    this.biometricAuthEnabled = false,
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
    this.totalOwed = 0,
    this.totalOwing = 0,
    this.groupCount = 0,
    this.fcmTokens = const [],
  });

  /// Currency is always INR (India-only app)
  String get currency => AppConstants.currency;

  /// Locale is always en_IN (India-only app)
  String get locale => AppConstants.locale;

  /// Timezone is always Asia/Kolkata (India-only app)
  String get timezone => AppConstants.timezone;

  /// Country code is always +91 (India-only app)
  String get countryCode => AppConstants.countryCode;

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
    notificationsEnabled,
    contactSyncEnabled,
    biometricAuthEnabled,
    createdAt,
    updatedAt,
    lastActiveAt,
    totalOwed,
    totalOwing,
    groupCount,
    fcmTokens,
  ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isPhoneVerified,
    bool? notificationsEnabled,
    bool? contactSyncEnabled,
    bool? biometricAuthEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    int? totalOwed,
    int? totalOwing,
    int? groupCount,
    List<String>? fcmTokens,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      contactSyncEnabled: contactSyncEnabled ?? this.contactSyncEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalOwed: totalOwed ?? this.totalOwed,
      totalOwing: totalOwing ?? this.totalOwing,
      groupCount: groupCount ?? this.groupCount,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
