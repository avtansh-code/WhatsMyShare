import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/logging_service.dart';
import '../bloc/auth_bloc.dart';

/// Forgot password page for password reset
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final LoggingService _log = LoggingService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _log.info('ForgotPasswordPage opened', tag: LogTags.ui);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      _log.info(
        'Password reset requested',
        tag: LogTags.ui,
        data: {'email': _emailController.text.trim()},
      );
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(email: _emailController.text.trim()),
      );
    } else {
      _log.debug('Password reset form validation failed', tag: LogTags.ui);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reset Password'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _log.warning(
              'Password reset error',
              tag: LogTags.ui,
              data: {'message': state.message},
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthPasswordResetSent) {
            _log.info(
              'Password reset email sent successfully',
              tag: LogTags.ui,
              data: {'email': _emailController.text.trim()},
            );
            setState(() {
              _emailSent = true;
            });
          }
        },
        builder: (context, state) {
          _isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _emailSent
                  ? _buildSuccessView(theme)
                  : _buildFormView(theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        
        // Icon
        Icon(Icons.lock_reset, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),

        // Header
        Text(
          'Forgot your password?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            onFieldSubmitted: (_) => _onResetPassword(),
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
        ),
        const SizedBox(height: 16),

        // Submit Button
        FilledButton(
          onPressed: _isLoading ? null : _onResetPassword,
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
                  'Send Reset Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 12),

        // Back to Login
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: Text(
            'Back to Sign In',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),

        // Success Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Success Message
        Text(
          'Check your email',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a password reset link to',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The link will expire in 24 hours',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your spam folder if you don\'t see it',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back to Login Button
        FilledButton(
          onPressed: () => context.go('/login'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Back to Sign In',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),

        // Resend Link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Didn\'t receive the email? Try again',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
