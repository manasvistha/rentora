import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your pages
import 'package:rentora/features/splash/presentation/pages/splash_screen.dart';
import 'package:rentora/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:rentora/features/auth/presentation/pages/login_page.dart';
import 'package:rentora/features/auth/presentation/pages/signup_page.dart';
import 'package:rentora/features/forgetpassword/presentation/pages/forgot_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/bottomnavigation_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // In Riverpod, we wrap the MaterialApp in a ProviderScope (usually done in main.dart)
    // If you haven't wrapped it in main.dart, you can do it here,
    // but ProviderScope should only exist ONCE at the top of the tree.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentora',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/forgot': (_) => const ForgotScreen(),
        '/bottomnavigation': (_) => const BottomnavigationScreen(),
      },
    );
  }
}
