import 'package:equatable/equatable.dart';

/// User profile entity with complete profile information
/// Phone number is the primary identifier (phone-only authentication)
class UserProfileEntity extends Equatable {
  final String id;
  final String phone; // Required - primary identifier
  final String? displayName;
  final String? photoUrl;
  final String defaultCurrency;
  final String locale;
  final String timezone;
  final bool notificationsEnabled;
  final bool contactSyncEnabled;
  final bool biometricAuthEnabled;
  final int totalOwed; // Amount owed to this user (in paisa)
  final int totalOwing; // Amount this user owes (in paisa)
  final int groupCount;
  final String countryCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;

  const UserProfileEntity({
    required this.id,
    required this.phone,
    this.displayName,
    this.photoUrl,
    this.defaultCurrency = 'INR',
    this.locale = 'en-IN',
    this.timezone = 'Asia/Kolkata',
    this.notificationsEnabled = true,
    this.contactSyncEnabled = false,
    this.biometricAuthEnabled = false,
    this.totalOwed = 0,
    this.totalOwing = 0,
    this.groupCount = 0,
    this.countryCode = 'IN',
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  /// Get display name or phone suffix for display
  String get displayNameOrPhone {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    // Show last 4 digits of phone
    if (phone.length >= 4) {
      return '****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  /// Get user initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    // Use last 2 digits of phone as fallback
    if (phone.length >= 2) {
      return phone.substring(phone.length - 2);
    }
    return '??';
  }

  /// Net balance (positive = owed to user, negative = user owes)
  int get netBalance => totalOwed - totalOwing;

  /// Check if user is settled up
  bool get isSettledUp => netBalance == 0;

  /// Copy with new values
  UserProfileEntity copyWith({
    String? id,
    String? phone,
    String? displayName,
    String? photoUrl,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? contactSyncEnabled,
    bool? biometricAuthEnabled,
    int? totalOwed,
    int? totalOwing,
    int? groupCount,
    String? countryCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      contactSyncEnabled: contactSyncEnabled ?? this.contactSyncEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      totalOwed: totalOwed ?? this.totalOwed,
      totalOwing: totalOwing ?? this.totalOwing,
      groupCount: groupCount ?? this.groupCount,
      countryCode: countryCode ?? this.countryCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    displayName,
    photoUrl,
    defaultCurrency,
    locale,
    timezone,
    notificationsEnabled,
    contactSyncEnabled,
    biometricAuthEnabled,
    totalOwed,
    totalOwing,
    groupCount,
    countryCode,
    createdAt,
    updatedAt,
    lastActiveAt,
  ];
}
