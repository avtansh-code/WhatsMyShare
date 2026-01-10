import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/core/errors/failures.dart';
import 'package:whats_my_share/features/profile/domain/entities/user_profile_entity.dart';
import 'package:whats_my_share/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:whats_my_share/features/profile/presentation/bloc/profile_bloc.dart';

// Mock classes
class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockFile extends Mock implements File {}

void main() {
  late MockUserProfileRepository mockRepository;
  late ProfileBloc profileBloc;

  final testDate = DateTime(2024, 1, 15, 10, 30);

  final testProfile = UserProfileEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    phone: '+1234567890',
    defaultCurrency: 'INR',
    locale: 'en_US',
    timezone: 'Asia/Kolkata',
    notificationsEnabled: true,
    contactSyncEnabled: false,
    biometricAuthEnabled: false,
    totalOwed: 5000,
    totalOwing: 2000,
    groupCount: 3,
    countryCode: 'IN',
    createdAt: testDate,
    updatedAt: testDate,
    lastActiveAt: testDate,
  );

  setUpAll(() {
    registerFallbackValue(MockFile());
  });

  setUp(() {
    mockRepository = MockUserProfileRepository();
    profileBloc = ProfileBloc(repository: mockRepository);
  });

  tearDown(() {
    profileBloc.close();
  });

  group('ProfileBloc', () {
    test('initial state is ProfileState with initial status', () {
      expect(profileBloc.state.status, ProfileStatus.initial);
      expect(profileBloc.state.profile, isNull);
    });

    group('ProfileLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, loaded] when loading succeeds',
        build: () {
          when(
            () => mockRepository.getCurrentUserProfile(),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.loading,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.loaded)
              .having((s) => s.profile, 'profile', isNotNull)
              .having(
                (s) => s.profile?.displayName,
                'displayName',
                'Test User',
              ),
        ],
        verify: (_) {
          verify(() => mockRepository.getCurrentUserProfile()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [loading, error] when loading fails',
        build: () {
          when(() => mockRepository.getCurrentUserProfile()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.loading,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, updated] when update succeeds',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          final updatedProfile = UserProfileEntity(
            id: testProfile.id,
            email: testProfile.email,
            displayName: 'Updated Name',
            photoUrl: testProfile.photoUrl,
            phone: testProfile.phone,
            defaultCurrency: testProfile.defaultCurrency,
            locale: testProfile.locale,
            timezone: testProfile.timezone,
            notificationsEnabled: testProfile.notificationsEnabled,
            contactSyncEnabled: testProfile.contactSyncEnabled,
            biometricAuthEnabled: testProfile.biometricAuthEnabled,
            totalOwed: testProfile.totalOwed,
            totalOwing: testProfile.totalOwing,
            groupCount: testProfile.groupCount,
            countryCode: testProfile.countryCode,
            createdAt: testProfile.createdAt,
            updatedAt: DateTime.now(),
            lastActiveAt: testProfile.lastActiveAt,
          );
          when(
            () => mockRepository.updateUserProfile(
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              phone: any(named: 'phone'),
              defaultCurrency: any(named: 'defaultCurrency'),
              locale: any(named: 'locale'),
              timezone: any(named: 'timezone'),
              countryCode: any(named: 'countryCode'),
            ),
          ).thenAnswer((_) async => Right(updatedProfile));
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(const ProfileUpdateRequested(displayName: 'Updated Name')),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.updated)
              .having(
                (s) => s.profile?.displayName,
                'displayName',
                'Updated Name',
              ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, error] when update fails',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.updateUserProfile(
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              phone: any(named: 'phone'),
              defaultCurrency: any(named: 'defaultCurrency'),
              locale: any(named: 'locale'),
              timezone: any(named: 'timezone'),
              countryCode: any(named: 'countryCode'),
            ),
          ).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')),
          );
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(const ProfileUpdateRequested(displayName: 'Updated Name')),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'does nothing when no profile is loaded',
        build: () => profileBloc,
        act: (bloc) =>
            bloc.add(const ProfileUpdateRequested(displayName: 'Updated Name')),
        expect: () => [],
      );
    });

    group('ProfilePhotoUpdateRequested', () {
      final mockFile = MockFile();

      blocTest<ProfileBloc, ProfileState>(
        'emits [uploadingPhoto, photoUpdated] when photo upload succeeds',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.updateProfilePhoto(
              userId: any(named: 'userId'),
              imageFile: any(named: 'imageFile'),
            ),
          ).thenAnswer((_) async => const Right('https://new-photo-url.com'));
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(ProfilePhotoUpdateRequested(imageFile: mockFile)),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.uploadingPhoto,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.photoUpdated)
              .having(
                (s) => s.profile?.photoUrl,
                'photoUrl',
                'https://new-photo-url.com',
              ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [uploadingPhoto, error] when photo upload fails',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.updateProfilePhoto(
              userId: any(named: 'userId'),
              imageFile: any(named: 'imageFile'),
            ),
          ).thenAnswer(
            (_) async => const Left(StorageFailure(message: 'Upload failed')),
          );
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(ProfilePhotoUpdateRequested(imageFile: mockFile)),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.uploadingPhoto,
          ),
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.error,
          ),
        ],
      );
    });

    group('ProfilePhotoDeleteRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, updated] when photo delete succeeds',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.deleteProfilePhoto(any()),
          ).thenAnswer((_) async => const Right(null));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfilePhotoDeleteRequested()),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.updated)
              .having((s) => s.profile?.photoUrl, 'photoUrl', isNull),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, error] when photo delete fails',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(() => mockRepository.deleteProfilePhoto(any())).thenAnswer(
            (_) async => const Left(StorageFailure(message: 'Delete failed')),
          );
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfilePhotoDeleteRequested()),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.error,
          ),
        ],
      );
    });

    group('ProfileSettingsChanged', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [updating, updated] when settings change succeeds',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.updateNotificationSettings(
              userId: any(named: 'userId'),
              enabled: any(named: 'enabled'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockRepository.getCurrentUserProfile(),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) =>
            bloc.add(const ProfileSettingsChanged(notificationsEnabled: false)),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updated,
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates multiple settings in sequence',
        seed: () =>
            ProfileState(status: ProfileStatus.loaded, profile: testProfile),
        build: () {
          when(
            () => mockRepository.updateNotificationSettings(
              userId: any(named: 'userId'),
              enabled: any(named: 'enabled'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockRepository.updateBiometricAuthSettings(
              userId: any(named: 'userId'),
              enabled: any(named: 'enabled'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockRepository.getCurrentUserProfile(),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(
          const ProfileSettingsChanged(
            notificationsEnabled: false,
            biometricAuthEnabled: true,
          ),
        ),
        expect: () => [
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updating,
          ),
          isA<ProfileState>().having(
            (s) => s.status,
            'status',
            ProfileStatus.updated,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.updateNotificationSettings(
              userId: any(named: 'userId'),
              enabled: any(named: 'enabled'),
            ),
          ).called(1);
          verify(
            () => mockRepository.updateBiometricAuthSettings(
              userId: any(named: 'userId'),
              enabled: any(named: 'enabled'),
            ),
          ).called(1);
        },
      );
    });
  });

  group('ProfileState', () {
    test('initial state has correct defaults', () {
      const state = ProfileState();
      expect(state.status, ProfileStatus.initial);
      expect(state.profile, isNull);
      expect(state.errorMessage, isNull);
    });

    test('isLoading returns true for loading status', () {
      const state = ProfileState(status: ProfileStatus.loading);
      expect(state.isLoading, isTrue);
    });

    test('isLoading returns true for updating status', () {
      const state = ProfileState(status: ProfileStatus.updating);
      expect(state.isLoading, isTrue);
    });

    test('isLoading returns true for uploadingPhoto status', () {
      const state = ProfileState(status: ProfileStatus.uploadingPhoto);
      expect(state.isLoading, isTrue);
    });

    test('isLoading returns false for loaded status', () {
      const state = ProfileState(status: ProfileStatus.loaded);
      expect(state.isLoading, isFalse);
    });

    test('isLoaded returns true when profile exists', () {
      final state = ProfileState(profile: testProfile);
      expect(state.isLoaded, isTrue);
    });

    test('isLoaded returns false when profile is null', () {
      const state = ProfileState();
      expect(state.isLoaded, isFalse);
    });

    test('hasError returns true for error status', () {
      const state = ProfileState(status: ProfileStatus.error);
      expect(state.hasError, isTrue);
    });

    test('hasError returns false for non-error status', () {
      const state = ProfileState(status: ProfileStatus.loaded);
      expect(state.hasError, isFalse);
    });

    test('copyWith creates copy with updated status', () {
      const state = ProfileState(status: ProfileStatus.initial);
      final copied = state.copyWith(status: ProfileStatus.loading);
      expect(copied.status, ProfileStatus.loading);
    });

    test('copyWith creates copy with updated profile', () {
      const state = ProfileState();
      final copied = state.copyWith(profile: testProfile);
      expect(copied.profile, testProfile);
    });

    test('copyWith preserves existing values', () {
      final state = ProfileState(profile: testProfile);
      final copied = state.copyWith(status: ProfileStatus.updated);
      expect(copied.profile, testProfile);
      expect(copied.status, ProfileStatus.updated);
    });

    test('props contain all state fields', () {
      final state = ProfileState(
        status: ProfileStatus.loaded,
        profile: testProfile,
        errorMessage: 'Error',
      );
      expect(state.props, contains(ProfileStatus.loaded));
      expect(state.props, contains(testProfile));
      expect(state.props, contains('Error'));
    });
  });

  group('ProfileEvent', () {
    test('ProfileLoadRequested props are empty', () {
      const event = ProfileLoadRequested();
      expect(event.props, isEmpty);
    });

    test('ProfileUpdateRequested props contain update fields', () {
      const event = ProfileUpdateRequested(
        displayName: 'New Name',
        phone: '+1234567890',
      );
      expect(event.props, contains('New Name'));
      expect(event.props, contains('+1234567890'));
    });

    test('ProfilePhotoUpdateRequested props contain file', () {
      final mockFile = MockFile();
      final event = ProfilePhotoUpdateRequested(imageFile: mockFile);
      expect(event.props, contains(mockFile));
    });

    test('ProfilePhotoDeleteRequested props are empty', () {
      const event = ProfilePhotoDeleteRequested();
      expect(event.props, isEmpty);
    });

    test('ProfileSettingsChanged props contain settings', () {
      const event = ProfileSettingsChanged(
        notificationsEnabled: true,
        biometricAuthEnabled: false,
      );
      expect(event.props, contains(true));
      expect(event.props, contains(false));
    });
  });
}
