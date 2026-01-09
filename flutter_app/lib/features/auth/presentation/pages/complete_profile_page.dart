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
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingPhone = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;
  String? _emailWarning;
  String? _phoneWarning;
  bool _controllersInitialized = false;

  // Email linking state
  EmailLinkStatus? _emailLinkStatus;
  bool _isCheckingEmail = false;
  bool _showPasswordField = false;

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
    _passwordController.dispose();
    super.dispose();
  }

  /// Check email status for linking/merging
  Future<void> _checkEmailStatus() async {
    final email = _emailController.text.trim();
    final currentUserEmail = _currentUser?.email ?? '';

    if (email.isEmpty || email == currentUserEmail) {
      if (mounted) {
        setState(() {
          _emailWarning = null;
          _emailLinkStatus = null;
          _showPasswordField = false;
        });
      }
      return;
    }

    // Validate email format first
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final status = await _authDataSource.checkEmailLinkStatus(email);

      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _emailLinkStatus = status;

        switch (status) {
          case EmailLinkStatus.newEmail:
            _emailWarning = null;
            _showPasswordField = false;
            break;
          case EmailLinkStatus.existsWithoutPhone:
            _emailWarning =
                'This email is already registered. Enter your password to merge accounts.';
            _showPasswordField = true;
            break;
          case EmailLinkStatus.existsWithPhone:
            _emailWarning =
                'This email is already linked to another account with a phone number. Please use a different email.';
            _showPasswordField = false;
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _emailWarning = null;
        _emailLinkStatus = null;
        _showPasswordField = false;
      });
    }
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

  /// Handle email submission based on the status
  Future<void> _handleEmailSubmission() async {
    final email = _emailController.text.trim();
    final displayName = _nameController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter an email address');
      return;
    }

    // Check email status if not already checked
    if (_emailLinkStatus == null) {
      await _checkEmailStatus();
      if (!mounted) return;
    }

    // Handle based on status
    switch (_emailLinkStatus) {
      case EmailLinkStatus.newEmail:
      case null:
        // New email - just add it to the profile
        await _linkNewEmail(email, displayName);
        break;

      case EmailLinkStatus.existsWithoutPhone:
        // Existing email without phone - merge accounts
        final password = _passwordController.text;
        if (password.isEmpty) {
          setState(() => _errorMessage = 'Please enter your password to merge accounts');
          return;
        }
        await _mergeEmailAccount(email, password, displayName);
        break;

      case EmailLinkStatus.existsWithPhone:
        // Email already has phone - error
        setState(() => _errorMessage =
            'This email is already linked to another account. Please use a different email.');
        break;
    }
  }

  /// Link a new email to the phone user
  Future<void> _linkNewEmail(String email, String displayName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authDataSource.linkEmailToPhoneUser(
        email: email,
        displayName: displayName.isNotEmpty ? displayName : null,
      );

      _log.info('Email linked successfully', tag: LogTags.auth);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

  /// Merge an existing email account into the current phone user
  Future<void> _mergeEmailAccount(
    String email,
    String password,
    String displayName,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authDataSource.mergeEmailAccountIntoPhoneUser(
        email: email,
        password: password,
        displayName: displayName.isNotEmpty ? displayName : null,
      );

      _log.info('Accounts merged successfully', tag: LogTags.auth);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accounts merged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                        helperText: userEmail.isNotEmpty
                            ? 'Email from your sign-in method'
                            : 'Enter your email address',
                        errorText: _emailWarning,
                        suffixIcon: _isCheckingEmail
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _emailLinkStatus == EmailLinkStatus.existsWithoutPhone
                                ? const Icon(Icons.merge_type, color: Colors.orange)
                                : _emailLinkStatus == EmailLinkStatus.existsWithPhone
                                    ? const Icon(Icons.error, color: Colors.red)
                                    : null,
                      ),
                      readOnly: userEmail.isNotEmpty,
                      enabled: userEmail.isEmpty,
                      onChanged: (_) => _checkEmailStatus(),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        // Only validate if email is editable (empty from sign-in)
                        if (userEmail.isEmpty) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password field for merging accounts
                    if (_showPasswordField) ...[
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password for ${_emailController.text}',
                          hintText: 'Enter your existing account password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          helperText:
                              'Enter the password of your existing email account to merge it with this phone number',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_emailLinkStatus == EmailLinkStatus.existsWithoutPhone) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required to merge accounts';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Phone Field with India country code (only for email users needing phone)
                    if (!isPhoneVerified && userEmail.isNotEmpty) ...[
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
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // OTP Section for email users adding phone
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

                    // Action Button - depends on user's current state
                    if (isPhoneVerified && userEmail.isEmpty) ...[
                      // Phone user needs to add email
                      FilledButton(
                        onPressed: (_isLoading ||
                                _emailLinkStatus == EmailLinkStatus.existsWithPhone ||
                                _isCheckingEmail)
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await _handleEmailSubmission();
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
                            : Text(_emailLinkStatus ==
                                    EmailLinkStatus.existsWithoutPhone
                                ? 'Merge Accounts & Continue'
                                : 'Continue'),
                      ),
                    ] else if (!isPhoneVerified && userEmail.isNotEmpty) ...[
                      // Email user needs to add/verify phone
                      if (!_isOtpSent) ...[
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
                    ] else if (isPhoneVerified && userEmail.isNotEmpty) ...[
                      // User has both phone and email - just update profile
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