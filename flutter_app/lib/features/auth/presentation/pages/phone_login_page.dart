import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/logging_service.dart';

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
  String _selectedCountryCode = '+91'; // Default to India

  // Track the phone number that verification was initiated for
  String? _verifyingPhoneNumber;
  // Flag to track if we've navigated to OTP screen
  bool _navigatedToOtp = false;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': 'India'},
    {'code': '+1', 'country': 'USA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+61', 'country': 'Australia'},
    {'code': '+971', 'country': 'UAE'},
    {'code': '+65', 'country': 'Singapore'},
    {'code': '+60', 'country': 'Malaysia'},
    {'code': '+49', 'country': 'Germany'},
    {'code': '+33', 'country': 'France'},
    {'code': '+81', 'country': 'Japan'},
  ];

  @override
  void initState() {
    super.initState();
    _log.info('PhoneLoginPage opened', tag: LogTags.ui);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    return '$_selectedCountryCode${_phoneController.text.trim()}';
  }

  Future<void> _handleAutoVerification(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    // Only handle auto-verification if:
    // 1. We haven't navigated to OTP screen yet
    // 2. The phone number matches what we're verifying
    if (_navigatedToOtp) {
      _log.debug(
        'Skipping auto-verification - already on OTP screen',
        tag: LogTags.auth,
      );
      return;
    }

    if (_verifyingPhoneNumber != _fullPhoneNumber) {
      _log.debug(
        'Skipping auto-verification - phone number mismatch',
        tag: LogTags.auth,
        data: {'verifying': _verifyingPhoneNumber, 'current': _fullPhoneNumber},
      );
      return;
    }

    _log.info('Auto verification completed', tag: LogTags.auth);

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        _log.info('User signed in via auto-verification', tag: LogTags.auth);
        await _ensureUserDocument(userCredential.user!);

        if (mounted) {
          // Check if profile needs completion
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            final hasCompletedProfile =
                data['displayName'] != null &&
                data['displayName'].toString().isNotEmpty;

            if (hasCompletedProfile) {
              context.go('/dashboard');
            } else {
              context.go(
                '/complete-profile',
                extra: {
                  'id': userCredential.user!.uid,
                  'phone': userCredential.user!.phoneNumber,
                  'isPhoneVerified': true,
                },
              );
            }
          } else {
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      _log.error('Auto sign-in failed', tag: LogTags.auth, error: e);
      if (mounted) {
        setState(() => _isLoading = false);
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

    setState(() {
      _isLoading = true;
      _navigatedToOtp = false;
      _verifyingPhoneNumber = _fullPhoneNumber;
    });

    _log.info(
      'Initiating phone verification',
      tag: LogTags.auth,
      data: {'phoneNumber': _fullPhoneNumber},
    );

    try {
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) {
          _handleAutoVerification(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _log.error(
            'Phone verification failed',
            tag: LogTags.auth,
            error: e,
            data: {'code': e.code, 'message': e.message},
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verifyingPhoneNumber = null;
            });
            _showError(_mapFirebaseError(e.code));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _log.info(
            'OTP sent successfully',
            tag: LogTags.auth,
            data: {'verificationId': verificationId},
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _navigatedToOtp = true;
            });
            context
                .push(
                  '/phone-verify',
                  extra: {
                    'verificationId': verificationId,
                    'phoneNumber': _fullPhoneNumber,
                    'resendToken': resendToken,
                  },
                )
                .then((_) {
                  // When returning from OTP screen, reset the flags
                  if (mounted) {
                    setState(() {
                      _navigatedToOtp = false;
                      _verifyingPhoneNumber = null;
                    });
                  }
                });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log.debug(
            'Auto retrieval timeout',
            tag: LogTags.auth,
            data: {'verificationId': verificationId},
          );
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _verifyingPhoneNumber = null;
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
              const Spacer(flex: 1),

              // Phone Form
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(12),
                          items: _countryCodes.map((country) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Text(
                                '${country['code']} ${country['country']}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(
                                      () => _selectedCountryCode = value,
                                    );
                                  }
                                },
                          selectedItemBuilder: (context) {
                            return _countryCodes.map((country) {
                              return Center(
                                child: Text(
                                  country['code']!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              );
                            }).toList();
                          },
                        ),
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
                            return 'Enter a valid phone number';
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
              const Spacer(flex: 1),

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
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
