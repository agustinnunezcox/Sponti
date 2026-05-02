import 'package:flutter/material.dart';

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
  final String place;
  final DateTime time;
  final PlanCategory category;
  final int joinedCount;
  final int quorumMin;
  final double price;

  const Plan({
    required this.id,
    required this.title,
    required this.city,
    required this.place,
    required this.time,
    required this.category,
    required this.joinedCount,
    this.quorumMin = 3,
    this.price = 2.0,
  });

  bool get isConfirmed => joinedCount >= quorumMin;
  double get quorumProgress => (joinedCount / quorumMin).clamp(0.0, 1.0);
  int get spotsToConfirm => (quorumMin - joinedCount).clamp(0, quorumMin);
}
