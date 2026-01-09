import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/network_avatar.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../groups/presentation/bloc/group_bloc.dart';
import '../../../groups/presentation/bloc/group_event.dart';
import '../../../groups/presentation/bloc/group_state.dart';

/// Represents a friend with aggregated balance across all groups
class FriendBalance {
  final String odTuserId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int totalBalance; // positive = they owe you, negative = you owe them
  final List<GroupBalanceDetail> groupBalances;

  FriendBalance({
    required this.odTuserId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.totalBalance,
    required this.groupBalances,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

/// Balance detail for a specific group
class GroupBalanceDetail {
  final String groupId;
  final String groupName;
  final int balance; // positive = they owe you, negative = you owe them

  GroupBalanceDetail({
    required this.groupId,
    required this.groupName,
    required this.balance,
  });
}

/// Friends page for managing friends list and viewing balances
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final LoggingService _log = LoggingService();
  late GroupBloc _groupBloc;

  @override
  void initState() {
    super.initState();
    _log.info('FriendsPage opened', tag: LogTags.ui);
    _groupBloc = sl<GroupBloc>();
    _groupBloc.add(const GroupLoadAllRequested());
  }

  @override
  void dispose() {
    _groupBloc.close();
    super.dispose();
  }

  /// Calculate friend balances from all groups for the current user
  List<FriendBalance> _calculateFriendBalances(
    List<GroupEntity> groups,
    String currentUserId,
  ) {
    // Map to store aggregated balances per friend
    final friendMap = <String, FriendBalance>{};

    for (final group in groups) {
      // Get current user's balance in this group
      final myBalance = group.balances[currentUserId] ?? 0;

      // Process simplified debts if available
      if (group.simplifiedDebts != null && group.simplifiedDebts!.isNotEmpty) {
        for (final debt in group.simplifiedDebts!) {
          String? friendId;
          String? friendName;
          int balanceWithFriend = 0;

          if (debt.fromUserId == currentUserId) {
            // Current user owes this person
            friendId = debt.toUserId;
            friendName = debt.toUserName;
            balanceWithFriend = -debt.amount; // Negative = I owe them
          } else if (debt.toUserId == currentUserId) {
            // This person owes current user
            friendId = debt.fromUserId;
            friendName = debt.fromUserName;
            balanceWithFriend = debt.amount; // Positive = they owe me
          }

          if (friendId != null && friendId != currentUserId) {
            final member = group.getMember(friendId);
            final groupDetail = GroupBalanceDetail(
              groupId: group.id,
              groupName: group.name,
              balance: balanceWithFriend,
            );

            if (friendMap.containsKey(friendId)) {
              final existing = friendMap[friendId]!;
              friendMap[friendId] = FriendBalance(
                odTuserId: friendId,
                displayName: existing.displayName,
                email: existing.email,
                photoUrl: existing.photoUrl ?? member?.photoUrl,
                totalBalance: existing.totalBalance + balanceWithFriend,
                groupBalances: [...existing.groupBalances, groupDetail],
              );
            } else {
              friendMap[friendId] = FriendBalance(
                odTuserId: friendId,
                displayName: friendName ?? 'Unknown',
                email: member?.email ?? '',
                photoUrl: member?.photoUrl,
                totalBalance: balanceWithFriend,
                groupBalances: [groupDetail],
              );
            }
          }
        }
      } else {
        // Fallback: Calculate from member balances
        for (final member in group.members) {
          if (member.userId == currentUserId) continue;

          final memberBalance = group.balances[member.userId] ?? 0;

          // Calculate relative balance between current user and this member
          // If my balance is positive (I'm owed) and their balance is negative (they owe),
          // we need to estimate how much they might owe me specifically
          // This is a simplified calculation when simplifiedDebts is not available
          int balanceWithFriend = 0;

          if (myBalance > 0 && memberBalance < 0) {
            // I'm owed money and they owe money
            // They might owe me proportionally
            final totalOwed = groups.fold<int>(0, (sum, g) {
              return sum +
                  g.balances.values
                      .where((b) => b < 0)
                      .fold(0, (s, b) => s + (-b));
            });
            if (totalOwed > 0) {
              balanceWithFriend = (myBalance * (-memberBalance) / totalOwed)
                  .round();
            }
          } else if (myBalance < 0 && memberBalance > 0) {
            // I owe money and they're owed money
            // I might owe them proportionally
            final totalOwed = groups.fold<int>(0, (sum, g) {
              return sum +
                  g.balances.values
                      .where((b) => b > 0)
                      .fold(0, (s, b) => s + b);
            });
            if (totalOwed > 0) {
              balanceWithFriend = -((-myBalance) * memberBalance / totalOwed)
                  .round();
            }
          }

          if (balanceWithFriend != 0) {
            final groupDetail = GroupBalanceDetail(
              groupId: group.id,
              groupName: group.name,
              balance: balanceWithFriend,
            );

            if (friendMap.containsKey(member.userId)) {
              final existing = friendMap[member.userId]!;
              friendMap[member.userId] = FriendBalance(
                odTuserId: member.userId,
                displayName: existing.displayName,
                email: existing.email,
                photoUrl: existing.photoUrl ?? member.photoUrl,
                totalBalance: existing.totalBalance + balanceWithFriend,
                groupBalances: [...existing.groupBalances, groupDetail],
              );
            } else {
              friendMap[member.userId] = FriendBalance(
                odTuserId: member.userId,
                displayName: member.displayName,
                email: member.email,
                photoUrl: member.photoUrl,
                totalBalance: balanceWithFriend,
                groupBalances: [groupDetail],
              );
            }
          } else {
            // Add friend even with zero balance if they're in a group with current user
            if (!friendMap.containsKey(member.userId)) {
              friendMap[member.userId] = FriendBalance(
                odTuserId: member.userId,
                displayName: member.displayName,
                email: member.email,
                photoUrl: member.photoUrl,
                totalBalance: 0,
                groupBalances: [],
              );
            }
          }
        }
      }
    }

    // Sort by absolute balance (most significant first)
    final friends = friendMap.values.toList();
    friends.sort(
      (a, b) => b.totalBalance.abs().compareTo(a.totalBalance.abs()),
    );
    return friends;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider.value(
      value: _groupBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddFriendDialog,
              tooltip: 'Add Friend',
            ),
          ],
        ),
        body: BlocBuilder<GroupBloc, GroupState>(
          builder: (context, groupState) {
            if (groupState.status == GroupStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (groupState.status == GroupStatus.failure) {
              return Center(
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
                      'Failed to load friends',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        _groupBloc.add(const GroupLoadAllRequested());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final friends = _calculateFriendBalances(
              groupState.groups,
              currentUserId,
            );

            if (friends.isEmpty) {
              return _buildEmptyState(theme);
            }

            return RefreshIndicator(
              onRefresh: () async {
                _groupBloc.add(const GroupLoadAllRequested());
              },
              child: _buildFriendsList(context, theme, friends),
            );
          },
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 2,
          onDestinationSelected: (index) =>
              _onDestinationSelected(context, index),
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
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a group or add friends to start splitting expenses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    ThemeData theme,
    List<FriendBalance> friends,
  ) {
    // Separate friends into categories
    final owedToYou = friends.where((f) => f.totalBalance > 0).toList();
    final youOwe = friends.where((f) => f.totalBalance < 0).toList();
    final settled = friends.where((f) => f.totalBalance == 0).toList();

    // Calculate totals
    final totalOwedToYou = owedToYou.fold<int>(
      0,
      (sum, f) => sum + f.totalBalance,
    );
    final totalYouOwe = youOwe.fold<int>(
      0,
      (sum, f) => sum + f.totalBalance.abs(),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        _buildSummaryCard(theme, totalOwedToYou, totalYouOwe),
        const SizedBox(height: 24),

        // Friends who owe you
        if (owedToYou.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            'Owed to you',
            CurrencyUtils.format(totalOwedToYou, 'INR'),
            Colors.green,
          ),
          const SizedBox(height: 8),
          ...owedToYou.map(
            (friend) => _buildFriendCard(context, theme, friend),
          ),
          const SizedBox(height: 16),
        ],

        // Friends you owe
        if (youOwe.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            'You owe',
            CurrencyUtils.format(totalYouOwe, 'INR'),
            Colors.red,
          ),
          const SizedBox(height: 8),
          ...youOwe.map((friend) => _buildFriendCard(context, theme, friend)),
          const SizedBox(height: 16),
        ],

        // Settled friends
        if (settled.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Settled up', '', null),
          const SizedBox(height: 8),
          ...settled.map((friend) => _buildFriendCard(context, theme, friend)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, int owedToYou, int youOwe) {
    final netBalance = owedToYou - youOwe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    theme,
                    'You are owed',
                    CurrencyUtils.format(owedToYou, 'INR'),
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
                    theme,
                    'You owe',
                    CurrencyUtils.format(youOwe, 'INR'),
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            if (netBalance != 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    netBalance > 0 ? 'Net: You are owed ' : 'Net: You owe ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    CurrencyUtils.format(netBalance.abs(), 'INR'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: netBalance > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String amount,
    Color? color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (amount.isNotEmpty)
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    ThemeData theme,
    FriendBalance friend,
  ) {
    final isOwedToYou = friend.totalBalance > 0;
    final isSettled = friend.totalBalance == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showFriendDetails(context, friend),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              NetworkAvatar(
                imageUrl: friend.photoUrl,
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  friend.initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${friend.groupBalances.length} group${friend.groupBalances.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isSettled)
                    Text(
                      'Settled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    Text(
                      isOwedToYou ? 'owes you' : 'you owe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(friend.totalBalance.abs(), 'INR'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOwedToYou ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),

              // Chevron
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendDetails(BuildContext context, FriendBalance friend) {
    _log.debug('Friend details opened: ${friend.displayName}', tag: LogTags.ui);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        NetworkAvatar(
                          imageUrl: friend.photoUrl,
                          radius: 28,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            friend.initials,
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (friend.email.isNotEmpty)
                                Text(
                                  friend.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total balance
                  if (friend.totalBalance != 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (friend.totalBalance > 0
                                    ? Colors.green
                                    : Colors.red)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            friend.totalBalance > 0 ? 'Owes you ' : 'You owe ',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            CurrencyUtils.format(
                              friend.totalBalance.abs(),
                              'INR',
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: friend.totalBalance > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Group breakdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Balance by Group',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Group list
                  Expanded(
                    child: friend.groupBalances.isEmpty
                        ? Center(
                            child: Text(
                              'No group balances',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: friend.groupBalances.length,
                            itemBuilder: (context, index) {
                              final groupBalance = friend.groupBalances[index];
                              return ListTile(
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(
                                    '/groups/${groupBalance.groupId}',
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  child: Icon(
                                    Icons.group,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                title: Text(groupBalance.groupName),
                                trailing: Text(
                                  CurrencyUtils.format(
                                    groupBalance.balance.abs(),
                                    'INR',
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: groupBalance.balance > 0
                                        ? Colors.green
                                        : groupBalance.balance < 0
                                        ? Colors.red
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  groupBalance.balance > 0
                                      ? 'owes you'
                                      : groupBalance.balance < 0
                                      ? 'you owe'
                                      : 'settled',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigate to settle up with this friend
                            },
                            icon: const Icon(Icons.payments),
                            label: const Text('Settle Up'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigate to add expense with this friend
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Add Expense'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/groups');
        break;
      case 2:
        // Already on friends page
        break;
      case 3:
        context.go('/notifications');
        break;
    }
  }

  void _showAddFriendDialog() {
    _log.debug('Add friend dialog opened', tag: LogTags.ui);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Friend',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email or Phone',
                    hintText: 'Enter email or phone number',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend invitation sent')),
                      );
                    },
                    child: const Text('Send Invitation'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement contacts import
                    },
                    icon: const Icon(Icons.contacts),
                    label: const Text('Import from Contacts'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
