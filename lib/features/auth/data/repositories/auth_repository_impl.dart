import 'package:dartz/dartz.dart';
import 'package:rentora/core/services/hive/hive_service.dart';
import 'package:rentora/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:rentora/features/auth/data/models/user_model.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final HiveService hiveService;

  AuthRepositoryImpl(this.localDataSource, this.hiveService);

  @override
  Future<Either<String, User>> login(String email, String password) async {
    try {
      final userModel = await localDataSource.getUser(email);

      if (userModel != null && userModel.password == password) {
        await hiveService.session.put('currentUser', email);
        return Right(userModel.toEntity());
      }

      return const Left('Invalid email or password');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, User>> signup(
    String email,
    String password,
    String name,
  ) async {
    final existing = await localDataSource.getUser(email);
    if (existing != null) {
      return const Left('User already exists');
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      password: password,
    );

    await localDataSource.saveUser(user);
    await hiveService.session.put('currentUser', email);

    return Right(user.toEntity());
  }

  @override
  Future<Either<String, void>> logout() async {
    await hiveService.session.delete('currentUser');
    return const Right(null);
  }

  @override
  Future<Either<String, User?>> getCurrentUser() async {
    final email = hiveService.session.get('currentUser');
    if (email == null) return const Right(null);

    final user = await localDataSource.getUser(email);
    return Right(user?.toEntity());
  }
}
