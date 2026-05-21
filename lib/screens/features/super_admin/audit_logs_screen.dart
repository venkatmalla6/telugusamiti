import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/super_admin_providers.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs found.'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForAction(log.actionType),
                  child: Icon(_getIconForAction(log.actionType), color: Colors.white),
                ),
                title: Text(log.actionType.replaceAll('_', ' ').toUpperCase()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('By: ${log.performedBy}'),
                    if (log.targetId != null) Text('Target: ${log.targetId}'),
                    Text('Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(log.timestamp)}'),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getColorForAction(String action) {
    if (action.contains('create') || action.contains('add')) return Colors.green;
    if (action.contains('remove') || action.contains('delete') || action.contains('revoke')) return Colors.red;
    if (action.contains('update') || action.contains('edit')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getIconForAction(String action) {
    if (action.contains('create') || action.contains('add')) return Icons.add;
    if (action.contains('remove') || action.contains('delete') || action.contains('revoke')) return Icons.remove;
    if (action.contains('update') || action.contains('edit')) return Icons.edit;
    return Icons.info;
  }
}
