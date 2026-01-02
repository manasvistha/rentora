import 'package:dartz/dartz.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<String, User>> login(String email, String password);
  Future<Either<String, User>> signup(
    String email,
    String password,
    String name,
  );
  Future<Either<String, void>> logout();
  Future<Either<String, User?>> getCurrentUser();
}
