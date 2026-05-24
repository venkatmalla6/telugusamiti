import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class MembershipTab extends ConsumerWidget {
  const MembershipTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async => ref.invalidate(currentUserProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Membership'),
              pinned: true,
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: const Color(0xFF5C0A0A),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    userAsync.when(
                      data: (user) => _DigitalIdCard(
                        name: user?.displayName ?? 'Member',
                        email: user?.email ?? '',
                        role: user?.role.name.toUpperCase() ?? 'USER',
                        uid: (user?.legacyUserId != null && user!.legacyUserId!.isNotEmpty) ? user.legacyUserId! : (user?.uid ?? ''),
                        photoUrl: user?.photoUrl,
                        membership: user?.membership,
                      ),
                      loading: () => const MembershipSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    userAsync.when(
                      loading: () => const MembershipSkeleton(),
                      error: (_, __) => const EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Could not load membership',
                        subtitle: 'Pull down to refresh',
                      ),
                      data: (user) => _SubscriptionCard(membership: user?.membership),
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
  final String? photoUrl;
  final MembershipInfo? membership;

  const _DigitalIdCard({
    required this.name,
    required this.email,
    required this.role,
    required this.uid,
    this.photoUrl,
    this.membership,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveSub = membership != null && membership!.renewalDate.isAfter(DateTime.now());
    
    Gradient gradient;
    Color textColor = Colors.white;
    Color subTextColor = Colors.white70;
    Color labelColor = Colors.white60;
    Color valueColor = AppColors.primaryGold;
    Color qrColor = AppColors.primaryMaroon;
    Border? border;

    if (!hasActiveSub) {
      gradient = const LinearGradient(
        colors: [Color(0xFF5A5A5A), Color(0xFF2C2C2C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      valueColor = Colors.grey.shade400;
      qrColor = Colors.black;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF800000), Color(0xFF4A0000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      valueColor = AppColors.primaryGold;
      qrColor = AppColors.primaryMaroon;
    }

    final String qrData = 'UID: $uid\n'
        'Name: $name\n'
        'Status: ${hasActiveSub ? "ACTIVE" : "EXPIRED"}\n'
        'Expiry: ${membership != null ? DateFormat.yMMMd().format(membership!.renewalDate) : "N/A"}';

    final String displayPlan = hasActiveSub 
        ? 'Premium Member'
        : (membership != null && membership!.renewalDate.isBefore(DateTime.now()))
            ? 'EXPIRED'
            : role;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.3),
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
                    Text(
                      'Telugu Samiti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Tamil Nadu',
                      style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: qrColor),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: qrColor),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: TextStyle(color: subTextColor, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardField(
                label: 'Member Type',
                value: displayPlan,
                labelColor: labelColor,
                valueColor: (!hasActiveSub)
                    ? AppColors.error
                    : valueColor,
              ),
              _CardField(
                label: 'Member ID',
                value: uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase(),
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ],
          ),
          if (hasActiveSub) ...[
            const SizedBox(height: 12),
            Text(
              'Valid Until: ${DateFormat('dd MMM yyyy').format(membership!.renewalDate)}',
              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _CardField({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Subscription Status Card ──────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final MembershipInfo? membership;
  const _SubscriptionCard({this.membership});

  @override
  Widget build(BuildContext context) {
    if (membership == null) {
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
                child: const Text('Contact Admin to Subscribe'),
              ),
            ],
          ),
        ),
      );
    }

    final isActive = membership!.renewalDate.isAfter(DateTime.now());
    final daysLeft = membership!.renewalDate.difference(DateTime.now()).inDays;

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
                      const Text(
                        'Premium Membership',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isActive ? 'Active' : 'Expired',
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
                  '₹${membership!.amount.toStringAsFixed(0)}',
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
                _SubDetail('Payment Date', DateFormat.yMMMd().format(membership!.paymentDate)),
                _SubDetail('Renewal Date', DateFormat.yMMMd().format(membership!.renewalDate)),
                if (isActive) _SubDetail('Days Left', '$daysLeft days'),
              ],
            ),
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
