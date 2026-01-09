import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC for user profile management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserProfileRepository _repository;
  final LoggingService _log = LoggingService();

  ProfileBloc({required UserProfileRepository repository})
    : _repository = repository,
      super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfilePhotoUpdateRequested>(_onPhotoUpdateRequested);
    on<ProfilePhotoDeleteRequested>(_onPhotoDeleteRequested);
    on<ProfileSettingsChanged>(_onSettingsChanged);

    _log.info('ProfileBloc initialized', tag: LogTags.profile);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    _log.debug('Loading user profile...', tag: LogTags.profile);
    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await _repository.getCurrentUserProfile();

    result.fold(
      (failure) {
        _log.error(
          'Failed to load profile',
          tag: LogTags.profile,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(
            status: ProfileStatus.error,
            errorMessage: ErrorMessages.profileLoadFailed,
          ),
        );
      },
      (profile) {
        _log.info(
          'Profile loaded successfully',
          tag: LogTags.profile,
          data: {'userId': profile.id, 'displayName': profile.displayName},
        );
        emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
      },
    );
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) {
      _log.warning(
        'Attempted to update profile but no profile loaded',
        tag: LogTags.profile,
      );
      return;
    }

    _log.info(
      'Updating profile',
      tag: LogTags.profile,
      data: {'userId': state.profile!.id, 'displayName': event.displayName},
    );
    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await _repository.updateUserProfile(
      userId: state.profile!.id,
      displayName: event.displayName,
      phone: event.phone,
      defaultCurrency: event.defaultCurrency,
      locale: event.locale,
      timezone: event.timezone,
      countryCode: event.countryCode,
    );

    result.fold(
      (failure) {
        _log.error(
          'Failed to update profile',
          tag: LogTags.profile,
          data: {'userId': state.profile!.id, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: ProfileStatus.error,
            errorMessage: ErrorMessages.profileUpdateFailed,
          ),
        );
      },
      (profile) {
        _log.info('Profile updated successfully', tag: LogTags.profile);
        emit(state.copyWith(status: ProfileStatus.updated, profile: profile));
      },
    );
  }

  Future<void> _onPhotoUpdateRequested(
    ProfilePhotoUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) {
      _log.warning(
        'Attempted to update photo but no profile loaded',
        tag: LogTags.profile,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profile not loaded. Please try again.',
        ),
      );
      return;
    }

    // Log detailed file info
    final imageFile = event.imageFile;
    bool fileExists = false;
    int fileSize = 0;
    
    try {
      fileExists = await imageFile.exists();
      if (fileExists) {
        fileSize = await imageFile.length();
      }
    } catch (e) {
      _log.error(
        'Error checking image file',
        tag: LogTags.profile,
        data: {'error': e.toString()},
      );
    }

    _log.info(
      'Starting profile photo upload',
      tag: LogTags.profile,
      data: {
        'userId': state.profile!.id,
        'filePath': imageFile.path,
        'fileExists': fileExists,
        'fileSizeBytes': fileSize,
        'fileSizeMB': (fileSize / (1024 * 1024)).toStringAsFixed(2),
      },
    );

    if (!fileExists) {
      _log.error(
        'Image file does not exist',
        tag: LogTags.profile,
        data: {'path': imageFile.path},
      );
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Image file not found. Please select again.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProfileStatus.uploadingPhoto));
    _log.debug(
      'Emitted uploadingPhoto status, calling repository',
      tag: LogTags.profile,
    );

    final result = await _repository.updateProfilePhoto(
      userId: state.profile!.id,
      imageFile: event.imageFile,
    );

    result.fold(
      (failure) {
        _log.error(
          'Profile photo upload failed',
          tag: LogTags.profile,
          data: {
            'userId': state.profile!.id,
            'errorType': failure.runtimeType.toString(),
            'errorMessage': failure.message,
          },
        );
        emit(
          state.copyWith(
            status: ProfileStatus.error,
            errorMessage: failure.message.isNotEmpty 
                ? failure.message 
                : ErrorMessages.profilePhotoUploadFailed,
          ),
        );
      },
      (photoUrl) {
        _log.info(
          'Profile photo uploaded successfully',
          tag: LogTags.profile,
          data: {
            'userId': state.profile!.id,
            'photoUrl': photoUrl,
          },
        );
        final updatedProfile = state.profile!.copyWith(photoUrl: photoUrl);
        emit(
          state.copyWith(
            status: ProfileStatus.photoUpdated,
            profile: updatedProfile,
          ),
        );
      },
    );
  }

  Future<void> _onPhotoDeleteRequested(
    ProfilePhotoDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) {
      _log.warning(
        'Attempted to delete photo but no profile loaded',
        tag: LogTags.profile,
      );
      return;
    }

    _log.info(
      'Deleting profile photo',
      tag: LogTags.profile,
      data: {'userId': state.profile!.id},
    );
    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await _repository.deleteProfilePhoto(state.profile!.id);

    result.fold(
      (failure) {
        _log.error(
          'Failed to delete profile photo',
          tag: LogTags.profile,
          data: {'userId': state.profile!.id, 'error': failure.message},
        );
        emit(
          state.copyWith(
            status: ProfileStatus.error,
            errorMessage: ErrorMessages.storageDeleteFailed,
          ),
        );
      },
      (_) {
        _log.info('Profile photo deleted successfully', tag: LogTags.profile);
        final updatedProfile = UserProfileEntity(
          id: state.profile!.id,
          email: state.profile!.email,
          displayName: state.profile!.displayName,
          photoUrl: null,
          phone: state.profile!.phone,
          defaultCurrency: state.profile!.defaultCurrency,
          locale: state.profile!.locale,
          timezone: state.profile!.timezone,
          notificationsEnabled: state.profile!.notificationsEnabled,
          contactSyncEnabled: state.profile!.contactSyncEnabled,
          biometricAuthEnabled: state.profile!.biometricAuthEnabled,
          totalOwed: state.profile!.totalOwed,
          totalOwing: state.profile!.totalOwing,
          groupCount: state.profile!.groupCount,
          countryCode: state.profile!.countryCode,
          createdAt: state.profile!.createdAt,
          updatedAt: DateTime.now(),
          lastActiveAt: state.profile!.lastActiveAt,
        );
        emit(
          state.copyWith(
            status: ProfileStatus.updated,
            profile: updatedProfile,
          ),
        );
      },
    );
  }

  Future<void> _onSettingsChanged(
    ProfileSettingsChanged event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) {
      _log.warning(
        'Attempted to change settings but no profile loaded',
        tag: LogTags.profile,
      );
      return;
    }

    _log.info(
      'Updating profile settings',
      tag: LogTags.profile,
      data: {
        'userId': state.profile!.id,
        'notifications': event.notificationsEnabled,
        'contactSync': event.contactSyncEnabled,
        'biometric': event.biometricAuthEnabled,
      },
    );
    emit(state.copyWith(status: ProfileStatus.updating));

    final userId = state.profile!.id;

    if (event.notificationsEnabled != null) {
      final result = await _repository.updateNotificationSettings(
        userId: userId,
        enabled: event.notificationsEnabled!,
      );
      result.fold(
        (failure) => _log.warning(
          'Failed to update notification settings',
          tag: LogTags.profile,
          data: {'error': failure.message},
        ),
        (_) =>
            _log.debug('Notification settings updated', tag: LogTags.profile),
      );
    }

    if (event.contactSyncEnabled != null) {
      final result = await _repository.updateContactSyncSettings(
        userId: userId,
        enabled: event.contactSyncEnabled!,
      );
      result.fold(
        (failure) => _log.warning(
          'Failed to update contact sync settings',
          tag: LogTags.profile,
          data: {'error': failure.message},
        ),
        (_) =>
            _log.debug('Contact sync settings updated', tag: LogTags.profile),
      );
    }

    if (event.biometricAuthEnabled != null) {
      final result = await _repository.updateBiometricAuthSettings(
        userId: userId,
        enabled: event.biometricAuthEnabled!,
      );
      result.fold(
        (failure) => _log.warning(
          'Failed to update biometric auth settings',
          tag: LogTags.profile,
          data: {'error': failure.message},
        ),
        (_) =>
            _log.debug('Biometric auth settings updated', tag: LogTags.profile),
      );
    }

    // Reload profile to get updated data
    final result = await _repository.getCurrentUserProfile();

    result.fold(
      (failure) {
        _log.error(
          'Failed to reload profile after settings change',
          tag: LogTags.profile,
          data: {'error': failure.message},
        );
        emit(
          state.copyWith(
            status: ProfileStatus.error,
            errorMessage: ErrorMessages.profileLoadFailed,
          ),
        );
      },
      (profile) {
        _log.info(
          'Profile settings updated successfully',
          tag: LogTags.profile,
        );
        emit(state.copyWith(status: ProfileStatus.updated, profile: profile));
      },
    );
  }
}
