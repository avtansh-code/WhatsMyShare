import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC for user profile management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserProfileRepository _repository;

  ProfileBloc({required UserProfileRepository repository})
    : _repository = repository,
      super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfilePhotoUpdateRequested>(_onPhotoUpdateRequested);
    on<ProfilePhotoDeleteRequested>(_onPhotoDeleteRequested);
    on<ProfileSettingsChanged>(_onSettingsChanged);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await _repository.getCurrentUserProfile();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (profile) =>
          emit(state.copyWith(status: ProfileStatus.loaded, profile: profile)),
    );
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) return;

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
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (profile) =>
          emit(state.copyWith(status: ProfileStatus.updated, profile: profile)),
    );
  }

  Future<void> _onPhotoUpdateRequested(
    ProfilePhotoUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.profile == null) return;

    emit(state.copyWith(status: ProfileStatus.uploadingPhoto));

    final result = await _repository.updateProfilePhoto(
      userId: state.profile!.id,
      imageFile: event.imageFile,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (photoUrl) {
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
    if (state.profile == null) return;

    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await _repository.deleteProfilePhoto(state.profile!.id);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) {
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
    if (state.profile == null) return;

    emit(state.copyWith(status: ProfileStatus.updating));

    final userId = state.profile!.id;

    if (event.notificationsEnabled != null) {
      await _repository.updateNotificationSettings(
        userId: userId,
        enabled: event.notificationsEnabled!,
      );
    }

    if (event.contactSyncEnabled != null) {
      await _repository.updateContactSyncSettings(
        userId: userId,
        enabled: event.contactSyncEnabled!,
      );
    }

    if (event.biometricAuthEnabled != null) {
      await _repository.updateBiometricAuthSettings(
        userId: userId,
        enabled: event.biometricAuthEnabled!,
      );
    }

    // Reload profile to get updated data
    final result = await _repository.getCurrentUserProfile();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (profile) =>
          emit(state.copyWith(status: ProfileStatus.updated, profile: profile)),
    );
  }
}
