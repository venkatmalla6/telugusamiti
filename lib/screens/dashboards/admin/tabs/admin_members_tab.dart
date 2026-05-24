import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/admin_providers.dart';
import '../../../../repositories/admin_repository.dart';
class AdminMembersTab extends ConsumerStatefulWidget {
  const AdminMembersTab({super.key});

  @override
  ConsumerState<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends ConsumerState<AdminMembersTab> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};

  void _toggleSelection(String uid) {
    setState(() {
      if (_selectedIds.contains(uid)) {
        _selectedIds.remove(uid);
      } else {
        _selectedIds.add(uid);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Members'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} selected member(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteUsers(_selectedIds.toList());
      _clearSelection();
    }
  }

  Future<void> _deleteSingle(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Member'),
        content: const Text('Are you sure you want to delete this member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteUser(uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(adminSearchResultsProvider);
    final filter = ref.watch(memberFilterProvider);

    return Column(
      children: [
        // ─── Pending Approvals Button ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/approve_members'),
              icon: const Icon(Icons.how_to_reg, color: Colors.white),
              label: const Text('Review Pending Registrations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A0404),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ─── Search Bar ───────────────────────────────────────────────────
        Container(
          color: const Color(0xFF5C0A0A),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or member ID...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(adminSearchQueryProvider.notifier).set('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              ref.read(adminSearchQueryProvider.notifier).set(value.trim());
            },
          ),
        ),

        // ─── Filter Chips ─────────────────────────────────────────────────
        Container(
          color: const Color(0xFF5C0A0A),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MemberFilter.values.map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: isSelected,
                    onSelected: (_) => ref.read(memberFilterProvider.notifier).set(f),
                    selectedColor: AppColors.primaryMaroon,
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                    checkmarkColor: const Color(0xFF5C0A0A),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ─── Selection Bar ────────────────────────────────────────────────
        if (_selectedIds.isNotEmpty)
          Container(
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedIds.length} Selected',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: _deleteSelected,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _clearSelection,
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ─── Results ──────────────────────────────────────────────────────
        Expanded(
          child: searchResults.when(
            loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            data: (unfilteredUsers) {
              final users = unfilteredUsers.where((u) {
                // Only show fully registered users (must have displayName) unless looking for pending
                if (filter == MemberFilter.pending) {
                  return u.approvalStatus == ApprovalStatus.pending;
                }
                
                // For other filters, user must be approved and have a name
                if (u.approvalStatus != ApprovalStatus.approved) return false;
                if (u.displayName == null || u.displayName!.isEmpty) return false;

                if (filter == MemberFilter.active) {
                  return u.membership?.status == 'active';
                }
                if (filter == MemberFilter.expired) {
                  return u.membership?.status != 'active';
                }
                
                return true;
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No members found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = _selectedIds.contains(user.uid);
                  final isSelectionMode = _selectedIds.isNotEmpty;

                  return _MemberTile(
                    user: user,
                    isSelected: isSelected,
                    isSelectionMode: isSelectionMode,
                    onTap: () {
                      if (isSelectionMode) {
                        _toggleSelection(user.uid);
                      } else {
                        context.push('/admin/members/${user.uid}');
                      }
                    },
                    onLongPress: () => _toggleSelection(user.uid),
                    onDeleteTap: () => _deleteSingle(user.uid),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _filterLabel(MemberFilter f) {
    switch (f) {
      case MemberFilter.all: return 'All';
      case MemberFilter.active: return 'Active';
      case MemberFilter.expired: return 'Expired';
      case MemberFilter.pending: return 'Pending';
    }
  }
}

class _MemberTile extends ConsumerWidget {
  final UserModel user;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDeleteTap;

  const _MemberTile({
    required this.user,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(adminUserSubscriptionProvider(user.uid));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF5C0A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.redAccent : Colors.white10),
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.redAccent : Colors.white54,
                ),
              ),
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.3),
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      (user.displayName?.isNotEmpty == true ? user.displayName! : 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Unknown',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.phoneNumber ?? user.email ?? 'No contact',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _RoleBadge(role: user.role),
                      const SizedBox(width: 6),
                      subAsync.when(
                        data: (sub) => sub != null
                            ? _StatusBadge(
                                label: sub.status.name.toUpperCase(),
                                color: sub.status.name == 'active' ? Colors.green : Colors.orange,
                              )
                            : const _StatusBadge(label: 'NO PLAN', color: Colors.grey),
                        loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDeleteTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case UserRole.superAdmin: color = Colors.purple; label = 'SUPER ADMIN'; break;
      case UserRole.admin: color = AppColors.primaryMaroon; label = 'ADMIN'; break;
      case UserRole.volunteer: color = Colors.blue; label = 'VOLUNTEER'; break;
      default: color = Colors.teal; label = 'MEMBER'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
