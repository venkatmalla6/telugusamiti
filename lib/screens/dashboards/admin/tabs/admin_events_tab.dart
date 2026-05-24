import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../providers/event_providers.dart';
import '../../../../repositories/event_repository.dart';

class AdminEventsTab extends ConsumerWidget {
  const AdminEventsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/events/create'),
        backgroundColor: AppColors.primaryMaroon,
        icon: const Icon(Icons.add, color: const Color(0xFF5C0A0A)),
        label: const Text('New Event', style: TextStyle(color: const Color(0xFF5C0A0A), fontWeight: FontWeight.bold)),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No events yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/events/create'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                    icon: const Icon(Icons.add, color: const Color(0xFF5C0A0A)),
                    label: const Text('Create First Event', style: TextStyle(color: const Color(0xFF5C0A0A))),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final upcoming = events.where((e) => e.startDate.isAfter(now)).toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final past = events.where((e) => e.startDate.isBefore(now)).toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming (${upcoming.length})'),
                const SizedBox(height: 8),
                ...upcoming.map((e) => _AdminEventCard(event: e)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeader(title: 'Past (${past.length})'),
                const SizedBox(height: 8),
                ...past.map((e) => _AdminEventCard(event: e)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(color: const Color(0xB35C0A0A), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }
}

class _AdminEventCard extends ConsumerWidget {
  final EventModel event;
  const _AdminEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = event.startDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5C0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPast ? Colors.white10 : AppColors.primaryMaroon.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/admin/events/edit/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date block
              Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey.shade900 : AppColors.primaryMaroon.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('d').format(event.startDate),
                      style: TextStyle(
                        color: isPast ? Colors.grey : AppColors.primaryGold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(event.startDate).toUpperCase(),
                      style: TextStyle(color: isPast ? Colors.grey.shade600 : Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: isPast ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _TagChip(
                          label: event.isPublished ? 'Published' : 'Draft',
                          color: event.isPublished ? Colors.green : Colors.orange,
                        ),
                        if (event.hasFood) _TagChip(label: '🍽️ Food', color: Colors.orange),
                        if (isPast) const _TagChip(label: 'Past', color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: const Color(0xFF5C0A0A), size: 20),
                    onPressed: () => context.push('/admin/events/edit/${event.id}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(context, ref),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF5C0A0A),
        title: const Text('Delete Event', style: TextStyle(color: const Color(0xFF5C0A0A))),
        content: Text('Delete "${event.title}"? This cannot be undone.', style: TextStyle(color: const Color(0xB35C0A0A))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) {
      await ref.read(eventRepositoryProvider).deleteEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
