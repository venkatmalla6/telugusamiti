import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/payment_model.dart';
import '../../../providers/admin_providers.dart';
import '../../../repositories/admin_repository.dart';

class AdminMemberDetailScreen extends ConsumerWidget {
  final String uid;
  const AdminMemberDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(uid));
    final subAsync = ref.watch(adminUserSubscriptionProvider(uid));
    final paymentsAsync = ref.watch(adminUserPaymentsProvider(uid));
    final eventsAsync = ref.watch(adminUserEventHistoryProvider(uid));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: const Color(0xFF5C0A0A),
        title: const Text('Member Profile'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Member not found.', style: TextStyle(color: Colors.grey)));
          }
          return _buildBody(context, ref, user, subAsync, paymentsAsync, eventsAsync);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserModel user,
      AsyncValue subAsync, AsyncValue paymentsAsync, AsyncValue eventsAsync) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Profile Header ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryMaroon, Color(0xFF5C0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        (user.displayName?.isNotEmpty == true ? user.displayName! : 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 32, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? 'Unknown Member',
                style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(user.email ?? user.phoneNumber ?? '', style: TextStyle(color: const Color(0x995C0A0A), fontSize: 13)),
              const SizedBox(height: 12),
              // Member ID row
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member ID copied!'), backgroundColor: Colors.green),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, color: const Color(0x995C0A0A), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ID: ${user.uid.length > 12 ? '${user.uid.substring(0, 12)}...' : user.uid}',
                        style: TextStyle(color: const Color(0x995C0A0A), fontSize: 11, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy, color: const Color(0x995C0A0A), size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Info Cards ────────────────────────────────────────────────
        _InfoSection(
          title: 'Contact Info',
          children: [
            _InfoRow(icon: Icons.phone, label: 'Phone', value: user.phoneNumber ?? 'Not provided'),
            _InfoRow(icon: Icons.email, label: 'Email', value: user.email ?? 'Not provided'),
            if (user.bloodGroup != null)
              _InfoRow(icon: Icons.bloodtype, label: 'Blood Group', value: user.bloodGroup!),
          ],
        ),

        const SizedBox(height: 12),

        // ─── Role Management ───────────────────────────────────────────
        _InfoSection(
          title: 'Role Management',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts, color: Colors.grey, size: 16),
                  const SizedBox(width: 10),
                  const Text('Current Role:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  DropdownButton<UserRole>(
                    value: user.role,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 13, fontWeight: FontWeight.bold),
                    underline: const SizedBox.shrink(),
                    items: UserRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    )).toList(),
                    onChanged: (newRole) async {
                      if (newRole == null || newRole == user.role) return;
                      await ref.read(adminRepositoryProvider).updateUserRole(user.uid, newRole);
                      ref.invalidate(adminUserDetailProvider(user.uid));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Role updated to ${newRole.name}'), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── Subscription ──────────────────────────────────────────────
        _InfoSection(
          title: 'Membership Subscription',
          children: [
            subAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
              error: (_, __) => const Text('Could not load subscription', style: TextStyle(color: Colors.red)),
              data: (sub) {
                if (sub == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No active subscription', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: [
                    _InfoRow(icon: Icons.card_membership, label: 'Plan', value: sub.planName),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Valid Until',
                      value: DateFormat('MMM d, yyyy').format(sub.endDate),
                    ),
                    _InfoRow(
                      icon: Icons.circle,
                      label: 'Status',
                      value: sub.status.name.toUpperCase(),
                      valueColor: sub.status.name == 'active' ? Colors.green : Colors.orange,
                    ),
                    _InfoRow(icon: Icons.currency_rupee, label: 'Amount Paid', value: '₹${sub.amount}'),
                  ],
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── Payment History ────────────────────────────────────────────
        _InfoSection(
          title: 'Payment History',
          children: [
            paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
              error: (_, __) => const Text('Could not load payments', style: TextStyle(color: Colors.red)),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No payment records', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: payments.take(5).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          p.status == PaymentStatus.success ? Icons.check_circle : Icons.error,
                          color: p.status == PaymentStatus.success ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.description, style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 13)),
                              Text(
                                DateFormat('MMM d, yyyy').format(p.createdAt),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${p.amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: const Color(0xFF5C0A0A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── Event Participation ────────────────────────────────────────
        _InfoSection(
          title: 'Event Participation',
          children: [
            eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: const Color(0xFF5C0A0A))),
              error: (_, __) => const Text('Could not load events', style: TextStyle(color: Colors.red)),
              data: (regs) {
                if (regs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No event registrations', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: regs.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: const Color(0xFF5C0A0A), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event ID: ${r.eventId.length > 10 ? r.eventId.substring(0, 10) : r.eventId}...',
                                style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 12),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(r.registrationDate),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${1 + r.numberOfAdults + r.numberOfChildren} members',
                              style: TextStyle(color: const Color(0xB35C0A0A), fontSize: 11),
                            ),
                            if (r.foodClaimed)
                              const Text('🍽️ Food claimed', style: TextStyle(color: Colors.orange, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 30),

        // ─── Delete User ──────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Delete User?'),
                content: const Text('Are you sure you want to permanently delete this user? This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(adminRepositoryProvider).deleteUser(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully.'), backgroundColor: Colors.red),
                );
                context.pop();
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade900,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete Member / Volunteer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x4D5C0A0A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(color: const Color(0xFF5C0A0A), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Color(0x1A5C0A0A), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 10),
          Text('$label:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF5C0A0A), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
