import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/user_model.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';

void showUserFormSheet(BuildContext context, {User? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UserBloc>(),
      child: _UserFormSheet(existing: existing),
    ),
  );
}

class _UserFormSheet extends StatefulWidget {
  final User? existing;
  const _UserFormSheet({this.existing});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _role;
  bool _isSubmitting = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _emailCtrl.text = widget.existing!.email;
      _nameCtrl.text = widget.existing!.name ?? '';
      _role = widget.existing!.role;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final role = _role;
    if (role == null) return;

    if (isEdit) {
      final bloc = context.read<UserBloc>();
      setState(() => _isSubmitting = true);
      bloc.add(
        UserUpdateRequested(
          id: widget.existing!.id,
          name: name,
          role: role,
          password: password.isEmpty ? null : password,
        ),
      );
    } else {
      context.read<UserBloc>().add(
        UserCreateRequested(
          email: email,
          password: password,
          name: name,
          role: role,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _confirmDeactivate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate user?'),
        content: Text(
          '${widget.existing!.displayName} will no longer be able to log in. '
          'Their data will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserBloc>().add(
                UserDeactivateRequested(widget.existing!.id),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final inactive = isEdit && widget.existing!.isActive == false;

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
      child: BlocListener<UserBloc, UserState>(
        listenWhen: (previous, current) =>
            previous.successMessage != current.successMessage ||
            previous.error != current.error,
        listener: (context, state) {
          if (state.successMessage == 'User updated') {
            Navigator.of(context).pop();
          } else if (state.error != null && mounted) {
            setState(() => _isSubmitting = false);
          }
        },
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Edit user' : 'Create user',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailCtrl,
                  enabled: !isEdit, // email cannot be changed
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Enter an email';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameCtrl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _role,
                  validator: (value) => value == null ? 'Select a role' : null,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  validator: (value) {
                    final password = value ?? '';
                    if (!isEdit && password.isEmpty) {
                      return 'Enter a password';
                    }
                    if (!isEdit && password.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (isEdit && password.isNotEmpty && password.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'New password (leave blank to keep)'
                        : 'Password',
                    border: const OutlineInputBorder(),
                    helperText: isEdit
                        ? 'Leave empty to keep the current one'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save changes' : 'Create user'),
                ),

                if (isEdit && !inactive) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _confirmDeactivate,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Deactivate user'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
