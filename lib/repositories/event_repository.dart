import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/event_registration_model.dart';
import '../models/food_token_model.dart';
import '../models/attendance_model.dart';
import '../core/services/firestore_service.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

class EventRepository {
  final FirestoreService<EventModel> _eventService;

  EventRepository()
      : _eventService = FirestoreService<EventModel>(
          collectionPath: 'events',
          fromMap: EventModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<String> createEvent(EventModel event) => _eventService.add(event);
  Future<void> updateEvent(String id, Map<String, dynamic> data) => _eventService.update(id, data);
  Future<void> deleteEvent(String id) => _eventService.delete(id);
  Future<EventModel?> getEvent(String id) => _eventService.getById(id);
  Stream<List<EventModel>> streamAllEvents() => _eventService.streamAll();

  Future<List<EventModel>> getUpcomingEvents({int limit = 5}) async {
    final now = DateTime.now();
    final all = await _eventService.getWhere(
      field: 'isPublished',
      isEqualTo: true,
    );
    final upcoming = all
        .where((e) => e.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.take(limit).toList();
  }

  Future<List<EventModel>> getTodayEvents() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final all = await _eventService.getWhere(
      field: 'isPublished',
      isEqualTo: true,
    );
    return all.where((e) => 
      (e.startDate.isAfter(todayStart) || e.startDate.isAtSameMomentAs(todayStart)) && 
      e.startDate.isBefore(todayEnd)
    ).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  FirestoreService<EventRegistrationModel> _registrationService(String eventId) =>
      FirestoreService<EventRegistrationModel>(
        collectionPath: 'events/$eventId/registrations',
        fromMap: EventRegistrationModel.fromMap,
        toMap: (item) => item.toMap(),
      );

  Future<void> registerForEvent(String eventId, EventRegistrationModel registration) async {
    await _registrationService(eventId).set(registration.id, registration);
  }

  Future<EventRegistrationModel?> getUserRegistrationForEvent(String eventId, String userId) async {
    final registrations = await _registrationService(eventId).getWhere(
      field: 'userId',
      isEqualTo: userId,
    );
    if (registrations.isNotEmpty) {
      return registrations.first;
    }
    return null;
  }

  Future<EventRegistrationModel?> getRegistrationById(String eventId, String registrationId) async {
    return await _registrationService(eventId).getById(registrationId);
  }

  Future<List<EventRegistrationModel>> getEventRegistrations(String eventId) async {
    return await _registrationService(eventId).getAll();
  }

  Future<void> markFoodClaimed(String eventId, String registrationId) async {
    await _registrationService(eventId).update(registrationId, {
      'foodClaimed': true,
      'foodClaimedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAttended(String eventId, String registrationId) async {
    await _registrationService(eventId).update(registrationId, {
      'attended': true,
      'attendedAt': DateTime.now().toIso8601String(),
    });
  }

  FirestoreService<FoodTokenModel> _foodTokenService(String eventId) =>
      FirestoreService<FoodTokenModel>(
        collectionPath: 'events/$eventId/food_tokens',
        fromMap: FoodTokenModel.fromMap,
        toMap: (item) => item.toMap(),
      );

  Future<void> generateFoodToken(String eventId, FoodTokenModel token) async {
    await _foodTokenService(eventId).set(token.id, token);
  }
}
