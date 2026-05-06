import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/interests_screen.dart';
import '../theme/app_theme.dart';

// Shared userId used throughout the app while real auth is not wired up.
const kUserId = 'user_test_01';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    print('[AuthGate] Consultando users/$kUserId en Firestore...');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .get();
      print('[AuthGate] Documento existe: ${doc.exists}');
      print('[AuthGate] Data completa: ${doc.data()}');
      final raw = (doc.data() ?? {})['interests'];
      print('[AuthGate] Campo interests (raw): $raw (tipo: ${raw.runtimeType})');
      final interests = (raw as List<dynamic>?) ?? [];
      print('[AuthGate] interests.length = ${interests.length} → ruta: ${interests.isNotEmpty ? "HomeScreen" : "InterestsScreen"}');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => interests.isNotEmpty
              ? const HomeScreen()
              : const InterestsScreen(),
        ),
        (route) => false,
      );
    } catch (e, st) {
      print('[AuthGate] ERROR: $e\n$st');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InterestsScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.dark,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}
