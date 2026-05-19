import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/features/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedBloodGroup;
  File? _imageFile;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Initialize with current user data once the FutureProvider has it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
        setState(() {
          _selectedBloodGroup = user.bloodGroup;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    ref.read(profileEditNotifierProvider.notifier).updateProfile(
      currentUser: user,
      displayName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      newProfileImage: _imageFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditNotifierProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    ref.listen<ProfileEditState>(profileEditNotifierProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                      child: (_imageFile == null && (user.photoUrl == null || user.photoUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMaroon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _bloodGroups.contains(_selectedBloodGroup) ? _selectedBloodGroup : null,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppColors.primaryMaroon),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _bloodGroups.map((bg) {
                  return DropdownMenuItem(value: bg, child: Text(bg));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedBloodGroup = val;
                  });
                },
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: editState.isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: editState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
