import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/auth/presentation/pages/login_page.dart';
import 'package:rentora/features/auth/presentation/pages/signup_page.dart';
import 'package:rentora/features/splash/presentation/pages/splash_screen.dart';
import 'package:rentora/features/forgetpassword/presentation/pages/forgot_screen.dart';
import 'package:rentora/features/onboarding/presentation/pages/onboarding_screen.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GetIt.I<AuthViewModel>()),
      ],
      child: MaterialApp(
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/landing': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/forgot': (context) => const ForgotScreen(),
          '/signup': (context) => const SignupPage(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/bottomnavigation': (context) => const BottomnavigationScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/message': (context) => const MessageScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
