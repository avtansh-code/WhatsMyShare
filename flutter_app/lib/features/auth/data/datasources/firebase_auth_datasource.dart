import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../models/user_model.dart';

/// Remote data source for Firebase Authentication
abstract class FirebaseAuthDataSource {
  /// Stream of auth state changes
  Stream<UserModel?> get authStateChanges;

  /// Get current user
  Future<UserModel?> getCurrentUser();

  /// Sign in with email and password
  Future<UserModel> signInWithEmail(String email, String password);

  /// Sign up with email and password
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  /// Sign in with Google
  Future<UserModel> signInWithGoogle();

  /// Sign in with phone number - initiates verification
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(firebase_auth.PhoneAuthCredential credential) verificationCompleted,
    required void Function(firebase_auth.FirebaseAuthException error) verificationFailed,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
  });

  /// Verify phone OTP and link to current user
  Future<UserModel> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
  });

  /// Link phone number to existing user
  Future<UserModel> linkPhoneNumber({
    required String verificationId,
    required String smsCode,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  });

  /// Update user preferences
  Future<UserModel> updatePreferences({
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
  });

  /// Delete user account
  Future<void> deleteAccount();

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);

  /// Check if phone number is already registered
  Future<bool> isPhoneRegistered(String phone);

  /// Check if email is registered by another user (not the current user)
  Future<bool> isEmailRegisteredByOther(String email, String currentUserId);

  /// Check if phone is registered by another user (not the current user)
  Future<bool> isPhoneRegisteredByOther(String phone, String currentUserId);

  /// Verify current password
  Future<bool> verifyPassword(String password);

  /// Update password
  Future<void> updatePassword(String currentPassword, String newPassword);

  /// Mark phone as verified
  Future<UserModel> markPhoneVerified();

  /// Update profile with email
  Future<UserModel> updateProfileWithEmail({
    required String email,
    String? displayName,
    String? phone,
  });
}

