import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/home/ui/home_screen.dart';
import 'features/notifications/ui/notification_screen.dart';
import 'features/profile/ui/profile_screen.dart';
import 'features/projects/ui/projects_screen.dart';
import 'features/tasks/ui/tasks_screen.dart';
import 'features/users/ui/users_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    final role = user.role;
    final isAdmin = role == 'admin';
    final isManager = role == 'manager';
    final canManageProjects = isAdmin || isManager;

    // Build the tab list based on role
    final tabs = <_TabItem>[
      _TabItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        screen: const HomeScreen(),
      ),
      _TabItem(
        label: 'Tasks',
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        screen: const TasksScreen(),
      ),
      if (canManageProjects)
        const _TabItem(
          label: 'Projects',
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder,
          screen: ProjectsScreen(),
        ),
      if (isAdmin)
        const _TabItem(
          label: 'Users',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          screen: UsersScreen(),
        ),
      _TabItem(
        label: 'Alerts',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        screen: const NotificationScreen(),
      ),
      _TabItem(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        screen: const ProfileScreen(),
      ),
    ];

    // Safety: if index out of range after a role change
    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}