import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/project_repository.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _repo;

  ProjectBloc(this._repo) : super(const ProjectState()) {
    on<ProjectsLoadRequested>(_onLoad);
    on<ProjectCreateRequested>(_onCreate);
    on<ProjectUpdateRequested>(_onUpdate);
    on<ProjectDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    ProjectsLoadRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectListStatus.loading, clearMessages: true));
    try {
      final projects =
          await _repo.listProjects(includeInactive: event.includeInactive);
      emit(state.copyWith(
        status: ProjectListStatus.loaded,
        projects: projects,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ProjectListStatus.error, error: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ProjectListStatus.error,
        error: 'Failed to load projects',
      ));
    }
  }

  Future<void> _onCreate(
    ProjectCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(clearMessages: true));
    try {
      final project = await _repo.createProject(
        name: event.name,
        description: event.description,
      );
      // Prepend so it shows at the top
      emit(state.copyWith(
        projects: [project, ...state.projects],
        successMessage: 'Project created',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> _onUpdate(
    ProjectUpdateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(clearMessages: true));

    final index = state.projects.indexWhere((p) => p.id == event.id);
    if (index == -1) return;
    final original = state.projects[index];

    // Optimistic
    final optimistic = original.copyWith(
      name: event.name,
      description: event.description,
    );
    final optimisticList = [...state.projects]..[index] = optimistic;
    emit(state.copyWith(projects: optimisticList));

    try {
      final serverProject = await _repo.updateProject(
        event.id,
        name: event.name,
        description: event.description,
      );
      final merged = serverProject.copyWith(
        taskCount: original.taskCount,
      );
      final confirmed = [...state.projects]..[index] = merged;
      emit(state.copyWith(
        projects: confirmed,
        successMessage: 'Project updated',
      ));
    } on ApiException catch (e) {
      final rolledBack = [...state.projects]..[index] = original;
      emit(state.copyWith(projects: rolledBack, error: e.message));
    }
  }

  Future<void> _onDelete(
    ProjectDeleteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(clearMessages: true));

    final index = state.projects.indexWhere((p) => p.id == event.id);
    if (index == -1) return;
    final original = state.projects[index];

    // Optimistic: remove from list
    final optimisticList = [...state.projects]..removeAt(index);
    emit(state.copyWith(projects: optimisticList));

    try {
      await _repo.deleteProject(event.id);
      emit(state.copyWith(successMessage: 'Project deleted'));
    } on ApiException catch (e) {
      // Rollback
      final rolledBack = [...state.projects]..insert(index, original);
      emit(state.copyWith(projects: rolledBack, error: e.message));
    }
  }
}