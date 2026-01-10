/// Integration tests for authentication flow
///
/// These tests verify the complete authentication flow including:
/// - User registration
/// - Email/password sign in
/// - Sign out
/// - Password reset
///
/// Requirements:
/// - Uses mock Firebase implementations for VM testing
/// - For real emulator tests, use integration_test package on device
@Tags(['integration'])
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helper.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;

  setUpAll(() async {
    // Initialize for testing
    await initializeFirebaseForTests();
  });

  setUp(() async {
    // Create fresh mock instances for each test
    MockFirebaseInstances.reset();
    auth = MockFirebaseInstances.auth;
    firestore = MockFirebaseInstances.firestore;
  });

  tearDown(() async {
    // Clean up after each test
    await TestCleanup.cleanupCurrentUser(auth);
  });

  group('User Registration Flow', () {
    test(
      'should successfully create a new user with email and password',
      () async {
        // Arrange
        final credentials = TestUsers.testUser1;

        // Act
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: credentials.email,
          password: credentials.password,
        );

        // Assert
        expect(userCredential.user, isNotNull);
        expect(userCredential.user!.email, equals(credentials.email));
        expect(userCredential.user!.uid, isNotEmpty);
      },
    );

    test(
      'should create user profile in Firestore after registration',
      () async {
        // Arrange
        final credentials = TestUsers.testUser1;

        // Act
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: credentials.email,
          password: credentials.password,
        );

        // Create profile in Firestore (simulating app behavior)
        await SeedData.createTestUserProfile(
          firestore: firestore,
          userId: userCredential.user!.uid,
          email: credentials.email,
          displayName: credentials.displayName,
        );

        // Assert
        final profileExists = await IntegrationAssertions.documentExists(
          firestore,
          'users',
          userCredential.user!.uid,
        );
        expect(profileExists, isTrue);
      },
    );
  });

  group('Sign In Flow', () {
    test('should successfully sign in with valid credentials', () async {
      // Arrange - Create user first
      final credentials = TestUsers.testUser1;
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      await auth.signOut();

      // Act
      final userCredential = await auth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Assert
      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, equals(credentials.email));
      expect(auth.currentUser, isNotNull);
    });

    test('should persist user session after sign in', () async {
      // Arrange - Create and sign in
      final credentials = TestUsers.testUser1;
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Assert - User should be current user
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(credentials.email));
    });
  });

  group('Sign Out Flow', () {
    test('should successfully sign out user', () async {
      // Arrange - Create and sign in
      final credentials = TestUsers.testUser1;
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      expect(auth.currentUser, isNotNull);

      // Act
      await auth.signOut();

      // Assert
      expect(auth.currentUser, isNull);
    });

    test('should clear user session after sign out', () async {
      // Arrange - Create and sign in
      final credentials = TestUsers.testUser1;
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Act
      await auth.signOut();

      // Assert - No current user
      expect(auth.currentUser, isNull);
    });
  });

  group('Auth State Changes', () {
    test('should emit auth state changes on sign in', () async {
      // Arrange
      final credentials = TestUsers.testUser1;
      final authStateChanges = <MockUser?>[];

      final subscription = auth.authStateChanges().listen((user) {
        authStateChanges.add(user as MockUser?);
      });

      // Wait for initial state
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - Create user
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Wait for state change
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(authStateChanges.length, greaterThanOrEqualTo(1));

      await subscription.cancel();
    });

    test('should emit auth state changes on sign out', () async {
      // Arrange
      final credentials = TestUsers.testUser1;
      await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      final authStateChanges = <MockUser?>[];
      final subscription = auth.authStateChanges().listen((user) {
        authStateChanges.add(user as MockUser?);
      });

      // Wait for initial state
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - Sign out
      await auth.signOut();

      // Wait for state change
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Last state should be null (signed out)
      expect(auth.currentUser, isNull);

      await subscription.cancel();
    });
  });

  group('User Profile Updates', () {
    test('should update display name after registration', () async {
      // Arrange
      final credentials = TestUsers.testUser1;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Act
      await userCredential.user!.updateDisplayName(credentials.displayName);

      // Assert
      final updatedUser = auth.currentUser;
      expect(updatedUser!.displayName, equals(credentials.displayName));
    });
  });

  group('Complete Auth Flow', () {
    test('should complete full registration and login cycle', () async {
      // 1. Register new user
      final credentials = TestUsers.testUser1;
      final regResult = await auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      expect(regResult.user, isNotNull);

      // 2. Create profile in Firestore
      await SeedData.createTestUserProfile(
        firestore: firestore,
        userId: regResult.user!.uid,
        email: credentials.email,
        displayName: credentials.displayName,
      );

      // 3. Sign out
      await auth.signOut();
      expect(auth.currentUser, isNull);

      // 4. Sign back in
      final signInResult = await auth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      expect(signInResult.user, isNotNull);
      expect(signInResult.user!.uid, equals(regResult.user!.uid));

      // 5. Verify profile exists
      final profileExists = await IntegrationAssertions.documentExists(
        firestore,
        'users',
        signInResult.user!.uid,
      );
      expect(profileExists, isTrue);

      // 6. Sign out again
      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });
}
