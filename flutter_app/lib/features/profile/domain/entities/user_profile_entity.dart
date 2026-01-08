import 'package:equatable/equatable.dart';

/// User profile entity with complete profile information
class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
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
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
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

  /// Get display name or email prefix
  String get displayNameOrEmail => displayName ?? email.split('@').first;

  /// Get user initials for avatar
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

  /// Net balance (positive = owed to user, negative = user owes)
  int get netBalance => totalOwed - totalOwing;

  /// Check if user is settled up
  bool get isSettledUp => netBalance == 0;

  /// Copy with new values
  UserProfileEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
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
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
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
        email,
        displayName,
        photoUrl,
        phone,
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