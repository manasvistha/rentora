import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<String, User>> call(String email, String password) {
    return repository.login(email, password);
  }
}
