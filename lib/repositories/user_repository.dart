import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/family_member_model.dart';
import '../core/services/firestore_service.dart';
import '../core/error_handling/app_exceptions.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final FirestoreService<UserModel> _userService;

  UserRepository()
      : _userService = FirestoreService<UserModel>(
          collectionPath: 'users',
          fromMap: UserModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<UserModel?> getUser(String uid) => _userService.getById(uid);

  Future<void> createUser(UserModel user) async {
    try {
      await _userService.set(user.uid, user);
    } catch (e) {
      throw BadRequestException('Failed to create user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _userService.update(user.uid, user.toMap());
    } catch (e) {
      throw BadRequestException('Failed to update user: $e');
    }
  }

  FirestoreService<FamilyMemberModel> _familyMemberService(String uid) =>
      FirestoreService<FamilyMemberModel>(
        collectionPath: 'users/$uid/family_members',
        fromMap: FamilyMemberModel.fromMap,
        toMap: (item) => item.toMap(),
      );

  Future<void> addFamilyMember(String uid, FamilyMemberModel member) async {
    await _familyMemberService(uid).set(member.id, member);
  }

  Future<List<FamilyMemberModel>> getFamilyMembers(String uid) =>
      _familyMemberService(uid).getAll();
}
