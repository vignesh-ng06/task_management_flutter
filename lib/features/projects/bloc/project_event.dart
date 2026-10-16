import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

class ProjectsLoadRequested extends ProjectEvent {
  final bool includeInactive;
  const ProjectsLoadRequested({this.includeInactive = false});
  @override
  List<Object?> get props => [includeInactive];
}

class ProjectCreateRequested extends ProjectEvent {
  final String name;
  final String? description;
  final List<int> memberIds;
  const ProjectCreateRequested({required this.name, this.description, this.memberIds = const []});
  @override
  List<Object?> get props => [name, description, memberIds];
}

class ProjectUpdateRequested extends ProjectEvent {
  final int id;
  final String? name;
  final String? description;
  final List<int>? memberIds;
  const ProjectUpdateRequested({required this.id, this.name, this.description, this.memberIds});
  @override
  List<Object?> get props => [id, name, description, memberIds];
}

class ProjectDeleteRequested extends ProjectEvent {
  final int id;
  const ProjectDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ProjectMembersUpdateRequested extends ProjectEvent {
  final int projectId;
  final List<int> memberIds;
  const ProjectMembersUpdateRequested(this.projectId, this.memberIds);
  @override
  List<Object?> get props => [projectId, memberIds];
}