import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DoubleBackToExit(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          )
        ],
      ),
      body: Center(
        child: Consumer(
          builder: (context, ref, child) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.when(
              data: (user) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome ${user?.displayName ?? 'Admin'}!', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Text('Active Role: ${user?.role.name.toUpperCase()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text('${user?.email ?? 'No email'}', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.campaign),
                    title: const Text('Manage Announcements'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/admin/create-announcement'),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error loading user: $e'),
            );
          },
        ),
      ),
      ),
    );
  }
}
