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
  const ProjectCreateRequested({required this.name, this.description});
  @override
  List<Object?> get props => [name, description];
}

class ProjectUpdateRequested extends ProjectEvent {
  final int id;
  final String? name;
  final String? description;
  const ProjectUpdateRequested({required this.id, this.name, this.description});
  @override
  List<Object?> get props => [id, name, description];
}

class ProjectDeleteRequested extends ProjectEvent {
  final int id;
  const ProjectDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}