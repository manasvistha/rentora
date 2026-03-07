import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import '../entities/admin_overview_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminOverviewEntity>> getOverview();
  Future<Either<Failure, Map<String, dynamic>>> getUsers({
    int page = 1,
    int limit = 10,
  });
  Future<Either<Failure, void>> deleteUser(String id);
  Future<Either<Failure, void>> promoteUser(String id);
  Future<Either<Failure, List<dynamic>>> getProperties();
  Future<Either<Failure, void>> updatePropertyStatus(String id, String status);
  Future<Either<Failure, void>> deleteProperty(String id);
}
