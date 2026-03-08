import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/admin/domain/entities/admin_overview_entity.dart';
import 'package:rentora/features/admin/domain/repositories/admin_repository.dart';
import '../datasources/remote/admin_remote_datasource.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final ds = ref.read(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(ds);
});

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remote;
  AdminRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, AdminOverviewEntity>> getOverview() async {
    try {
      final users = await _remote.getUsersCount();
      final props = await _remote.getPropertiesCount();
      final bookings = await _remote.getBookingsCount();
      return right(
        AdminOverviewEntity(
          usersCount: users,
          propertiesCount: props,
          bookingsCount: bookings,
        ),
      );
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUsers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final data = await _remote.getUsers(page: page, limit: limit);
      return right(data);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getBookings() async {
    try {
      final data = await _remote.getBookings();
      return right(data);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      await _remote.deleteUser(id);
      return right(null);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> promoteUser(String id) async {
    try {
      await _remote.promoteUser(id);
      return right(null);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getProperties() async {
    try {
      final data = await _remote.getProperties();
      return right(data);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePropertyStatus(
    String id,
    String status,
  ) async {
    try {
      await _remote.updatePropertyStatus(id, status);
      return right(null);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProperty(String id) async {
    try {
      await _remote.deleteProperty(id);
      return right(null);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }
}
