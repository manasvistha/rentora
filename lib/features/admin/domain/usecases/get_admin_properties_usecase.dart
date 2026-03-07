import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';
import '../repositories/admin_repository.dart';

final getAdminPropertiesUseCaseProvider = Provider<GetAdminPropertiesUseCase>((
  ref,
) {
  final repo = ref.read(adminRepositoryProvider);
  return GetAdminPropertiesUseCase(repo);
});

class GetAdminPropertiesUseCase {
  final AdminRepository _repo;
  GetAdminPropertiesUseCase(this._repo);

  Future<Either<Failure, List<dynamic>>> execute() {
    return _repo.getProperties();
  }
}
