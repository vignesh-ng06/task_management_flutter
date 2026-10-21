import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_header.dart';
import '../../auth/data/user_model.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../data/user_repository.dart';
import 'user_detail_screen.dart';
import 'user_form_sheet.dart';

// ── Design tokens ──
const _kPrimary = Color(0xFF4F46E5);
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);
const _kTextDark = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextLight = Color(0xFF94A3B8);
const _kSuccess = Color(0xFF10B981);
const _kInfo = Color(0xFF3B82F6);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _screenBackground(BuildContext context) =>
    _isDark(context) ? Theme.of(context).colorScheme.surface : _kBg;

Color _cardBackground(BuildContext context) => _isDark(context)
    ? Theme.of(context).colorScheme.surfaceContainerLow
    : Colors.white;

Color _borderColor(BuildContext context) =>
    _isDark(context) ? Theme.of(context).colorScheme.outlineVariant : _kBorder;

Color _mutedTextColor(BuildContext context) => _isDark(context)
    ? Theme.of(context).colorScheme.onSurfaceVariant
    : _kTextMuted;

Color _lightTextColor(BuildContext context) => _isDark(context)
    ? Theme.of(context).colorScheme.onSurfaceVariant
    : _kTextLight;

Color _roleColor(String role) {
  switch (role) {
    case 'admin':
      return const Color(0xFF7C3AED);
    case 'manager':
      return const Color(0xFF2563EB);
    default:
      return const Color(0xFF64748B);
  }
}

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

  void _reload(BuildContext context) {
    final includeInactive = context.read<UserBloc>().state.includeInactive;
    context.read<UserBloc>().add(
      UsersLoadRequested(includeInactive: includeInactive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground(context),
      appBar: AppHeader(section: 'Users'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users-add-user',
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => showUserFormSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add user'),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          if (state.successMessage != null) {
            final isUpdate = state.successMessage == 'User updated';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isUpdate
                      ? 'User updated'
                      : state.successMessage == 'User created successfully'
                      ? 'User created'
                      : state.successMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: isUpdate ? _kInfo : _kSuccess,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.error ?? 'Error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<UserBloc>().add(
                      const UsersLoadRequested(),
                    ),
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

          final noUsersAtAll =
              state.users.isEmpty &&
              !state.includeInactive &&
              state.roleFilter == 'all';

          int roleCount(String role) =>
              state.users.where((u) => u.role == role).length;

          return Column(
            children: [
              // ── Control panel (search + toggle + role chips with counts) ──
              Container(
                decoration: BoxDecoration(
                  color: _cardBackground(context),
                  border: Border(
                    bottom: BorderSide(color: _borderColor(context)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SearchField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            showClear: _query.isNotEmpty,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusToggle(
                          includeInactive: state.includeInactive,
                          onChanged: (value) => context.read<UserBloc>().add(
                            UsersLoadRequested(includeInactive: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            value: 'all',
                            count: state.users.length,
                          ),
                          _FilterChip(
                            label: 'Admin',
                            value: 'admin',
                            count: roleCount('admin'),
                          ),
                          _FilterChip(
                            label: 'Manager',
                            value: 'manager',
                            count: roleCount('manager'),
                          ),
                          _FilterChip(
                            label: 'Employee',
                            value: 'employee',
                            count: roleCount('employee'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Result count ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Text(
                      '${displayList.length} ${displayList.length == 1 ? 'member' : 'members'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _mutedTextColor(context),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      state.includeInactive ? 'Inactive' : 'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _lightTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: displayList.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async => _reload(context),
                        child: LayoutBuilder(
                          builder: (context, constraints) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: _UsersEmptyState(
                                    title: _query.isNotEmpty
                                        ? 'No users match "$_query"'
                                        : noUsersAtAll
                                        ? 'No teammates yet'
                                        : state.includeInactive
                                        ? 'No inactive users'
                                        : 'No users match this role',
                                    subtitle: _query.isNotEmpty
                                        ? 'Try a different name or email.'
                                        : noUsersAtAll
                                        ? 'Add your first team member to start assigning tasks.'
                                        : state.includeInactive
                                        ? 'There are no inactive teammates to show.'
                                        : 'Try another role filter to see more teammates.',
                                    onAdd: _query.isEmpty && noUsersAtAll
                                        ? () => showUserFormSheet(context)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _reload(context);
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: displayList.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final user = displayList[i];
                            return _UserCard(
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

// ─────────────────────────────────────────────
// Search + status toggle
// ─────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: _isDark(context)
              ? Theme.of(context).colorScheme.onSurface
              : _kTextDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search name or email',
          hintStyle: TextStyle(fontSize: 13, color: _lightTextColor(context)),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: _lightTextColor(context),
          ),
          suffixIcon: showClear
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: _lightTextColor(context),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: _screenBackground(context),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isDark(context)
                  ? Theme.of(context).colorScheme.primary
                  : _kPrimary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool includeInactive;
  final ValueChanged<bool> onChanged;

  const _StatusToggle({required this.includeInactive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool value) {
      final selected = includeInactive == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) onChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _mutedTextColor(context),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _screenBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('Active', false), seg('Inactive', true)],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Role filter chips
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final current = context.watch<UserBloc>().state.roleFilter;
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _mutedTextColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : _borderColor(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _mutedTextColor(context),
                ),
              ),
            ),
          ],
        ),
        selected: selected,
        selectedColor: _kPrimary,
        backgroundColor: _cardBackground(context),
        side: BorderSide(color: selected ? _kPrimary : _borderColor(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) =>
            context.read<UserBloc>().add(UserFilterChanged(value)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// User card
// ─────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final User user;
  const _UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final inactive = user.isActive == false;
    final color = _roleColor(user.role);

    return Material(
      color: _cardBackground(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<UserBloc>(),
              child: UserDetailScreen(user: user),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: inactive
                        ? Colors.grey.shade200
                        : color.withValues(alpha: 0.12),
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: inactive ? Colors.grey : color,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: inactive ? _kTextLight : _kSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cardBackground(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name, email, badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: inactive
                            ? _lightTextColor(context)
                            : _isDark(context)
                            ? Theme.of(context).colorScheme.onSurface
                            : _kTextDark,
                        decoration: inactive
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _mutedTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Badge(label: user.role.toUpperCase(), color: color),
                        if (inactive)
                          const _Badge(label: 'INACTIVE', color: Colors.red),
                        _ProjectsBadge(count: user.projectCount),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: _lightTextColor(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _ProjectsBadge extends StatelessWidget {
  final int count;
  const _ProjectsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    final color = _mutedTextColor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.folder_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          empty
              ? 'No projects'
              : '$count ${count == 1 ? 'project' : 'projects'}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _UsersEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  const _UsersEmptyState({
    required this.title,
    required this.subtitle,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 40,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _kTextMuted),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add user'),
            ),
          ],
        ],
      ),
    );
  }
}
