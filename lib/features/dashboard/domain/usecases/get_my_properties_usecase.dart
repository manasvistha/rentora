import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final getMyPropertiesUseCaseProvider = Provider<GetMyPropertiesUseCase>((ref) {
  return GetMyPropertiesUseCase(ref.read(dashboardRepositoryProvider));
});

class GetMyPropertiesUseCase {
  final IDashboardRepository _repository;

  GetMyPropertiesUseCase(this._repository);

  Future<Either<Failure, List<DashboardPropertyEntity>>> execute({
    bool forceRefresh = false,
  }) {
    return _repository.getMyProperties(forceRefresh: forceRefresh);
  }
}
