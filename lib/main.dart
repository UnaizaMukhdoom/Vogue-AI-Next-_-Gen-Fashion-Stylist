// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/questionnaire_flow_screen.dart';
import 'screens/selfie_screen.dart';
import 'screens/result_screen.dart';
import 'screens/firebase_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOGUE AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const DashboardScreen(),
        '/questionnaire': (_) => const QuestionnaireFlowScreen(),
        '/selfie': (_) => const SelfieScreen(),
        '/result': (_) => const ResultScreen(), // Removed const since it reads route args
        '/firebase-test': (_) => const FirebaseTestScreen(), // Firebase connection test
      },
    );
  }
}
