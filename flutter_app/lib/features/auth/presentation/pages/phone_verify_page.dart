import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/logging_service.dart';

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

  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;
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
    _startResendTimer();
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

  void _startResendTimer() {
    _resendCountdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
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

      if (mounted) {
        // Check if user needs to complete profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final hasCompletedProfile =
              data['displayName'] != null &&
              data['displayName'].toString().isNotEmpty;

          if (hasCompletedProfile) {
            context.go('/dashboard');
          } else {
            // Navigate to complete profile
            context.go(
              '/complete-profile',
              extra: {
                'id': user.uid,
                'phone': user.phoneNumber,
                'isPhoneVerified': true,
              },
            );
          }
        } else {
          context.go('/dashboard');
        }
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
    if (!_canResend) return;

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
                  context.go('/dashboard');
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
        codeSent: (String verificationId, int? resendToken) {
          _log.info('OTP resent successfully', tag: LogTags.auth);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentVerificationId = verificationId;
              _currentResendToken = resendToken;
            });
            _startResendTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully'),
                backgroundColor: Colors.green,
              ),
            );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

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
              const Spacer(flex: 1),

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
                              ? theme.colorScheme.primaryContainer.withOpacity(
                                  0.3,
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
                      child: const Text('Resend'),
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
              const Spacer(flex: 1),

              // Change Number
              TextButton.icon(
                onPressed: _isLoading ? null : () => context.pop(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change phone number'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
