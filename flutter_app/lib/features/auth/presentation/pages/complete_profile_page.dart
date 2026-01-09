import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';

/// Page for completing user profile after phone authentication
/// Phone-only authentication requires users to set up a display name
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

  bool _isLoading = false;
  String? _errorMessage;
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

    // Initialize with widget.user if provided
    if (widget.user != null) {
      _initializeFromUser(widget.user!);
    }
  }

  void _initializeFromUser(UserEntity user) {
    if (_controllersInitialized) return;

    _currentUser = user;
    _nameController.text = user.displayName ?? '';

    _controllersInitialized = true;

    _log.debug(
      'Initialized controllers from user',
      tag: LogTags.auth,
      data: {
        'displayName': user.displayName,
        'phone': user.phone,
        'isPhoneVerified': user.isPhoneVerified,
        'hasCompletedProfile': user.hasCompletedProfile,
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final displayName = _nameController.text.trim();

      // Update profile with display name
      await _authDataSource.updateProfile(displayName: displayName);

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

                    // Phone Number Display (read-only, verified)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Number (Verified)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  user.phone,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified, color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 24),

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

                    // Continue Button
                    FilledButton(
                      onPressed: _isLoading ? null : _completeProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Complete Profile'),
                    ),
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
