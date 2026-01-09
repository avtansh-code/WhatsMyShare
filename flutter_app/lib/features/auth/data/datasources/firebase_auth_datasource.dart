import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../models/user_model.dart';

/// Firebase Auth data source for phone-based authentication ONLY
/// No email/password or social login methods
abstract class FirebaseAuthDataSource {
  /// Get the currently authenticated user
  Future<UserModel?> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;

  /// Start phone number verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  /// Sign in with phone credential (OTP verification)
  Future<UserModel> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  });

  /// Sign in with auto-retrieved credential (Android only)
  Future<UserModel> signInWithAutoRetrievedCredential(
    firebase_auth.PhoneAuthCredential credential,
  );

  /// Update user profile
  Future<UserModel> updateProfile({
    required String displayName,
    String? photoUrl,
  });

  /// Complete profile setup for new users
  Future<UserModel> completeProfileSetup({
    required String displayName,
    String? photoUrl,
    String? defaultCurrency,
    String? countryCode,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Delete user account
  Future<void> deleteAccount();

  /// Check if phone number is registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber);

  /// Get user by phone number
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber);

  /// Update FCM token
  Future<void> updateFcmToken(String token);

  /// Remove FCM token
  Future<void> removeFcmToken(String token);
}

/// Implementation of Firebase Auth data source
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;

  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    required LoggingService loggingService,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _loggingService = loggingService;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      // Get user data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // User exists in Firebase Auth but not in Firestore
        // This might be a new user who needs to complete profile
        return UserModel(
          id: firebaseUser.uid,
          phone: firebaseUser.phoneNumber ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          isPhoneVerified: firebaseUser.phoneNumber != null,
        );
      }

      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      _loggingService.error('Error getting current user', e, stackTrace);
      throw ServerException(message: 'Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          // New user - return basic info from Firebase Auth
          return UserModel(
            id: firebaseUser.uid,
            phone: firebaseUser.phoneNumber ?? '',
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            isPhoneVerified: firebaseUser.phoneNumber != null,
          );
        }

        return UserModel.fromFirestore(userDoc);
      } catch (e) {
        _loggingService.error('Error in auth state changes', e);
        return null;
      }
    });
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken,
      );
    } catch (e, stackTrace) {
      _loggingService.error('Error verifying phone number', e, stackTrace);
      throw AuthException(message: 'Failed to verify phone number: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await _signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      _loggingService.error('Firebase auth error', e, stackTrace);
      throw _mapFirebaseAuthException(e);
    } catch (e, stackTrace) {
      _loggingService.error('Error signing in with phone credential', e, stackTrace);
      throw AuthException(message: 'Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithAutoRetrievedCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    try {
      return await _signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      _loggingService.error('Firebase auth error', e, stackTrace);
      throw _mapFirebaseAuthException(e);
    } catch (e, stackTrace) {
      _loggingService.error('Error signing in with auto-retrieved credential', e, stackTrace);
      throw AuthException(message: 'Failed to sign in: ${e.toString()}');
    }
  }

  Future<UserModel> _signInWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw const AuthException(message: 'Sign in failed - no user returned');
    }

    // Check if user exists in Firestore
    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      // New user - create initial record
      final newUser = UserModel(
        id: firebaseUser.uid,
        phone: firebaseUser.phoneNumber ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isPhoneVerified: true,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toFirestoreCreate());

      return newUser;
    }

    // Existing user - update last active and return
    await _firestore.collection('users').doc(firebaseUser.uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
      'isPhoneVerified': true,
    });

    return UserModel.fromFirestore(
      await _firestore.collection('users').doc(firebaseUser.uid).get(),
    );
  }

  @override
  Future<UserModel> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'No authenticated user');
      }

      // Update Firebase Auth profile
      await firebaseUser.updateDisplayName(displayName);
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return UserModel.fromFirestore(
        await _firestore.collection('users').doc(firebaseUser.uid).get(),
      );
    } catch (e, stackTrace) {
      _loggingService.error('Error updating profile', e, stackTrace);
      throw ServerException(message: 'Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> completeProfileSetup({
    required String displayName,
    String? photoUrl,
    String? defaultCurrency,
    String? countryCode,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'No authenticated user');
      }

      // Update Firebase Auth profile
      await firebaseUser.updateDisplayName(displayName);
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      // Update Firestore with complete profile
      final updates = <String, dynamic>{
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (defaultCurrency != null) updates['defaultCurrency'] = defaultCurrency;
      if (countryCode != null) updates['countryCode'] = countryCode;

      await _firestore.collection('users').doc(firebaseUser.uid).update(updates);

      return UserModel.fromFirestore(
        await _firestore.collection('users').doc(firebaseUser.uid).get(),
      );
    } catch (e, stackTrace) {
      _loggingService.error('Error completing profile setup', e, stackTrace);
      throw ServerException(message: 'Failed to complete profile setup: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e, stackTrace) {
      _loggingService.error('Error signing out', e, stackTrace);
      throw AuthException(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'No authenticated user');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // Delete Firebase Auth account
      await firebaseUser.delete();
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      _loggingService.error('Firebase auth error during account deletion', e, stackTrace);
      throw _mapFirebaseAuthException(e);
    } catch (e, stackTrace) {
      _loggingService.error('Error deleting account', e, stackTrace);
      throw ServerException(message: 'Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      _loggingService.error('Error checking phone registration', e, stackTrace);
      throw ServerException(message: 'Failed to check phone registration: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      _loggingService.error('Error getting user by phone', e, stackTrace);
      throw ServerException(message: 'Failed to get user by phone: ${e.toString()}');
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return; // No user to update
      }

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e, stackTrace) {
      _loggingService.error('Error updating FCM token', e, stackTrace);
      // Don't throw - FCM token update failure shouldn't break the app
    }
  }

  @override
  Future<void> removeFcmToken(String token) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return;
      }

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e, stackTrace) {
      _loggingService.error('Error removing FCM token', e, stackTrace);
      // Don't throw - FCM token removal failure shouldn't break the app
    }
  }

  /// Map Firebase Auth exceptions to our custom exceptions
  AuthException _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return const AuthException(message: 'Invalid verification code. Please try again.');
      case 'invalid-verification-id':
        return const AuthException(message: 'Verification session expired. Please request a new code.');
      case 'session-expired':
        return const AuthException(message: 'Verification session expired. Please request a new code.');
      case 'too-many-requests':
        return const AuthException(message: 'Too many attempts. Please try again later.');
      case 'invalid-phone-number':
        return const AuthException(message: 'Invalid phone number format.');
      case 'quota-exceeded':
        return const AuthException(message: 'SMS quota exceeded. Please try again later.');
      case 'user-disabled':
        return const AuthException(message: 'This account has been disabled.');
      case 'requires-recent-login':
        return const AuthException(message: 'Please sign in again to complete this action.');
      default:
        return AuthException(message: e.message ?? 'Authentication failed');
    }
  }
}
