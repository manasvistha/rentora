import 'package:flutter/material.dart';
import 'package:rentora/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/login_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/signup_usecase.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthViewModel({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  });

  AuthState _state = AuthInitial();
  AuthState get state => _state;

  Future<void> login(String email, String password) async {
    _state = AuthLoading();
    notifyListeners();

    final result = await loginUseCase(email, password);
    result.fold(
      (e) => _state = AuthError(e),
      (user) => _state = AuthAuthenticated(user),
    );
    notifyListeners();
  }

  Future<void> signup(String email, String password, String name) async {
    _state = AuthLoading();
    notifyListeners();

    final result = await signupUseCase(email, password, name);
    result.fold(
      (e) => _state = AuthError(e),
      (user) => _state = AuthAuthenticated(user),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await logoutUseCase();
    _state = AuthInitial();
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final result = await getCurrentUserUseCase();
    result.fold((_) => _state = AuthInitial(), (user) {
      if (user != null) {
        _state = AuthAuthenticated(user);
      } else {
        _state = AuthInitial();
      }
    });
    notifyListeners();
  }
}
