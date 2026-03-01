import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/explore_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: HomeContent());
  }
}
