import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/admin/data/repositories/admin_repository_impl.dart';
import '../repositories/admin_repository.dart';

final updateAdminPropertyStatusUseCaseProvider =
    Provider<UpdateAdminPropertyStatusUseCase>((ref) {
      final repo = ref.read(adminRepositoryProvider);
      return UpdateAdminPropertyStatusUseCase(repo);
    });

class UpdateAdminPropertyStatusUseCase {
  final AdminRepository _repo;
  UpdateAdminPropertyStatusUseCase(this._repo);

  Future<Either<Failure, void>> execute(String id, String status) {
    return _repo.updatePropertyStatus(id, status);
  }
}
