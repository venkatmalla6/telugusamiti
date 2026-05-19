import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/event_model.dart';
import '../../../models/announcement_model.dart';
import '../../../models/subscription_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primaryMaroon,
      onRefresh: () async {
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(announcementsStreamProvider);
        ref.invalidate(userSubscriptionProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _MembershipBanner(),
                  const SizedBox(height: 24),
                  _QuickActionsRow(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Upcoming Events', onSeeAll: () => context.go('/user/events')),
                  const SizedBox(height: 12),
                  _UpcomingEventsRow(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Announcements', onSeeAll: null),
                  const SizedBox(height: 12),
                  _AnnouncementsList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final name = userAsync.value?.displayName ?? 'Member';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryMaroon,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryMaroon, Color(0xFF5C0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('🙏 ', style: TextStyle(fontSize: 22)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryGold),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Membership Status Banner ─────────────────────────────────────────────────
class _MembershipBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(userSubscriptionProvider);

    return subAsync.when(
      loading: () => const MembershipSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sub) {
        final isActive = sub?.status == SubscriptionStatus.active;
        final expiry = sub != null
            ? DateFormat.yMMMd().format(sub.endDate)
            : null;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isActive
                  ? [AppColors.primaryMaroon, const Color(0xFF9A0007)]
                  : [Colors.orange.shade800, Colors.deepOrange.shade700],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMaroon.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.verified_user : Icons.warning_amber_rounded,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Active Member' : 'Membership Expired',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isActive && expiry != null)
                      Text(
                        'Valid until $expiry',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      )
                    else if (!isActive)
                      Text(
                        'Renew now to enjoy full benefits',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    if (sub == null)
                      const Text(
                        'No membership found',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              if (!isActive)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('Renew', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> _actions = const [
    _QuickAction(icon: Icons.event, label: 'Events', color: Color(0xFF800000)),
    _QuickAction(icon: Icons.family_restroom, label: 'Family', color: Color(0xFF1565C0)),
    _QuickAction(icon: Icons.payment, label: 'Pay Dues', color: Color(0xFF2E7D32)),
    _QuickAction(icon: Icons.photo_library, label: 'Gallery', color: Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _actions
          .map((a) => _QuickActionButton(action: a))
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: action.color.withValues(alpha: 0.25)),
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }
}

// ── Upcoming Events Horizontal Scroll ─────────────────────────────────────────
class _UpcomingEventsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return SizedBox(
      height: 200,
      child: eventsAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => const EventSkeleton(),
        ),
        error: (_, __) => const EmptyStateWidget(
          icon: Icons.event_busy,
          title: 'Could not load events',
          subtitle: 'Pull to refresh',
        ),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_note,
              title: 'No upcoming events',
              subtitle: 'Check back later for new events',
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) => _EventCard(event: events[index]),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.MMMd().format(event.startDate);
    final dayStr = DateFormat.EEEE().format(event.startDate);

    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: event.imageUrl != null
                  ? Image.network(event.imageUrl!, height: 110, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _eventPlaceholder())
                  : _eventPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppColors.primaryMaroon),
                        const SizedBox(width: 4),
                        Text('$dayStr, $dateStr',
                            style: const TextStyle(fontSize: 11, color: AppColors.primaryMaroon)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventPlaceholder() {
    return Container(
      height: 110,
      color: AppColors.primaryMaroon.withValues(alpha: 0.15),
      child: const Center(child: Icon(Icons.celebration, color: AppColors.primaryMaroon, size: 36)),
    );
  }
}

// ── Announcements List ────────────────────────────────────────────────────────
class _AnnouncementsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annAsync = ref.watch(announcementsStreamProvider);

    return annAsync.when(
      loading: () => Column(
        children: List.generate(3, (_) => const AnnouncementSkeleton()),
      ),
      error: (_, __) => const EmptyStateWidget(
        icon: Icons.announcement,
        title: 'Could not load announcements',
        subtitle: 'Pull to refresh',
      ),
      data: (announcements) {
        if (announcements.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
            subtitle: 'Check back later for updates from the Samiti',
          );
        }
        final sorted = [...announcements]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final preview = sorted.take(3).toList();
        return Column(
          children: preview
              .map((a) => _AnnouncementTile(announcement: a))
              .toList(),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementTile({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign, color: AppColors.primaryMaroon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat.yMMMd().format(announcement.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
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
