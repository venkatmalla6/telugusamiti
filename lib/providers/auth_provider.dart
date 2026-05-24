import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import 'notification_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = await ref.watch(authStateProvider.future);
  if (firebaseUser == null) return null;

  final userRepo = ref.watch(userRepositoryProvider);
  UserModel? user = await userRepo.getUser(firebaseUser.uid);
  
  if (user == null) {
    // Create default user document if it doesn't exist
    user = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName,
      role: UserRole.user,
      approvalStatus: ApprovalStatus.pending,
    );
    // Retry loop to ensure Firestore SDK has received the Auth Token
    for (int i = 0; i < 3; i++) {
      try {
        await userRepo.createUser(user);
        break;
      } catch (e) {
        if (i == 2) debugPrint('[Auth] Error creating user doc: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  // If the user doesn't have a membership attached, check if a super admin 
  // pre-uploaded their membership data using their legacy User ID.
  if (user != null && user.membership == null && user.legacyUserId != null && user.legacyUserId!.isNotEmpty) {
    try {
      final legacyDoc = await FirebaseFirestore.instance.collection('users').doc(user.legacyUserId).get();
      if (legacyDoc.exists && legacyDoc.data() != null && legacyDoc.data()!.containsKey('membership')) {
        final legacyMembership = legacyDoc.data()!['membership'];
        user = user.copyWith(membership: MembershipInfo.fromMap(legacyMembership));
        
        // Move it permanently to the real user document so we don't have to fetch it every time
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'membership': legacyMembership
        }, SetOptions(merge: true));
        
        // Clean up the ghost document to keep the database clean
        await FirebaseFirestore.instance.collection('users').doc(user.legacyUserId).delete();
      }
    } catch (e) {
      debugPrint('[Auth] Error fetching legacy membership data: $e');
    }
  }

  return user;
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    ref,
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

class AuthController {
  final Ref _ref;
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthController(this._ref, this._authRepository, this._userRepository);

  Future<void> signInWithIdOrEmail(String input, String password) async {
    if (input.contains('@')) {
      await _authRepository.signInWithEmail(input, password);
    } else {
      // It's a User ID, resolve it to an email
      try {
        final doc = await FirebaseFirestore.instance.collection('public_member_ids').doc(input).get();
        if (doc.exists && doc.data() != null) {
          final email = doc.data()!['email'] as String;
          await _authRepository.signInWithEmail(email, password);
        } else {
          throw Exception('User ID not found.');
        }
      } catch (e) {
        throw Exception('Failed to login with User ID: $e');
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _authRepository.signInWithEmail(email, password);
  }

  Future<void> signUpWithEmail(String email, String password, String legacyUserId, String name) async {
    final credential = await _authRepository.signUpWithEmail(email, password);
    
    // Save the User ID to Email mapping publicly so they can login later with User ID
    if (legacyUserId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('public_member_ids').doc(legacyUserId).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[Auth] Failed to write public_member_ids mapping: $e');
      }
    }
    
    // Create the user document immediately with pending status and legacy ID
    if (credential.user != null) {
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: name.isNotEmpty ? name : null,
        legacyUserId: legacyUserId,
        role: UserRole.user,
        approvalStatus: ApprovalStatus.pending,
      );
      
      // Retry loop to ensure Firestore SDK has received the Auth Token
      for (int i = 0; i < 4; i++) {
        try {
          await _userRepository.createUser(user);
          break; // Success!
        } catch (e) {
          if (i == 3) throw Exception('Failed to save user data: $e');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  Future<void> signOut() async {
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user != null) {
        // Run without await to decrease sign out delay
        _ref.read(fcmServiceProvider).unregisterDevice(user.uid);
      }
    } catch (_) {
      // Ignore any errors unregistering device on signOut
    }
    await _authRepository.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  // OTP Flow
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await _authRepository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _authRepository.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> verifyOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _authRepository.signInWithCredential(credential);
  }
}
extension UserRoleExtensions on UserModel {
  bool get isAdminOrSuperAdmin => role == UserRole.admin || role == UserRole.superAdmin;
}
