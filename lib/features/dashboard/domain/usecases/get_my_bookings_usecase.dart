import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final getMyBookingsUseCaseProvider = Provider<GetMyBookingsUseCase>((ref) {
  return GetMyBookingsUseCase(ref.read(dashboardRepositoryProvider));
});

class GetMyBookingsUseCase {
  final IDashboardRepository _repository;

  GetMyBookingsUseCase(this._repository);

  Future<Either<Failure, List<DashboardBookingEntity>>> execute({
    bool forceRefresh = false,
  }) {
    return _repository.getMyBookings(forceRefresh: forceRefresh);
  }
}
