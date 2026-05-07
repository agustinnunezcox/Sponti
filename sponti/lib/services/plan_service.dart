import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan.dart';

class PlanService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _plans => _db.collection('Plans');

  Stream<List<Plan>> getPlansForDate({required DateTime date, String? city}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = _plans
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay));
    return query.snapshots().map((snap) {
      final plans = <Plan>[];
      for (final doc in snap.docs) {
        try {
          plans.add(Plan.fromFirestore(doc));
        } catch (_) {}
      }
      final filtered = (city != null && city != 'All')
          ? plans.where((p) => p.city == city).toList()
          : plans;
      filtered.sort((a, b) => a.time.compareTo(b.time));
      return filtered;
    });
  }

  Future<void> joinPlan(String planId, String userId) async {
    if (userId.trim().isEmpty) throw Exception('Usuario no identificado.');
    final docRef = _plans.doc(planId);
    final snap = await docRef.get();
    final joined = List<String>.from(
        ((snap.data() ?? {})['joinedUsers'] as List<dynamic>?) ?? []);
    if (joined.contains(userId)) return;
    await docRef.set({
      'joinedUsers': FieldValue.arrayUnion([userId]),
      'joinedCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<List<String>> get availableCities async {
    final snap = await _plans.get();
    final cities = snap.docs
        .map((d) => d.data()['city'] as String)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cities];
  }

}
