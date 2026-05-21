import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/super_admin_providers.dart';
import '../../../models/admin_profile_model.dart';
import '../../../core/utils/snackbar_utils.dart';

class AdminPermissionsScreen extends ConsumerStatefulWidget {
  final String adminId;

  const AdminPermissionsScreen({super.key, required this.adminId});

  @override
  ConsumerState<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends ConsumerState<AdminPermissionsScreen> {
  final List<String> _currentPermissions = [];
  bool _isInitialized = false;

  void _togglePermission(String perm, bool? value) {
    setState(() {
      if (value == true) {
        _currentPermissions.add(perm);
      } else {
        _currentPermissions.remove(perm);
      }
    });
  }

  Future<void> _savePermissions() async {
    try {
      await ref.read(superAdminNotifierProvider.notifier).updateAdminPermissions(widget.adminId, _currentPermissions);
      if (mounted) {
        showSuccessSnackBar(context, 'Permissions updated successfully.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to update: $e');
      }
    }
  }

  void _confirmRevoke() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Admin Access?'),
        content: const Text('This will demote the user back to a standard User and delete their admin profile. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(superAdminNotifierProvider.notifier).revokeAdminAccess(widget.adminId);
                if (mounted) {
                  showSuccessSnackBar(context, 'Admin access revoked.');
                  Navigator.pop(context); // close screen
                }
              } catch (e) {
                if (mounted) showErrorSnackBar(context, 'Failed to revoke: $e');
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adminProfileProvider(widget.adminId));
    final isLoading = ref.watch(superAdminNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Revoke Admin Access',
            onPressed: _confirmRevoke,
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Admin profile not found.'));
          }

          if (!_isInitialized) {
            _currentPermissions.addAll(profile.permissions);
            _isInitialized = true;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Department: ${profile.department}', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: PermissionMatrix.allPermissions.map((perm) {
                    return CheckboxListTile(
                      title: Text(perm.replaceAll('_', ' ').toUpperCase()),
                      value: _currentPermissions.contains(perm),
                      onChanged: (val) => _togglePermission(perm, val),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : _savePermissions,
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Save Permissions'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
