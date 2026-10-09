import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/features/tasks/bloc/task_event.dart';

import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'features/notifications/bloc/notification_event.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/tasks/bloc/task_bloc.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/ui/tasks_screen.dart';
import 'app_shell.dart';
import 'features/users/data/user_repository.dart';
import 'features/projects/data/project_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/home/data/dashboard_repository.dart';

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(); 
    final storage = TokenStorage();
    final authRepo = AuthRepository(api); 
    final taskRepo = TaskRepository(api);
    final notifRepo = NotificationRepository(api);
    final userRepo = UserRepository(api);
    final projectRepo = ProjectRepository(api);
    final dashboardRepo = DashboardRepository(api);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: taskRepo),
        RepositoryProvider.value(value: notifRepo),
        RepositoryProvider.value(value: userRepo),
        RepositoryProvider.value(value: projectRepo),
        RepositoryProvider.value(value: dashboardRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(repo: authRepo, api: api, storage: storage)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(create: (_) => TaskBloc(taskRepo)),
          BlocProvider(create: (_) => NotificationBloc(notifRepo)),
        ],
        child: MaterialApp(
          title: 'Task App',
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.read<TaskBloc>().add(const TasksLoadRequested());
          context.read<NotificationBloc>().add( NotificationsUnreadCountRequested());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.unknown) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status == AuthStatus.authenticated) {
            return const AppShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}