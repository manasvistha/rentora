import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../repositories/admin_repository.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';

final promoteUserUseCaseProvider = Provider<PromoteUserUseCase>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return PromoteUserUseCase(repo);
});

class PromoteUserUseCase {
  final AdminRepository _repo;
  PromoteUserUseCase(this._repo);

  Future<Either<Failure, void>> execute(String id) {
    return _repo.promoteUser(id);
  }
}
