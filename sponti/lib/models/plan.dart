import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PlanCategory {
  food,
  music,
  sports,
  football,
  culture,
  nightlife,
  adventure,
  art;

  String get label => switch (this) {
        food => 'Food & Drink',
        music => 'Music',
        sports => 'Sports',
        football => 'Football',
        culture => 'Culture',
        nightlife => 'Nightlife',
        adventure => 'Adventure',
        art => 'Art',
      };

  Color get color => switch (this) {
        food => const Color(0xFFFF6B35),
        music => const Color(0xFF7B2FBE),
        sports => const Color(0xFF2196F3),
        football => const Color(0xFF16A34A),
        culture => const Color(0xFFE91E63),
        nightlife => const Color(0xFFFF0080),
        adventure => const Color(0xFF16A34A),
        art => const Color(0xFFFF5722),
      };

  String get emoji => switch (this) {
        food => '🍷',
        music => '🎵',
        sports => '⚽',
        football => '⚽',
        culture => '🏛️',
        nightlife => '🌙',
        adventure => '🧗',
        art => '🎨',
      };

  static PlanCategory fromString(String value) => PlanCategory.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => PlanCategory.culture,
      );
}

class Plan {
  final String id;
  final String title;
  final String description;
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
    this.description = '',
    required this.city,
    required this.place,
    required this.time,
    required this.category,
    required this.joinedCount,
    this.quorumMin = 3,
    this.price = 5.0,
  });

  bool get hasQuorum => quorumMin > 0;
  bool get isConfirmed => hasQuorum && joinedCount >= quorumMin;
  double get quorumProgress => !hasQuorum ? 0.0 : (joinedCount / quorumMin).clamp(0.0, 1.0);
  int get spotsToConfirm => !hasQuorum ? 0 : (quorumMin - joinedCount).clamp(0, quorumMin);

  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plan(
      id: doc.id,
      title: data['title'] as String,
      description: (data['description'] as String?) ?? '',
      city: data['city'] as String,
      place: (data['location'] ?? data['place'] ?? '') as String,
      time: (data['time'] as Timestamp).toDate(),
      category: PlanCategory.fromString(data['category'] as String),
      joinedCount: (data['joinedCount'] as num).toInt(),
      quorumMin: ((data['minPeople'] ?? data['quorumMin'] ?? 0) as num).toInt(),
      price: (data['price'] as num? ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'city': city,
        'place': place,
        'time': Timestamp.fromDate(time),
        'category': category.name,
        'joinedCount': joinedCount,
        'quorumMin': quorumMin,
        'price': price,
        'dateStr': '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}',
      };
}
