import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error_handling/app_exceptions.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw UnauthorisedException(_handleAuthException(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(_handleAuthException(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(_handleAuthException(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw UnauthorisedException(_handleAuthException(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'invalid-verification-code':
        return 'The SMS verification code is invalid.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
