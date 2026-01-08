part of 'profile_bloc.dart';

/// Base class for profile events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Event to update user profile
class ProfileUpdateRequested extends ProfileEvent {
  final String? displayName;
  final String? phone;
  final String? defaultCurrency;
  final String? locale;
  final String? timezone;
  final String? countryCode;

  const ProfileUpdateRequested({
    this.displayName,
    this.phone,
    this.defaultCurrency,
    this.locale,
    this.timezone,
    this.countryCode,
  });

  @override
  List<Object?> get props => [
        displayName,
        phone,
        defaultCurrency,
        locale,
        timezone,
        countryCode,
      ];
}

/// Event to update profile photo
class ProfilePhotoUpdateRequested extends ProfileEvent {
  final File imageFile;

  const ProfilePhotoUpdateRequested({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

/// Event to delete profile photo
class ProfilePhotoDeleteRequested extends ProfileEvent {
  const ProfilePhotoDeleteRequested();
}

/// Event to change profile settings
class ProfileSettingsChanged extends ProfileEvent {
  final bool? notificationsEnabled;
  final bool? contactSyncEnabled;
  final bool? biometricAuthEnabled;

  const ProfileSettingsChanged({
    this.notificationsEnabled,
    this.contactSyncEnabled,
    this.biometricAuthEnabled,
  });

  @override
  List<Object?> get props => [
        notificationsEnabled,
        contactSyncEnabled,
        biometricAuthEnabled,
      ];
}