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
              foregroundColor: const Color(0xFF5C0A0A),
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

  Widget _eventPlaceholder() {
    return Container(
      color: AppColors.primaryMaroon.withOpacity(0.1),
      child: const Icon(Icons.event, color: AppColors.primaryMaroon, size: 40),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthStr = DateFormat.MMM().format(event.startDate).toUpperCase();
    final dayStr = DateFormat.d().format(event.startDate);
    
    // In Telugu
    final monthsTelugu = {
      'JAN': 'జన', 'FEB': 'ఫిబ్', 'MAR': 'మార్చి', 'APR': 'ఏప్రి', 'MAY': 'మే', 'JUN': 'జూన్',
      'JUL': 'జూలై', 'AUG': 'ఆగ', 'SEP': 'సెప్టె', 'OCT': 'అక్టో', 'NOV': 'నవం', 'DEC': 'డిసెం'
    };
    final teluguMonth = monthsTelugu[monthStr] ?? monthStr;

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DD4AF37)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/events/${event.id}'),
        child: Row(
          children: [
            // Image left side
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: double.infinity,
                child: event.imageUrl != null
                    ? Image.network(event.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _eventPlaceholder())
                    : _eventPlaceholder(),
              ),
            ),
            
            // Content middle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C0A0A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('రాబోయేది', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF7D0E0E)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.isNotEmpty ? event.location : 'అణు కల్పక్కం కమ్యూనిటీ హాల్',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5C0A0A)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Date right side
            Container(
              width: 55,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5C0A0A),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      teluguMonth,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        dayStr,
                        style: const TextStyle(color: Color(0xFF5C0A0A), fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
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
