import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/event_model.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/event_providers.dart';
import 'package:go_router/go_router.dart';

class EventsTab extends ConsumerStatefulWidget {
  const EventsTab({super.key});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async => ref.invalidate(upcomingEventsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Events'),
              pinned: true,
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: eventsAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _EventListSkeleton(),
                    ),
                    childCount: 4,
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'Could not load events',
                    subtitle: 'Please check your internet connection',
                    actionLabel: 'Try Again',
                    onAction: () => ref.invalidate(upcomingEventsProvider),
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.event_note,
                        title: 'No Upcoming Events',
                        subtitle: 'The Samiti has not announced any upcoming events yet. Check back soon!',
                        actionLabel: 'Refresh',
                        onAction: () => ref.invalidate(upcomingEventsProvider),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _EventListTile(event: events[index]),
                      childCount: events.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListTile extends ConsumerWidget {
  final EventModel event;
  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationAsync = ref.watch(eventRegistrationProvider(event.id));
    final dateStr = DateFormat('EEE, dd MMM • hh:mm a').format(event.startDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/events/${event.id}'),
        child: Row(
          children: [
            // Date block on left
            Container(
              width: 70,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primaryMaroon,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.d().format(event.startDate),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat.MMM().format(event.startDate).toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: AppColors.primaryMaroon),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryMaroon),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.maxCapacity > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Capacity: ${event.maxCapacity}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (event.hasFood) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '🍽️ Food Included',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListSkeleton extends StatelessWidget {
  const _EventListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const SkeletonBox(width: 70, height: 100, borderRadius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 16, width: 180),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 140),
                SizedBox(height: 6),
                SkeletonBox(height: 12, width: 120),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
