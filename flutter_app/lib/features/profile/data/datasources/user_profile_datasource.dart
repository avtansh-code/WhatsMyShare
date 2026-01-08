import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_profile_model.dart';

/// Remote data source for user profile operations
abstract class UserProfileDataSource {
  /// Get user profile by ID
  Future<UserProfileModel> getUserProfile(String userId);

  /// Get current user's profile
  Future<UserProfileModel> getCurrentUserProfile();

  /// Stream of current user's profile
  Stream<UserProfileModel?> watchCurrentUserProfile();

  /// Create a new user profile
  Future<UserProfileModel> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  });

  /// Update user profile
  Future<UserProfileModel> updateUserProfile({
    required String userId,
    Map<String, dynamic> data,
  });

  /// Upload profile photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  });

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId);

  /// Check if profile exists
  Future<bool> profileExists(String userId);

  /// Delete user profile
  Future<void> deleteUserProfile(String userId);

  /// Update last active timestamp
  Future<void> updateLastActive(String userId);
}

/// Implementation of UserProfileDataSource using Firebase
class UserProfileDataSourceImpl implements UserProfileDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  UserProfileDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  /// Reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        throw ServerException(message: 'User profile not found');
      }
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get user profile');
    }
  }

  @override
  Future<UserProfileModel> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(message: 'Not authenticated');
    }
    return getUserProfile(user.uid);
  }

  @override
  Stream<UserProfileModel?> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _usersCollection.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  @override
  Future<UserProfileModel> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now();
      final model = UserProfileModel(
        id: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _usersCollection.doc(userId).set(model.toCreateFirestore());

      // Fetch the created document to get server timestamps
      final doc = await _usersCollection.doc(userId).get();
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to create user profile',
      );
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updateData = {...?data, 'updatedAt': FieldValue.serverTimestamp()};

      await _usersCollection.doc(userId).update(updateData);

      // Fetch updated document
      final doc = await _usersCollection.doc(userId).get();
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update user profile',
      );
    }
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Create storage reference
      final ref = _storage.ref().child('users/$userId/profile/avatar.jpg');

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      final uploadTask = ref.putFile(imageFile, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile with new photo URL
      await _usersCollection.doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to upload profile photo',
      );
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // Delete from storage
      final ref = _storage.ref().child('users/$userId/profile/avatar.jpg');
      try {
        await ref.delete();
      } catch (_) {
        // File might not exist, continue
      }

      // Update user profile
      await _usersCollection.doc(userId).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete profile photo',
      );
    }
  }

  @override
  Future<bool> profileExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to check profile existence',
      );
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      // Delete profile photo from storage
      try {
        final ref = _storage.ref().child('users/$userId/profile/avatar.jpg');
        await ref.delete();
      } catch (_) {
        // File might not exist
      }

      // Delete user document
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete user profile',
      );
    }
  }

  @override
  Future<void> updateLastActive(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update last active',
      );
    }
  }
}
