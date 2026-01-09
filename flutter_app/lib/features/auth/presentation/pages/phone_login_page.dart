import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/otp_rate_limiter_service.dart';
import '../../../../core/services/user_cache_service.dart';

/// Callback type for verification received
typedef VerificationCallback =
    void Function(String verificationId, String phoneNumber, int? resendToken);

/// Singleton to hold pending phone verification state
/// This persists across page rebuilds when returning from reCAPTCHA
class PendingPhoneVerification {
  static final PendingPhoneVerification _instance =
      PendingPhoneVerification._();
  factory PendingPhoneVerification() => _instance;
  PendingPhoneVerification._();

  String? verificationId;
  String? phoneNumber;
  int? resendToken;
  bool isVerifying = false;

  // Listeners for when verification is received
  final List<VerificationCallback> _listeners = [];

  void addListener(VerificationCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(VerificationCallback callback) {
    _listeners.remove(callback);
  }

  void notifyListeners() {
    if (verificationId != null && phoneNumber != null) {
      final vId = verificationId!;
      final phone = phoneNumber!;
      final token = resendToken;
      for (final listener in _listeners.toList()) {
        listener(vId, phone, token);
      }
    }
  }

  void clear() {
    verificationId = null;
    phoneNumber = null;
    resendToken = null;
    isVerifying = false;
  }

  bool get hasPendingVerification =>
      verificationId != null && phoneNumber != null;
}

/// Phone login page for phone number authentication
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final LoggingService _log = LoggingService();
  bool _isLoading = false;
  bool _hasNavigatedToOtp = false;

