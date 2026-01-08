import 'failures.dart';
import 'exceptions.dart';

/// Centralized error messages for user-friendly display
/// Ready for localization (l10n)
class ErrorMessages {
  // ==================== Authentication ====================
  static const String authInvalidEmail = 'Please enter a valid email address.';
  static const String authInvalidPassword =
      'Password must be at least 6 characters.';
  static const String authUserNotFound =
      'No account found with this email. Please sign up.';
  static const String authWrongPassword =
      'Incorrect password. Please try again.';
  static const String authEmailInUse =
      'An account already exists with this email.';
  static const String authWeakPassword = 'Please choose a stronger password.';
  static const String authSignInFailed = 'Sign in failed. Please try again.';
  static const String authSignUpFailed = 'Sign up failed. Please try again.';
  static const String authSignOutFailed = 'Sign out failed. Please try again.';
  static const String authResetPasswordFailed =
      'Failed to send password reset email.';
  static const String authGoogleSignInCancelled =
      'Google sign in was cancelled.';
  static const String authGoogleSignInFailed =
      'Google sign in failed. Please try again.';
  static const String authSessionExpired =
      'Your session has expired. Please sign in again.';
  static const String authUnauthorized =
      'You are not authorized to perform this action.';

  // ==================== Profile ====================
  static const String profileLoadFailed =
      'Failed to load profile. Please try again.';
  static const String profileUpdateFailed =
      'Failed to update profile. Please try again.';
  static const String profilePhotoUploadFailed =
      'Failed to upload profile photo.';
  static const String profileNotFound = 'Profile not found.';
  static const String profileNameRequired = 'Please enter your name.';
  static const String profileNameTooShort =
      'Name must be at least 2 characters.';

  // ==================== Groups ====================
  static const String groupCreateFailed =
      'Failed to create group. Please try again.';
  static const String groupUpdateFailed =
      'Failed to update group. Please try again.';
  static const String groupDeleteFailed =
      'Failed to delete group. Please try again.';
  static const String groupLoadFailed =
      'Failed to load groups. Please try again.';
  static const String groupNotFound = 'Group not found.';
  static const String groupNameRequired = 'Please enter a group name.';
  static const String groupNameTooShort =
      'Group name must be at least 2 characters.';
  static const String groupMemberAddFailed = 'Failed to add member to group.';
  static const String groupMemberRemoveFailed =
      'Failed to remove member from group.';
  static const String groupAlreadyMember =
      'This person is already a member of the group.';
  static const String groupCannotRemoveSelf =
      'You cannot remove yourself from the group.';
  static const String groupCannotLeaveOwner =
      'The group owner cannot leave. Transfer ownership first.';

  // ==================== Expenses ====================
  static const String expenseCreateFailed =
      'Failed to create expense. Please try again.';
  static const String expenseUpdateFailed =
      'Failed to update expense. Please try again.';
  static const String expenseDeleteFailed =
      'Failed to delete expense. Please try again.';
  static const String expenseLoadFailed =
      'Failed to load expenses. Please try again.';
  static const String expenseNotFound = 'Expense not found.';
  static const String expenseDescriptionRequired =
      'Please enter a description.';
  static const String expenseAmountRequired = 'Please enter an amount.';
  static const String expenseAmountInvalid = 'Please enter a valid amount.';
  static const String expenseAmountZero = 'Amount must be greater than zero.';
  static const String expensePayerRequired =
      'Please select at least one payer.';
  static const String expenseSplitRequired =
      'Please select at least one person to split with.';
  static const String expenseSplitMismatch =
      'Split amounts must equal the total expense.';
  static const String expenseReceiptUploadFailed = 'Failed to upload receipt.';

  // ==================== Settlements ====================
  static const String settlementCreateFailed =
      'Failed to record settlement. Please try again.';
  static const String settlementUpdateFailed =
      'Failed to update settlement. Please try again.';
  static const String settlementLoadFailed =
      'Failed to load settlements. Please try again.';
  static const String settlementNotFound = 'Settlement not found.';
  static const String settlementAmountInvalid =
      'Please enter a valid settlement amount.';
  static const String settlementAmountExceeds =
      'Settlement amount exceeds the owed amount.';
  static const String settlementBiometricFailed =
      'Biometric verification failed.';
  static const String settlementConfirmationFailed =
      'Settlement confirmation failed.';

