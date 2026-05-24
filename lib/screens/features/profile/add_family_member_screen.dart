import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/family_member_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/features/profile_providers.dart';

class AddFamilyMemberScreen extends ConsumerStatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  ConsumerState<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends ConsumerState<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedRelationship;
  String? _selectedGender;
  DateTime? _selectedDate;

  final List<String> _relationships = ['Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Other'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMaroon,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a relationship')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final newMember = FamilyMemberModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID until Firestore sets it
      name: _nameController.text.trim(),
      relationship: _selectedRelationship!,
      gender: _selectedGender,
      dateOfBirth: _selectedDate,
    );

    ref.read(profileEditNotifierProvider.notifier).addFamilyMember(user.uid, newMember);
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditNotifierProvider);

    ref.listen<ProfileEditState>(profileEditNotifierProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member added successfully'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: const Color(0xFF5C0A0A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.family_restroom, color: AppColors.primaryMaroon),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedRelationship = val),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.people_outline, color: AppColors.primaryMaroon),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primaryMaroon),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null ? 'Date of Birth (Optional)' : DateFormat.yMMMd().format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null ? Colors.grey.shade700 : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: editState.isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: editState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: const Color(0xFF5C0A0A), strokeWidth: 2))
                      : const Text('Add Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
