part of 'profile_bloc.dart';

/// Profile status enum
enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  updated,
  uploadingPhoto,
  photoUpdated,
  error,
}

/// Profile state
class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserProfileEntity? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  /// Whether the state is in a loading state
  bool get isLoading =>
      status == ProfileStatus.loading ||
      status == ProfileStatus.updating ||
      status == ProfileStatus.uploadingPhoto;

  /// Whether the profile is loaded
  bool get isLoaded => profile != null;

  /// Whether there's an error
  bool get hasError => status == ProfileStatus.error;

  /// Copy with new values
  ProfileState copyWith({
    ProfileStatus? status,
    UserProfileEntity? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
