import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/super_admin_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/super_admin_repository.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Add Important Note',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _AddNoteDialog(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _AddLogDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Manual Log'),
        backgroundColor: const Color(0xFF5C0A0A),
        foregroundColor: Colors.white,
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
                  child: Icon(_getIconForAction(log.actionType), color: const Color(0xFF5C0A0A)),
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
    if (action.contains('budget') || action.contains('financial')) return Icons.attach_money;
    if (action.contains('annual') || action.contains('report')) return Icons.assessment;
    return Icons.info;
  }
}

class _AddLogDialog extends ConsumerStatefulWidget {
  const _AddLogDialog();

  @override
  ConsumerState<_AddLogDialog> createState() => _AddLogDialogState();
}

class _AddLogDialogState extends ConsumerState<_AddLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _detailsCtrl = TextEditingController();
  final _targetIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  
  String _selectedCategory = 'Annual Budget';
  final List<String> _categories = [
    'Annual Budget',
    'Event Financials',
    'Maintenance',
    'General Report',
    'Other'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _targetIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      
      final details = <String, dynamic>{
        'description': _detailsCtrl.text.trim(),
        'category': _selectedCategory,
      };
      
      if (_amountCtrl.text.isNotEmpty) {
        details['amount'] = _amountCtrl.text.trim();
      }

      await ref.read(superAdminRepositoryProvider).logAction(
        actionType: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        performedBy: user?.email ?? user?.uid ?? 'Admin',
        targetId: _targetIdCtrl.text.trim().isEmpty ? null : _targetIdCtrl.text.trim(),
        details: details,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add log: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Manual Log'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log external events like budgets, financials, or reports manually into the system.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Log Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Related ID (Optional)',
                  hintText: 'e.g. Event ID or User ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedCategory.contains('Budget') || _selectedCategory.contains('Financial'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹) (Optional)',
                      hintText: 'e.g. 5000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                ),
              TextFormField(
                controller: _detailsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details / Description',
                  hintText: 'Enter comprehensive details...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text('SAVE LOG'),
        ),
      ],
    );
  }
}

class _AddNoteDialog extends ConsumerStatefulWidget {
  const _AddNoteDialog();

  @override
  ConsumerState<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<_AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      
      await ref.read(superAdminRepositoryProvider).logAction(
        actionType: 'important_note',
        performedBy: user?.email ?? user?.uid ?? 'Admin',
        details: {'note': _noteCtrl.text.trim()},
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add note: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Important Note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This note will be permanently added to the audit logs with the current date and time.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note Content',
                hintText: 'Enter important points...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text('SAVE NOTE'),
        ),
      ],
    );
  }
}

