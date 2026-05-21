import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/admin_profile_model.dart';
import '../models/audit_log_model.dart';
import '../repositories/super_admin_repository.dart';
import '../providers/auth_provider.dart';

// Stream of all admins (including superAdmins)
final allAdminsProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.streamAllAdmins();
});

// Stream of audit logs
final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.streamAuditLogs();
});

// Fetch a specific admin's profile
final adminProfileProvider = FutureProvider.family<AdminProfileModel?, String>((ref, uid) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminProfile(uid);
});

class SuperAdminNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> promoteUserToAdmin(String email, String department) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(superAdminRepositoryProvider);
      final user = ref.read(currentUserProvider).value;
      await repo.promoteUserToAdmin(email, department, user?.uid ?? '');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> revokeAdminAccess(String adminId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(superAdminRepositoryProvider);
      final user = ref.read(currentUserProvider).value;
      await repo.revokeAdminAccess(adminId, user?.uid ?? '');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateAdminPermissions(String adminId, List<String> permissions) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(superAdminRepositoryProvider);
      final user = ref.read(currentUserProvider).value;
      await repo.updateAdminPermissions(adminId, permissions, user?.uid ?? '');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final superAdminNotifierProvider = AsyncNotifierProvider<SuperAdminNotifier, void>(() {
  return SuperAdminNotifier();
});
