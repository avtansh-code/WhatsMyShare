import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/profile/data/models/user_profile_model.dart';
import 'package:whats_my_share/features/profile/domain/entities/user_profile_entity.dart';

void main() {
  group('UserProfileModel', () {
    final testCreatedAt = DateTime(2026, 1, 1, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 1, 9, 12, 0, 0);
    final testLastActiveAt = DateTime(2026, 1, 9, 11, 30, 0);

    final testProfile = UserProfileModel(
      id: 'user123',
      email: 'john@example.com',
      displayName: 'John Doe',
      photoUrl: 'https://example.com/photo.jpg',
      phone: '+919876543210',
      defaultCurrency: 'INR',
      locale: 'en-IN',
      timezone: 'Asia/Kolkata',
      notificationsEnabled: true,
      contactSyncEnabled: false,
      biometricAuthEnabled: true,
      totalOwed: 5000,
      totalOwing: 2500,
      groupCount: 3,
      countryCode: 'IN',
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      lastActiveAt: testLastActiveAt,
    );

    group('constructor', () {
      test('creates UserProfileModel with all fields', () {
        expect(testProfile.id, 'user123');
        expect(testProfile.email, 'john@example.com');
        expect(testProfile.displayName, 'John Doe');
        expect(testProfile.photoUrl, 'https://example.com/photo.jpg');
        expect(testProfile.phone, '+919876543210');
        expect(testProfile.defaultCurrency, 'INR');
        expect(testProfile.locale, 'en-IN');
        expect(testProfile.timezone, 'Asia/Kolkata');
        expect(testProfile.notificationsEnabled, true);
        expect(testProfile.contactSyncEnabled, false);
        expect(testProfile.biometricAuthEnabled, true);
        expect(testProfile.totalOwed, 5000);
        expect(testProfile.totalOwing, 2500);
        expect(testProfile.groupCount, 3);
        expect(testProfile.countryCode, 'IN');
        expect(testProfile.createdAt, testCreatedAt);
        expect(testProfile.updatedAt, testUpdatedAt);
        expect(testProfile.lastActiveAt, testLastActiveAt);
      });

      test('creates UserProfileModel with minimal fields', () {
        final minimalProfile = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(minimalProfile.id, 'user123');
        expect(minimalProfile.email, 'john@example.com');
        expect(minimalProfile.displayName, isNull);
        expect(minimalProfile.photoUrl, isNull);
        expect(minimalProfile.phone, isNull);
        expect(minimalProfile.lastActiveAt, isNull);
      });
    });

    group('fromEntity', () {
      test('creates UserProfileModel from UserProfileEntity', () {
        final entity = UserProfileEntity(
          id: 'user123',
          email: 'john@example.com',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
          phone: '+919876543210',
          defaultCurrency: 'USD',
          locale: 'en-US',
          timezone: 'America/New_York',
          notificationsEnabled: false,
          contactSyncEnabled: true,
          biometricAuthEnabled: false,
          totalOwed: 1000,
          totalOwing: 500,
          groupCount: 5,
          countryCode: 'US',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastActiveAt: testLastActiveAt,
        );

        final result = UserProfileModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.email, entity.email);
        expect(result.displayName, entity.displayName);
        expect(result.photoUrl, entity.photoUrl);
        expect(result.phone, entity.phone);
        expect(result.defaultCurrency, entity.defaultCurrency);
        expect(result.locale, entity.locale);
        expect(result.timezone, entity.timezone);
        expect(result.notificationsEnabled, entity.notificationsEnabled);
        expect(result.contactSyncEnabled, entity.contactSyncEnabled);
        expect(result.biometricAuthEnabled, entity.biometricAuthEnabled);
        expect(result.totalOwed, entity.totalOwed);
        expect(result.totalOwing, entity.totalOwing);
        expect(result.groupCount, entity.groupCount);
        expect(result.countryCode, entity.countryCode);
        expect(result.createdAt, entity.createdAt);
        expect(result.updatedAt, entity.updatedAt);
        expect(result.lastActiveAt, entity.lastActiveAt);
      });

      test('preserves null optional fields from entity', () {
        final entity = UserProfileEntity(
          id: 'user123',
          email: 'john@example.com',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final result = UserProfileModel.fromEntity(entity);

        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.phone, isNull);
        expect(result.lastActiveAt, isNull);
      });
    });

    group('toFirestore', () {
      test('converts UserProfileModel to Firestore map', () {
        final result = testProfile.toFirestore();

        expect(result['email'], 'john@example.com');
        expect(result['displayName'], 'John Doe');
        expect(result['photoUrl'], 'https://example.com/photo.jpg');
        expect(result['phone'], '+919876543210');
        expect(result['defaultCurrency'], 'INR');
        expect(result['locale'], 'en-IN');
        expect(result['timezone'], 'Asia/Kolkata');
        expect(result['notificationsEnabled'], true);
        expect(result['contactSyncEnabled'], false);
        expect(result['biometricAuthEnabled'], true);
        expect(result['totalOwed'], 5000);
        expect(result['totalOwing'], 2500);
        expect(result['groupCount'], 3);
        expect(result['countryCode'], 'IN');
      });

      test('converts createdAt to Timestamp', () {
        final result = testProfile.toFirestore();

        expect(result['createdAt'], isA<Timestamp>());
        expect((result['createdAt'] as Timestamp).toDate(), testCreatedAt);
      });

      test('uses FieldValue.serverTimestamp for updatedAt', () {
        final result = testProfile.toFirestore();

        expect(result['updatedAt'], isA<FieldValue>());
      });

      test('converts lastActiveAt to Timestamp when present', () {
        final result = testProfile.toFirestore();

        expect(result['lastActiveAt'], isA<Timestamp>());
        expect(
          (result['lastActiveAt'] as Timestamp).toDate(),
          testLastActiveAt,
        );
      });

      test('sets lastActiveAt to null when not present', () {
        final profileWithoutLastActive = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastActiveAt: null,
        );

        final result = profileWithoutLastActive.toFirestore();

        expect(result['lastActiveAt'], isNull);
      });

      test('does not include id in Firestore map', () {
        final result = testProfile.toFirestore();

        expect(result.containsKey('id'), isFalse);
      });
    });

    group('toCreateFirestore', () {
      test('creates new user profile map with server timestamps', () {
        final result = testProfile.toCreateFirestore();

        expect(result['email'], 'john@example.com');
        expect(result['displayName'], 'John Doe');
        expect(result['photoUrl'], 'https://example.com/photo.jpg');
        expect(result['phone'], '+919876543210');
        expect(result['defaultCurrency'], 'INR');
        expect(result['locale'], 'en-IN');
        expect(result['timezone'], 'Asia/Kolkata');
        expect(result['notificationsEnabled'], true);
        expect(result['contactSyncEnabled'], false);
        expect(result['biometricAuthEnabled'], true);
        expect(result['countryCode'], 'IN');
      });

      test('resets financial fields to zero for new profile', () {
        final result = testProfile.toCreateFirestore();

        expect(result['totalOwed'], 0);
        expect(result['totalOwing'], 0);
        expect(result['groupCount'], 0);
      });

      test('uses server timestamps for time fields', () {
        final result = testProfile.toCreateFirestore();

        expect(result['createdAt'], isA<FieldValue>());
        expect(result['updatedAt'], isA<FieldValue>());
        expect(result['lastActiveAt'], isA<FieldValue>());
      });

      test('includes empty fcmTokens array', () {
        final result = testProfile.toCreateFirestore();

        expect(result['fcmTokens'], isA<List>());
        expect((result['fcmTokens'] as List), isEmpty);
      });

      test('does not include id in create map', () {
        final result = testProfile.toCreateFirestore();

        expect(result.containsKey('id'), isFalse);
      });
    });

    group('toEntity', () {
      test('converts UserProfileModel to UserProfileEntity', () {
        final result = testProfile.toEntity();

        expect(result, isA<UserProfileEntity>());
        expect(result.id, testProfile.id);
        expect(result.email, testProfile.email);
        expect(result.displayName, testProfile.displayName);
        expect(result.photoUrl, testProfile.photoUrl);
        expect(result.phone, testProfile.phone);
        expect(result.defaultCurrency, testProfile.defaultCurrency);
        expect(result.locale, testProfile.locale);
        expect(result.timezone, testProfile.timezone);
        expect(result.notificationsEnabled, testProfile.notificationsEnabled);
        expect(result.contactSyncEnabled, testProfile.contactSyncEnabled);
        expect(result.biometricAuthEnabled, testProfile.biometricAuthEnabled);
        expect(result.totalOwed, testProfile.totalOwed);
        expect(result.totalOwing, testProfile.totalOwing);
        expect(result.groupCount, testProfile.groupCount);
        expect(result.countryCode, testProfile.countryCode);
        expect(result.createdAt, testProfile.createdAt);
        expect(result.updatedAt, testProfile.updatedAt);
        expect(result.lastActiveAt, testProfile.lastActiveAt);
      });

      test('preserves all nullable fields in entity conversion', () {
        final profileWithNulls = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          displayName: null,
          photoUrl: null,
          phone: null,
          lastActiveAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final result = profileWithNulls.toEntity();

        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.phone, isNull);
        expect(result.lastActiveAt, isNull);
      });
    });

    group('inheritance', () {
      test('UserProfileModel is a UserProfileEntity', () {
        expect(testProfile, isA<UserProfileEntity>());
      });

      test('can be used where UserProfileEntity is expected', () {
        UserProfileEntity entity = testProfile;
        expect(entity.id, 'user123');
        expect(entity.email, 'john@example.com');
      });
    });

    group('default values', () {
      test('entity provides default values for settings', () {
        final minimalProfile = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // These should use entity defaults
        expect(minimalProfile.defaultCurrency, 'INR');
        expect(minimalProfile.locale, 'en-IN');
        expect(minimalProfile.timezone, 'Asia/Kolkata');
        expect(minimalProfile.notificationsEnabled, true);
        expect(minimalProfile.contactSyncEnabled, false);
        expect(minimalProfile.biometricAuthEnabled, false);
        expect(minimalProfile.totalOwed, 0);
        expect(minimalProfile.totalOwing, 0);
        expect(minimalProfile.groupCount, 0);
        expect(minimalProfile.countryCode, 'IN');
      });
    });

    group('roundtrip conversion', () {
      test('entity -> model -> entity preserves all data', () {
        final originalEntity = UserProfileEntity(
          id: 'user123',
          email: 'john@example.com',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
          phone: '+919876543210',
          defaultCurrency: 'USD',
          locale: 'en-US',
          timezone: 'America/New_York',
          notificationsEnabled: false,
          contactSyncEnabled: true,
          biometricAuthEnabled: true,
          totalOwed: 1000,
          totalOwing: 500,
          groupCount: 5,
          countryCode: 'US',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastActiveAt: testLastActiveAt,
        );

        final model = UserProfileModel.fromEntity(originalEntity);
        final convertedEntity = model.toEntity();

        expect(convertedEntity.id, originalEntity.id);
        expect(convertedEntity.email, originalEntity.email);
        expect(convertedEntity.displayName, originalEntity.displayName);
        expect(convertedEntity.photoUrl, originalEntity.photoUrl);
        expect(convertedEntity.phone, originalEntity.phone);
        expect(convertedEntity.defaultCurrency, originalEntity.defaultCurrency);
        expect(convertedEntity.locale, originalEntity.locale);
        expect(convertedEntity.timezone, originalEntity.timezone);
        expect(
          convertedEntity.notificationsEnabled,
          originalEntity.notificationsEnabled,
        );
        expect(
          convertedEntity.contactSyncEnabled,
          originalEntity.contactSyncEnabled,
        );
        expect(
          convertedEntity.biometricAuthEnabled,
          originalEntity.biometricAuthEnabled,
        );
        expect(convertedEntity.totalOwed, originalEntity.totalOwed);
        expect(convertedEntity.totalOwing, originalEntity.totalOwing);
        expect(convertedEntity.groupCount, originalEntity.groupCount);
        expect(convertedEntity.countryCode, originalEntity.countryCode);
        expect(convertedEntity.createdAt, originalEntity.createdAt);
        expect(convertedEntity.updatedAt, originalEntity.updatedAt);
        expect(convertedEntity.lastActiveAt, originalEntity.lastActiveAt);
      });
    });

    group('financial calculations', () {
      test('totalOwed and totalOwing are independent', () {
        final profile = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          totalOwed: 10000,
          totalOwing: 5000,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(profile.totalOwed, 10000);
        expect(profile.totalOwing, 5000);
      });

      test('handles zero balances', () {
        final profile = UserProfileModel(
          id: 'user123',
          email: 'john@example.com',
          totalOwed: 0,
          totalOwing: 0,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(profile.totalOwed, 0);
        expect(profile.totalOwing, 0);
      });
    });
  });
}
