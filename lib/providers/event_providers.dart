import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/event_registration_model.dart';
import '../repositories/event_repository.dart';
import 'auth_provider.dart';

// Stream of all events for admin
final allEventsProvider = StreamProvider.autoDispose<List<EventModel>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.streamAllEvents();
});

// Single event provider
final eventDetailProvider = FutureProvider.family.autoDispose<EventModel?, String>((ref, eventId) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEvent(eventId);
});

// No longer needed, using local state in the UI for saving events.

// Registration for a specific event
final eventRegistrationProvider = FutureProvider.family.autoDispose<EventRegistrationModel?, String>((ref, eventId) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return null;
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getUserRegistrationForEvent(eventId, user.uid);
});

// Events happening today (for volunteers)
final todayEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getTodayEvents();
});
