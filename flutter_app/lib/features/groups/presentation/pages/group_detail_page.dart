import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/user_cache_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/group_entity.dart';
import '../bloc/group_bloc.dart';
import '../bloc/group_event.dart';
import '../bloc/group_state.dart';

/// Page displaying group details with members and balances
class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoggingService _log = LoggingService();

  @override
  void initState() {
    super.initState();
    _log.info(
      'GroupDetailPage opened',
      tag: LogTags.ui,
      data: {'groupId': widget.groupId},
    );
    _tabController = TabController(length: 3, vsync: this);
    // Load the specific group
    context.read<GroupBloc>().add(GroupLoadByIdRequested(widget.groupId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        final group = state.selectedGroup;

        if (state.isLoading && group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'Group not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(context, group),
                SliverToBoxAdapter(child: _buildBalanceSummary(context, group)),
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'Expenses'),
                        Tab(text: 'Balances'),
                        Tab(text: 'Members'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(context, group),
                _buildBalancesTab(context, group),
                _buildMembersTab(context, group),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Navigate to add expense page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add expense coming soon!')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, GroupEntity group) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  _getGroupTypeEmoji(group.type),
                  style: const TextStyle(fontSize: 48),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            _showGroupSettings(context, group);
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, group),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settle',
              child: ListTile(
                leading: Icon(Icons.handshake),
                title: Text('Settle Up'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'simplify',
              child: ListTile(
                leading: Icon(Icons.auto_fix_high),
                title: Text('Simplify Debts'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'leave',
              child: ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: Text('Leave Group', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(BuildContext context, GroupEntity group) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total',
                CurrencyUtils.format(group.totalExpenses, group.currency),
                Icons.receipt_long,
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildStatItem(
                context,
                'Expenses',
                '${group.expenseCount}',
                Icons.list_alt,
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildStatItem(
                context,
                'Members',
                '${group.memberCount}',
                Icons.people,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab(BuildContext context, GroupEntity group) {
    // Placeholder for expenses list
    if (group.expenseCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 0, // Will be populated with actual expenses
      itemBuilder: (context, index) {
        return const SizedBox(); // Placeholder
      },
    );
  }

  Widget _buildBalancesTab(BuildContext context, GroupEntity group) {
    if (group.balances.isEmpty) {
      return const Center(child: Text('No balances to show'));
    }

    final balanceEntries = group.balances.entries.toList();
    final userCache = sl<UserCacheService>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: balanceEntries.length,
      itemBuilder: (context, index) {
        final entry = balanceEntries[index];
        final member = group.members.firstWhere(
          (m) => m.userId == entry.key,
          orElse: () => GroupMember(
            userId: entry.key,
            joinedAt: DateTime.now(),
            role: MemberRole.member,
          ),
        );
        final balance = entry.value;

        // Resolve display name via cache
        final displayName = member.displayName.isNotEmpty
            ? member.displayName
            : userCache.getCachedDisplayName(member.userId);
        final photoUrl =
            member.photoUrl ?? userCache.getCachedPhotoUrl(member.userId);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(displayName[0].toUpperCase())
                  : null,
            ),
            title: Text(displayName),
            trailing: Text(
              CurrencyUtils.formatWithSign(balance, group.currency),
              style: TextStyle(
                color: balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              balance > 0
                  ? 'is owed'
                  : balance < 0
                  ? 'owes'
                  : 'settled up',
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(BuildContext context, GroupEntity group) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        final isAdmin = member.role == MemberRole.admin;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(member.displayName[0].toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Text(member.displayName),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(member.maskedPhone),
            trailing: PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMemberAction(context, value, group, member),
              itemBuilder: (context) => [
                if (!isAdmin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Text('Make Admin'),
                  ),
                if (isAdmin)
                  const PopupMenuItem(
                    value: 'remove_admin',
                    child: Text('Remove Admin'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove from Group'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupSettings(BuildContext context, GroupEntity group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit group page
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Member'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show add member dialog
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.auto_fix_high),
              title: const Text('Simplify Debts'),
              value: group.simplifyDebts,
              onChanged: (value) {
                Navigator.pop(context);
                context.read<GroupBloc>().add(
                  GroupUpdateRequested(groupId: group.id, simplifyDebts: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    GroupEntity group,
  ) {
    switch (action) {
      case 'settle':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settle up coming soon!')));
        break;
      case 'simplify':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Simplify debts coming soon!')),
        );
        break;
      case 'leave':
        _showLeaveConfirmation(context, group);
        break;
    }
  }

  void _handleMemberAction(
    BuildContext context,
    String action,
    GroupEntity group,
    GroupMember member,
  ) {
    switch (action) {
      case 'make_admin':
        context.read<GroupBloc>().add(
          GroupMemberRoleUpdateRequested(
            groupId: group.id,
            userId: member.userId,
            newRole: MemberRole.admin,
          ),
        );
        break;
      case 'remove_admin':
        context.read<GroupBloc>().add(
          GroupMemberRoleUpdateRequested(
            groupId: group.id,
            userId: member.userId,
            newRole: MemberRole.member,
          ),
        );
        break;
      case 'remove':
        _showRemoveMemberConfirmation(context, group, member);
        break;
    }
  }

  void _showLeaveConfirmation(BuildContext context, GroupEntity group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GroupBloc>().add(GroupLeaveRequested(group.id));
              context.pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberConfirmation(
    BuildContext context,
    GroupEntity group,
    GroupMember member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GroupBloc>().add(
                GroupMemberRemoveRequested(
                  groupId: group.id,
                  userId: member.userId,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _getGroupTypeEmoji(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return '✈️';
      case GroupType.home:
        return '🏠';
      case GroupType.couple:
        return '💑';
      case GroupType.other:
        return '👥';
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
