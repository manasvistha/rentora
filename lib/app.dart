import 'package:flutter/material.dart';
import 'package:rentora/screens/landing_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: 'LandingScreen',
      routes: {'LandingScreen': (context) => LandingScreen()},
    );
  }
}
