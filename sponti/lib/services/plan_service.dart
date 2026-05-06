import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan.dart';

class PlanService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _plans => _db.collection('Plans');

  Stream<List<Plan>> getTodayPlans({String? city}) {
    Query<Map<String, dynamic>> query = _plans;

    if (city != null && city != 'All') {
      query = query.where('city', isEqualTo: city);
    }

    return query.snapshots().map((snap) {
      print('DOCUMENTOS RECIBIDOS: ${snap.docs.length}');
      for (var doc in snap.docs) {
        print('DOC: ${doc.id} - ${doc.data()}');
      }
      final plans = <Plan>[];
      for (final doc in snap.docs) {
        try {
          plans.add(Plan.fromFirestore(doc));
        } catch (e, st) {
          print('ERROR en fromFirestore [${doc.id}]: $e\n$st');
        }
      }
      plans.sort((a, b) => a.time.compareTo(b.time));
      return plans;
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
