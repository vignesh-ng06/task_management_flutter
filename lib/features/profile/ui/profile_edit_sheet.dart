import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

void showProfileEditSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: const _ProfileEditSheet(),
    ),
  );
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet();

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _nameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();

  bool _changePassword = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      _toast('Name cannot be empty');
      return;
    }

    if (_changePassword) {
      if (_currentPwCtrl.text.isEmpty) {
        _toast('Enter your current password');
        return;
      }
      if (_newPwCtrl.text.length < 6) {
        _toast('New password must be at least 6 characters');
        return;
      }
    }

    setState(() => _saving = true);

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
          name: name,
          currentPassword:
              _changePassword ? _currentPwCtrl.text : null,
          newPassword:
              _changePassword && _newPwCtrl.text.isNotEmpty
                  ? _newPwCtrl.text
                  : null,
        ));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = context.watch<AuthBloc>().state.user;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error ||
          (prev.user?.name != curr.user?.name) && curr.user != null,
      listener: (context, state) {
        if (_saving) {
          // If we got an error, stop the spinner and show it
          if (state.error != null) {
            setState(() => _saving = false);
            _toast(state.error!);
          } else {
            // Success — close the sheet
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      child: Container(
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Email (read-only)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Change password toggle
              Row(
                children: [
                  Checkbox(
                    value: _changePassword,
                    onChanged: (v) =>
                        setState(() => _changePassword = v ?? false),
                  ),
                  const Text('Change password'),
                ],
              ),

              if (_changePassword) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _currentPwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                    helperText: 'At least 6 characters',
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}