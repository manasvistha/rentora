import 'package:flutter/material.dart';
import 'package:rentora/features/dashboard/presentation/pages/home_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/search_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/settings_screen.dart';
import 'package:rentora/features/splash/presentation/pages/splash_screen.dart';
import 'package:rentora/screens/landing_screen.dart';
import 'package:rentora/screens/login_screen.dart';
import 'package:rentora/features/forgetpassword/presentation/pages/forgot_screen.dart';
import 'package:rentora/screens/signup_screen.dart';
import 'package:rentora/features/onboarding/presentation/pages/onboardingScreen.dart';
import 'package:rentora/features/dashboard/presentation/pages/bottomnavigation_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/home_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/search_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/message_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/settings_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/profile_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot': (context) => const ForgotScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/bottomnavigation': (context) => const BottomnavigationScreen(),
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const SearchScreen(),
        '/message': (context) => const MessageScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
