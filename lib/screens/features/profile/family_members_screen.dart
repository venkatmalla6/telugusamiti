import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../providers/features/profile_providers.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.family_restroom_outlined,
              title: 'No Family Members',
              subtitle: 'Add your family members to get them access to Samiti events and benefits.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.1),
                    child: Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                      style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${member.relationship}'
                    '${member.dateOfBirth != null ? ' • ${DateFormat.yMMMd().format(member.dateOfBirth!)}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      // TODO: Implement delete
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/profile/family/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }
}
