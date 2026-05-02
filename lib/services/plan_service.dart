import '../models/plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanService {
  final FirebaseFirestore _db;

  PlanService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Plan>> getTodayPlans() {
    return _db
        .collection('Plans')
        .orderBy('time', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Plan.fromFirestore).toList());
  }

  Future<void> joinPlan(String planId) async {
    final ref = _db.collection('Plans').doc(planId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final joined = (data['joinedCount'] as num?)?.toInt() ?? 0;
      final minPeople = (data['minPeople'] as num?)?.toInt() ?? 1;
      final nextJoined = joined + 1;

      final updates = <String, dynamic>{'joinedCount': nextJoined};
      final status = (data['status'] as String?) ?? 'pending';
      if (status != 'confirmed' && nextJoined >= minPeople) {
        updates['status'] = 'confirmed';
      }
      tx.update(ref, updates);
    });
  }
}
