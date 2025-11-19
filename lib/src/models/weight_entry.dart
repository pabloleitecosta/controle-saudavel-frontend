import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
  });

  factory WeightEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final dateStr = data['date']?.toString();
    DateTime? parsedDate;
    if (dateStr != null) {
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (_) {
        parsedDate = null;
      }
    }
    parsedDate ??=
        (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return WeightEntry(
      id: doc.id,
      date: parsedDate,
      weight: (data['weight'] ?? 0).toDouble(),
    );
  }
}
