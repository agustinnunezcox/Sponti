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
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .get();
      final raw = (doc.data() ?? {})['interests'];
      final interests = (raw as List<dynamic>?) ?? [];
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
    } catch (_) {
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
