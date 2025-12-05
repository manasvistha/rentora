import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingData {
  static const List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Find Rooms Easily',
      description:
          'Search and discover rooms that perfectly match your needs in just a few taps.',
      imagePath: 'assets/images/onboard1.png',
    ),
    OnboardingModel(
      title: 'Compare & Choose',
      description:
          'View details, compare prices, and pick the best room that suits your lifestyle.',
      imagePath: 'assets/images/onboard2.png',
    ),
    OnboardingModel(
      title: 'Secure & Simple',
      description:
          'Enjoy a smooth, fast, and secure experience throughout your room-finding journey.',
      imagePath: 'assets/images/onboard3.png',
    ),
  ];
}
