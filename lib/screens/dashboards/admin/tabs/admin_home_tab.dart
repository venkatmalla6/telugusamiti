import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/admin_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/event_providers.dart';
import '../../../features/home/widgets/custom_home_app_bar.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final eventsAsync = ref.watch(allEventsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final name = userAsync.value?.displayName?.split(' ').first ?? 'Admin';
    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12 ? 'శుభ ఉదయం' : hour < 17 ? 'శుభ మధ్యాహ్నం' : 'శుభ సాయంత్రం';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6), // Cream background
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async {
          ref.invalidate(adminAnalyticsProvider);
          ref.invalidate(allEventsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CustomHomeAppBar(
              greetingTitle: '$greetingPrefix ☀️',
              greetingSubtitle: 'స్వాగతం, $name 🙏',
              showMenu: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C0A0A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF5C0A0A).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.admin_panel_settings, color: Color(0xFF5C0A0A), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Color(0xFF5C0A0A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Quick Actions ─────────────────────────────────────────────
                    const Text('త్వరిత చర్యలు (Quick Actions)', style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin/notifications/manage'),
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Manage\nNotifications', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: const Color(0xFF5C0A0A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin/events/create'),
                            icon: const Icon(Icons.add_box),
                            label: const Text('Create\nEvent', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Stats Cards ─────────────────────────────────────────────
                    const Text('అవలోకనం (Overview)', style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    analyticsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon)),
                      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                      data: (stats) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _StatCard(
                            icon: Icons.people_rounded,
                            label: 'Total Members',
                            value: '${stats['totalMembers'] ?? 0}',
                            color: const Color(0xFFE65100),
                          ),
                          _StatCard(
                            icon: Icons.card_membership_rounded,
                            label: 'Active Subscriptions',
                            value: '${stats['activeSubscriptions'] ?? 0}',
                            color: const Color(0xFF00695C),
                          ),
                          _StatCard(
                            icon: Icons.event_rounded,
                            label: 'Total Events',
                            value: '${stats['totalEvents'] ?? 0}',
                            color: const Color(0xFF1565C0),
                          ),
                          _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            label: 'Total Collection',
                            value: '₹${stats['totalCollection'] ?? 0}',
                            color: const Color(0xFF5C0A0A),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Upcoming Events ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('రాబోయే ఈవెంట్స్ (Upcoming)', style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => ref.read(adminTabProvider.notifier).set(2),
                          child: Row(
                            children: const [
                              Text(
                                'అన్ని చూడండి',
                                style: TextStyle(color: Color(0xFF7D0E0E), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF7D0E0E)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    eventsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon)),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                      data: (events) {
                        final upcoming = events
                            .where((e) => e.startDate.isAfter(DateTime.now()) && e.isPublished)
                            .take(3)
                            .toList();
                        if (upcoming.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x4DD4AF37)),
                            ),
                            child: const Center(child: Text('No upcoming events', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        return Column(
                          children: upcoming.map((event) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4DD4AF37)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C0A0A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.event, color: Color(0xFF5C0A0A), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.title, style: const TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('MMM d, yyyy • h:mm a').format(event.startDate),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (event.hasFood)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('🍽️', style: TextStyle(fontSize: 14)),
                                  ),
                              ],
                            ),
                          )).toList(),
                        );
                      },
                    ),

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

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

