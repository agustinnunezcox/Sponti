import '../models/plan.dart';

class PlanService {
  static final _now = DateTime.now();

  static final List<Plan> _mockPlans = [
    Plan(
      id: '1',
      title: 'Rooftop Wine & Tapas',
      city: 'Barcelona',
      place: 'Bar Marsella, El Born',
      time: _now.copyWith(hour: 20, minute: 0, second: 0),
      category: PlanCategory.food,
      joinedCount: 2,
    ),
    Plan(
      id: '2',
      title: 'Flamenco Night at Tablao',
      city: 'Seville',
      place: 'El Arenal, Centro',
      time: _now.copyWith(hour: 22, minute: 30, second: 0),
      category: PlanCategory.music,
      joinedCount: 5,
    ),
    Plan(
      id: '3',
      title: 'Beach Volleyball Sunset',
      city: 'Lisbon',
      place: 'Praia de Carcavelos',
      time: _now.copyWith(hour: 18, minute: 30, second: 0),
      category: PlanCategory.sports,
      joinedCount: 1,
    ),
    Plan(
      id: '4',
      title: 'Guided Alhambra Tour',
      city: 'Granada',
      place: 'Alhambra Palace',
      time: _now.copyWith(hour: 10, minute: 0, second: 0),
      category: PlanCategory.culture,
      joinedCount: 7,
    ),
    Plan(
      id: '5',
      title: 'Techno Rave Underground',
      city: 'Berlin',
      place: 'Tresor Club',
      time: _now.copyWith(hour: 23, minute: 59, second: 0),
      category: PlanCategory.nightlife,
      joinedCount: 3,
    ),
    Plan(
      id: '6',
      title: 'Rock Climbing at Montserrat',
      city: 'Barcelona',
      place: 'Montserrat Mountain',
      time: _now.copyWith(hour: 9, minute: 0, second: 0),
      category: PlanCategory.adventure,
      joinedCount: 2,
    ),
    Plan(
      id: '7',
      title: 'Street Art Walking Tour',
      city: 'Lisbon',
      place: 'LX Factory, Alcântara',
      time: _now.copyWith(hour: 15, minute: 0, second: 0),
      category: PlanCategory.art,
      joinedCount: 4,
    ),
  ];

  Stream<List<Plan>> getTodayPlans({String? city}) {
    // TODO: swap with Firestore stream after flutterfire configure
    // return FirebaseFirestore.instance
    //     .collection('plans')
    //     .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()))
    //     .snapshots()
    //     .map((s) => s.docs.map(Plan.fromFirestore).toList());
    final filtered = (city == null || city == 'All')
        ? _mockPlans
        : _mockPlans.where((p) => p.city == city).toList();
    return Stream.value(filtered);
  }

  Future<void> joinPlan(String planId) async {
    // TODO: Firestore transaction
    // await FirebaseFirestore.instance.runTransaction((tx) async {
    //   final ref = FirebaseFirestore.instance.collection('plans').doc(planId);
    //   final snap = await tx.get(ref);
    //   tx.update(ref, {'joinedCount': (snap['joinedCount'] as int) + 1});
    // });
  }

  List<String> get availableCities =>
      ['All', ..._mockPlans.map((p) => p.city).toSet().toList()..sort()];
}
