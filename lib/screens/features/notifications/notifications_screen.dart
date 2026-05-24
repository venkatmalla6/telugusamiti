import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../repositories/communication_repository.dart';
import '../../../repositories/admin_repository.dart';
import '../../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        actions: [
          if (user != null)
            notificationsAsync.maybeWhen(
              data: (list) => list.isNotEmpty
                  ? TextButton(
                      onPressed: () => _confirmClearAll(context, ref, user.uid),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      floatingActionButton: user?.isAdminOrSuperAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/notifications/send'),
              icon: const Icon(Icons.add, color: Color(0xFF5C0A0A)),
              label: const Text('New Notification', style: TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryGold,
            )
          : null,
      body: user == null
          ? const Center(child: Text('Please log in to view notifications'))
          : notificationsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonBox(height: 80, borderRadius: 12),
                ),
              ),
              error: (err, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Error loading notifications',
                subtitle: err.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(userNotificationsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.notifications_off_outlined,
                    title: 'No Notifications Yet',
                    subtitle: 'We will notify you when there are updates from Telugu Samiti.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: item.isRead ? Colors.white : const Color(0xFFFFF8E1), // Light gold tint for unread
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: item.isRead ? Colors.grey.shade200 : AppColors.primaryGold.withValues(alpha: 0.5),
                          width: item.isRead ? 1 : 1.5,
                        ),
                      ),
                      elevation: item.isRead ? 1 : 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (!item.isRead) {
                            ref.read(communicationRepositoryProvider).markNotificationAsRead(user.uid, item.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Unread dot or read icon
                                  Container(
                                    margin: const EdgeInsets.only(top: 4, right: 12),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: item.isRead ? Colors.transparent : AppColors.primaryMaroon,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (user.isAdminOrSuperAdmin)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          onPressed: () => _showEditDialog(context, ref, item),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _confirmDelete(context, ref, item),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      item.body,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat('dd MMM yyyy • hh:mm a').format(item.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(communicationRepositoryProvider).clearAllNotifications(uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, NotificationModel item) {
    final titleCtrl = TextEditingController(text: item.title);
    final bodyCtrl = TextEditingController(text: item.body);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF5C0A0A),
        title: const Text('Edit Notification', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: bodyCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGold),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  await ref.read(adminRepositoryProvider).updateNotification(
                        item.id,
                        titleCtrl.text.trim(),
                        bodyCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification updated globally')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Save Changes', style: TextStyle(color: Color(0xFF5C0A0A))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, NotificationModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF5C0A0A),
        title: const Text('Delete Notification', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this notification globally? It will be removed for all users.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminRepositoryProvider).deleteNotification(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted globally')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
