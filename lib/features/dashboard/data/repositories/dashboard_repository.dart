import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:rentora/features/dashboard/data/datasources/local/dashboard_local_datasource.dart';
import 'package:rentora/features/dashboard/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';
import 'package:rentora/features/dashboard/domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return DashboardRepository(
    localDataSource: ref.read(dashboardLocalDataSourceProvider),
    remoteDataSource: ref.read(dashboardRemoteDataSourceProvider),
  );
});

class DashboardRepository implements IDashboardRepository {
  final IDashboardLocalDataSource _localDataSource;
  final IDashboardRemoteDataSource _remoteDataSource;

  DashboardRepository({
    required IDashboardLocalDataSource localDataSource,
    required IDashboardRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<DashboardPropertyEntity>>> getAllProperties({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localDataSource.getCachedAllProperties();
      if (cached.isNotEmpty) return Right(cached);
    }

    try {
      final remote = await _remoteDataSource.getAllProperties();
      _localDataSource.cacheAllProperties(remote);
      return Right(remote);
    } catch (e) {
      final cached = _localDataSource.getCachedAllProperties();
      if (cached.isNotEmpty) return Right(cached);
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DashboardBookingEntity>>> getBookingRequests({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localDataSource.getCachedBookingRequests();
      if (cached.isNotEmpty) return Right(cached);
    }

    try {
      final remote = await _remoteDataSource.getBookingRequests();
      _localDataSource.cacheBookingRequests(remote);
      return Right(remote);
    } catch (e) {
      final cached = _localDataSource.getCachedBookingRequests();
      if (cached.isNotEmpty) return Right(cached);
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardSnapshotEntity>> getDashboardSnapshot({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localDataSource.getCachedDashboardSnapshot();
      if (cached.allProperties.isNotEmpty ||
          cached.myProperties.isNotEmpty ||
          cached.myBookings.isNotEmpty ||
          cached.bookingRequests.isNotEmpty) {
        return Right(cached);
      }
    }

    try {
      final remote = await _remoteDataSource.getDashboardSnapshot();
      _localDataSource.cacheDashboardSnapshot(remote);
      return Right(remote);
    } catch (e) {
      final cached = _localDataSource.getCachedDashboardSnapshot();
      if (cached.allProperties.isNotEmpty ||
          cached.myProperties.isNotEmpty ||
          cached.myBookings.isNotEmpty ||
          cached.bookingRequests.isNotEmpty) {
        return Right(cached);
      }
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DashboardBookingEntity>>> getMyBookings({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localDataSource.getCachedMyBookings();
      if (cached.isNotEmpty) return Right(cached);
    }

    try {
      final remote = await _remoteDataSource.getMyBookings();
      _localDataSource.cacheMyBookings(remote);
      return Right(remote);
    } catch (e) {
      final cached = _localDataSource.getCachedMyBookings();
      if (cached.isNotEmpty) return Right(cached);
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DashboardPropertyEntity>>> getMyProperties({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localDataSource.getCachedMyProperties();
      if (cached.isNotEmpty) return Right(cached);
    }

    try {
      final remote = await _remoteDataSource.getMyProperties();
      _localDataSource.cacheMyProperties(remote);
      return Right(remote);
    } catch (e) {
      final cached = _localDataSource.getCachedMyProperties();
      if (cached.isNotEmpty) return Right(cached);
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
