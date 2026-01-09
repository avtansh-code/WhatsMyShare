import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../bloc/profile_bloc.dart';

/// Profile page showing user information and settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LoggingService _log = LoggingService();

  @override
  void initState() {
    super.initState();
    _log.info('ProfilePage opened', tag: LogTags.ui);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(context),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load profile'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(
                        const ProfileLoadRequested(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final profile = state.profile!;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(const ProfileLoadRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(context, profile, state),
                  const SizedBox(height: 24),

                  // Balance Summary
                  _buildBalanceSummary(context, profile),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSettingsSection(context, profile),
                  const SizedBox(height: 24),

                  // Account Section
                  _buildAccountSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic profile,
    ProfileState state,
  ) {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Text(
                      profile.initials,
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  : null,
            ),
            if (state.status == ProfileStatus.uploadingPhoto)
              const Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          profile.displayNameOrEmail,
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        // Email
        Text(
          profile.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        // Phone
        if (profile.phone != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.phone!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceSummary(BuildContext context, dynamic profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are owed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyUtils.format(
                          profile.totalOwed,
                          profile.defaultCurrency,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You owe',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyUtils.format(
                          profile.totalOwing,
                          profile.defaultCurrency,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  CurrencyUtils.format(
                    profile.netBalance.abs(),
                    profile.defaultCurrency,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: profile.netBalance >= 0
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, dynamic profile) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text(
              'Receive updates about expenses and settlements',
            ),
            value: profile.notificationsEnabled,
            onChanged: (value) {
              context.read<ProfileBloc>().add(
                ProfileSettingsChanged(notificationsEnabled: value),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Contact Sync'),
            subtitle: const Text('Sync contacts to find friends'),
            value: profile.contactSyncEnabled,
            onChanged: (value) {
              context.read<ProfileBloc>().add(
                ProfileSettingsChanged(contactSyncEnabled: value),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text(
              'Use fingerprint or face ID for large transactions',
            ),
            value: profile.biometricAuthEnabled,
            onChanged: (value) {
              context.read<ProfileBloc>().add(
                ProfileSettingsChanged(biometricAuthEnabled: value),
              );
            },
          ),
          ListTile(
            title: const Text('Default Currency'),
            subtitle: Text(profile.defaultCurrency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, profile.defaultCurrency),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to terms
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    context.push('/profile/edit');
  }

  void _showCurrencyPicker(BuildContext context, String currentCurrency) {
    final currencies = ['INR', 'USD', 'EUR', 'GBP', 'AUD', 'CAD'];

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          return ListTile(
            title: Text(currency),
            trailing: currency == currentCurrency
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              context.read<ProfileBloc>().add(
                ProfileUpdateRequested(defaultCurrency: currency),
              );
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger sign out and navigate to login
              context.go('/login');
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
