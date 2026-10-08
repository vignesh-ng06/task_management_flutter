import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../data/models/project.dart';

void showProjectFormSheet(BuildContext context, {Project? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProjectBloc>(),
      child: _ProjectFormSheet(existing: existing),
    ),
  );
}

class _ProjectFormSheet extends StatefulWidget {
  final Project? existing;
  const _ProjectFormSheet({this.existing});

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
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

    if (isEdit) {
      context.read<ProjectBloc>().add(ProjectUpdateRequested(
            id: widget.existing!.id,
            name: name,
            description: desc.isEmpty ? null : desc,
          ));
    } else {
      context.read<ProjectBloc>().add(ProjectCreateRequested(
            name: name,
            description: desc.isEmpty ? null : desc,
          ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit project' : 'New project',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(isEdit ? 'Save changes' : 'Create project'),
            ),
          ],
        ),
      ),
    );
  }
}