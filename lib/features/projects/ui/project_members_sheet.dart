import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/user_model.dart';
import '../../users/data/user_repository.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../data/models/project.dart';

Future<void> showProjectMembersSheet(
  BuildContext context,
  Project project,
) async {
  final userRepo = context.read<UserRepository>();
  final users = await userRepo.listUsers(isActive: true);

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProjectBloc>(),
      child: _ProjectMembersSheet(project: project, allUsers: users),
    ),
  );
}

class _ProjectMembersSheet extends StatefulWidget {
  final Project project;
  final List<User> allUsers;
  const _ProjectMembersSheet({required this.project, required this.allUsers});

  @override
  State<_ProjectMembersSheet> createState() => _ProjectMembersSheetState();
}

class _ProjectMembersSheetState extends State<_ProjectMembersSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.project.members.map((m) => m.id).toSet();
  }

  void _save() {
    context.read<ProjectBloc>().add(
      ProjectMembersUpdateRequested(widget.project.id, _selected.toList()),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(top: 20, bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage team members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.name,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Member list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.allUsers.length,
                  itemBuilder: (_, i) {
                    final u = widget.allUsers[i];
                    final isSelected = _selected.contains(u.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(u.id);
                          } else {
                            _selected.add(u.id);
                          }
                        });
                      },
                      title: Text(
                        u.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${u.email} · ${u.role}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      secondary: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.indigo.shade50,
                        child: Text(
                          u.initials,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                ),
              ),

              // Save
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('Save (${_selected.length} selected)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
