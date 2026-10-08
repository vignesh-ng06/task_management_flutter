import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (user.name?.isNotEmpty == true ? user.name![0] : user.email[0])
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.name ?? 'No name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(label: 'Role', value: user.role),
                _InfoTile(
                  label: 'Company ID',
                  value: user.companyId?.toString() ?? 'Not available',
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}