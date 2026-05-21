import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/super_admin_providers.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/snackbar_utils.dart';

class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  final _emailController = TextEditingController();
  final _deptController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _promoteAdmin() async {
    final email = _emailController.text.trim();
    final dept = _deptController.text.trim();
    if (email.isEmpty || dept.isEmpty) return;

    try {
      await ref.read(superAdminNotifierProvider.notifier).promoteUserToAdmin(email, dept);
      if (mounted) {
        showSuccessSnackBar(context, 'Successfully promoted user to Admin');
        _emailController.clear();
        _deptController.clear();
        Navigator.pop(context); // close dialog
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to promote user: $e');
      }
    }
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of an existing user to promote them to Admin.'),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deptController,
              decoration: const InputDecoration(
                labelText: 'Department / Role Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final isL = ref.read(superAdminNotifierProvider).isLoading;
              if (!isL) _promoteAdmin();
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(allAdminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Admin'),
      ),
      body: adminsAsync.when(
        data: (admins) {
          if (admins.isEmpty) {
            return const Center(child: Text('No admins found.'));
          }
          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final isSuper = admin.role == UserRole.superAdmin;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: admin.photoUrl != null ? NetworkImage(admin.photoUrl!) : null,
                  child: admin.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(admin.displayName ?? admin.email ?? 'Unknown User'),
                subtitle: Text('${isSuper ? 'Super Admin' : 'Admin'} • ${admin.email ?? ''}'),
                trailing: isSuper 
                  ? const Chip(label: Text('SuperAdmin'), backgroundColor: Colors.amber)
                  : IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      onPressed: () => context.push('/super-admin/manage-admins/permissions/${admin.uid}'),
                      tooltip: 'Manage Permissions',
                    ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
