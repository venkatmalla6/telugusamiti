import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../providers/event_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      body: eventAsync.when(
        loading: () => const _EventDetailSkeleton(),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (event) {
          if (event == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Event not found')),
            );
          }
          
          final dateStr = DateFormat('EEE, dd MMM yyyy • hh:mm a').format(event.startDate);
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.primaryMaroon,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      color: const Color(0xFF5C0A0A),
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                        Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      else
                        _buildPlaceholder(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.calendar_today, 'Date & Time', dateStr),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.location_on, 'Location', event.location),
                      if (event.maxCapacity > 0) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.group, 'Capacity', '${event.maxCapacity} people'),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'About this Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description.isNotEmpty ? event.description : 'No description provided.',
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 100), // padding for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: eventAsync.maybeWhen(
        data: (event) {
          if (event == null) return const SizedBox.shrink();
          
          return Consumer(
            builder: (context, ref, child) {
              final registrationAsync = ref.watch(eventRegistrationProvider(event.id));
              
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: registrationAsync.when(
                    data: (reg) {
                      if (reg != null) {
                        int total = 1 + reg.numberOfAdults + reg.numberOfChildren;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You are registered!',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Members: $total (Self: 1, Adults: ${reg.numberOfAdults}, Children: ${reg.numberOfChildren})',
                                style: TextStyle(color: Colors.green.shade800),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/events/${event.id}/ticket/${reg.id}');
                                },
                                icon: const Icon(Icons.qr_code, color: Colors.green),
                                label: const Text('View Ticket', style: TextStyle(color: Colors.green)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.shade700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/events/${event.id}/register');
                                },
                                icon: const Icon(Icons.edit, color: AppColors.primaryMaroon),
                                label: const Text('Update', style: TextStyle(color: AppColors.primaryMaroon)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primaryMaroon),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return FilledButton(
                        onPressed: () {
                          context.push('/events/${event.id}/register');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryMaroon,
      child: const Center(
        child: Icon(Icons.event, size: 80, color: const Color(0x665C0A0A)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryMaroon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryMaroon, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventDetailSkeleton extends StatelessWidget {
  const _EventDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SkeletonBox(height: 250, width: double.infinity, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 24, width: 200),
                  SizedBox(height: 20),
                  SkeletonBox(height: 16, width: double.infinity),
                  SizedBox(height: 12),
                  SkeletonBox(height: 16, width: double.infinity),
                  SizedBox(height: 12),
                  SkeletonBox(height: 16, width: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
