import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<String, void>> call() {
    return repository.logout();
  }
}
