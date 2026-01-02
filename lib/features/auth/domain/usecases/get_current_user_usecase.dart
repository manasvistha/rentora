import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

@injectable
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<String, User?>> call() {
    return repository.getCurrentUser();
  }
}
