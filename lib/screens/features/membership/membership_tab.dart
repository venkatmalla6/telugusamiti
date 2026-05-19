import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/subscription_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_providers.dart';


class MembershipTab extends ConsumerWidget {
  const MembershipTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final subAsync = ref.watch(userSubscriptionProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async => ref.invalidate(userSubscriptionProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Membership'),
              pinned: true,
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Digital ID Card
                    userAsync.when(
                      data: (user) => _DigitalIdCard(
                        name: user?.displayName ?? 'Member',
                        email: user?.email ?? '',
                        role: user?.role.name.toUpperCase() ?? 'USER',
                        uid: user?.uid ?? '',
                      ),
                      loading: () => const MembershipSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    // Subscription Info
                    subAsync.when(
                      loading: () => const MembershipSkeleton(),
                      error: (_, __) => const EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Could not load membership',
                        subtitle: 'Pull down to refresh',
                      ),
                      data: (sub) => _SubscriptionCard(subscription: sub),
                    ),
                    const SizedBox(height: 24),
                    _BenefitsList(),
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

// ── Digital Membership ID Card ────────────────────────────────────────────────
class _DigitalIdCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String uid;

  const _DigitalIdCard({
    required this.name,
    required this.email,
    required this.role,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF800000), Color(0xFF4A0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telugu Samiti',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const Text(
                      'Tamil Nadu',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: uid,
                  version: QrVersions.auto,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryMaroon),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primaryMaroon),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardField(label: 'Member Type', value: role),
              _CardField(label: 'Member ID', value: uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  const _CardField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ── Subscription Status Card ──────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel? subscription;
  const _SubscriptionCard({this.subscription});

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.card_membership, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No Active Membership',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Subscribe now to enjoy full Samiti benefits',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/membership/plans'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                child: const Text('Subscribe Now'),
              ),
            ],
          ),
        ),
      );
    }

    final isActive = subscription!.status == SubscriptionStatus.active;
    final daysLeft = subscription!.endDate.difference(DateTime.now()).inDays;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription!.planName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isActive ? 'Active' : subscription!.status.name.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${subscription!.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryMaroon,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SubDetail('Valid From', DateFormat.yMMMd().format(subscription!.startDate)),
                _SubDetail('Valid Until', DateFormat.yMMMd().format(subscription!.endDate)),
                if (isActive) _SubDetail('Days Left', '$daysLeft days'),
              ],
            ),
            if (!isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/membership/plans'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                  child: const Text('Renew Membership'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubDetail extends StatelessWidget {
  final String label;
  final String value;
  const _SubDetail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Benefits List ─────────────────────────────────────────────────────────────
class _BenefitsList extends StatelessWidget {
  final List<_Benefit> benefits = const [
    _Benefit(icon: Icons.event, text: 'Access to all Samiti events'),
    _Benefit(icon: Icons.restaurant, text: 'Food tokens at cultural events'),
    _Benefit(icon: Icons.family_restroom, text: 'Add up to 5 family members'),
    _Benefit(icon: Icons.photo_library, text: 'Access event photo gallery'),
    _Benefit(icon: Icons.support_agent, text: 'Priority support from volunteers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Member Benefits',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(b.icon, color: AppColors.primaryMaroon, size: 20),
                      const SizedBox(width: 12),
                      Text(b.text, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});
}
