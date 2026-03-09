import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../repositories/admin_repository.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return DeleteUserUseCase(repo);
});

class DeleteUserUseCase {
  final AdminRepository _repo;
  DeleteUserUseCase(this._repo);

  Future<Either<Failure, void>> execute(String id) {
    return _repo.deleteUser(id);
  }
}
