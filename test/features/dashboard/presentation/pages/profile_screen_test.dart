import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/dashboard/presentation/pages/profile_screen.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => AuthState(
    user: const AuthEntity(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      profilePicture: null,
    ),
  );

  @override
  Future<void> logout() async {}

  @override
  Future<void> uploadPhoto(file) async {}
}

void main() {
  Widget createWidget() {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('ProfileScreen shows user name and email', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows menu options', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('About us'), findsOneWidget);
    expect(find.text('Get Help'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
