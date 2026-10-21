import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_header.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../data/models/notification.dart';
import '../../projects/ui/project_detail_screen.dart';
import '../../tasks/ui/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(NotificationsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppHeader(
        section: 'Notifications',
        showNotificationsAction: false,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Mark all read',
                onPressed: state.unreadCount == 0
                    ? null
                    : () => context.read<NotificationBloc>().add(
                        NotificationsMarkAllReadRequested(),
                      ),
                icon: const Icon(Icons.done_all),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final visibleItems = _showUnreadOnly
              ? state.items
                    .where((notification) => !notification.isRead)
                    .toList()
              : state.items;

          if (state.status == NotificationListStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(
                NotificationsLoadRequested(),
              );
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NotificationOverview(
                          unreadCount: state.unreadCount,
                          totalCount: state.items.length,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent activity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _NotificationFilter(
                              showUnreadOnly: _showUnreadOnly,
                              onChanged: (value) {
                                setState(() => _showUnreadOnly = value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyNotifications(
                      unreadOnly: _showUnreadOnly,
                      hasNotifications: state.items.isNotEmpty,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = visibleItems[index];
                        return _NotificationTile(
                          key: ValueKey(notification.id),
                          notification: notification,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationOverview extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _NotificationOverview({
    required this.unreadCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = totalCount == 0
        ? 'You’re all caught up'
        : unreadCount == 0
        ? 'You’re all caught up'
        : '$unreadCount unread ${unreadCount == 1 ? 'update' : 'updates'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              unreadCount == 0
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_outlined,
              color: colorScheme.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 0
                      ? 'New updates will appear here.'
                      : '$totalCount ${totalCount == 1 ? 'notification' : 'notifications'} in your inbox',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationFilter extends StatelessWidget {
  final bool showUnreadOnly;
  final ValueChanged<bool> onChanged;

  const _NotificationFilter({
    required this.showUnreadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterButton(
            label: 'All',
            selected: !showUnreadOnly,
            onPressed: () => onChanged(false),
          ),
          _FilterButton(
            label: 'Unread',
            selected: showUnreadOnly,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final bool unreadOnly;
  final bool hasNotifications;

  const _EmptyNotifications({
    required this.unreadOnly,
    required this.hasNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final noNotifications = !hasNotifications;

    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noNotifications
                  ? Icons.notifications_off_outlined
                  : Icons.mark_email_read_outlined,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              noNotifications ? 'No notifications' : 'You’re all caught up',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noNotifications
                  ? 'You’ll see updates here when tasks are\nassigned or commented on.'
                  : 'There are no unread updates right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({super.key, required this.notification});

  void _openDestination(BuildContext context) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        NotificationMarkReadRequested(notification.id),
      );
    }

    final linkType = notification.linkType?.toLowerCase();
    final linkId = notification.linkId;
    if (linkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This notification has no linked page.')),
      );
      return;
    }

    switch (linkType) {
      case 'task':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(taskId: linkId),
          ),
        );
        break;
      case 'project':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: linkId),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This notification type has no linked page.'),
          ),
        );
        break;
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text(
          'This notification will be removed from your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return shouldDelete == true;
  }

  void _deleteNotification(BuildContext context) {
    context.read<NotificationBloc>().add(
      NotificationDeleteRequested(notification.id),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    if (await _confirmDelete(context) && context.mounted) {
      _deleteNotification(context);
    }
  }

  Future<bool?> _confirmSwipe(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      if (!notification.isRead) {
        context.read<NotificationBloc>().add(
          NotificationMarkReadRequested(notification.id),
        );
      }
      return false;
    }

    return _confirmDelete(context);
  }

  IconData get _icon {
    switch (notification.type) {
      case 'TASK_ASSIGNED':
        return Icons.assignment_outlined;
      case 'COMMENT_ADDED':
        return Icons.chat_bubble_outline_rounded;
      case 'STATUS_CHANGED':
        return Icons.sync_alt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _accent(ColorScheme colors) {
    switch (notification.type) {
      case 'TASK_ASSIGNED':
        return colors.primary;
      case 'COMMENT_ADDED':
        return const Color(0xFF25856B);
      case 'STATUS_CHANGED':
        return const Color(0xFFB56A12);
      default:
        return colors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUnread = !notification.isRead;
    final accent = _accent(colors);

    return Dismissible(
      key: ValueKey('notification-swipe-${notification.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) => _confirmSwipe(context, direction),
      onDismissed: (_) => _deleteNotification(context),
      background: _SwipeActionBackground(
        color: const Color(0xFF16845B),
        icon: Icons.mark_email_read_outlined,
        label: 'Mark as read',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeActionBackground(
        color: colors.error,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      child: Material(
        color: isUnread
            ? colors.primaryContainer.withValues(alpha: 0.28)
            : colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDestination(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnread
                    ? colors.primary.withValues(alpha: 0.18)
                    : colors.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: accent, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5, left: 8),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: PopupMenuButton<String>(
                              tooltip: 'Notification actions',
                              padding: EdgeInsets.zero,
                              iconSize: 19,
                              icon: Icon(
                                Icons.more_horiz,
                                color: colors.onSurfaceVariant,
                              ),
                              onSelected: (action) {
                                if (action == 'delete') {
                                  _confirmAndDelete(context);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: colors.error,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            notification.relativeTime,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (isUnread)
                            Text(
                              notification.linkId != null &&
                                      (notification.linkType?.toLowerCase() ==
                                              'task' ||
                                          notification.linkType
                                                  ?.toLowerCase() ==
                                              'project')
                                  ? 'Tap to open'
                                  : 'Tap to mark read',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _SwipeActionBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeActionBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isLeftAligned = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeftAligned ? 20 : 0,
        right: isLeftAligned ? 0 : 20,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeftAligned) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (isLeftAligned) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
