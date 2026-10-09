import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../data/user_repository.dart';
import 'user_form_sheet.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UserBloc(context.read<UserRepository>())
            ..add(const UsersLoadRequested()),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final includeInactive =
                  context.read<UserBloc>().state.includeInactive;
              context.read<UserBloc>().add(
                    UsersLoadRequested(includeInactive: includeInactive),
                  );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserFormSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add user'),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == UserListStatus.loading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == UserListStatus.error && state.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.error ?? 'Error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<UserBloc>()
                        .add(const UsersLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Client-side search on top of the server-fetched list
          final q = _query.trim().toLowerCase();
          final displayList = state.filteredUsers.where((u) {
            if (q.isEmpty) return true;
            final name = (u.name ?? '').toLowerCase();
            final email = u.email.toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();

          return Column(
            children: [
              // ── Active / Inactive toggle ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Active'),
                      icon: Icon(Icons.check, size: 16),
                    ),
                    ButtonSegment(value: true, label: Text('Inactive')),
                  ],
                  selected: {state.includeInactive},
                  onSelectionChanged: (selection) =>
                      context.read<UserBloc>().add(
                            UsersLoadRequested(
                              includeInactive: selection.single,
                            ),
                          ),
                  style: ButtonStyle(
                    foregroundColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.black87;
                    }),
                    backgroundColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF4F46E5);
                      }
                      return Colors.white;
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              // ── Role filter chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: const [
                    _FilterChip(label: 'All', value: 'all'),
                    _FilterChip(label: 'Admin', value: 'admin'),
                    _FilterChip(label: 'Manager', value: 'manager'),
                    _FilterChip(label: 'Employee', value: 'employee'),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.includeInactive
                                  ? Icons.group_off_outlined
                                  : Icons.person_off_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _query.isNotEmpty
                                  ? 'No users match "$_query"'
                                  : (state.includeInactive
                                      ? 'No inactive users'
                                      : 'No active users'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final includeInactive = context
                              .read<UserBloc>()
                              .state
                              .includeInactive;
                          context.read<UserBloc>().add(
                                UsersLoadRequested(
                                  includeInactive: includeInactive,
                                ),
                              );
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) {
                            final user = displayList[i];
                            return _UserTile(
                              key: ValueKey(
                                'user-${user.id}-${user.name}-${user.role}-${user.isActive}',
                              ),
                              user: user,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  const _FilterChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<UserBloc>().state.roleFilter;
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
        selected: selected,
        selectedColor: const Color(0xFF4F46E5),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        showCheckmark: false,
        onSelected: (_) =>
            context.read<UserBloc>().add(UserFilterChanged(value)),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final dynamic user;
  const _UserTile({super.key, required this.user});

  Color get _roleColor {
    switch (user.role) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inactive = user.isActive == false;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor:
            inactive ? Colors.grey.shade300 : _roleColor.withOpacity(0.15),
        child: Text(
          user.initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: inactive ? Colors.grey : _roleColor,
          ),
        ),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: inactive ? Colors.grey : null,
          decoration: inactive ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _roleColor,
                  ),
                ),
              ),
              if (inactive) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'INACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showUserFormSheet(context, existing: user),
    );
  }
}