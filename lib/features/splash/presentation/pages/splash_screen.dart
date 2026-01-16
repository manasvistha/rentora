import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Just a simple timer delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Navigate straight to Onboarding
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7E3E4), // Your theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/Logo.png",
              height: 150,
              // Fallback if image is missing
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.home_work, size: 100, color: Colors.teal),
            ),
            const SizedBox(height: 30),
            // Optional: Simple loader
            const CircularProgressIndicator(
              color: Color(0xFF4AA6A6),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
