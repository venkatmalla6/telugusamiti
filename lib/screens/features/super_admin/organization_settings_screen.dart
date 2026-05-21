import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../models/app_setting_model.dart';
import '../../../core/utils/snackbar_utils.dart';

// Assuming we want a specific provider to update app settings from super admin.
// We can just use a local StateNotifier or directly call firestore for simplicity here.
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends ConsumerState<OrganizationSettingsScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feeController = TextEditingController();
  bool _enableRegistrations = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_config').get();
      if (doc.exists) {
        final data = doc.data()!;
        _emailController.text = data['contactEmail'] ?? '';
        _phoneController.text = data['contactPhone'] ?? '';
        _feeController.text = (data['defaultMembershipFee'] ?? 0).toString();
        _enableRegistrations = data['enableEventRegistrations'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('app_config').set({
        'contactEmail': _emailController.text,
        'contactPhone': _phoneController.text,
        'defaultMembershipFee': int.tryParse(_feeController.text) ?? 0,
        'enableEventRegistrations': _enableRegistrations,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) showSuccessSnackBar(context, 'Settings updated successfully.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to update: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Global App Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feeController,
              decoration: const InputDecoration(labelText: 'Default Membership Fee (₹)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Event Registrations'),
              subtitle: const Text('Turn off to prevent new event bookings globally.'),
              value: _enableRegistrations,
              onChanged: (val) => setState(() => _enableRegistrations = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
