import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthViewModel>();
    await auth.restoreSession();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (auth.state is AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, '/bottomnavigation');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Image.asset("assets/images/Logo.png")));
  }
}
