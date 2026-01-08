import 'package:equatable/equatable.dart';

/// User entity representing authenticated user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final String defaultCurrency;
  final String locale;
  final String timezone;
  final bool notificationsEnabled;
  final bool biometricAuthEnabled;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.defaultCurrency = 'INR',
    this.locale = 'en-IN',
    this.timezone = 'Asia/Kolkata',
    this.notificationsEnabled = true,
    this.biometricAuthEnabled = false,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Check if user has completed profile setup
  bool get hasCompletedProfile => displayName != null && displayName!.isNotEmpty;

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
        biometricAuthEnabled,
        createdAt,
        lastActiveAt,
      ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}