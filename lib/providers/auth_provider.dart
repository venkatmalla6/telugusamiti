import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
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
    );
    await userRepo.createUser(user);
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

  Future<void> signInWithEmail(String email, String password) async {
    await _authRepository.signInWithEmail(email, password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _authRepository.signUpWithEmail(email, password);
  }

  Future<void> signOut() async {
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user != null) {
        await _ref.read(fcmServiceProvider).unregisterDevice(user.uid);
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
