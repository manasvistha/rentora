import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final updateBookingStatusUseCaseProvider = Provider<UpdateBookingStatusUseCase>(
  (ref) {
    return UpdateBookingStatusUseCase(ref.read(dashboardRepositoryProvider));
  },
);

class UpdateBookingStatusUseCase {
  final IDashboardRepository _repository;

  UpdateBookingStatusUseCase(this._repository);

  Future<Either<Failure, bool>> execute(String bookingId, String status) {
    return _repository.updateBookingStatus(bookingId, status);
  }
}
