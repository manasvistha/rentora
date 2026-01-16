import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/login_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/signup_usecase.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';

// Provider definition using the modern NotifierProvider
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

class AuthViewModel extends Notifier<AuthState> {
  late final SignupUsecase _signupUseCase;
  late final LoginUseCase _loginUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final LogoutUseCase _logoutUseCase;

  @override
  AuthState build() {
    // Initializing use cases from their respective providers
    _signupUseCase = ref.read(signupUseCaseProvider);
    _loginUseCase = ref.read(loginUseCaseProvider);
    _getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    _logoutUseCase = ref.read(logoutUseCaseProvider);

    // Auto-check for existing session on app startup/provider initialization
    Future.microtask(() => getCurrentUser());

    return const AuthState();
  }

  /// Handles user registration (using your strict 4-field UserEntity)
  Future<void> register(AuthEntity user) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signupUseCase.execute(user);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (success) => state = state.copyWith(status: AuthStatus.registered),
    );
  }

  /// Handles user login
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _loginUseCase.execute(email, password);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (success) => state = state.copyWith(
        status: AuthStatus.authenticated,
        // After successful login, we usually trigger getCurrentUser
        // to populate the user entity in the state
      ),
    );

    // If successful, refresh the current user data
    if (state.status == AuthStatus.authenticated) {
      await getCurrentUser();
    }
  }

  /// Checks if a session exists (e.g., on app startup)
  Future<void> getCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _getCurrentUserUseCase.execute();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ),
      (user) {
        if (user != null) {
          state = state.copyWith(status: AuthStatus.authenticated, user: user);
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  /// Handles user logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _logoutUseCase.execute();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (success) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ),
    );
  }

  /// Resets error messages
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> restoreSession() async {}
}
