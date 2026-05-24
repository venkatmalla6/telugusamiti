import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/dashboard_providers.dart';
import '../../../../providers/auth_provider.dart';

class CustomHomeAppBar extends ConsumerWidget {
  final String greetingTitle;
  final String greetingSubtitle;
  final bool showLogout;
  final bool showMenu;
  
  const CustomHomeAppBar({
    super.key,
    required this.greetingTitle,
    required this.greetingSubtitle,
    this.showLogout = false,
    this.showMenu = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryMaroon,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background Image with gradient overlay
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryMaroon.withOpacity(0.9),
                      AppColors.primaryMaroon.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Menu, Logo, Title, Notification
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showMenu) ...[
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                            onPressed: () {
                              // The drawer is on the outer UserDashboard Scaffold, so we need to find it
                              final scaffoldState = context.findRootAncestorStateOfType<ScaffoldState>();
                              scaffoldState?.openDrawer();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Circular Logo placeholder
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGold, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/login_bg.png'), // Use same temple bg as logo placeholder
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'అణు కల్పక్కం తెలుగు సమితి',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'భావమే మన బంధం, సంస్కృతే మన గర్వం',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                              onPressed: () => context.push('/notifications'),
                            ),
                            if (ref.watch(unreadNotificationsCountProvider) > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox(width: 4, height: 4),
                                ),
                              ),
                          ],
                        ),
                        if (showLogout)
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                            onPressed: () => ref.read(authControllerProvider).signOut(),
                          ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Greeting Section
                    Text(
                      greetingTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greetingSubtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
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
