import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/features/profile_providers.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../repositories/admin_repository.dart';
import '../../../models/user_model.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('My Profile'),
            pinned: true,
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Sign Out',
                onPressed: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: userAsync.when(
              data: (user) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.15),
                      backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                          ? Text(
                              user?.displayName?.isNotEmpty == true
                                  ? user!.displayName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryMaroon,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'Member',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? user?.phoneNumber ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (user != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'ID: ${user.legacyUserId?.isNotEmpty == true ? user.legacyUserId : user.uid}',
                              style: TextStyle(
                                color: Colors.grey.shade800, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user?.role.name.toUpperCase() ?? 'USER',
                        style: const TextStyle(
                          color: AppColors.primaryMaroon,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Menu Sections
                    _ProfileSection(
                      title: 'Account',
                      items: [
                        _ProfileMenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.family_restroom,
                          label: 'Family Members',
                          trailing: ref.watch(familyMembersProvider).maybeWhen(
                                data: (members) => '${members.length} members',
                                orElse: () => '...',
                              ),
                          onTap: () => context.push('/profile/family'),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          trailing: user?.phoneNumber ?? 'Not set',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProfileSection(
                      title: 'Membership',
                      items: [
                        _ProfileMenuItem(
                          icon: Icons.card_membership,
                          label: 'My Subscription',
                          onTap: () => context.push('/membership/subscriptions'),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.history,
                          label: 'Payment History',
                          onTap: () => context.push('/membership/payments'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (user?.role == UserRole.admin || user?.role == UserRole.superAdmin) ...[
                      _ProfileSection(
                        title: 'Admin Tools',
                        items: [
                          _ProfileMenuItem(
                            icon: Icons.delete_sweep_outlined,
                            label: 'Clear All Test/Dummy Data',
                            iconColor: AppColors.error,
                            textColor: AppColors.error,
                            onTap: () => _confirmClearTestData(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ProfileSection(
                      title: 'More',
                      items: [
                        _ProfileMenuItem(
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          onTap: () {},
                        ),
                        _ProfileMenuItem(
                          icon: Icons.logout,
                          label: 'Sign Out',
                          textColor: AppColors.error,
                          iconColor: AppColors.error,
                          onTap: () => _confirmSignOut(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              loading: () => const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(color: AppColors.primaryMaroon),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearTestData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Test Data'),
        content: const Text(
          'This will permanently delete all events, announcements, gallery uploads, '
          'payment records, and subscriptions from the database.\n\n'
          'Are you absolutely sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primaryMaroon),
                            SizedBox(height: 16),
                            Text('Clearing Firestore collections...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ),
              );

              try {
                final adminRepo = ref.read(adminRepositoryProvider);
                await adminRepo.clearAllTestData();
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All test database records cleared successfully!')),
                  );
                  ref.invalidate(upcomingEventsProvider);

                  ref.invalidate(galleryNotifierProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing data: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: EdgeInsets.zero,
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < items.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primaryMaroon, size: 22),
      title: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: Colors.grey, fontSize: 13))
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
