import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final getDashboardSnapshotUseCaseProvider =
    Provider<GetDashboardSnapshotUseCase>((ref) {
      return GetDashboardSnapshotUseCase(ref.read(dashboardRepositoryProvider));
    });

class GetDashboardSnapshotUseCase {
  final IDashboardRepository _repository;

  GetDashboardSnapshotUseCase(this._repository);

  Future<Either<Failure, DashboardSnapshotEntity>> execute({
    bool forceRefresh = false,
  }) {
    return _repository.getDashboardSnapshot(forceRefresh: forceRefresh);
  }
}
