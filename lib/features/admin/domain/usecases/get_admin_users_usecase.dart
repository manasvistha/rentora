import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../repositories/admin_repository.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';

final getAdminUsersUseCaseProvider = Provider<GetAdminUsersUseCase>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return GetAdminUsersUseCase(repo);
});

class GetAdminUsersUseCase {
  final AdminRepository _repo;
  GetAdminUsersUseCase(this._repo);

  Future<Either<Failure, Map<String, dynamic>>> execute({
    int page = 1,
    int limit = 10,
  }) {
    return _repo.getUsers(page: page, limit: limit);
  }
}
