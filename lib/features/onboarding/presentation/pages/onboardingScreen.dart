import 'package:flutter/material.dart';
import 'package:rentora/features/onboarding/data/models/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Visibility(
                visible: _currentIndex > 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  onPressed: () {
                    _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: OnboardingData.pages.length,
              itemBuilder: (context, index) {
                final page = OnboardingData.pages[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      page.imagePath,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        page.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              OnboardingData.pages.length,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: _currentIndex == index ? 25 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? const Color(0xFF4AA6A6)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4AA6A6),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_currentIndex == OnboardingData.pages.length - 1) {
                  Navigator.pushReplacementNamed(context, '/landing');
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                _currentIndex == OnboardingData.pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
