import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/auth/data/repositories/auth_repository.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

class LoginUseCase {
  final IAuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, AuthEntity>> execute(
    String email,
    String password,
  ) async {
    return await _repository.login(email, password);
  }
}
