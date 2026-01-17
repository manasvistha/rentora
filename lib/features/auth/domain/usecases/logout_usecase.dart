import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/auth/data/repositories/auth_repository.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

class LogoutUseCase {
  final IAuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Either<Failure, bool>> execute() async {
    return await _repository.logout();
  }
}
