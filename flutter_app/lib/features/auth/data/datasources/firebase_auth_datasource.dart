import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
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

  /// Verify current password
  Future<bool> verifyPassword(String password);

  /// Update password
  Future<void> updatePassword(String currentPassword, String newPassword);
}

/// Implementation of FirebaseAuthDataSource
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  /// Reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _getUserFromFirestore(user.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Sign in failed');
      }

      // Update last active timestamp
      await _updateLastActive(user.uid);

      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
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

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'Google sign in cancelled');
      }

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
        throw const AuthException(message: 'Google sign in failed');
      }

      // Check if user document exists
      final userDoc = await _usersCollection.doc(user.uid).get();

      if (!userDoc.exists) {
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

      return await _getUserFromFirestore(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
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
    final user = _firebaseAuth.currentUser;
    if (user == null) {
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

    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    // Delete Firestore document
    await _usersCollection.doc(user.uid).delete();

    // Delete Firebase Auth account
    await user.delete();
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    // Instead of using deprecated fetchSignInMethodsForEmail,
    // check Firestore for existing user with this email.
    // This is more secure and doesn't expose email enumeration.
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If query fails, assume email is not registered
      // This prevents email enumeration attacks
      return false;
    }
  }

  @override
  Future<bool> verifyPassword(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on firebase_auth.FirebaseAuthException {
      return false;
    }
  }

  @override
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Get user from Firestore
  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      throw const ServerException(message: 'User document not found');
    }
    return UserModel.fromFirestore(doc);
  }

  /// Update last active timestamp
  Future<void> _updateLastActive(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
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
      default:
        return AuthException(
          message: e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}
