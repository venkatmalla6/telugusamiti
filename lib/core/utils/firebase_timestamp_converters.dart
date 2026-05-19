import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? timestampToDateTime(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
  if (timestamp is String) return DateTime.tryParse(timestamp);
  return null;
}

Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
