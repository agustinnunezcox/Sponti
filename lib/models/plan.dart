import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanCategory {
  food,
  music,
  sports,
  culture,
  nightlife,
  adventure,
  art;

  String get label => switch (this) {
        food => 'Food & Drink',
        music => 'Music',
        sports => 'Sports',
        culture => 'Culture',
        nightlife => 'Nightlife',
        adventure => 'Adventure',
        art => 'Art',
      };

  Color get color => switch (this) {
        food => const Color(0xFFFF6B35),
        music => const Color(0xFF7B2FBE),
        sports => const Color(0xFF2196F3),
        culture => const Color(0xFFE91E63),
        nightlife => const Color(0xFFFF0080),
        adventure => const Color(0xFF16A34A),
        art => const Color(0xFFFF5722),
      };

  String get emoji => switch (this) {
        food => '🍷',
        music => '🎵',
        sports => '⚽',
        culture => '🏛️',
        nightlife => '🌙',
        adventure => '🧗',
        art => '🎨',
      };

  static PlanCategory fromString(String value) => PlanCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PlanCategory.culture,
      );
}

class Plan {
  final String id;
  final String title;
  final String city;
  final String location;
  final DateTime time;
  final PlanCategory category;
  final String status;
  final int joinedCount;
  final int minPeople;
  final double price;

  const Plan({
    required this.id,
    required this.title,
    required this.city,
    required this.location,
    required this.time,
    required this.category,
    required this.status,
    required this.joinedCount,
    required this.minPeople,
    required this.price,
  });

  factory Plan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawTime = data['time'];
    final DateTime time = switch (rawTime) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };

    return Plan(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      time: time,
      category: PlanCategory.fromString(((data['category'] as String?) ?? 'culture').trim()),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      joinedCount: (data['joinedCount'] as num?)?.toInt() ?? 0,
      minPeople: (data['minPeople'] as num?)?.toInt() ?? 1,
      status: (data['status'] as String?) ?? 'pending',
    );
  }

  bool get isConfirmed => status == 'confirmed' || joinedCount >= minPeople;
  double get quorumProgress => (joinedCount / minPeople).clamp(0.0, 1.0);
  int get spotsToConfirm => (minPeople - joinedCount).clamp(0, minPeople);
}
