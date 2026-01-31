import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/home_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: HomeContent()));
  }
}