/// Implementation of FirebaseAuthDataSource
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final LoggingService _log = LoggingService();

  FirebaseAuthDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn {
    _log.debug('FirebaseAuthDataSource initialized', tag: LogTags.auth);
  }

  /// Reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _log.debug('Auth state changed: user signed out', tag: LogTags.auth);
        return null;
      }
      _log.debug(
        'Auth state changed: user signed in',
        tag: LogTags.auth,
        data: {'uid': user.uid},
      );
      return await _getUserFromFirestore(user.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _log.debug('getCurrentUser: no current user', tag: LogTags.auth);
      return null;
    }
    _log.debug(
      'getCurrentUser: returning user',
      tag: LogTags.auth,
      data: {'uid': user.uid},
    );
    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    _log.info(
      'Attempting email sign in',
      tag: LogTags.auth,
      data: {'email': email},
    );
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _log.error('Sign in returned null user', tag: LogTags.auth);
        throw const AuthException(message: 'Sign in failed');
      }

      // Update last active timestamp
      await _updateLastActive(user.uid);

      _log.info(
        'Email sign in successful',
        tag: LogTags.auth,
        data: {'uid': user.uid},
      );
      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Firebase auth exception during sign in',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _log.info(
      'Attempting email sign up',
      tag: LogTags.auth,
      data: {'email': email, 'displayName': displayName},
    );
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _log.error('Sign up returned null user', tag: LogTags.auth);
        throw const AuthException(message: 'Sign up failed');
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        photoUrl: user.photoURL,
      );

      await _usersCollection.doc(user.uid).set(userModel.toFirestoreCreate());

      _log.info(
        'Email sign up successful',
        tag: LogTags.auth,
        data: {'uid': user.uid},
      );
      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Firebase auth exception during sign up',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    _log.info('Attempting Google sign in', tag: LogTags.auth);
    try {
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _log.warning('Google sign in cancelled by user', tag: LogTags.auth);
        throw const AuthException(message: 'Google sign in cancelled');
      }

      _log.debug(
        'Google user obtained',
        tag: LogTags.auth,
        data: {'email': googleUser.email},
      );

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        _log.error('Google sign in returned null user', tag: LogTags.auth);
        throw const AuthException(message: 'Google sign in failed');
      }

      // Check if user document exists
      final userDoc = await _usersCollection.doc(user.uid).get();

      if (!userDoc.exists) {
        _log.info(
          'Creating new user document for Google user',
          tag: LogTags.auth,
          data: {'uid': user.uid},
        );
        // Create new user document
        final userModel = UserModel(
          id: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

        await _usersCollection.doc(user.uid).set(userModel.toFirestoreCreate());
        return userModel;
      }

      // Update last active
      await _updateLastActive(user.uid);

      _log.info(
        'Google sign in successful',
        tag: LogTags.auth,
        data: {'uid': user.uid},
      );
      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Firebase auth exception during Google sign in',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    _log.info('Signing out user', tag: LogTags.auth);
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _log.info('User signed out successfully', tag: LogTags.auth);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _log.info(
      'Sending password reset email',
      tag: LogTags.auth,
      data: {'email': email},
    );
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _log.info('Password reset email sent', tag: LogTags.auth);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Failed to send password reset email',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    _log.info(
      'Updating user profile',
      tag: LogTags.auth,
      data: {
        'displayName': displayName,
        'hasPhotoUrl': photoUrl != null,
        'hasPhone': phone != null,
      },
    );
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _log.error(
        'Cannot update profile: user not authenticated',
        tag: LogTags.auth,
      );
      throw const AuthException(message: 'User not authenticated');
    }

    // Update Firebase Auth profile
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Update Firestore document
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (phone != null) updates['phone'] = phone;

    await _usersCollection.doc(user.uid).update(updates);

    _log.info('Profile updated successfully', tag: LogTags.auth);
    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<UserModel> updatePreferences({
    String? defaultCurrency,
    String? locale,
    String? timezone,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
  }) async {
    _log.info('Updating user preferences', tag: LogTags.auth);
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _log.error(
        'Cannot update preferences: user not authenticated',
        tag: LogTags.auth,
      );
      throw const AuthException(message: 'User not authenticated');
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (defaultCurrency != null) updates['defaultCurrency'] = defaultCurrency;
    if (locale != null) updates['locale'] = locale;
    if (timezone != null) updates['timezone'] = timezone;
    if (notificationsEnabled != null) {
      updates['notificationsEnabled'] = notificationsEnabled;
    }
    if (biometricAuthEnabled != null) {
      updates['biometricAuthEnabled'] = biometricAuthEnabled;
    }

    await _usersCollection.doc(user.uid).update(updates);

    _log.info('Preferences updated successfully', tag: LogTags.auth);
    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<void> deleteAccount() async {
    _log.warning('Deleting user account', tag: LogTags.auth);
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _log.error(
        'Cannot delete account: user not authenticated',
        tag: LogTags.auth,
      );
      throw const AuthException(message: 'User not authenticated');
    }

    // Delete Firestore document
    await _usersCollection.doc(user.uid).delete();
    _log.debug('User document deleted from Firestore', tag: LogTags.auth);

    // Delete Firebase Auth account
    await user.delete();
    _log.info('User account deleted successfully', tag: LogTags.auth);
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    _log.debug(
      'Checking if email is registered',
      tag: LogTags.auth,
      data: {'email': email},
    );
    // Instead of using deprecated fetchSignInMethodsForEmail,
    // check Firestore for existing user with this email.
    // This is more secure and doesn't expose email enumeration.
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      final isRegistered = querySnapshot.docs.isNotEmpty;
      _log.debug(
        'Email registration check result',
        tag: LogTags.auth,
        data: {'isRegistered': isRegistered},
      );
      return isRegistered;
    } catch (e) {
      // If query fails, assume email is not registered
      // This prevents email enumeration attacks
      _log.warning(
        'Email registration check failed, assuming not registered',
        tag: LogTags.auth,
      );
      return false;
    }
  }

  @override
  Future<bool> verifyPassword(String password) async {
    _log.debug('Verifying user password', tag: LogTags.auth);
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      _log.error(
        'Cannot verify password: user not authenticated',
        tag: LogTags.auth,
      );
      throw const AuthException(message: 'User not authenticated');
    }

    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      _log.debug('Password verification successful', tag: LogTags.auth);
      return true;
    } on firebase_auth.FirebaseAuthException {
      _log.debug('Password verification failed', tag: LogTags.auth);
      return false;
    }
  }

  @override
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _log.info('Updating user password', tag: LogTags.auth);
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      _log.error(
        'Cannot update password: user not authenticated',
        tag: LogTags.auth,
      );
      throw const AuthException(message: 'User not authenticated');
    }

    try {
      // Re-authenticate first
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      _log.info('Password updated successfully', tag: LogTags.auth);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Failed to update password',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Get user from Firestore, creating the document if it doesn't exist
  Future<UserModel> _getUserFromFirestore(String uid) async {
    _log.debug(
      'Fetching user from Firestore',
      tag: LogTags.auth,
      data: {'uid': uid},
    );
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      _log.warning(
        'User document not found in Firestore, creating one',
        tag: LogTags.auth,
        data: {'uid': uid},
      );
      // Get the Firebase Auth user to get email and display name
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        _log.error(
          'Cannot create user document: Firebase user is null',
          tag: LogTags.auth,
        );
        throw const ServerException(message: 'User not authenticated');
      }
      
      // Create a new user document
      final userModel = UserModel(
        id: uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
      
      await _usersCollection.doc(uid).set(userModel.toFirestoreCreate());
      _log.info(
        'Created missing user document',
        tag: LogTags.auth,
        data: {'uid': uid},
      );
      
      // Fetch the newly created document
      final newDoc = await _usersCollection.doc(uid).get();
      return UserModel.fromFirestore(newDoc);
    }
    return UserModel.fromFirestore(doc);
  }

  /// Update last active timestamp (uses set with merge to handle missing documents)
  Future<void> _updateLastActive(String uid) async {
    _log.debug(
      'Updating last active timestamp',
      tag: LogTags.auth,
      data: {'uid': uid},
    );
    await _usersCollection.doc(uid).set({
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(firebase_auth.PhoneAuthCredential credential) verificationCompleted,
    required void Function(firebase_auth.FirebaseAuthException error) verificationFailed,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    _log.info(
      'Initiating phone verification',
      tag: LogTags.auth,
      data: {'phoneNumber': phoneNumber},
    );

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Future<UserModel> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    _log.info('Verifying phone OTP', tag: LogTags.auth);
    
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // If user is already signed in, link the phone credential
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
        _log.info('Phone number linked to existing user', tag: LogTags.auth);
        return await markPhoneVerified();
      }

      // Otherwise, sign in with the phone credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(message: 'Phone verification failed');
      }

      // Check if user document exists, create if not
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          phone: user.phoneNumber,
          isPhoneVerified: true,
        );
        await _usersCollection.doc(user.uid).set(userModel.toFirestoreCreate());
      } else {
        // Update phone number and verification status
        await _usersCollection.doc(user.uid).update({
          'phone': user.phoneNumber,
          'isPhoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Phone OTP verification failed',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> linkPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    _log.info('Linking phone number to user', tag: LogTags.auth);
    
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.linkWithCredential(credential);
      
      // Update Firestore with the phone number
      await _usersCollection.doc(user.uid).update({
        'phone': user.phoneNumber,
        'isPhoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log.info('Phone number linked successfully', tag: LogTags.auth);
      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'Failed to link phone number',
        tag: LogTags.auth,
        data: {'code': e.code, 'message': e.message},
      );
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<bool> isPhoneRegistered(String phone) async {
    _log.debug(
      'Checking if phone is registered',
      tag: LogTags.auth,
      data: {'phone': phone},
    );
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      final querySnapshot = await _usersCollection
          .where('phone', isEqualTo: normalizedPhone)
          .where('isPhoneVerified', isEqualTo: true)
          .limit(1)
          .get();
      final isRegistered = querySnapshot.docs.isNotEmpty;
      _log.debug(
        'Phone registration check result',
        tag: LogTags.auth,
        data: {'isRegistered': isRegistered},
      );
      return isRegistered;
    } catch (e) {
      _log.warning(
        'Phone registration check failed',
        tag: LogTags.auth,
      );
      return false;
    }
  }

  @override
  Future<bool> isEmailRegisteredByOther(String email, String currentUserId) async {
    _log.debug(
      'Checking if email is registered by another user',
      tag: LogTags.auth,
      data: {'email': email, 'currentUserId': currentUserId},
    );
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(2)
          .get();
      
      // Check if any user other than current user has this email
      for (final doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _log.warning(
        'Email registration check failed',
        tag: LogTags.auth,
      );
      return false;
    }
  }

  @override
  Future<bool> isPhoneRegisteredByOther(String phone, String currentUserId) async {
    _log.debug(
      'Checking if phone is registered by another user',
      tag: LogTags.auth,
      data: {'phone': phone, 'currentUserId': currentUserId},
    );
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      final querySnapshot = await _usersCollection
          .where('phone', isEqualTo: normalizedPhone)
          .where('isPhoneVerified', isEqualTo: true)
          .limit(2)
          .get();
      
      // Check if any user other than current user has this phone
      for (final doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _log.warning(
        'Phone registration check failed',
        tag: LogTags.auth,
      );
      return false;
    }
  }

  @override
  Future<UserModel> markPhoneVerified() async {
    _log.info('Marking phone as verified', tag: LogTags.auth);
    
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    await _usersCollection.doc(user.uid).update({
      'isPhoneVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<UserModel> updateProfileWithEmail({
    required String email,
    String? displayName,
    String? phone,
  }) async {
    _log.info(
      'Updating profile with email',
      tag: LogTags.auth,
      data: {'email': email, 'displayName': displayName, 'phone': phone},
    );
    
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    // Update Firebase Auth profile
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }

    // Update Firestore
    final updates = <String, dynamic>{
      'email': email.toLowerCase().trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (phone != null) updates['phone'] = phone;

    await _usersCollection.doc(user.uid).update(updates);

    return await _getUserFromFirestore(user.uid);
  }

  /// Normalize phone number for consistent storage
  String _normalizePhoneNumber(String phone) {
    // Remove spaces and dashes
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Ensure it starts with +
    if (!normalized.startsWith('+')) {
      // Assume Indian number if no country code
      if (normalized.length == 10) {
        normalized = '+91$normalized';
      }
    }
    
    return normalized;
  }

  /// Map Firebase Auth exceptions to custom exceptions
  AuthException _mapFirebaseAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          message: 'No user found with this email',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthException(
          message: 'Incorrect password',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'Email is already registered',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Password is too weak',
          code: 'weak-password',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Invalid email address',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many attempts. Please try again later',
          code: 'too-many-requests',
        );
      case 'operation-not-allowed':
        return const AuthException(
          message: 'This sign-in method is not enabled',
          code: 'operation-not-allowed',
        );
      case 'requires-recent-login':
        return const AuthException(
          message: 'Please sign in again to continue',
          code: 'requires-recent-login',
        );
      case 'invalid-verification-code':
        return const AuthException(
          message: 'Invalid OTP code. Please try again',
          code: 'invalid-verification-code',
        );
      case 'invalid-verification-id':
        return const AuthException(
          message: 'Verification session expired. Please request a new OTP',
          code: 'invalid-verification-id',
        );
      case 'credential-already-in-use':
        return const AuthException(
          message: 'This phone number is already linked to another account',
          code: 'credential-already-in-use',
        );
      default:
        return AuthException(
          message: e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}
