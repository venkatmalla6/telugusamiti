import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/admin_profile_model.dart';
import '../models/audit_log_model.dart';
import '../core/services/firestore_service.dart';
import '../core/error_handling/app_exceptions.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository();
});

class SuperAdminRepository {
  final FirestoreService<UserModel> _userService;
  final FirestoreService<AdminProfileModel> _adminProfileService;
  final FirestoreService<AuditLogModel> _auditLogService;
  final FirebaseFirestore _firestore;

  SuperAdminRepository()
      : _userService = FirestoreService<UserModel>(
          collectionPath: 'users',
          fromMap: UserModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _adminProfileService = FirestoreService<AdminProfileModel>(
          collectionPath: 'admins',
          fromMap: AdminProfileModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _auditLogService = FirestoreService<AuditLogModel>(
          collectionPath: 'audit_logs',
          fromMap: AuditLogModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _firestore = FirebaseFirestore.instance;

  // ─── Admins Management ───────────────────────────────────────────────────

  Stream<List<UserModel>> streamAllAdmins() {
    return _firestore
        .collection('users')
        .where('role', whereIn: [UserRole.admin.name, UserRole.superAdmin.name])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<AdminProfileModel?> getAdminProfile(String uid) {
    return _adminProfileService.getById(uid);
  }

  Future<void> updateAdminPermissions(
      String adminId, List<String> permissions, String superAdminId) async {
    await _adminProfileService.update(adminId, {'permissions': permissions});
    await logAction(
      actionType: 'permissions_updated',
      performedBy: superAdminId,
      targetId: adminId,
      details: {'new_permissions': permissions},
    );
  }

  /// Revokes admin access by setting role to 'user' and removing the admin profile.
  Future<void> revokeAdminAccess(String adminId, String superAdminId) async {
    final batch = _firestore.batch();
    
    final userRef = _firestore.collection('users').doc(adminId);
    batch.update(userRef, {'role': UserRole.user.name});
    
    final adminProfileRef = _firestore.collection('admins').doc(adminId);
    batch.delete(adminProfileRef);

    // Audit log
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'actionType': 'admin_removed',
      'performedBy': superAdminId,
      'targetId': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Note: To create an admin completely securely from within the app, one typically
  // creates a secondary Firebase App instance or calls a Cloud Function so it doesn't
  // log out the current SuperAdmin. For simplicity, we assume an existing user is promoted,
  // or provide a function to promote an existing user by email.

  Future<void> promoteUserToAdmin(String email, String department, String superAdminId) async {
    final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isEmpty) {
      throw AppException('User with email $email not found.');
    }
    
    final userId = snapshot.docs.first.id;
    final batch = _firestore.batch();
    
    // Update user role
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {'role': UserRole.admin.name});
    
    // Create admin profile
    final adminProfileRef = _firestore.collection('admins').doc(userId);
    final adminProfile = AdminProfileModel(
      id: userId,
      department: department,
      permissions: [],
      lastLoginAt: DateTime.now(),
    );
    batch.set(adminProfileRef, adminProfile.toMap());

    // Audit log
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'actionType': 'admin_created',
      'performedBy': superAdminId,
      'targetId': userId,
      'details': {'department': department},
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ─── Audit Logs ─────────────────────────────────────────────────────────

  Stream<List<AuditLogModel>> streamAuditLogs({int limit = 50}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> logAction({
    required String actionType,
    required String performedBy,
    String? targetId,
    Map<String, dynamic> details = const {},
  }) async {
    await _auditLogService.add(AuditLogModel(
      id: '',
      actionType: actionType,
      performedBy: performedBy,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
    ));
  }
}
