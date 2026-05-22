import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';
import '../models/subscription_model.dart';
import '../models/gallery_model.dart';
import '../models/album_model.dart';
import '../models/media_item_model.dart';
import '../models/notification_model.dart';
import '../repositories/communication_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/payment_repository.dart';
import '../core/services/firestore_service.dart';
import 'auth_provider.dart';

// ── Announcements (real-time stream) ──────────────────────────────────────────
final announcementsStreamProvider =
    StreamProvider.autoDispose<List<AnnouncementModel>>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.streamAnnouncements();
});

// ── Upcoming Events (next 5 upcoming) ────────────────────────────────────────
final upcomingEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getUpcomingEvents(limit: 5);
});

// ── Active Subscription for current user ────────────────────────────────────
final userSubscriptionProvider =
    FutureProvider.autoDispose<SubscriptionModel?>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return null;
  final repo = ref.watch(paymentRepositoryProvider);
  final subs = await repo.getUserSubscriptions(user.uid);
  if (subs.isEmpty) return null;
  
  // Return most recent active subscription, checking for expiry dynamically
  final active = subs.where((s) => s.status == SubscriptionStatus.active).toList();
  if (active.isNotEmpty) {
    active.sort((a, b) => b.endDate.compareTo(a.endDate));
    final latestActive = active.first;
    if (latestActive.endDate.isBefore(DateTime.now())) {
      return latestActive.copyWith(status: SubscriptionStatus.expired);
    }
    return latestActive;
  }
  
  subs.sort((a, b) => b.endDate.compareTo(a.endDate));
  final latestSub = subs.first;
  if (latestSub.endDate.isBefore(DateTime.now())) {
    return latestSub.copyWith(status: SubscriptionStatus.expired);
  }
  return latestSub;
});

// ── Gallery Albums (latest 12) ───────────────────────────────────────────────
final galleryPreviewProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final service = FirestoreService<Album>(
    collectionPath: 'gallery_albums',
    fromMap: (data, id) => Album.fromMap(id, data),
    toMap: (item) => item.toMap(),
  );
  final snapshot = await service.getPaginated(
    limit: 12,
    orderByField: 'createdAt',
    descending: true,
  );
  return snapshot.docs.map((d) => d.data()).toList();
});

// ── Full gallery (paginated via Notifier) ─────────────────────────────────────
class GalleryState {
  final List<Album> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  const GalleryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
  GalleryState copyWith({List<Album>? items, bool? isLoading, bool? hasMore, String? error}) =>
      GalleryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class GalleryNotifier extends Notifier<GalleryState> {
  final FirestoreService<Album> _service = FirestoreService<Album>(
    collectionPath: 'gallery_albums',
    fromMap: (data, id) => Album.fromMap(id, data),
    toMap: (item) => item.toMap(),
  );

  // We track the raw snapshot to use startAfterDocument correctly
  QueryDocumentSnapshot<Album>? _lastDoc;
  final List<Album> _items = [];

  @override
  GalleryState build() {
    _load();
    return const GalleryState(isLoading: true);
  }

  Future<void> _load() async {
    if (!state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _service.getPaginated(
  limit: 20,
  orderByField: 'createdAt',
  descending: true,
  startAfterDocument: _lastDoc,
);
if (snapshot.docs.isNotEmpty) {
  _lastDoc = snapshot.docs.last;
  _items.addAll(snapshot.docs.map((d) => d.data()));
}
final hasMore = snapshot.docs.length == 20;
state = GalleryState(items: List.unmodifiable(_items), isLoading: false, hasMore: hasMore);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() => _load();

  Future<void> refresh() async {
    _lastDoc = null;
    _items.clear();
    state = const GalleryState(isLoading: true, hasMore: true);
    await _load();
  }
}

final galleryNotifierProvider =
    NotifierProvider<GalleryNotifier, GalleryState>(
  GalleryNotifier.new,
);

// ── Album Media Provider ──────────────────────────────────────────────────
final albumMediaProvider = StreamProvider.family.autoDispose<List<MediaItem>, String>((ref, albumId) {
  final service = FirestoreService<MediaItem>(
    collectionPath: 'gallery_albums/$albumId/media',
    fromMap: (data, id) => MediaItem.fromMap(id, data),
    toMap: (item) => item.toMap(),
  );
  return service.streamAll().map((items) {
    items.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return items;
  });
});

class _DashboardIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

final userDashboardIndexProvider =
    NotifierProvider<_DashboardIndexNotifier, int>(
  _DashboardIndexNotifier.new,
);

final userNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = FirestoreService<NotificationModel>(
    collectionPath: 'users/${user.uid}/notifications',
    fromMap: NotificationModel.fromMap,
    toMap: (item) => item.toMap(),
  );
  return service.streamAll().map((list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
