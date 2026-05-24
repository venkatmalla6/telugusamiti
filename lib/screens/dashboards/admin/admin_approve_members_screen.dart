import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../core/widgets/snackbar_utils.dart';

final pendingUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(userRepositoryProvider).getPendingUsers();
});

class AdminApproveMembersScreen extends ConsumerWidget {
  const AdminApproveMembersScreen({super.key});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, UserModel user, ApprovalStatus status) async {
    try {
      final updatedUser = user.copyWith(approvalStatus: status);
      await ref.read(userRepositoryProvider).updateUser(updatedUser);
      ref.invalidate(pendingUsersProvider);
      if (context.mounted) {
        SnackbarUtils.showSuccess(context, 'User ${status.name} successfully');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Failed to update user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: const Color(0xFF4A0404),
        foregroundColor: Colors.white,
      ),
      body: pendingUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A0404))),
        error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Color(0xFF4A0404)))),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No pending registrations.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A0404)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x80D4AF37)),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF4A0404)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.email ?? 'No Email',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A0404),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Legacy User ID: ${user.legacyUserId ?? 'Not provided'}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4A0404)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateStatus(context, ref, user, ApprovalStatus.rejected),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateStatus(context, ref, user, ApprovalStatus.approved),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A0404),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
