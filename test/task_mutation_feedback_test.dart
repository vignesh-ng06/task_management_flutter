import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/core/widgets/app_feedback.dart';
import 'package:task_app/features/tasks/bloc/task_bloc.dart';
import 'package:task_app/features/tasks/bloc/task_event.dart';
import 'package:task_app/features/tasks/bloc/task_state.dart';
import 'package:task_app/features/tasks/data/models/task_model.dart';
import 'package:task_app/features/tasks/data/task_repository.dart';

class _TaskMutationRepository extends TaskRepository {
  _TaskMutationRepository() : super(ApiClient());

  final task = Task(
    id: 7,
    title: 'Prepare report',
    description: 'Draft the quarterly report',
    status: 'TODO',
    priority: 'MEDIUM',
    priorityLevel: 2,
    createdBy: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  bool clearDescriptionReceived = false;
  bool returnNoTaskAfterCreate = false;
  Object? createFailure;
  Object? updateFailure;

  @override
  Future<List<Task>> getMyTasks({TaskFilters? filters}) async => [task];

  @override
  Future<Task?> createTask({
    required String title,
    String? description,
    required int projectId,
    int? assignedTo,
    required String priority,
    DateTime? dueDate,
  }) async {
    if (createFailure case final failure?) throw failure;
    if (returnNoTaskAfterCreate) return null;
    return task.copyWith(title: title, description: description);
  }

  @override
  Future<Task> updateTask(
    int id, {
    String? title,
    String? description,
    bool clearDescription = false,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? assignedTo,
    bool clearAssignee = false,
  }) async {
    clearDescriptionReceived = clearDescription;
    if (updateFailure case final failure?) throw failure;
    return task.copyWith(
      title: title,
      description: description,
      clearDescription: clearDescription,
      priority: priority,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
      assignedTo: assignedTo,
      clearAssignee: clearAssignee,
    );
  }
}

Future<void> _loadTasks(TaskBloc bloc) async {
  final loaded = bloc.stream.firstWhere(
    (state) => state.status == TaskListStatus.loaded,
  );
  bloc.add(const TasksLoadRequested());
  await loaded;
}

void main() {
  testWidgets('success snackbar closes automatically after three seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showSuccessSnackBar(context, 'Task created successfully'),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Task created successfully'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Task created successfully'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Task created successfully'), findsNothing);
  });

  test('successful create emits a success message', () async {
    final repository = _TaskMutationRepository();
    final bloc = TaskBloc(repository);

    final succeeded = bloc.stream.firstWhere(
      (state) => state.mutationStatus == TaskMutationStatus.succeeded,
    );
    bloc.add(
      const TaskCreateRequested(
        title: 'New task',
        projectId: 2,
        priority: 'HIGH',
      ),
    );

    final state = await succeeded;
    expect(state.mutationMessage, 'Task created successfully');
    await bloc.close();
  });

  test('successful create without response task still emits success', () async {
    final repository = _TaskMutationRepository()
      ..returnNoTaskAfterCreate = true;
    final bloc = TaskBloc(repository);

    final succeeded = bloc.stream.firstWhere(
      (state) => state.mutationStatus == TaskMutationStatus.succeeded,
    );
    bloc.add(
      const TaskCreateRequested(
        title: 'New task',
        projectId: 2,
        priority: 'HIGH',
      ),
    );

    final state = await succeeded;
    expect(state.mutationMessage, 'Task created successfully');
    await bloc.close();
  });

  test(
    'successful edit emits feedback and clears an empty description',
    () async {
      final repository = _TaskMutationRepository();
      final bloc = TaskBloc(repository);
      await _loadTasks(bloc);

      final succeeded = bloc.stream.firstWhere(
        (state) => state.mutationStatus == TaskMutationStatus.succeeded,
      );
      bloc.add(
        const TaskUpdateRequested(
          id: 7,
          description: null,
          clearDescription: true,
        ),
      );

      final state = await succeeded;
      expect(state.mutationMessage, 'Task updated successfully');
      expect(repository.clearDescriptionReceived, isTrue);
      expect(state.tasks.single.description, isNull);
      await bloc.close();
    },
  );

  test('failed create exposes the error without reporting success', () async {
    final repository = _TaskMutationRepository()
      ..createFailure = StateError('server unavailable');
    final bloc = TaskBloc(repository);

    final failed = bloc.stream.firstWhere(
      (state) => state.mutationStatus == TaskMutationStatus.failed,
    );
    bloc.add(
      const TaskCreateRequested(
        title: 'New task',
        projectId: 2,
        priority: 'HIGH',
      ),
    );

    final state = await failed;
    expect(state.mutationMessage, contains('server unavailable'));
    expect(state.error, contains('server unavailable'));
    await bloc.close();
  });
}
