import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/volunteer_profile_model.dart';
import '../models/admin_profile_model.dart';
import '../models/app_setting_model.dart';
import '../core/services/firestore_service.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository {
  final FirestoreService<VolunteerProfileModel> _volunteerService;
  final FirestoreService<AdminProfileModel> _adminService;
  final FirestoreService<AppSettingModel> _settingsService;

  AdminRepository()
      : _volunteerService = FirestoreService<VolunteerProfileModel>(
          collectionPath: 'volunteers',
          fromMap: VolunteerProfileModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _adminService = FirestoreService<AdminProfileModel>(
          collectionPath: 'admins',
          fromMap: AdminProfileModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _settingsService = FirestoreService<AppSettingModel>(
          collectionPath: 'settings',
          fromMap: AppSettingModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<void> updateVolunteerProfile(String uid, VolunteerProfileModel profile) =>
      _volunteerService.set(uid, profile);

  Future<AppSettingModel?> getAppSettings() => _settingsService.getById('app_config');
}
