import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/snackbar_utils.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  final ApprovalStatus status;
  
  const PendingApprovalScreen({super.key, required this.status});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isLoading = false;

  Future<void> _handleDeleteSession() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. Delete the user entirely from Firebase Auth (this will trigger signout implicitly in some flows, but we also sign out)
        await user.delete();
      }
      
      // 3. Clear local auth state
      await ref.read(authControllerProvider).signOut();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to delete account: $e');
        // Fallback to normal signout if delete fails (e.g., needs recent login)
        await ref.read(authControllerProvider).signOut();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await ref.read(authControllerProvider).signOut();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = widget.status == ApprovalStatus.rejected;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isRejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded,
                size: 80,
                color: isRejected ? Colors.red.shade700 : const Color(0xFFD4AF37),
              ),
              const SizedBox(height: 24),
              Text(
                isRejected ? 'Approval Rejected' : 'Pending Approval',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C0A0A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isRejected 
                    ? 'Your registration was rejected by the admin. Please delete this session to restart the registration process and ensure you use the correct User ID.'
                    : 'Your account has been successfully created and is waiting for Admin verification. You will be able to access the app once approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5C0A0A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF5C0A0A)))
              else if (isRejected)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleDeleteSession,
                  child: const Text('Delete Session & Restart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              else
                PrimaryButton(
                  text: 'Sign Out',
                  onPressed: _handleSignOut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
