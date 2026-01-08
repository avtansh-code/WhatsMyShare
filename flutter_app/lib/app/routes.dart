import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

/// App router configuration with auth-aware navigation
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create and configure the GoRouter instance
  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/login',
      debugLogDiagnostics: true,
      redirect: _handleRedirect,
      routes: _routes,
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
    );
  }

  /// Handle authentication-based redirects
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password';

    // If not logged in and trying to access protected route, redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // If logged in and on auth route, redirect to dashboard
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }

    return null; // No redirect needed
  }

  /// Define all app routes
  static final List<RouteBase> _routes = [
    // Auth Routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AuthBloc>(),
        child: const SignUpPage(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AuthBloc>(),
        child: const ForgotPasswordPage(),
      ),
    ),

    // Main App Routes
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        child: const DashboardPage(),
      ),
    ),

    // Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/profile/edit',
      name: 'edit-profile',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
        child: const EditProfilePage(),
      ),
    ),

    // Redirect root to appropriate page
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;
        return isLoggedIn ? '/dashboard' : '/login';
      },
    ),
  ];
}

/// Error page for navigation errors
class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The page you\'re looking for doesn\'t exist.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
