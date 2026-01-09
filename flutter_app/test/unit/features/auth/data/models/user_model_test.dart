import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/auth/data/models/user_model.dart';
import 'package:whats_my_share/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    const testUserModel = UserModel(
      id: 'user-123',
      phone: '+919876543210',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isPhoneVerified: true,
      notificationsEnabled: true,
      contactSyncEnabled: false,
      biometricAuthEnabled: true,
      totalOwed: 1000,
      totalOwing: 500,
      groupCount: 3,
      fcmTokens: ['token1', 'token2'],
    );

    group('fromMap', () {
      test('creates UserModel from valid map', () {
        // Arrange
        final map = {
          'id': 'user-123',
          'phone': '+919876543210',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'isPhoneVerified': true,
          'notificationsEnabled': true,
          'contactSyncEnabled': false,
          'biometricAuthEnabled': true,
          'totalOwed': 1000,
          'totalOwing': 500,
          'groupCount': 3,
          'fcmTokens': ['token1', 'token2'],
        };

        // Act
        final result = UserModel.fromMap(map);

        // Assert
        expect(result.id, 'user-123');
        expect(result.phone, '+919876543210');
        expect(result.displayName, 'Test User');
        expect(result.photoUrl, 'https://example.com/photo.jpg');
        expect(result.isPhoneVerified, true);
        expect(result.notificationsEnabled, true);
        expect(result.contactSyncEnabled, false);
        expect(result.biometricAuthEnabled, true);
        expect(result.totalOwed, 1000);
        expect(result.totalOwing, 500);
        expect(result.groupCount, 3);
        expect(result.fcmTokens, ['token1', 'token2']);
      });

      test('uses default values for missing optional fields', () {
        // Arrange
        final minimalMap = {'id': 'user-123', 'phone': '+919876543210'};

        // Act
        final result = UserModel.fromMap(minimalMap);

        // Assert
        expect(result.id, 'user-123');
        expect(result.phone, '+919876543210');
        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.isPhoneVerified, false);
        expect(result.notificationsEnabled, true);
        expect(result.contactSyncEnabled, false);
        expect(result.biometricAuthEnabled, false);
        expect(result.totalOwed, 0);
        expect(result.totalOwing, 0);
        expect(result.groupCount, 0);
        expect(result.fcmTokens, []);
      });

      test('parses DateTime fields from ISO strings', () {
        // Arrange
        final mapWithDates = {
          'id': 'user-123',
          'phone': '+919876543210',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'updatedAt': '2024-06-20T15:45:00.000Z',
          'lastActiveAt': '2024-12-01T08:00:00.000Z',
        };

        // Act
        final result = UserModel.fromMap(mapWithDates);

        // Assert
        expect(result.createdAt, isNotNull);
        expect(result.updatedAt, isNotNull);
        expect(result.lastActiveAt, isNotNull);
        expect(result.createdAt!.year, 2024);
        expect(result.createdAt!.month, 1);
        expect(result.createdAt!.day, 15);
      });

      test('handles null date fields', () {
        // Arrange
        final mapWithNullDates = {
          'id': 'user-123',
          'phone': '+919876543210',
          'createdAt': null,
          'updatedAt': null,
          'lastActiveAt': null,
        };

        // Act
        final result = UserModel.fromMap(mapWithNullDates);

        // Assert
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
        expect(result.lastActiveAt, isNull);
      });
    });

    group('toMap', () {
      test('converts UserModel to map', () {
        // Act
        final result = testUserModel.toMap();

        // Assert
        expect(result['id'], 'user-123');
        expect(result['phone'], '+919876543210');
        expect(result['displayName'], 'Test User');
        expect(result['photoUrl'], 'https://example.com/photo.jpg');
        expect(result['isPhoneVerified'], true);
        expect(result['notificationsEnabled'], true);
        expect(result['contactSyncEnabled'], false);
        expect(result['biometricAuthEnabled'], true);
        expect(result['totalOwed'], 1000);
        expect(result['totalOwing'], 500);
        expect(result['groupCount'], 3);
        expect(result['fcmTokens'], ['token1', 'token2']);
      });

      test('includes India-specific hardcoded values', () {
        // Act
        final result = testUserModel.toMap();

        // Assert - India-only app hardcoded values
        expect(result['currency'], 'INR');
        expect(result['locale'], 'en_IN');
        expect(result['timezone'], 'Asia/Kolkata');
        expect(result['countryCode'], '+91');
      });

      test('includes all fields in map', () {
        // Act
        final result = testUserModel.toMap();

        // Assert
        expect(result.containsKey('id'), isTrue);
        expect(result.containsKey('phone'), isTrue);
        expect(result.containsKey('displayName'), isTrue);
        expect(result.containsKey('photoUrl'), isTrue);
        expect(result.containsKey('isPhoneVerified'), isTrue);
        expect(result.containsKey('notificationsEnabled'), isTrue);
        expect(result.containsKey('contactSyncEnabled'), isTrue);
        expect(result.containsKey('biometricAuthEnabled'), isTrue);
        expect(result.containsKey('createdAt'), isTrue);
        expect(result.containsKey('updatedAt'), isTrue);
        expect(result.containsKey('lastActiveAt'), isTrue);
        expect(result.containsKey('totalOwed'), isTrue);
        expect(result.containsKey('totalOwing'), isTrue);
        expect(result.containsKey('groupCount'), isTrue);
        expect(result.containsKey('fcmTokens'), isTrue);
      });

      test('serializes DateTime to ISO string', () {
        // Arrange
        final modelWithDates = UserModel(
          id: 'user-123',
          phone: '+919876543210',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 6, 20, 15, 45),
        );

        // Act
        final result = modelWithDates.toMap();

        // Assert
        expect(result['createdAt'], isA<String>());
        expect(result['updatedAt'], isA<String>());
      });
    });

    group('fromEntity', () {
      test('creates UserModel from UserEntity', () {
        // Arrange
        final entity = UserEntity(
          id: 'user-456',
          phone: '+919123456789',
          displayName: 'Entity User',
          photoUrl: 'https://example.com/entity.jpg',
          isPhoneVerified: true,
          notificationsEnabled: false,
          contactSyncEnabled: true,
          biometricAuthEnabled: false,
          totalOwed: 2000,
          totalOwing: 1500,
          groupCount: 5,
          fcmTokens: ['token3'],
          createdAt: DateTime(2024, 1, 1),
        );

        // Act
        final result = UserModel.fromEntity(entity);

        // Assert
        expect(result, isA<UserModel>());
        expect(result.id, entity.id);
        expect(result.phone, entity.phone);
        expect(result.displayName, entity.displayName);
        expect(result.photoUrl, entity.photoUrl);
        expect(result.isPhoneVerified, entity.isPhoneVerified);
        expect(result.notificationsEnabled, entity.notificationsEnabled);
        expect(result.contactSyncEnabled, entity.contactSyncEnabled);
        expect(result.biometricAuthEnabled, entity.biometricAuthEnabled);
        expect(result.totalOwed, entity.totalOwed);
        expect(result.totalOwing, entity.totalOwing);
        expect(result.groupCount, entity.groupCount);
        expect(result.fcmTokens, entity.fcmTokens);
      });
    });

    group('copyWithModel', () {
      test('creates copy with updated phone', () {
        // Act
        final result = testUserModel.copyWithModel(phone: '+919999999999');

        // Assert
        expect(result.phone, '+919999999999');
        expect(result.id, testUserModel.id);
        expect(result.displayName, testUserModel.displayName);
      });

      test('creates copy with updated displayName', () {
        // Act
        final result = testUserModel.copyWithModel(displayName: 'New Name');

        // Assert
        expect(result.displayName, 'New Name');
        expect(result.id, testUserModel.id);
        expect(result.phone, testUserModel.phone);
      });

      test('creates copy with updated settings', () {
        // Act
        final result = testUserModel.copyWithModel(
          notificationsEnabled: false,
          biometricAuthEnabled: false,
        );

        // Assert
        expect(result.notificationsEnabled, false);
        expect(result.biometricAuthEnabled, false);
      });

      test('creates copy with updated financial data', () {
        // Act
        final result = testUserModel.copyWithModel(
          totalOwed: 5000,
          totalOwing: 2500,
          groupCount: 10,
        );

        // Assert
        expect(result.totalOwed, 5000);
        expect(result.totalOwing, 2500);
        expect(result.groupCount, 10);
      });

      test('creates copy with updated tokens', () {
        // Act
        final result = testUserModel.copyWithModel(
          fcmTokens: ['newToken1', 'newToken2', 'newToken3'],
        );

        // Assert
        expect(result.fcmTokens, ['newToken1', 'newToken2', 'newToken3']);
        expect(result.fcmTokens.length, 3);
      });
    });

    group('inheritance', () {
      test('UserModel is a UserEntity', () {
        expect(testUserModel, isA<UserEntity>());
      });

      test('can be used where UserEntity is expected', () {
        // Arrange
        UserEntity entity = testUserModel;

        // Assert
        expect(entity.id, testUserModel.id);
        expect(entity.phone, testUserModel.phone);
      });
    });

    group('roundtrip serialization', () {
      test('toMap and fromMap produce equivalent object', () {
        // Arrange
        final modelWithDates = UserModel(
          id: 'user-123',
          phone: '+919876543210',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          isPhoneVerified: true,
          notificationsEnabled: true,
          contactSyncEnabled: false,
          biometricAuthEnabled: true,
          totalOwed: 1000,
          totalOwing: 500,
          groupCount: 3,
          fcmTokens: ['token1', 'token2'],
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        // Act
        final map = modelWithDates.toMap();
        final result = UserModel.fromMap(map);

        // Assert
        expect(result.id, modelWithDates.id);
        expect(result.phone, modelWithDates.phone);
        expect(result.displayName, modelWithDates.displayName);
        expect(result.photoUrl, modelWithDates.photoUrl);
        expect(result.isPhoneVerified, modelWithDates.isPhoneVerified);
        expect(result.totalOwed, modelWithDates.totalOwed);
        expect(result.totalOwing, modelWithDates.totalOwing);
        expect(result.groupCount, modelWithDates.groupCount);
        expect(result.fcmTokens, modelWithDates.fcmTokens);
      });
    });
  });
}
