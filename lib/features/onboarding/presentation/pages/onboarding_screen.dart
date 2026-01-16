import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/onboarding/data/models/onboarding_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle navigation to next page or finishing onboarding
  void _handleNext(bool isLoading) async {
    if (isLoading) return;

    if (_currentPage < OnboardingData.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  // Handle skipping straight to login
  void _finishOnboarding() async {
    final authNotifier = ref.read(authViewModelProvider.notifier);

    // Check if user already has a session
    await authNotifier.restoreSession();

    final authState = ref.read(authViewModelProvider);

    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(context, '/bottomnavigation');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final bool isLoading = authState.status == AuthStatus.loading;
    final bool isLastPage = _currentPage == OnboardingData.pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER: Logo & Skip Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/Logo.png',
                    height: 40,
                    errorBuilder: (context, _, __) => const Text(
                      'RENTORA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4AA6A6),
                      ),
                    ),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: isLoading ? null : _finishOnboarding,
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),

            // --- BODY: PageView ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: OnboardingData.pages.length,
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
                itemBuilder: (context, i) {
                  final data = OnboardingData.pages[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(data.imagePath, height: 280),
                      const SizedBox(height: 40),
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // --- FOOTER: Indicators & Button ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      OnboardingData.pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 5),
                        height: 10,
                        width: _currentPage == index ? 25 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF4AA6A6)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _handleNext(isLoading),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4AA6A6),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLastPage ? "Get Started" : "Next",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
