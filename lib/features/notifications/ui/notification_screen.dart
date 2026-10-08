import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../data/models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(NotificationsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const _NotificationView();
  }
}

class _NotificationView extends StatelessWidget {
  const _NotificationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationBloc>().add(
                  NotificationsMarkAllReadRequested(),
                ),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.status == NotificationListStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No notifications',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(
                NotificationsLoadRequested(),
              );
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = state.items[i];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case 'TASK_ASSIGNED':
        return Icons.assignment_turned_in_outlined;
      case 'COMMENT_ADDED':
        return Icons.comment_outlined;
      case 'STATUS_CHANGED':
        return Icons.swap_horiz;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (notification.type) {
      case 'TASK_ASSIGNED':
        return Colors.blue;
      case 'COMMENT_ADDED':
        return Colors.green;
      case 'STATUS_CHANGED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Material(
      color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.15),
          child: Icon(_icon, color: _color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.relativeTime,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (isUnread) {
            context.read<NotificationBloc>().add(
              NotificationMarkReadRequested(notification.id),
            );
          }
        },
      ),
    );
  }
}
