import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/widgets/network_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Main dashboard page for authenticated users
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LoggingService _log = LoggingService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _log.info('DashboardPage opened', tag: LogTags.ui);
  }

  void _onDestinationSelected(int index) {
    _log.debug('Navigation destination selected: $index', tag: LogTags.ui);

    // Only update state and navigate if switching to a different tab
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home - go to dashboard
        context.go('/dashboard');
        break;
      case 1:
        // Groups - go to groups list
        context.go('/groups');
        break;
      case 2:
        // Friends - go to friends page
        context.go('/friends');
        break;
      case 3:
        // Activity - go to notifications
        context.go('/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          _log.info('User signed out, redirecting to login', tag: LogTags.ui);
          context.go('/login');
        }
        // Note: Profile completion check is handled at login time,
        // not here, to avoid redirect loops when returning from profile completion
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text("What's My Share"),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              PopupMenuButton<String>(
                icon: NetworkAvatar(
                  imageUrl: user?.photoUrl,
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  encryptionService: sl<EncryptionService>(),
                  child: Text(
                    user?.initials ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                onSelected: (value) {
                  _log.debug('Menu item selected: $value', tag: LogTags.ui);
                  if (value == 'profile') {
                    context.push('/profile');
                  } else if (value == 'settings') {
                    context.push(
                      '/profile',
                    ); // Settings is part of profile page
                  } else if (value == 'logout') {
                    _log.info(
                      'Sign out requested from dashboard',
                      tag: LogTags.ui,
                    );
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sign Out'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // TODO: Refresh data
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  _buildWelcomeCard(context, theme, user),
                  const SizedBox(height: 24),

                  // Balance Summary
                  _buildBalanceSummary(context, theme, user),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(context, theme),
                  const SizedBox(height: 24),

                  // Recent Activity
                  _buildRecentActivity(context, theme),
                  const SizedBox(height: 24),

                  // Groups Section
                  _buildGroupsSection(context, theme),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showAddOptions(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Friends',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Activity',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    ThemeData theme,
    dynamic user,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user?.initials ?? '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    user?.displayNameOrEmail ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(
    BuildContext context,
    ThemeData theme,
    dynamic user,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    context,
                    theme,
                    'You are owed',
                    '₹0.00',
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildBalanceItem(
                    context,
                    theme,
                    'You owe',
                    '₹0.00',
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                Icons.group_add,
                'New Group',
                () {
                  context.push('/groups/create');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                Icons.person_add,
                'Add Friend',
                () {
                  context.push('/friends'); // Navigate to friends page
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                Icons.payments,
                'Settle Up',
                () {
                  context.push(
                    '/groups',
                  ); // Navigate to groups to select for settle up
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/notifications');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add an expense to get started',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Groups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/groups');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No groups yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/groups/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddOptions(BuildContext context) {
    _log.debug('Add options bottom sheet opened', tag: LogTags.ui);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Add Expense'),
                  subtitle: const Text('Split a bill with your group'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/groups',
                    ); // First select a group, then add expense
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Create Group'),
                  subtitle: const Text('Start a new expense group'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/groups/create');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments),
                  title: const Text('Settle Up'),
                  subtitle: const Text('Record a payment'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/groups',
                    ); // First select a group, then settle up
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
