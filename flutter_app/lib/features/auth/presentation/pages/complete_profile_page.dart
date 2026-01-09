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
  final UserEntity? user;

  const CompleteProfilePage({super.key, this.user});

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
  bool _controllersInitialized = false;

  // Current user entity - either from widget or loaded from bloc
  UserEntity? _currentUser;

  late FirebaseAuthDataSource _authDataSource;

  @override
  void initState() {
    super.initState();
    _log.info('CompleteProfilePage opened', tag: LogTags.ui);
    _authDataSource = sl<FirebaseAuthDataSource>();

    // Initialize controllers with empty values first
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Initialize with widget.user if provided
    if (widget.user != null) {
      _initializeFromUser(widget.user!);
    }
  }

  void _initializeFromUser(UserEntity user) {
    if (_controllersInitialized) return;

    _currentUser = user;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email;

    // Extract 10-digit phone number (remove country code if present)
    String phone = user.phone ?? '';
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(2);
    }
    _phoneController.text = phone;

    _controllersInitialized = true;

    _log.debug(
      'Initialized controllers from user',
      tag: LogTags.auth,
      data: {
        'displayName': user.displayName,
        'email': user.email,
        'phone': user.phone,
        'isPhoneVerified': user.isPhoneVerified,
        'hasCompletedProfile': user.hasCompletedProfile,
      },
    );
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
    final currentUserEmail = _currentUser?.email ?? '';
    final currentUserId = _currentUser?.id ?? '';

    if (email.isEmpty || email == currentUserEmail) {
      if (mounted) setState(() => _emailWarning = null);
      return;
    }

    if (currentUserId.isEmpty) return;

    final isRegisteredByOther = await _authDataSource.isEmailRegisteredByOther(
      email,
      currentUserId,
    );

    if (!mounted) return;
    setState(() {
      _emailWarning = isRegisteredByOther
          ? 'This email is already associated with another account'
          : null;
    });
  }

  Future<void> _checkPhoneUniqueness() async {
    final phone = _phoneController.text.trim();
    final currentUserId = _currentUser?.id ?? '';

    if (phone.isEmpty || currentUserId.isEmpty) {
      if (mounted) setState(() => _phoneWarning = null);
      return;
    }

    final isRegisteredByOther = await _authDataSource.isPhoneRegisteredByOther(
      phone,
      currentUserId,
    );

    if (!mounted) return;
    setState(() {
      _phoneWarning = isRegisteredByOther
          ? 'This phone number is already associated with another account'
          : null;
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter a phone number');
      return;
    }

    // Check if phone is already registered by another user
    await _checkPhoneUniqueness();
    if (!mounted) return;
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
          if (!mounted) return;
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
          if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isVerifyingPhone = false;
        _errorMessage = 'Failed to send OTP: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      if (mounted) setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Verification session expired. Please request a new OTP',
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // Get the phone number from the controller
    final phone = _phoneController.text.trim();

    try {
      await _authDataSource.linkPhoneNumber(
        verificationId: _verificationId!,
        smsCode: otp,
        phoneNumber: phone,
      );

      // Update name if changed
      final currentDisplayName = _currentUser?.displayName ?? '';
      if (_nameController.text.trim() != currentDisplayName) {
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyWithCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);

        // Get the phone number from the controller and save it along with verification status
        final phone = _phoneController.text.trim();
        await _authDataSource.markPhoneVerified(phoneNumber: phone);

        // Update name if changed
        final currentDisplayName = _currentUser?.displayName ?? '';
        if (_nameController.text.trim() != currentDisplayName) {
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Initialize controllers from loaded user if not already done
          _initializeFromUser(state.user);
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        // Show loading if we don't have user data yet
        if (_currentUser == null && state is! AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Complete Your Profile'),
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Get user from state if available
        final user =
            _currentUser ?? (state is AuthAuthenticated ? state.user : null);
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Complete Your Profile'),
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Phone is only truly verified if both the flag is set AND the phone number exists
        // This handles data inconsistency where isPhoneVerified=true but phone is null
        final hasValidPhone = user.phone != null && user.phone!.isNotEmpty;
        final isPhoneVerified = user.isPhoneVerified && hasValidPhone;
        final userEmail = user.email;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Header
                    Icon(
                      Icons.person_add_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Almost there!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please complete your profile to continue using the app.',
                      style: theme.textTheme.bodySmall?.copyWith(
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
                    const SizedBox(height: 12),

                    // Email Field (read-only for Google users)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                        helperText: userEmail.isNotEmpty
                            ? 'Email from your sign-in method'
                            : null,
                        errorText: _emailWarning,
                      ),
                      readOnly: userEmail.isNotEmpty,
                      enabled: userEmail.isEmpty,
                      onChanged: (_) => _checkEmailUniqueness(),
                    ),
                    const SizedBox(height: 12),

                    // Phone Field with India country code
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed India country code prefix
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🇮🇳',
                                style: TextStyle(fontSize: 20),
                              ),
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
                              suffixIcon: isPhoneVerified
                                  ? const Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                    )
                                  : null,
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            enabled: !_isOtpSent && !isPhoneVerified,
                            onChanged: (_) => _checkPhoneUniqueness(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final phone = value.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (phone.length != 10) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                              // Note: Removed strict Indian mobile validation (6-9 prefix)
                              // to allow test phone numbers during development
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // OTP Section
                    if (_isOtpSent && !isPhoneVerified) ...[
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
                      const SizedBox(height: 8),
                    ],

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action Button
                    if (isPhoneVerified) ...[
                      // Just update name
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (mounted) setState(() => _isLoading = true);

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
                                  if (!mounted) return;
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify & Continue'),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