  // ==================== Chat ====================
  static const String chatLoadFailed = 'Failed to load chat messages.';
  static const String chatSendFailed =
      'Failed to send message. Please try again.';
  static const String chatDeleteFailed = 'Failed to delete message.';
  static const String chatImageUploadFailed = 'Failed to upload image.';
  static const String chatVoiceNoteUploadFailed =
      'Failed to upload voice note.';
  static const String chatRecordingFailed =
      'Failed to start recording. Check microphone permission.';
  static const String chatPlaybackFailed = 'Failed to play voice note.';

  // ==================== Notifications ====================
  static const String notificationLoadFailed = 'Failed to load notifications.';
  static const String notificationUpdateFailed =
      'Failed to update notification.';
  static const String notificationDeleteFailed =
      'Failed to delete notification.';
  static const String notificationMarkReadFailed =
      'Failed to mark notification as read.';
  static const String notificationPermissionDenied =
      'Notification permission denied.';
  static const String notificationPreferencesLoadFailed =
      'Failed to load notification preferences.';
  static const String notificationPreferencesSaveFailed =
      'Failed to save notification preferences.';
  static const String notificationActivityLoadFailed =
      'Failed to load activity feed.';

  // ==================== Network ====================
  static const String networkNoConnection =
      'No internet connection. Please check your network.';
  static const String networkTimeout =
      'Connection timed out. Please try again.';
  static const String networkServerError =
      'Server error. Please try again later.';
  static const String networkUnknownError =
      'An unexpected error occurred. Please try again.';

  // ==================== Offline ====================
  static const String offlineModeActive =
      'You are offline. Changes will be synced when online.';
  static const String offlineSyncFailed =
      'Failed to sync changes. Will retry automatically.';
  static const String offlineSyncPending = 'Some changes are pending sync.';

  // ==================== Storage ====================
  static const String storageUploadFailed = 'Failed to upload file.';
  static const String storageDownloadFailed = 'Failed to download file.';
  static const String storageDeleteFailed = 'Failed to delete file.';
  static const String storageFileTooLarge =
      'File is too large. Maximum size is 10MB.';
  static const String storageInvalidFileType = 'Invalid file type.';

  // ==================== Permissions ====================
  static const String permissionCameraRequired =
      'Camera permission is required to take photos.';
  static const String permissionPhotoLibraryRequired =
      'Photo library permission is required.';
  static const String permissionMicrophoneRequired =
      'Microphone permission is required to record voice notes.';
  static const String permissionContactsRequired =
      'Contacts permission is required to add friends.';

  // ==================== Generic ====================
  static const String genericError = 'Something went wrong. Please try again.';
  static const String genericRetry = 'Please try again.';
  static const String genericLoading = 'Loading...';
  static const String genericSaving = 'Saving...';
  static const String genericDeleting = 'Deleting...';

  // ==================== Helper Methods ====================

  /// Get user-friendly message from Failure
  static String fromFailure(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message.isNotEmpty ? failure.message : networkServerError;
    } else if (failure is NetworkFailure) {
      return networkNoConnection;
    } else if (failure is CacheFailure) {
      return 'Failed to load cached data.';
    } else if (failure is AuthFailure) {
      return failure.message.isNotEmpty ? failure.message : authSignInFailed;
    }
    return genericError;
  }

  /// Get user-friendly message from Exception
  static String fromException(Object exception) {
    if (exception is ServerException) {
      return exception.message.isNotEmpty
          ? exception.message
          : networkServerError;
    } else if (exception is NetworkException) {
      return networkNoConnection;
    } else if (exception is CacheException) {
      return 'Failed to access local storage.';
    } else if (exception is AuthException) {
      return _getAuthExceptionMessage(exception.code);
    }
    return genericError;
  }

  /// Map Firebase Auth error codes to user-friendly messages
  static String _getAuthExceptionMessage(String? code) {
    switch (code) {
      case 'user-not-found':
        return authUserNotFound;
      case 'wrong-password':
        return authWrongPassword;
      case 'email-already-in-use':
        return authEmailInUse;
      case 'weak-password':
        return authWeakPassword;
      case 'invalid-email':
        return authInvalidEmail;
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return networkNoConnection;
      default:
        return authSignInFailed;
    }
  }

  /// Get validation error message
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return authInvalidEmail;
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 6) {
      return authInvalidPassword;
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return profileNameRequired;
    }
    if (name.length < 2) {
      return profileNameTooShort;
    }
    return null;
  }

  static String? validateAmount(String? amount) {
    if (amount == null || amount.isEmpty) {
      return expenseAmountRequired;
    }
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      return expenseAmountInvalid;
    }
    if (parsedAmount <= 0) {
      return expenseAmountZero;
    }
    return null;
  }
}
