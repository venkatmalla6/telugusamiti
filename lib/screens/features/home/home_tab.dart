import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/event_model.dart';
import '../../../models/subscription_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/event_providers.dart';
import 'widgets/custom_home_app_bar.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final name = userAsync.value?.displayName?.split(' ').first ?? 'Member';
    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12 ? 'శుభ ఉదయం' : hour < 17 ? 'శుభ మధ్యాహ్నం' : 'శుభ సాయంత్రం';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6), // Cream background
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async {
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(userSubscriptionProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CustomHomeAppBar(
              greetingTitle: '$greetingPrefix ☀️',
              greetingSubtitle: 'స్వాగతం, $name 🙏',
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Membership banner removed as per request
                    _QuickActionsRow(),
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'రాబోయే ఈవెంట్స్', onSeeAll: () => context.go('/user/events')),
                    const SizedBox(height: 12),
                    _UpcomingEventsRow(),
                    const SizedBox(height: 24),
                    _QuoteBanner(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
        final now = DateTime.now();
        final isExpired = sub != null && sub.endDate.isBefore(now);
        final isActive = sub?.status == SubscriptionStatus.active && !isExpired;
        final daysRemaining = sub != null ? sub.endDate.difference(now).inDays : 0;
        final isExpiringSoon = isActive && daysRemaining <= 30;
        
        final expiry = sub != null ? DateFormat.yMMMd().format(sub.endDate) : null;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFCC5500), Color(0xFF8B2500)], // Orange to dark red gradient
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
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
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium, // Crown-like icon
                  color: Color(0xFFF9E8B6),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpired ? 'Membership Expired' : (isActive ? 'Active Member' : 'No Membership'),
                      style: TextStyle(
                        color: isExpiringSoon || isExpired ? Colors.yellowAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isExpiringSoon) ...[
                      Text(
                        'Renews in $daysRemaining days ($expiry)',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Text(
                        isActive && expiry != null 
                            ? 'Valid until $expiry' 
                            : 'Renew now to enjoy full benefits',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                    if (sub == null) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'No membership found',
                        style: TextStyle(color: Color(0xFFF9E8B6), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isActive || isExpiringSoon)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9E8B6),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.push('/membership/plans'),
                  child: Text(isActive ? 'Renew Early' : 'Renew', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Primary Quick Actions ───────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> _actions = const [
    _QuickAction(icon: Icons.calendar_today, label: 'ఈవెంట్స్', color: Color(0xFF5C0A0A)),
    _QuickAction(icon: Icons.family_restroom, label: 'ఫ్యామిలీ', color: Color(0xFF3F51B5)),
    _QuickAction(icon: Icons.credit_card, label: 'ఫీజు వివరాలు', color: Color(0xFF2E7D32)),
    _QuickAction(icon: Icons.photo_library, label: 'గ్యాలరీ', color: Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _actions.map((a) => _QuickActionButton(action: a)).toList(),
    );
  }
}



class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});
}

class _QuickActionButton extends ConsumerWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        switch (action.label) {
          case 'ఈవెంట్స్':
            ref.read(userDashboardIndexProvider.notifier).set(1);
            break;
          case 'ఫ్యామిలీ':
            context.push('/profile/family');
            break;
          case 'ఫీజు వివరాలు':
            context.push('/membership/plans');
            break;
          case 'గ్యాలరీ':
            ref.read(userDashboardIndexProvider.notifier).set(3);
            break;
        }
      },
      child: Container(
        width: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x4DD4AF37)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5C0A0A),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
          style: const TextStyle(
            color: Color(0xFF5C0A0A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                const Text(
                  'అన్ని చూడండి',
                  style: TextStyle(color: Color(0xFF7D0E0E), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF7D0E0E)),
              ],
            ),
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
      height: 140, // Reduced height for horizontal list to match mockup
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

class _EventCard extends ConsumerWidget {
  final EventModel event;
  const _EventCard({required this.event});

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
      width: 280,
      margin: const EdgeInsets.only(right: 16),
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
            
            // Content right side
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
              width: 50,
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        style: const TextStyle(color: Color(0xFF5C0A0A), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${event.startDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
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

  Widget _eventPlaceholder() {
    return Container(
      color: AppColors.primaryMaroon.withOpacity(0.15),
      child: const Center(child: Icon(Icons.celebration, color: AppColors.primaryMaroon, size: 36)),
    );
  }
}

// ── Quote Banner ────────────────────────────────────────────────────────────
class _QuoteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF4A0404),
        image: const DecorationImage(
          image: AssetImage('assets/images/login_bg.png'), // Reuse asset for subtle background texture
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: const Column(
        children: [
          Text(
            '"మన భాష - మన బాట"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFF9E8B6), fontSize: 16, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 4),
          Text(
            '"మన సంస్కృతి - మన గౌరవం"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFF9E8B6), fontSize: 16, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Icon(Icons.spa, color: Color(0xFFD4AF37), size: 16),
        ],
      ),
    );
  }
}


