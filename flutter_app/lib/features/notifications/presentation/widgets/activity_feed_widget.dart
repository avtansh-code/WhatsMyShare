import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

/// Widget displaying activity feed for a group
class ActivityFeedWidget extends StatefulWidget {
  final String groupId;
  final int maxItems;
  final bool showHeader;

  const ActivityFeedWidget({
    super.key,
    required this.groupId,
    this.maxItems = 10,
    this.showHeader = true,
  });

  @override
  State<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

class _ActivityFeedWidgetState extends State<ActivityFeedWidget> {
  @override
  void initState() {
    super.initState();
    // Load activity for this group
    context.read<NotificationBloc>().add(
      LoadGroupActivity(widget.groupId, limit: widget.maxItems),
    );
    // Subscribe to real-time updates
    context.read<NotificationBloc>().add(
      SubscribeToGroupActivity(widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(context, state),
            if (state.isLoadingActivity)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.activities.isEmpty)
              _buildEmptyState(context)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.activities.length > widget.maxItems
                    ? widget.maxItems
                    : state.activities.length,
                itemBuilder: (context, index) {
                  final activity = state.activities[index];
                  return _ActivityTile(activity: activity);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, NotificationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (state.activities.length > widget.maxItems)
            TextButton(
              onPressed: () {
                // Navigate to full activity page
              },
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEntity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: _buildActivityText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(activity.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case ActivityType.expenseAdded:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case ActivityType.expenseUpdated:
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case ActivityType.expenseDeleted:
        icon = Icons.delete;
        color = Colors.red;
        break;
      case ActivityType.settlementCreated:
        icon = Icons.payment;
        color = Colors.orange;
        break;
      case ActivityType.settlementConfirmed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ActivityType.memberAdded:
        icon = Icons.person_add;
        color = Colors.purple;
        break;
      case ActivityType.memberRemoved:
        icon = Icons.person_remove;
        color = Colors.grey;
        break;
      case ActivityType.groupCreated:
        icon = Icons.group_add;
        color = Colors.indigo;
        break;
      case ActivityType.groupUpdated:
        icon = Icons.settings;
        color = Colors.teal;
        break;
      case ActivityType.settlementRejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  List<TextSpan> _buildActivityText(BuildContext context) {
    final theme = Theme.of(context);
    final boldStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    switch (activity.type) {
      case ActivityType.expenseAdded:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' added '),
          if (activity.description != null)
            TextSpan(text: '"${activity.description}"', style: boldStyle),
          if (activity.amount != null) ...[
            const TextSpan(text: ' for '),
            TextSpan(
              text: CurrencyUtils.format(
                activity.amount!,
                activity.currency ?? 'INR',
              ),
              style: boldStyle,
            ),
          ],
        ];
      case ActivityType.expenseUpdated:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' updated '),
          if (activity.description != null)
            TextSpan(text: '"${activity.description}"', style: boldStyle),
        ];
      case ActivityType.expenseDeleted:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' deleted an expense'),
        ];
      case ActivityType.settlementCreated:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' recorded a payment'),
          if (activity.amount != null) ...[
            const TextSpan(text: ' of '),
            TextSpan(
              text: CurrencyUtils.format(
                activity.amount!,
                activity.currency ?? 'INR',
              ),
              style: boldStyle,
            ),
          ],
        ];
      case ActivityType.settlementConfirmed:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' confirmed a settlement'),
        ];
      case ActivityType.memberAdded:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' added a new member'),
        ];
      case ActivityType.memberRemoved:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' removed a member'),
        ];
      case ActivityType.groupCreated:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' created the group'),
        ];
      case ActivityType.groupUpdated:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' updated group settings'),
        ];
      case ActivityType.settlementRejected:
        return [
          TextSpan(text: activity.actorName, style: boldStyle),
          const TextSpan(text: ' rejected a settlement'),
        ];
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
