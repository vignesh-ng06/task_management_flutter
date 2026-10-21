import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/user_model.dart';
import '../../users/data/user_repository.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../data/models/project.dart';

Future<void> showProjectFormSheet(
  BuildContext context, {
  Project? existing,
}) async {
  final userRepo = context.read<UserRepository>();

  // Fetch active users of the company
  final users = await userRepo.listUsers(isActive: true);

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProjectBloc>(),
      child: _ProjectFormSheet(existing: existing, allUsers: users),
    ),
  );
}

class _ProjectFormSheet extends StatefulWidget {
  final Project? existing;
  final List<User> allUsers;
  const _ProjectFormSheet({this.existing, required this.allUsers});

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _repositoryUrlCtrl = TextEditingController();
  final _designDocsCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  final Set<int> _selectedMemberIds = {};
  String _memberSearch = '';

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
      _selectedMemberIds.addAll(widget.existing!.members.map((m) => m.id));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    _repositoryUrlCtrl.dispose();
    _designDocsCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }

    final memberIds = _selectedMemberIds.toList();

    if (isEdit) {
      context.read<ProjectBloc>().add(
        ProjectUpdateRequested(
          id: widget.existing!.id,
          name: name,
          description: desc.isEmpty ? null : desc,
          memberIds: memberIds,
        ),
      );
    } else {
      context.read<ProjectBloc>().add(
        ProjectCreateRequested(
          name: name,
          description: desc.isEmpty ? null : desc,
          memberIds: memberIds,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final filtered = widget.allUsers.where((u) {
      if (_memberSearch.isEmpty) return true;
      final q = _memberSearch.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(top: 20, bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isEdit ? 'Edit project' : 'New project',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        autofocus: !isEdit,
                        decoration: const InputDecoration(
                          labelText: 'Project name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          Icon(Icons.attach_file, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Project links & files',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _repositoryUrlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Repository URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _designDocsCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Design / Docs',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach file'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _goalCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Goal',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Links will be saved in a future update',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Team members ──
                      Row(
                        children: [
                          const Icon(Icons.group_outlined, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Team members',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedMemberIds.length} selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Selected member chips
                      if (_selectedMemberIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _selectedMemberIds.map((id) {
                              final u = widget.allUsers.firstWhere(
                                (u) => u.id == id,
                              );
                              return Chip(
                                label: Text(u.displayName),
                                onDeleted: () => setState(
                                  () => _selectedMemberIds.remove(id),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                              );
                            }).toList(),
                          ),
                        ),

                      // Search members
                      TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search members…',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (v) => setState(() => _memberSearch = v),
                      ),
                      const SizedBox(height: 8),

                      // Member list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.outlineVariant
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No users found',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final u = filtered[i];
                                  final selected = _selectedMemberIds.contains(
                                    u.id,
                                  );
                                  return CheckboxListTile(
                                    dense: true,
                                    value: selected,
                                    onChanged: (_) {
                                      setState(() {
                                        if (selected) {
                                          _selectedMemberIds.remove(u.id);
                                        } else {
                                          _selectedMemberIds.add(u.id);
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
                                      u.email,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
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
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Submit button pinned at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(isEdit ? 'Save changes' : 'Create project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
