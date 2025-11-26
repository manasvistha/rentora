import 'package:flutter/material.dart';
import 'package:rentora/screens/forgot_screen.dart';
import 'package:rentora/screens/landing_screen.dart';
import 'package:rentora/screens/login_screen.dart';
import 'package:rentora/screens/signup_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: 'LandingScreen',
      routes: {
        'LandingScreen': (context) => LandingScreen(),
        'LoginScreen': (context) => LoginScreen(),
        'Forgot': (context) => ForgotScreen(),
        'signup': (context) => SignupScreen(),
      },
    );
  }
}
