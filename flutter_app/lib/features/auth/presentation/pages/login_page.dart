import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/logging_service.dart';
import '../bloc/auth_bloc.dart';

/// Login page for email/password and Google authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoggingService _log = LoggingService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log.info('LoginPage opened', tag: LogTags.ui);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      _log.info(
        'Sign in with email requested',
        tag: LogTags.ui,
        data: {'email': _emailController.text.trim()},
      );
      context.read<AuthBloc>().add(
        AuthSignInWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      _log.debug('Sign in form validation failed', tag: LogTags.ui);
    }
  }

  void _onSignInWithGoogle() {
    _log.info('Sign in with Google requested', tag: LogTags.ui);
    context.read<AuthBloc>().add(const AuthSignInWithGoogleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _log.warning(
              'Auth error on login page',
              tag: LogTags.ui,
              data: {'message': state.message},
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            final user = state.user;
            _log.info(
              'User authenticated',
              tag: LogTags.ui,
              data: {
                'userId': user.id,
                'email': user.email,
                'displayName': user.displayName,
                'phone': user.phone,
                'isPhoneVerified': user.isPhoneVerified,
                'hasCompletedProfile': user.hasCompletedProfile,
              },
            );

            // Check if profile is complete (has name, email, and verified phone)
            if (user.hasCompletedProfile) {
              _log.info('Navigating to dashboard', tag: LogTags.ui);
              context.go('/dashboard');
            } else {
              _log.info(
                'Navigating to complete profile',
                tag: LogTags.ui,
                data: {
                  'reason': user.displayName == null || user.displayName!.isEmpty
                      ? 'missing displayName'
                      : user.phone == null || user.phone!.isEmpty
                          ? 'missing phone'
                          : !user.isPhoneVerified
                              ? 'phone not verified'
                              : 'unknown',
                },
              );
              context.go('/complete-profile', extra: user);
            }
          }
        },
        builder: (context, state) {
          _isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo and Title
                  _buildHeader(theme),
                  const Spacer(flex: 2),

                  // Login Form
                  _buildForm(theme),
                  const SizedBox(height: 16),

                  // Sign In Button
                  _buildSignInButton(theme),
                  const SizedBox(height: 8),

                  // Forgot Password
                  _buildForgotPassword(theme),
                  const Spacer(flex: 1),

                  // Divider
                  _buildDivider(theme),
                  const Spacer(flex: 1),

                  // Google Sign In
                  _buildGoogleSignIn(theme),
                  const SizedBox(height: 12),

                  // Phone Sign In
                  _buildPhoneSignIn(theme),
                  const Spacer(flex: 1),

                  // Sign Up Link
                  _buildSignUpLink(theme),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "What's My Share",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Split expenses with friends easily',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            key: const Key('emailField'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            key: const Key('passwordField'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            onFieldSubmitted: (_) => _onSignIn(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(ThemeData theme) {
    return FilledButton(
      onPressed: _isLoading ? null : _onSignIn,
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
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildForgotPassword(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : () => context.push('/forgot-password'),
        child: Text(
          'Forgot password?',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  Widget _buildGoogleSignIn(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _onSignInWithGoogle,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: Image.network(
        'https://www.google.com/favicon.ico',
        height: 20,
        width: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildPhoneSignIn(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : () => context.push('/phone-login'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(Icons.phone_outlined, size: 20),
      label: const Text('Sign in with Phone', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: _isLoading ? null : () => context.push('/signup'),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
