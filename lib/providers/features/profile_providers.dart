import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/family_member_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/payment_repository.dart';
import '../auth_provider.dart';
import '../../core/services/storage_service.dart';

// Family Members
final familyMembersProvider = FutureProvider.autoDispose<List<FamilyMemberModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];
  
  final repo = ref.watch(userRepositoryProvider);
  return repo.getFamilyMembers(user.uid);
});

// Payment History
final paymentHistoryProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];
  
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getUserPayments(user.uid);
});

// Profile Edit Notifier State
class ProfileEditState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ProfileEditState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ProfileEditState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Profile Edit Notifier
class ProfileEditNotifier extends Notifier<ProfileEditState> {
  late final UserRepository _userRepo;
  late final StorageService _storageService;

  @override
  ProfileEditState build() {
    _userRepo = ref.watch(userRepositoryProvider);
    _storageService = StorageService();
    return const ProfileEditState();
  }

  Future<void> updateProfile({
    required UserModel currentUser,
    String? displayName,
    String? phoneNumber,
    String? bloodGroup,
    File? newProfileImage,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      String? photoUrl = currentUser.photoUrl;

      // Upload image if provided
      if (newProfileImage != null) {
        photoUrl = await _storageService.uploadProfileImage(newProfileImage, currentUser.uid);
      }

      final updatedUser = currentUser.copyWith(
        displayName: displayName ?? currentUser.displayName,
        phoneNumber: phoneNumber ?? currentUser.phoneNumber,
        bloodGroup: bloodGroup ?? currentUser.bloodGroup,
        photoUrl: photoUrl,
      );

      await _userRepo.updateUser(updatedUser);
      
      // Invalidate current user provider to refresh UI
      ref.invalidate(currentUserProvider);
      
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addFamilyMember(String uid, FamilyMemberModel member) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _userRepo.addFamilyMember(uid, member);
      ref.invalidate(familyMembersProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeFamilyMember(String uid, String memberId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _userRepo.deleteFamilyMember(uid, memberId);
      ref.invalidate(familyMembersProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileEditNotifierProvider = NotifierProvider<ProfileEditNotifier, ProfileEditState>(
  ProfileEditNotifier.new,
);
