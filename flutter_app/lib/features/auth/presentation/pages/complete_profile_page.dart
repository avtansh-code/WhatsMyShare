import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';

/// Page for completing user profile with required information
class CompleteProfilePage extends StatefulWidget {
  final UserEntity user;

  const CompleteProfilePage({super.key, required this.user});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final LoggingService _log = LoggingService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingPhone = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;
  String? _emailWarning;
  String? _phoneWarning;

  late FirebaseAuthDataSource _authDataSource;

  @override
  void initState() {
    super.initState();
    _log.info('CompleteProfilePage opened', tag: LogTags.ui);
    _authDataSource = sl<FirebaseAuthDataSource>();

    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailUniqueness() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || email == widget.user.email) {
      setState(() => _emailWarning = null);
      return;
    }

    final isRegisteredByOther = await _authDataSource.isEmailRegisteredByOther(
      email,
      widget.user.id,
    );

    setState(() {
      _emailWarning = isRegisteredByOther
          ? 'This email is already associated with another account'
          : null;
    });
  }

  Future<void> _checkPhoneUniqueness() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneWarning = null);
      return;
    }

    final isRegisteredByOther = await _authDataSource.isPhoneRegisteredByOther(
      phone,
      widget.user.id,
    );

    setState(() {
      _phoneWarning = isRegisteredByOther
          ? 'This phone number is already associated with another account'
          : null;
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a phone number');
      return;
    }

    // Check if phone is already registered by another user
    await _checkPhoneUniqueness();
    if (_phoneWarning != null) {
      setState(() => _errorMessage = _phoneWarning);
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
      _errorMessage = null;
    });

    // Normalize phone number
    String normalizedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!normalizedPhone.startsWith('+')) {
      if (normalizedPhone.length == 10) {
        normalizedPhone = '+91$normalizedPhone';
      }
    }

    try {
      await _authDataSource.signInWithPhone(
        phoneNumber: normalizedPhone,
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isVerifyingPhone = false;
          });
          _log.info('OTP sent successfully', tag: LogTags.auth);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationCompleted: (credential) async {
          _log.info('Auto verification completed', tag: LogTags.auth);
          await _verifyWithCredential(credential);
        },
        verificationFailed: (error) {
          _log.error(
            'Phone verification failed',
            tag: LogTags.auth,
            data: {'code': error.code, 'message': error.message},
          );
          setState(() {
            _isVerifyingPhone = false;
            _errorMessage = error.message ?? 'Phone verification failed';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        resendToken: _resendToken,
      );
    } catch (e) {
      setState(() {
        _isVerifyingPhone = false;
        _errorMessage = 'Failed to send OTP: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      setState(
        () => _errorMessage =
            'Verification session expired. Please request a new OTP',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authDataSource.linkPhoneNumber(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Update name if changed
      if (_nameController.text.trim() != widget.user.displayName) {
        await _authDataSource.updateProfile(
          displayName: _nameController.text.trim(),
        );
      }

      _log.info('Profile completed successfully', tag: LogTags.auth);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh auth state and navigate to dashboard
        context.read<AuthBloc>().add(const AuthCheckRequested());
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyWithCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    setState(() => _isLoading = true);

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        await _authDataSource.markPhoneVerified();

        // Update name if changed
        if (_nameController.text.trim() != widget.user.displayName) {
          await _authDataSource.updateProfile(
            displayName: _nameController.text.trim(),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<AuthBloc>().add(const AuthCheckRequested());
          context.go('/dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.person_add_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Almost there!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete your profile to continue using the app.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field (read-only for Google users)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: widget.user.email.isNotEmpty
                        ? 'Email from your sign-in method'
                        : null,
                    errorText: _emailWarning,
                  ),
                  readOnly: widget.user.email.isNotEmpty,
                  enabled: widget.user.email.isEmpty,
                  onChanged: (_) => _checkEmailUniqueness(),
                ),
                const SizedBox(height: 16),

                // Phone Field with India country code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed India country code prefix
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            '+91',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Phone number input (10 digits only)
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: 'XXXXXXXXXX',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          errorText: _phoneWarning,
                          suffixIcon: widget.user.isPhoneVerified
                              ? const Icon(Icons.verified, color: Colors.green)
                              : null,
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        enabled: !_isOtpSent && !widget.user.isPhoneVerified,
                        onChanged: (_) => _checkPhoneUniqueness(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final phone = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (phone.length != 10) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          // Validate Indian mobile number format (starts with 6-9)
                          if (!RegExp(r'^[6-9]').hasMatch(phone)) {
                            return 'Indian mobile numbers start with 6, 7, 8 or 9';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // OTP Section
                if (_isOtpSent && !widget.user.isPhoneVerified) ...[
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '6-digit code',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isVerifyingPhone
                            ? null
                            : () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                        child: const Text('Change Number'),
                      ),
                      TextButton(
                        onPressed: _isVerifyingPhone ? null : _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Action Button
                if (widget.user.isPhoneVerified) ...[
                  // Just update name
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _isLoading = true);

                            try {
                              await _authDataSource.updateProfile(
                                displayName: _nameController.text.trim(),
                              );

                              if (mounted) {
                                context.read<AuthBloc>().add(
                                  const AuthCheckRequested(),
                                );
                                context.go('/dashboard');
                              }
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                                _errorMessage = e.toString();
                              });
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ] else if (!_isOtpSent) ...[
                  // Send OTP
                  FilledButton(
                    onPressed: (_isVerifyingPhone || _phoneWarning != null)
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            _sendOtp();
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isVerifyingPhone
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify Phone Number'),
                  ),
                ] else ...[
                  // Verify OTP
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify & Continue'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
