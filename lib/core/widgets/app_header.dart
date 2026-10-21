import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/user_model.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import '../../features/notifications/bloc/notification_state.dart';
import '../theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String section;
  final List<Widget> actions;
  final bool showNotificationsAction;

  const AppHeader({
    super.key,
    required this.section,
    this.actions = const [],
    this.showNotificationsAction = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/branding/taskflow_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TaskFlow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
                Text(
                  section,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (user != null && showNotificationsAction)
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) => IconButton(
              tooltip: 'Alerts',
              onPressed: () =>
                  Navigator.of(context).pushNamed('/notifications'),
              icon: Badge(
                isLabelVisible: state.unreadCount > 0,
                label: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: IconButton(
              tooltip: 'Account: ${user.displayName}',
              onPressed: () => _showAccount(context, user),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(3),
                backgroundColor: colors.primaryContainer,
              ),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAccount(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primaryDark,
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(user.role),
              backgroundColor: AppColors.primaryLight,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
