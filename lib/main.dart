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
import 'features/tasks/bloc/task_bloc.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/ui/tasks_screen.dart';

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

return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: taskRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthBloc(repo: authRepo, api: api, storage: storage)
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(create: (_) => TaskBloc(taskRepo)),
        ],
        child: MaterialApp(
          title: 'Task App',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
          // When user logs in, load their tasks
          context.read<TaskBloc>().add(const TasksLoadRequested());
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
            return const TasksScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}