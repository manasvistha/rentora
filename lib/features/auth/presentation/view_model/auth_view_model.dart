import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/data/repositories/auth_repository.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/login_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rentora/features/auth/domain/usecases/signup_usecase.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';

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
    _signupUseCase = ref.read(signupUseCaseProvider);
    _loginUseCase = ref.read(loginUseCaseProvider);
    _getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    _logoutUseCase = ref.read(logoutUseCaseProvider);
    Future.microtask(() => getCurrentUser());

    return const AuthState();
  }

  Future<void> register(
    AuthEntity user, {
    File? profileImage,
    String? confirmPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signupUseCase.execute(
      user,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (success) => state = state.copyWith(status: AuthStatus.registered),
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _loginUseCase.execute(email, password);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (success) => state = state.copyWith(status: AuthStatus.authenticated),
    );
    if (state.status == AuthStatus.authenticated) {
      await getCurrentUser();
    }
  }

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

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> uploadPhoto(File photo) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.uploadPhoto(photo);
      
      // Refresh user data to get the updated profile picture
      await getCurrentUser();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> restoreSession() async {}
}
