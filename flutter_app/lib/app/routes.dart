import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/services/logging_service.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/complete_profile_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/groups/presentation/bloc/group_bloc.dart';
import '../features/groups/presentation/bloc/group_event.dart';
import '../features/groups/presentation/pages/group_list_page.dart';
import '../features/groups/presentation/pages/create_group_page.dart';
import '../features/groups/presentation/pages/group_detail_page.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/notifications/presentation/bloc/notification_event.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/friends/presentation/pages/friends_page.dart';
import '../features/expenses/presentation/bloc/chat_bloc.dart';
import '../features/expenses/presentation/pages/expense_chat_page.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import '../features/splash/presentation/pages/splash_page.dart';

/// Logging service for navigation
final _log = LoggingService();

/// App router configuration with auth-aware navigation
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create and configure the GoRouter instance
  static GoRouter createRouter() {
    _log.info('Creating app router', tag: LogTags.navigation);
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      redirect: _handleRedirect,
      routes: _routes,
      errorBuilder: (context, state) {
        _log.error(
          'Navigation error',
          tag: LogTags.navigation,
          error: state.error,
          data: {'location': state.matchedLocation},
        );
        return _ErrorPage(error: state.error);
      },
    );
  }

  /// Handle authentication-based redirects
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isSplashRoute = state.matchedLocation == '/splash';
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password';

    // Don't redirect if on splash screen
    if (isSplashRoute) {
      return null;
    }

    _log.debug(
      'Handling redirect',
      tag: LogTags.navigation,
      data: {
        'location': state.matchedLocation,
        'isLoggedIn': isLoggedIn,
        'isAuthRoute': isAuthRoute,
      },
    );

    // If not logged in and trying to access protected route, redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      _log.info(
        'Redirecting unauthenticated user to login',
        tag: LogTags.navigation,
        data: {'from': state.matchedLocation},
      );
      return '/login';
    }

    // If logged in and on auth route, redirect to dashboard
    if (isLoggedIn && isAuthRoute) {
      _log.info(
        'Redirecting authenticated user to dashboard',
        tag: LogTags.navigation,
        data: {'from': state.matchedLocation},
      );
      return '/dashboard';
    }

    return null; // No redirect needed
  }

  /// Define all app routes
  static final List<RouteBase> _routes = [
    // Splash Route
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        _log.debug('Navigating to splash page', tag: LogTags.navigation);
        return const SplashPage();
      },
    ),

    // Auth Routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        _log.debug('Navigating to login page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
          child: const LoginPage(),
        );
      },
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) {
        _log.debug('Navigating to signup page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const SignUpPage(),
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) {
        _log.debug(
          'Navigating to forgot password page',
          tag: LogTags.navigation,
        );
        return BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const ForgotPasswordPage(),
        );
      },
    ),
    GoRoute(
      path: '/complete-profile',
      name: 'complete-profile',
      builder: (context, state) {
        _log.debug('Navigating to complete profile page', tag: LogTags.navigation);
        final user = state.extra as UserEntity;
        return BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: CompleteProfilePage(user: user),
        );
      },
    ),

    // Main App Routes
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) {
        _log.debug('Navigating to dashboard', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
          child: const DashboardPage(),
        );
      },
    ),

    // Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) {
        _log.debug('Navigating to profile page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
          child: const ProfilePage(),
        );
      },
    ),
    GoRoute(
      path: '/profile/edit',
      name: 'edit-profile',
      builder: (context, state) {
        _log.debug('Navigating to edit profile page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
          child: const EditProfilePage(),
        );
      },
    ),

    // Notification Routes
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) {
        _log.debug('Navigating to notifications page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<NotificationBloc>()..add(const LoadNotifications()),
          child: const NotificationsPage(),
        );
      },
    ),

    // Friends Routes
    GoRoute(
      path: '/friends',
      name: 'friends',
      builder: (context, state) {
        _log.debug('Navigating to friends page', tag: LogTags.navigation);
        return const FriendsPage();
      },
    ),

    // Group Routes
    GoRoute(
      path: '/groups',
      name: 'groups',
      builder: (context, state) {
        _log.debug('Navigating to groups list', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<GroupBloc>()..add(const GroupLoadAllRequested()),
          child: const GroupListPage(),
        );
      },
    ),
    GoRoute(
      path: '/groups/create',
      name: 'create-group',
      builder: (context, state) {
        _log.debug('Navigating to create group page', tag: LogTags.navigation);
        return BlocProvider(
          create: (_) => sl<GroupBloc>(),
          child: const CreateGroupPage(),
        );
      },
    ),
    GoRoute(
      path: '/groups/:groupId',
      name: 'group-detail',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        _log.debug(
          'Navigating to group detail',
          tag: LogTags.navigation,
          data: {'groupId': groupId},
        );
        return BlocProvider(
          create: (_) => sl<GroupBloc>()..add(GroupLoadByIdRequested(groupId)),
          child: GroupDetailPage(groupId: groupId),
        );
      },
    ),

    // Expense Chat Route
    GoRoute(
      path: '/expenses/:expenseId/chat',
      name: 'expense-chat',
      builder: (context, state) {
        final expense = state.extra as ExpenseEntity;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        _log.debug(
          'Navigating to expense chat',
          tag: LogTags.navigation,
          data: {'expenseId': expense.id},
        );
        return BlocProvider(
          create: (_) => sl<ChatBloc>(),
          child: ExpenseChatPage(
            expense: expense,
            currentUserId: currentUserId,
          ),
        );
      },
    ),

    // Redirect root to appropriate page
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;
        final destination = isLoggedIn ? '/dashboard' : '/login';
        _log.debug(
          'Root redirect',
          tag: LogTags.navigation,
          data: {'destination': destination},
        );
        return destination;
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
                onPressed: () {
                  _log.info(
                    'User navigating home from error page',
                    tag: LogTags.navigation,
                  );
                  context.go('/');
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
