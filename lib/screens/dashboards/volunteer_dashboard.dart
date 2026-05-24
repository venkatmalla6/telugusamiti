import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_providers.dart';
import '../features/home/widgets/custom_home_app_bar.dart';

class VolunteerDashboard extends ConsumerWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final eventsAsync = ref.watch(todayEventsProvider);
    final name = userAsync.value?.displayName?.split(' ').first ?? 'Volunteer';
    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12 ? 'శుభ ఉదయం' : hour < 17 ? 'శుభ మధ్యాహ్నం' : 'శుభ సాయంత్రం';

    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF2E6), // Cream background
        body: RefreshIndicator(
          color: AppColors.primaryMaroon,
          onRefresh: () async {
            ref.invalidate(todayEventsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CustomHomeAppBar(
                greetingTitle: '$greetingPrefix ☀️',
                greetingSubtitle: 'స్వాగతం, $name 🙏',
                showLogout: true,
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
                            Icon(Icons.volunteer_activism, color: Color(0xFF5C0A0A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'VOLUNTEER',
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

                      // Quick Actions
                      const Text('శీఘ్ర కార్యాచరణలు (Quick Actions)', style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/volunteer/scan'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x80D4AF37), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C0A0A).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF5C0A0A), size: 48),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'QR కోడ్ స్కాన్ చేయండి',
                                style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Verify attendance & food tokens',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Today's Events
                      const Text('నేటి ఈవెంట్స్ (Today\'s Events)', style: TextStyle(color: Color(0xFF5C0A0A), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      eventsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon)),
                        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                        data: (events) {
                          if (events.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x4DD4AF37)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.event_busy, color: Colors.grey, size: 40),
                                  SizedBox(height: 12),
                                  Text('No events scheduled for today.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: events.map((event) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x4DD4AF37)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5C0A0A).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.event, color: Color(0xFF5C0A0A), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(event.title, style: const TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('h:mm a').format(event.startDate),
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        if (event.hasFood) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('🍽️ Food Arranged', style: TextStyle(fontSize: 11, color: Colors.orange.shade900)),
                                          ),
                                        ],
                                      ],
                                    ),
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
      ),
    );
  }
}

