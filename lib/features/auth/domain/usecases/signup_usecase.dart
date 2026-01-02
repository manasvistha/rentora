import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignupUseCase {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  Future<Either<String, User>> call(
    String email,
    String password,
    String name,
  ) {
    return repository.signup(email, password, name);
  }
}
