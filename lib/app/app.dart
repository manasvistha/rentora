import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/app/localization/locale_provider.dart';
import 'package:rentora/app/theme/ambient_light_provider.dart';
import 'package:rentora/app/theme/theme_mode_provider.dart';
import 'package:rentora/core/localization/app_localizations.dart';

// admin
import 'package:rentora/features/admin/presentation/pages/admin_dashboard_screen.dart';

// Import your pages
import 'package:rentora/features/splash/presentation/pages/splash_screen.dart';
import 'package:rentora/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:rentora/features/auth/presentation/pages/login_page.dart';
import 'package:rentora/features/auth/presentation/pages/signup_page.dart';
import 'package:rentora/features/forgetpassword/presentation/pages/forgot_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/bottomnavigation_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(ambientLightProvider);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentora',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
