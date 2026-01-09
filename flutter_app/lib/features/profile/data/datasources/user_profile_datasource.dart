import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
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
  final EncryptionService _encryptionService;
  final LoggingService _log = LoggingService();

  UserProfileDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    required EncryptionService encryptionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _encryptionService = encryptionService {
    _log.debug('UserProfileDataSource initialized', tag: LogTags.profile);
  }

  /// Reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    _log.debug(
      'Fetching user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        _log.warning(
          'User profile not found',
          tag: LogTags.profile,
          data: {'userId': userId},
        );
        throw ServerException(message: 'User profile not found');
      }
      _log.debug('User profile fetched successfully', tag: LogTags.profile);
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get user profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get user profile');
    }
  }

  @override
  Future<UserProfileModel> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _log.warning(
        'Not authenticated when getting current profile',
        tag: LogTags.profile,
      );
      throw AuthException(message: 'Not authenticated');
    }
    _log.debug(
      'Getting current user profile',
      tag: LogTags.profile,
      data: {'userId': user.uid},
    );
    return getUserProfile(user.uid);
  }

  @override
  Stream<UserProfileModel?> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      _log.debug(
        'No authenticated user for profile stream',
        tag: LogTags.profile,
      );
      return Stream.value(null);
    }

    _log.debug(
      'Setting up profile stream',
      tag: LogTags.profile,
      data: {'userId': user.uid},
    );
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
    _log.info(
      'Creating user profile',
      tag: LogTags.profile,
      data: {'userId': userId, 'email': email, 'displayName': displayName},
    );
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
      _log.info(
        'User profile created successfully',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to create user profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
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
    _log.info(
      'Updating user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final updateData = {...?data, 'updatedAt': FieldValue.serverTimestamp()};

      await _usersCollection.doc(userId).update(updateData);

      // Fetch updated document
      final doc = await _usersCollection.doc(userId).get();
      _log.info(
        'User profile updated successfully',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update user profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
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
    _log.info(
      'Uploading profile photo',
      tag: LogTags.profile,
      data: {'userId': userId, 'filePath': imageFile.path},
    );
    try {
      // Verify file exists
      if (!await imageFile.exists()) {
        _log.error(
          'Image file does not exist',
          tag: LogTags.profile,
          data: {'path': imageFile.path},
        );
        throw ServerException(message: 'Image file not found');
      }

      // Get file size for logging
      final fileSize = await imageFile.length();
      _log.debug(
        'File size verified',
        tag: LogTags.profile,
        data: {
          'sizeBytes': fileSize,
          'sizeMB': (fileSize / (1024 * 1024)).toStringAsFixed(2),
        },
      );

      // Determine content type from file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      String contentType;
      String fileName;

      switch (extension) {
        case 'png':
          contentType = 'image/png';
          fileName = 'avatar.png';
          break;
        case 'gif':
          contentType = 'image/gif';
          fileName = 'avatar.gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          fileName = 'avatar.webp';
          break;
        case 'heic':
        case 'heif':
          contentType = 'image/heic';
          fileName = 'avatar.heic';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          contentType = 'image/jpeg';
          fileName = 'avatar.jpg';
          break;
      }

      _log.debug(
        'Detected image format',
        tag: LogTags.profile,
        data: {
          'extension': extension,
          'contentType': contentType,
          'fileName': fileName,
        },
      );

      // Create storage reference
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'users/$userId/profile/$fileName';
      final ref = _storage.ref().child(storagePath);

      _log.debug(
        'Storage reference created',
        tag: LogTags.profile,
        data: {
          'path': storagePath,
          'fullPath': ref.fullPath,
          'bucket': ref.bucket,
        },
      );

      // Upload with metadata using putFile (more reliable for iOS)
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'timestamp': timestamp.toString(),
        },
      );

      _log.debug(
        'Starting file encryption before upload',
        tag: LogTags.encryption,
      );

      // Encrypt the image before uploading
      final encryptedBytes = await _encryptionService.encryptFile(imageFile);

      // Update metadata for encrypted file
      final encryptedMetadata = SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'timestamp': timestamp.toString(),
          'encrypted': 'true',
          'originalContentType': contentType,
          'originalExtension': extension,
        },
      );

      _log.debug(
        'File encrypted successfully',
        tag: LogTags.encryption,
        data: {
          'originalSize': fileSize,
          'encryptedSize': encryptedBytes.length,
        },
      );

      _log.debug(
        'Starting encrypted file upload to Firebase Storage',
        tag: LogTags.profile,
      );

      // Use putData for encrypted bytes
      final uploadTask = ref.putData(encryptedBytes, encryptedMetadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          _log.debug(
            'Upload progress',
            tag: LogTags.profile,
            data: {
              'progress': '${progress.toStringAsFixed(1)}%',
              'bytesTransferred': snapshot.bytesTransferred,
              'totalBytes': snapshot.totalBytes,
              'state': snapshot.state.toString(),
            },
          );
        },
        onError: (error) {
          _log.error(
            'Upload stream error',
            tag: LogTags.profile,
            data: {'error': error.toString()},
          );
        },
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      _log.debug(
        'Upload task completed',
        tag: LogTags.profile,
        data: {
          'state': snapshot.state.toString(),
          'bytesTransferred': snapshot.bytesTransferred,
          'totalBytes': snapshot.totalBytes,
        },
      );

      if (snapshot.state != TaskState.success) {
        _log.error(
          'Upload did not complete successfully',
          tag: LogTags.profile,
          data: {'state': snapshot.state.toString()},
        );
        throw ServerException(
          message: 'Upload failed with state: ${snapshot.state}',
        );
      }

      // Get download URL from the snapshot reference
      _log.debug(
        'Getting download URL from snapshot reference',
        tag: LogTags.profile,
      );
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _log.debug(
        'Profile photo uploaded to storage',
        tag: LogTags.profile,
        data: {'downloadUrl': downloadUrl},
      );

      // Update user profile with new photo URL
      _log.debug('Updating Firestore with new photo URL', tag: LogTags.profile);
      await _usersCollection.doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log.info(
        'Profile photo upload successful',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
      return downloadUrl;
    } on FirebaseException catch (e) {
      _log.error(
        'Firebase error uploading profile photo',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'code': e.code,
          'message': e.message,
          'plugin': e.plugin,
        },
      );

      // Provide more helpful error messages for common issues
      String errorMessage;
      switch (e.code) {
        case 'object-not-found':
          // This error during upload usually means Storage isn't enabled
          errorMessage =
              'Firebase Storage may not be enabled. Please check Firebase Console.';
          break;
        case 'unauthorized':
        case 'unauthenticated':
          errorMessage = 'Not authorized to upload. Please sign in again.';
          break;
        case 'canceled':
          errorMessage = 'Upload was canceled.';
          break;
        case 'unknown':
          errorMessage =
              'Upload failed. Please check your internet connection.';
          break;
        default:
          errorMessage =
              e.message ?? 'Failed to upload profile photo: ${e.code}';
      }

      throw ServerException(message: errorMessage);
    } on ServerException {
      rethrow;
    } catch (e, stackTrace) {
      _log.error(
        'Unexpected error uploading profile photo',
        tag: LogTags.profile,
        data: {
          'userId': userId,
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      throw ServerException(
        message: 'Failed to upload profile photo: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId) async {
    _log.info(
      'Deleting profile photo',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      // Try to delete all possible avatar file extensions
      final extensions = ['jpg', 'png', 'gif', 'webp', 'heic'];
      for (final ext in extensions) {
        try {
          final ref = _storage.ref().child('users/$userId/profile/avatar.$ext');
          await ref.delete();
          _log.debug(
            'Profile photo deleted from storage',
            tag: LogTags.profile,
            data: {'extension': ext},
          );
        } catch (_) {
          // File with this extension doesn't exist, continue to next
        }
      }

      // Update user profile
      await _usersCollection.doc(userId).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.info(
        'Profile photo deleted successfully',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete profile photo',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to delete profile photo',
      );
    }
  }

  @override
  Future<bool> profileExists(String userId) async {
    _log.debug(
      'Checking if profile exists',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      final doc = await _usersCollection.doc(userId).get();
      final exists = doc.exists;
      _log.debug(
        'Profile existence check result',
        tag: LogTags.profile,
        data: {'exists': exists},
      );
      return exists;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to check profile existence',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to check profile existence',
      );
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    _log.warning(
      'Deleting user profile',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      // Delete profile photo from storage
      try {
        final ref = _storage.ref().child('users/$userId/profile/avatar.jpg');
        await ref.delete();
        _log.debug('Profile photo deleted from storage', tag: LogTags.profile);
      } catch (_) {
        // File might not exist
        _log.debug('Profile photo not found in storage', tag: LogTags.profile);
      }

      // Delete user document
      await _usersCollection.doc(userId).delete();
      _log.info(
        'User profile deleted successfully',
        tag: LogTags.profile,
        data: {'userId': userId},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete user profile',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to delete user profile',
      );
    }
  }

  @override
  Future<void> updateLastActive(String userId) async {
    _log.debug(
      'Updating last active timestamp',
      tag: LogTags.profile,
      data: {'userId': userId},
    );
    try {
      await _usersCollection.doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      _log.debug('Last active timestamp updated', tag: LogTags.profile);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to update last active',
        tag: LogTags.profile,
        data: {'userId': userId, 'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to update last active',
      );
    }
  }
}
