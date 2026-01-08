import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String groups = '/groups';
  static const String groupDetail = '/groups/:groupId';
  static const String addExpense = '/groups/:groupId/add-expense';
  static const String expenseDetail = '/groups/:groupId/expenses/:expenseId';
  static const String settlements = '/settlements';
  static const String friends = '/friends';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
}

/// Application router configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash/Loading route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
      ),
      
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const _PlaceholderPage(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const _PlaceholderPage(title: 'Sign Up'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const _PlaceholderPage(title: 'Forgot Password'),
      ),
      
      // Main app routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const _PlaceholderPage(title: 'Home'),
      ),
      GoRoute(
        path: AppRoutes.groups,
        name: 'groups',
        builder: (context, state) => const _PlaceholderPage(title: 'Groups'),
        routes: [
          GoRoute(
            path: ':groupId',
            name: 'groupDetail',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return _PlaceholderPage(title: 'Group: $groupId');
            },
            routes: [
              GoRoute(
                path: 'add-expense',
                name: 'addExpense',
                builder: (context, state) => const _PlaceholderPage(title: 'Add Expense'),
              ),
              GoRoute(
                path: 'expenses/:expenseId',
                name: 'expenseDetail',
                builder: (context, state) {
                  final expenseId = state.pathParameters['expenseId']!;
                  return _PlaceholderPage(title: 'Expense: $expenseId');
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settlements,
        name: 'settlements',
        builder: (context, state) => const _PlaceholderPage(title: 'Settlements'),
      ),
      GoRoute(
        path: AppRoutes.friends,
        name: 'friends',
        builder: (context, state) => const _PlaceholderPage(title: 'Friends'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const _PlaceholderPage(title: 'Notifications'),
      ),
    ],
    errorBuilder: (context, state) => _PlaceholderPage(
      title: 'Error',
      message: state.error?.message ?? 'Page not found',
    ),
    // TODO: Add redirect logic for authentication
    // redirect: (context, state) {
    //   final isLoggedIn = // check auth state
    //   final isLoggingIn = state.matchedLocation == AppRoutes.login;
    //   
    //   if (!isLoggedIn && !isLoggingIn) {
    //     return AppRoutes.login;
    //   }
    //   if (isLoggedIn && isLoggingIn) {
    //     return AppRoutes.home;
    //   }
    //   return null;
    // },
  );
}

/// Temporary placeholder page for routes
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String? message;

  const _PlaceholderPage({
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Page under construction',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}