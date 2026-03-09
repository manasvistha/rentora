import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../entities/admin_overview_entity.dart';
import '../repositories/admin_repository.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';

final getAdminOverviewUseCaseProvider = Provider<GetAdminOverviewUseCase>((
  ref,
) {
  final repo = ref.read(adminRepositoryProvider);
  return GetAdminOverviewUseCase(repo);
});

class GetAdminOverviewUseCase {
  final AdminRepository _repo;
  GetAdminOverviewUseCase(this._repo);

  Future<Either<Failure, AdminOverviewEntity>> execute() {
    return _repo.getOverview();
  }
}
