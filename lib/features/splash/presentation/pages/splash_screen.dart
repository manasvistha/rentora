import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';

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
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final sessionService = UserSessionService(const FlutterSecureStorage());
    final hasSession = await sessionService.hasSession();
    if (!hasSession) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final isAdmin = await sessionService.isAdmin();
    Navigator.pushReplacementNamed(
      context,
      isAdmin ? '/admin' : '/bottomnavigation',
    );
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.home_work, size: 100, color: Colors.teal),
            ),
            const SizedBox(height: 30),
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
