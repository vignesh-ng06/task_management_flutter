import 'package:equatable/equatable.dart';
import '../data/models/project.dart';

enum ProjectListStatus { initial, loading, loaded, error }

class ProjectState extends Equatable {
  final ProjectListStatus status;
  final List<Project> projects;
  final String? error;
  final String? successMessage;

  const ProjectState({
    this.status = ProjectListStatus.initial,
    this.projects = const [],
    this.error,
    this.successMessage,
  });

  ProjectState copyWith({
    ProjectListStatus? status,
    List<Project>? projects,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      error: clearMessages ? null : (error ?? this.error),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, projects, error, successMessage];
}