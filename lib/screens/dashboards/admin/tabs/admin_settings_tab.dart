import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/admin_providers.dart';

class AdminSettingsTab extends ConsumerWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Profile Card ──────────────────────────────────────────────
          userAsync.when(
            data: (user) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryMaroon,
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Text(
                            (user?.displayName ?? 'A').substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Admin',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(user?.email ?? user?.phoneNumber ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMaroon.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role.name.toUpperCase() ?? 'ADMIN',
                            style: const TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // ─── Admin Actions ─────────────────────────────────────────────
          const Text('Admin Tools', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconColor: Colors.blue,
            title: 'Send Notification',
            subtitle: 'Broadcast a message to all members',
            onTap: () => context.push('/admin/notifications/send'),
          ),
          _SettingsTile(
            icon: Icons.campaign_rounded,
            iconColor: Colors.orange,
            title: 'Create Announcement',
            subtitle: 'Post a new announcement for all users',
            onTap: () => context.push('/admin/create-announcement'),
          ),
          _SettingsTile(
            icon: Icons.event_rounded,
            iconColor: AppColors.primaryMaroon,
            title: 'Manage Events',
            subtitle: 'Create, edit and delete events',
            onTap: () => ref.read(adminTabProvider.notifier).set(2),
          ),
          _SettingsTile(
            icon: Icons.people_rounded,
            iconColor: Colors.teal,
            title: 'Manage Members',
            subtitle: 'Search and manage member profiles',
            onTap: () => ref.read(adminTabProvider.notifier).set(1),
          ),
          _SettingsTile(
            icon: Icons.qr_code_scanner_rounded,
            iconColor: AppColors.primaryGold,
            title: 'Scan QR / Validate Token',
            subtitle: 'Scan event and food QR codes',
            onTap: () => context.push('/volunteer/scan'),
          ),

          const SizedBox(height: 24),

          // ─── Danger Zone ────────────────────────────────────────────────
          const Text('Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            title: 'Sign Out',
            subtitle: 'Log out of the admin panel',
            onTap: () => ref.read(authControllerProvider).signOut(),
            trailing: const Icon(Icons.logout, color: Colors.red, size: 20),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}
