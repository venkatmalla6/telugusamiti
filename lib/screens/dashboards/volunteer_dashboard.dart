import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../../providers/auth_provider.dart';

class VolunteerDashboard extends ConsumerWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DoubleBackToExit(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
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
                  Text('Welcome ${user?.displayName ?? 'Volunteer'}!', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Text('Active Role: ${user?.role.name.toUpperCase()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text('${user?.email ?? 'No email'}', style: Theme.of(context).textTheme.bodyLarge),
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
