import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/auth/data/repositories/auth_repository.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

class GetCurrentUserUseCase {
  final IAuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, AuthEntity?>> execute() async {
    return await _repository.getCurrentUser();
  }
}
