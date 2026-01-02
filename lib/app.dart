import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GetIt.I<AuthViewModel>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        /// ✅ Splash is landing
        initialRoute: '/splash',

        routes: {
          '/splash': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignupPage(),
          '/forgot': (_) => const ForgotScreen(),
          '/bottomnavigation': (_) => const BottomnavigationScreen(),
        },
      ),
    );
  }
}
