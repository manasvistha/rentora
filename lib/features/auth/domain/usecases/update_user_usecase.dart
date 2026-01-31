import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/auth/data/repositories/auth_repository.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final updateUserUseCaseProvider = Provider<UpdateUserUseCase>((ref) {
  return UpdateUserUseCase(ref.read(authRepositoryProvider));
});

class UpdateUserUseCase {
  final IAuthRepository _repository;

  UpdateUserUseCase(this._repository);

  Future<Either<Failure, bool>> execute(AuthEntity user) async {
    return await _repository.updateUser(user);
  }
}
