import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../repositories/communication_repository.dart';

final announcementsProvider = StreamProvider.autoDispose<List<AnnouncementModel>>((ref) {
  final repository = ref.watch(communicationRepositoryProvider);
  return repository.streamAnnouncements(); // Wait, let's check if streamAnnouncements exists!
});
