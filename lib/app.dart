import 'package:flutter/material.dart';
import 'package:rentora/screens/home_screen.dart';
import 'package:rentora/screens/search_screen.dart';
import 'package:rentora/screens/splash_screen.dart';
import 'package:rentora/screens/landing_screen.dart';
import 'package:rentora/screens/login_screen.dart';
import 'package:rentora/screens/forgot_screen.dart';
import 'package:rentora/screens/signup_screen.dart';
import 'package:rentora/screens/onboardingScreen.dart';
import 'package:rentora/screens/bottomnavigation_screen.dart';
import 'package:rentora/screens/home_screen.dart';
import 'package:rentora/screens/search_screen.dart';

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
      },
    );
  }
}
