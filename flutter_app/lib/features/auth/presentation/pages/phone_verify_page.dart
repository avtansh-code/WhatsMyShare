import 'dart:async';

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

/// OTP verification page for phone authentication
class PhoneVerifyPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const PhoneVerifyPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final LoggingService _log = LoggingService();
  final OtpRateLimiterService _otpRateLimiter = OtpRateLimiterService();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = AppConstants.otpResendCooldownSeconds;
  int _requestsRemaining = AppConstants.otpMaxRequestsPerHour;
  bool _isHourlyLimitReached = false;
  Timer? _timer;
  String _currentVerificationId = '';
  int? _currentResendToken;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentResendToken = widget.resendToken;
    _log.info(
      'PhoneVerifyPage opened',
      tag: LogTags.ui,
      data: {'phoneNumber': widget.phoneNumber},
    );
    _initializeRateLimitState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Initialize rate limit state from the OTP rate limiter service
  Future<void> _initializeRateLimitState() async {
    final result = await _otpRateLimiter.checkCanSendOtp(widget.phoneNumber);

    if (!mounted) return;

    setState(() {
      _requestsRemaining = result.requestsRemaining;
      _isHourlyLimitReached = result.isHourlyLimitReached;
    });

    if (result.isHourlyLimitReached) {
      // Don't start timer if hourly limit is reached
      setState(() {
        _canResend = false;
        _resendCountdown = 0;
      });
    } else if (result.cooldownSecondsRemaining > 0) {
      // Start timer with remaining cooldown
      _startResendTimerWithSeconds(result.cooldownSecondsRemaining);
    } else {
      // OTP was just sent, start full cooldown timer
      _startResendTimerWithSeconds(AppConstants.otpResendCooldownSeconds);
    }
  }

  /// Start the resend timer with the specified number of seconds
  void _startResendTimerWithSeconds(int seconds) {
    _resendCountdown = seconds;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        // Re-check rate limit before enabling resend
        _checkAndEnableResend();
        timer.cancel();
      }
    });
  }

  /// Check rate limit and enable resend if allowed
  Future<void> _checkAndEnableResend() async {
    final result = await _otpRateLimiter.checkCanSendOtp(widget.phoneNumber);

    if (!mounted) return;

    setState(() {
      _requestsRemaining = result.requestsRemaining;
      _isHourlyLimitReached = result.isHourlyLimitReached;
      _canResend = result.canSend && !result.isHourlyLimitReached;
    });

    // If there's still cooldown remaining (shouldn't happen normally), restart timer
    if (result.cooldownSecondsRemaining > 0) {
      _startResendTimerWithSeconds(result.cooldownSecondsRemaining);
    }
  }

  void _startResendTimer() {
    _startResendTimerWithSeconds(AppConstants.otpResendCooldownSeconds);
  }

  String get _otp {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOTP() async {
    final otp = _otp;
    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    _log.info('Verifying OTP', tag: LogTags.auth);

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );

      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      _log.info(
        'Phone verification successful',
        tag: LogTags.auth,
        data: {'userId': user.uid},
      );

      // Check/create user document in Firestore
      await _ensureUserDocument(user);

      if (!mounted) return;

      // Check profile completion in both local cache AND backend
      final isProfileComplete = await _checkProfileCompletion(user.uid);

      if (!mounted) return;

      if (isProfileComplete) {
        _log.info(
          'Profile is complete, navigating to dashboard',
          tag: LogTags.auth,
        );
        context.go('/dashboard');
      } else {
        _log.info(
          'Profile incomplete, navigating to complete profile',
          tag: LogTags.auth,
        );
        context.go('/complete-profile');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(
        'OTP verification failed',
        tag: LogTags.auth,
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(_mapFirebaseError(e.code));
        // Clear OTP fields on error
        for (final controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e, stackTrace) {
      _log.error(
        'OTP verification error',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Verification failed. Please try again.');
      }
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
      // Update phone verification status
      await userDoc.update({
        'phone': user.phoneNumber,
        'isPhoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isHourlyLimitReached) return;

    // Check rate limit before sending
    final rateLimitResult = await _otpRateLimiter.checkCanSendOtp(
      widget.phoneNumber,
    );

    if (!rateLimitResult.canSend) {
      if (mounted) {
        setState(() {
          _isHourlyLimitReached = rateLimitResult.isHourlyLimitReached;
          _requestsRemaining = rateLimitResult.requestsRemaining;
        });

        if (rateLimitResult.isHourlyLimitReached) {
          _showError(
            'You have reached the maximum of ${AppConstants.otpMaxRequestsPerHour} OTP requests per hour. Please try again later.',
          );
        } else if (rateLimitResult.cooldownSecondsRemaining > 0) {
          _startResendTimerWithSeconds(
            rateLimitResult.cooldownSecondsRemaining,
          );
        }
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _canResend = false;
    });

    _log.info('Resending OTP', tag: LogTags.auth);

    try {
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              _log.info(
                'Auto verification completed on resend',
                tag: LogTags.auth,
              );
              try {
                final userCredential = await firebase_auth.FirebaseAuth.instance
                    .signInWithCredential(credential);
                if (userCredential.user != null && mounted) {
                  await _ensureUserDocument(userCredential.user!);

                  // Check profile completion before navigation
                  final isProfileComplete = await _checkProfileCompletion(
                    userCredential.user!.uid,
                  );

                  if (mounted) {
                    if (isProfileComplete) {
                      context.go('/dashboard');
                    } else {
                      context.go('/complete-profile');
                    }
                  }
                }
              } catch (e) {
                _log.error('Auto sign-in failed', tag: LogTags.auth, error: e);
              }
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _log.error('Resend verification failed', tag: LogTags.auth, error: e);
          if (mounted) {
            setState(() => _isLoading = false);
            _showError(_mapFirebaseError(e.code));
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          _log.info('OTP resent successfully', tag: LogTags.auth);

          // Record the OTP request in the rate limiter
          await _otpRateLimiter.recordOtpRequest(widget.phoneNumber);

          if (mounted) {
            // Update requests remaining
            final updatedResult = await _otpRateLimiter.checkCanSendOtp(
              widget.phoneNumber,
            );

            setState(() {
              _isLoading = false;
              _currentVerificationId = verificationId;
              _currentResendToken = resendToken;
              _requestsRemaining = updatedResult.requestsRemaining;
              _isHourlyLimitReached = updatedResult.isHourlyLimitReached;
            });

            _startResendTimer();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'OTP sent successfully. $_requestsRemaining request${_requestsRemaining == 1 ? '' : 's'} remaining this hour.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _currentVerificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _currentResendToken,
      );
    } catch (e) {
      _log.error('Failed to resend OTP', tag: LogTags.auth, error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to resend OTP. Please try again.');
      }
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'invalid-verification-id':
        return 'Session expired. Please request a new OTP.';
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      default:
        return 'Verification failed. Please try again.';
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

  void _onOTPChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-verify when all digits are entered
    if (_otp.length == 6) {
      _verifyOTP();
    }
  }

  void _onOTPKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                Icons.sms_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Enter verification code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'We sent a 6-digit code to',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onOTPKeyDown(index, event),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_isLoading,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _otpControllers[index].text.isNotEmpty
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.3,
                                )
                              : null,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOTPChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Verify Button
              FilledButton(
                onPressed: _isLoading ? null : _verifyOTP,
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
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Resend OTP
              if (_isHourlyLimitReached)
                // Hourly limit reached message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have reached the maximum of ${AppConstants.otpMaxRequestsPerHour} OTP requests per hour. Please try again later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: _isLoading ? null : _resendOTP,
                            child: Text('Resend ($_requestsRemaining left)'),
                          )
                        else
                          Text(
                            'Resend in ${_resendCountdown}s',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    // Show remaining requests info
                    if (_requestsRemaining < AppConstants.otpMaxRequestsPerHour)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$_requestsRemaining OTP request${_requestsRemaining == 1 ? '' : 's'} remaining this hour',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // Change Number
              TextButton.icon(
                onPressed: _isLoading ? null : () => context.pop(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change phone number'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if user profile is complete in both local cache and backend
  /// Profile is complete if displayName exists and is not empty
  Future<bool> _checkProfileCompletion(String userId) async {
    _log.debug(
      'Checking profile completion',
      tag: LogTags.auth,
      data: {'userId': userId},
    );

    // 1. First check local cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDisplayName = prefs.getString('user_display_name_$userId');

      if (localDisplayName != null && localDisplayName.isNotEmpty) {
        _log.debug(
          'Profile complete in local cache',
          tag: LogTags.auth,
          data: {'displayName': localDisplayName},
        );

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
        _log.debug(
          'Profile complete in UserCacheService',
          tag: LogTags.auth,
          data: {'displayName': cachedUser.displayName},
        );
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

        _log.debug(
          'Backend profile check',
          tag: LogTags.auth,
          data: {
            'userId': userId,
            'displayName': displayName,
            'isComplete': isComplete,
          },
        );

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

      _log.debug(
        'User document does not exist in backend',
        tag: LogTags.auth,
        data: {'userId': userId},
      );
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
}
