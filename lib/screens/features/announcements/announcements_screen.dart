import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/announcement_providers.dart';
import 'widgets/announcement_card.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        centerTitle: true,
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return const Center(
              child: Text('No announcements yet. Check back later!'),
            );
          }
          // Sort by latest first (assuming dates are in the model)
          final sortedAnnouncements = [...announcements]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = sortedAnnouncements[index];
              return AnnouncementCard(announcement: announcement);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading announcements: $error'),
        ),
      ),
    );
  }
}
