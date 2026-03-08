import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final createBookingRequestUseCaseProvider =
    Provider<CreateBookingRequestUseCase>((ref) {
      return CreateBookingRequestUseCase(ref.read(dashboardRepositoryProvider));
    });

class CreateBookingRequestUseCase {
  final IDashboardRepository _repository;

  CreateBookingRequestUseCase(this._repository);

  Future<Either<Failure, bool>> execute(String propertyId) {
    return _repository.createBookingRequest(propertyId);
  }
}
