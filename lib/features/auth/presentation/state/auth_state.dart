import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entity.dart';

/// Defines the different stages of the authentication lifecycle.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  registered,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// The starting state of the application.
  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.initial,
      user: null,
      errorMessage: null,
    );
  }

  /// Returns a new instance of [AuthState] with updated fields.
  /// Use this inside your StateNotifier to trigger UI updates.
  AuthState copyWith({
    AuthStatus? status,
    AuthEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];

  /// Useful for debugging state transitions in the console.
  @override
  bool get stringify => true;
}
