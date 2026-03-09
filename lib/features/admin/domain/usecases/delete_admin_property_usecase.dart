import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';
import '../repositories/admin_repository.dart';

final deleteAdminPropertyUseCaseProvider = Provider<DeleteAdminPropertyUseCase>(
  (ref) {
    final repo = ref.read(adminRepositoryProvider);
    return DeleteAdminPropertyUseCase(repo);
  },
);

class DeleteAdminPropertyUseCase {
  final AdminRepository _repo;
  DeleteAdminPropertyUseCase(this._repo);

  Future<Either<Failure, void>> execute(String id) {
    return _repo.deleteProperty(id);
  }
}
