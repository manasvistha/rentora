import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:rentora/features/onboarding/data/models/onboarding_model.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState();

  @override
  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.authenticated);
  }
}

void main() {
  const Size _testScreenSize = Size(1080, 1920);

  Widget makeTestable({required Widget child}) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
      child: MaterialApp(
        home: child,
        routes: {
          '/bottomnavigation': (context) =>
              const Scaffold(body: Text('Bottom Nav')),
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );
  }

  testWidgets('1. Should render first onboarding page', (tester) async {
    tester.binding.window.physicalSizeTestValue = _testScreenSize;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(makeTestable(child: const OnboardingScreen()));
    expect(find.text(OnboardingData.pages[0].title), findsOneWidget);
    expect(find.text(OnboardingData.pages[0].description), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('2. Should navigate to next page on Next button tap', (
    tester,
  ) async {
    tester.binding.window.physicalSizeTestValue = _testScreenSize;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(makeTestable(child: const OnboardingScreen()));

    if (OnboardingData.pages.length > 1) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text(OnboardingData.pages[1].title), findsOneWidget);
      expect(find.text(OnboardingData.pages[1].description), findsOneWidget);
    }
  });

  testWidgets('3. Should navigate to BottomNavigation after last page', (
    tester,
  ) async {
    tester.binding.window.physicalSizeTestValue = _testScreenSize;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(makeTestable(child: const OnboardingScreen()));

    for (int i = 0; i < OnboardingData.pages.length; i++) {
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bottom Nav'), findsOneWidget);
  });
}