  @override
  void initState() {
    super.initState();
    _log.info('PhoneLoginPage opened', tag: LogTags.ui);

    // Add listener for verification data
    PendingPhoneVerification().addListener(_onVerificationReceived);

    // Check if there's already pending verification from before reCAPTCHA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingVerification();
    });
  }

  @override
  void dispose() {
    PendingPhoneVerification().removeListener(_onVerificationReceived);
    _phoneController.dispose();
    super.dispose();
  }

  /// Called when verification data is received (from codeSent callback)
  void _onVerificationReceived(
    String verificationId,
    String phoneNumber,
    int? resendToken,
  ) {
    if (!mounted || _hasNavigatedToOtp) return;

    _log.info(
      'Verification received via listener - navigating to OTP screen',
      tag: LogTags.auth,
      data: {'phoneNumber': phoneNumber},
    );

    _hasNavigatedToOtp = true;
    PendingPhoneVerification().clear();

    setState(() {
      _isLoading = false;
    });

    context.push(
      '/phone-verify',
      extra: {
        'verificationId': verificationId,
        'phoneNumber': phoneNumber,
        'resendToken': resendToken,
      },
    );
  }

  /// Check if there's a pending verification and navigate to OTP screen
  void _checkPendingVerification() {
    if (_hasNavigatedToOtp) return;

    final pending = PendingPhoneVerification();
    if (pending.hasPendingVerification && mounted) {
      _log.info(
        'Found pending verification - navigating to OTP screen',
        tag: LogTags.auth,
        data: {
          'phoneNumber': pending.phoneNumber,
          'hasVerificationId': pending.verificationId != null,
        },
      );

      _hasNavigatedToOtp = true;
      final verificationId = pending.verificationId!;
      final phoneNumber = pending.phoneNumber!;
      final resendToken = pending.resendToken;
      pending.clear();

      context.push(
        '/phone-verify',
        extra: {
          'verificationId': verificationId,
          'phoneNumber': phoneNumber,
          'resendToken': resendToken,
        },
      );
    }
  }

  String get _fullPhoneNumber {
    return '${AppConstants.countryCode}${_phoneController.text.trim()}';
  }

  Future<void> _handleAutoVerification(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    _log.info('Auto verification completed', tag: LogTags.auth);

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        _log.info('User signed in via auto-verification', tag: LogTags.auth);
        await _ensureUserDocument(userCredential.user!);

        if (!mounted) return;

        // Check if profile needs completion using local cache and backend
        final isProfileComplete = await _checkProfileCompletion(
          userCredential.user!.uid,
        );

        if (!mounted) return;

        if (isProfileComplete) {
          context.go('/dashboard');
        } else {
          context.go('/complete-profile');
        }
      }
    } catch (e) {
      _log.error('Auto sign-in failed', tag: LogTags.auth, error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if user profile is complete in both local cache and backend
  Future<bool> _checkProfileCompletion(String userId) async {
    // 1. First check local cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDisplayName = prefs.getString('user_display_name_$userId');

      if (localDisplayName != null && localDisplayName.isNotEmpty) {
        // Also verify with backend to ensure consistency
        final backendComplete = await _checkBackendProfileCompletion(userId);
        if (backendComplete) {
          return true;
        }
      }
    } catch (e) {
      _log.warning(
        'Failed to check local cache',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
    }

    // 2. Check UserCacheService (in-memory cache)
    try {
      final userCacheService = sl<UserCacheService>();
      final cachedUser = await userCacheService.getUser(userId);

      if (cachedUser != null &&
          cachedUser.displayName != null &&
          cachedUser.displayName!.isNotEmpty) {
        return true;
      }
    } catch (e) {
      _log.warning(
        'Failed to check UserCacheService',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
    }

    // 3. Finally check backend (Firestore)
    return await _checkBackendProfileCompletion(userId);
  }

  /// Check if profile is complete in Firestore backend
  Future<bool> _checkBackendProfileCompletion(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final displayName = data['displayName'] as String?;
        final isComplete = displayName != null && displayName.isNotEmpty;

        // If profile is complete in backend, save to local cache for future use
        if (isComplete) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_display_name_$userId', displayName);

            // Also update UserCacheService
            final userCacheService = sl<UserCacheService>();
            userCacheService.updateCache(
              userId,
              CachedUser(
                id: userId,
                displayName: displayName,
                phone: data['phone'] as String?,
                photoUrl: data['photoUrl'] as String?,
                cachedAt: DateTime.now(),
              ),
            );
          } catch (e) {
            _log.warning(
              'Failed to update local cache from backend',
              tag: LogTags.auth,
              data: {'error': e.toString()},
            );
          }
        }

        return isComplete;
      }

      return false;
    } catch (e) {
      _log.error(
        'Failed to check backend profile completion',
        tag: LogTags.auth,
        error: e,
      );
      return false;
    }
  }

  Future<void> _ensureUserDocument(firebase_auth.User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      _log.info('Creating user document for phone user', tag: LogTags.auth);
      await userDoc.set({
        'id': user.uid,
        'phone': user.phoneNumber,
        'isPhoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'phone': user.phoneNumber,
        'isPhoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _onSendOTP() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _log.debug('Phone form validation failed', tag: LogTags.ui);
      return;
    }

    final phoneNumber = _fullPhoneNumber;

    // Check rate limit before sending OTP
    final otpRateLimiter = OtpRateLimiterService();
    final rateLimitResult = await otpRateLimiter.checkCanSendOtp(phoneNumber);

    if (!rateLimitResult.canSend) {
      if (rateLimitResult.isHourlyLimitReached) {
        _showError(
          'You have reached the maximum of ${AppConstants.otpMaxRequestsPerHour} OTP requests per hour. Please try again later.',
        );
      } else if (rateLimitResult.cooldownSecondsRemaining > 0) {
        _showError(
          'Please wait ${rateLimitResult.cooldownSecondsRemaining} seconds before requesting another OTP.',
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasNavigatedToOtp = false;
    });

    _log.info(
      'Initiating phone verification',
      tag: LogTags.auth,
      data: {'phoneNumber': phoneNumber},
    );

    // Mark that we're verifying - this persists across page rebuilds
    final pending = PendingPhoneVerification();
    pending.isVerifying = true;
    pending.phoneNumber = phoneNumber;

    try {
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) {
          pending.clear();
          _handleAutoVerification(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _log.error(
            'Phone verification failed',
            tag: LogTags.auth,
            error: e,
            data: {'code': e.code, 'message': e.message},
          );
          pending.clear();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showError(_mapFirebaseError(e.code));
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          _log.info(
            'OTP sent successfully',
            tag: LogTags.auth,
            data: {'verificationId': verificationId},
          );

          // Record the OTP request in the rate limiter
          await otpRateLimiter.recordOtpRequest(phoneNumber);

          // Store in singleton and notify all listeners
          pending.verificationId = verificationId;
          pending.resendToken = resendToken;

          // Notify listeners (this will trigger navigation on the active page)
          pending.notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log.debug(
            'Auto retrieval timeout',
            tag: LogTags.auth,
            data: {'verificationId': verificationId},
          );
          // Update the verification ID in case it changed
          if (pending.isVerifying && pending.verificationId == null) {
            pending.verificationId = verificationId;
            pending.notifyListeners();
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stackTrace) {
      _log.error(
        'Failed to initiate phone verification',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      pending.clear();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to send OTP. Please try again.');
      }
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      case 'captcha-check-failed':
        return 'Verification failed. Please try again.';
      case 'web-internal-error':
        // This error occurs when reCAPTCHA fails to load
        // Common on iOS Simulator where APNs is not available
        return 'Phone verification is not available on this device. Please use a physical device or configure test phone numbers in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'missing-client-identifier':
        return 'App verification failed. Please restart the app and try again.';
      case 'invalid-app-credential':
        return 'App verification failed. Please update the app or contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Phone'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Icon
              Icon(
                Icons.phone_android,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Enter your phone number',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'We will send you a verification code to confirm your identity',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Phone Form
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code (India only - hardcoded +91)
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            AppConstants.countryCode,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Phone Number Field
                    Expanded(
                      child: TextFormField(
                        key: const Key('phoneField'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '10 digit number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        onFieldSubmitted: (_) => _onSendOTP(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length < 10) {
                            return 'Enter a valid 10 digit phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Send OTP Button
              FilledButton(
                onPressed: _isLoading ? null : _onSendOTP,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Standard SMS rates may apply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
