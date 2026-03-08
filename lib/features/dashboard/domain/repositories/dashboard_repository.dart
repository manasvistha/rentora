import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';

abstract class IDashboardRepository {
  Future<Either<Failure, List<DashboardPropertyEntity>>> getAllProperties({
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<DashboardPropertyEntity>>> getMyProperties({
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<DashboardBookingEntity>>> getMyBookings({
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<DashboardBookingEntity>>> getBookingRequests({
    bool forceRefresh = false,
  });

  Future<Either<Failure, bool>> createBookingRequest(String propertyId);

  Future<Either<Failure, bool>> updateBookingStatus(
    String bookingId,
    String status,
  );

  Future<Either<Failure, DashboardSnapshotEntity>> getDashboardSnapshot({
    bool forceRefresh = false,
  });
}
