import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService<T> {
  final String collectionPath;
  final T Function(Map<String, dynamic> data, String documentId) fromMap;
  final Map<String, dynamic> Function(T item) toMap;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService({
    required this.collectionPath,
    required this.fromMap,
    required this.toMap,
  });

  CollectionReference<T> get _collection =>
      _db.collection(collectionPath).withConverter<T>(
            fromFirestore: (snapshot, _) => fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (item, _) => toMap(item),
          );

  Future<String> add(T item) async {
    final docRef = await _collection.add(item);
    return docRef.id;
  }

  Future<void> set(String id, T item, {bool merge = true}) async {
    await _collection.doc(id).set(item, SetOptions(merge: merge));
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _db.collection(collectionPath).doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> clearCollection() async {
    final snapshots = await _collection.get();
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<T?> getById(String id, {Source source = Source.serverAndCache}) async {
    final docSnapshot = await _collection.doc(id).get(GetOptions(source: source));
    return docSnapshot.data();
  }

  Stream<T?> streamById(String id) {
    return _collection.doc(id).snapshots().map((snapshot) => snapshot.data());
  }

  Future<List<T>> getAll({Source source = Source.serverAndCache}) async {
    final querySnapshot = await _collection.get(GetOptions(source: source));
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<T>> streamAll() {
    return _collection.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<T>> getWhere({
    required String field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
    Source source = Source.serverAndCache,
  }) async {
    final query = _collection.where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );

    final snapshot = await query.get(GetOptions(source: source));
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<QuerySnapshot<T>> getPaginated({
    int limit = 20,
    DocumentSnapshot<T>? startAfterDocument,
    String? orderByField,
    bool descending = false,
    Source source = Source.serverAndCache,
  }) async {
    Query<T> query = _collection;

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    query = query.limit(limit);

    return await query.get(GetOptions(source: source));
  }
}
