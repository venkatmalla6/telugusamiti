import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_providers.dart';
import '../features/home/home_tab.dart';
import '../features/events/events_tab.dart';
import '../features/membership/membership_tab.dart';
import '../features/gallery/gallery_tab.dart';
import '../features/profile/profile_tab.dart';

class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  DateTime? _lastBackPressed;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Events'),
    _NavItem(icon: Icons.card_membership_outlined, activeIcon: Icons.card_membership, label: 'Membership'),
    _NavItem(icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Gallery'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  final List<Widget> _pages = const [
    HomeTab(),
    EventsTab(),
    MembershipTab(),
    GalleryTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    final currentIndex = ref.read(userDashboardIndexProvider);
    if (index == currentIndex) return;
    ref.read(userDashboardIndexProvider.notifier).set(index);
    _animController.forward(from: 0);
  }

  Future<bool> _onBackPressed() async {
    final currentIndex = ref.read(userDashboardIndexProvider);
    // If not on Home tab — navigate back to Home tab
    if (currentIndex != 0) {
      ref.read(userDashboardIndexProvider.notifier).set(0);
      return false;
    }
    // On Home tab — double-back-to-exit
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(userDashboardIndexProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _onBackPressed();
      },
      child: Scaffold(
        drawer: const _AppDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: _pages[currentIndex],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, currentIndex),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = currentIndex == index;

              return GestureDetector(
                onTap: () => _onTabTapped(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGold.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? AppColors.primaryGold
                            : Colors.white70,
                        size: 24,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFFFAF2E6),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryMaroon,
              image: DecorationImage(
                image: AssetImage('assets/images/home_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/login_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'అణు కల్పక్కం\nతెలుగు సమితి',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primaryMaroon),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              // Handle About Us
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined, color: AppColors.primaryMaroon),
            title: const Text('Contact Us'),
            onTap: () {
              Navigator.pop(context);
              // Handle Contact Us
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryMaroon),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              // Handle Privacy Policy
            },
          ),
          const Divider(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
