import 'package:flutter/material.dart';

// admin
import 'package:rentora/features/admin/presentation/pages/admin_dashboard_screen.dart';

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
        '/admin': (_) => const AdminDashboardScreen(),
        '/bottomnavigation': (_) => const BottomnavigationScreen(),
      },
    );
  }
}
