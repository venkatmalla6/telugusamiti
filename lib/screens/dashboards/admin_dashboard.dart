import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_providers.dart';
import 'admin/tabs/admin_home_tab.dart';
import 'admin/tabs/admin_members_tab.dart';
import 'admin/tabs/admin_events_tab.dart';
import 'admin/tabs/admin_settings_tab.dart';
import '../features/gallery/gallery_tab.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  DateTime? _lastBackPress;

  final _tabs = const [
    AdminHomeTab(),
    AdminMembersTab(),
    AdminEventsTab(),
    GalleryTab(),
    AdminSettingsTab(),
  ];

  final _tabLabels = ['Home', 'Members', 'Events', 'Gallery', 'Settings'];
  final _tabIcons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.event_rounded,
    Icons.photo_library_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(adminTabProvider);
    final userAsync = ref.watch(currentUserProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (tabIndex != 0) {
          // Not on Home tab → go to Home tab
          ref.read(adminTabProvider.notifier).set(0);
        } else {
          // Already on Home tab -> pop if possible, otherwise double-back to exit
          if (context.canPop()) {
            context.pop();
          } else {
            final now = DateTime.now();
            final lastBack = _lastBackPress;
            _lastBackPress = now;
            if (lastBack != null && now.difference(lastBack) < const Duration(seconds: 2)) {
              await SystemNavigator.pop();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Press back again to exit'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          title: userAsync.when(
            data: (user) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabLabels[tabIndex],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Welcome, ${user?.displayName?.split(' ').first ?? 'Admin'}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            loading: () => const Text('Admin Panel'),
            error: (_, __) => const Text('Admin Panel'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => context.push('/admin/notifications/send'),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => ref.read(authControllerProvider).signOut(),
            ),
          ],
        ),
        body: IndexedStack(
          index: tabIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, -3)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  final isSelected = index == tabIndex;
                  return GestureDetector(
                    onTap: () => ref.read(adminTabProvider.notifier).set(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMaroon.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabIcons[index],
                            color: isSelected ? AppColors.primaryGold : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tabLabels[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryGold : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
