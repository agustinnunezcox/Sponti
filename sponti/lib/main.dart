import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

  if (!kIsWeb) {
    Stripe.publishableKey =
        'pk_test_51TUDFbHkbOqvtdtUXb08mTjbKY7OmlDB7I6NqZhY7n2Q1Wx54YwJ6dg0BXoS3DBIbpVr9uAwAYDqJKWHa2tePVjO00ReCg1LZp';
    try {
      await Stripe.instance.applySettings();
    } catch (_) {}
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  AppStrings.setLanguage(prefs.getString('language') ?? 'Español');

  runApp(SpontiApp(showOnboarding: !onboardingDone));
}

class SpontiApp extends StatelessWidget {
  final bool showOnboarding;
  const SpontiApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppStrings.localeNotifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'Sponti',
        theme: AppTheme.theme,
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: showOnboarding ? const OnboardingScreen() : const WelcomeScreen(),
      ),
    );
  }
}
