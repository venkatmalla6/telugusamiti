import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/event_model.dart';
import '../../../models/event_registration_model.dart';
import '../../../repositories/event_repository.dart';
import '../../../core/theme/app_colors.dart';

final allEventsProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.watch(eventRepositoryProvider).streamAllEvents();
});

final eventRegistrationsProvider = FutureProvider.family<List<EventRegistrationModel>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).getEventRegistrations(eventId);
});

class EventRegistrationLogsScreen extends ConsumerWidget {
  const EventRegistrationLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        title: const Text('Event Registration Logs'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No events found.'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventLogCard(event: event);
            },
          );
        },
      ),
    );
  }
}

class _EventLogCard extends ConsumerWidget {
  final EventModel event;

  const _EventLogCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationsAsync = ref.watch(eventRegistrationsProvider(event.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: registrationsAsync.when(
        loading: () => ListTile(
          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const SizedBox(
            width: 20, height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, stack) => ListTile(
          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Failed to load registrations', style: TextStyle(color: Colors.red)),
        ),
        data: (registrations) {
          int totalUsers = registrations.length;
          int totalAdults = 0;
          int totalChildren = 0;
          
          for (var reg in registrations) {
            totalAdults += reg.numberOfAdults;
            totalChildren += reg.numberOfChildren;
          }
          
          int totalMembers = totalAdults + totalChildren;

          return InkWell(
            onTap: () {
              context.push('/super_admin/event_registration_logs/${event.id}', extra: event.title);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _StatBadge(label: 'Registrations: $totalUsers', color: Colors.blue),
                      _StatBadge(label: 'Adults: $totalAdults', color: Colors.green),
                      _StatBadge(label: 'Children: $totalChildren', color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.withValues(alpha: 1.0), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryMaroon, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
