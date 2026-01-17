import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/core/services/connectivity/network_info.dart';
import 'package:rentora/features/auth/data/datasources/auth_datasource.dart';
import 'package:rentora/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:rentora/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:rentora/features/auth/data/models/auth_api_model.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authLocalDataSource = ref.read(authLocalDataSourceProvider);
  final authRemoteDataSource = ref.read(authRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return AuthRepository(
    authLocalDataSource: authLocalDataSource,
    authRemoteDataSource: authRemoteDataSource,
    networkInfo: networkInfo,
  );
});

class AuthRepository implements IAuthRepository {
  final IAuthLocalDataSource _authLocalDataSource;
  final IAuthRemoteDataSource _authRemoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepository({
    required IAuthLocalDataSource authLocalDataSource,
    required IAuthRemoteDataSource authRemoteDataSource,
    required NetworkInfo networkInfo,
  }) : _authLocalDataSource = authLocalDataSource,
       _authRemoteDataSource = authRemoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, bool>> signup(AuthEntity user) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(user);
        await _authRemoteDataSource.register(apiModel);
        return const Right(true);
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message: e.response?.data['message'] ?? 'Registration failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      try {
        final existingUser = await _authLocalDataSource.getUserByEmail(
          user.email,
        );
        if (existingUser != null) {
          return const Left(
            LocalDatabaseFailure(message: "User already exists locally"),
          );
        }
        final hiveModel = AuthHiveModel.fromEntity(user);
        await _authLocalDataSource.register(hiveModel);
        return const Right(true);
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = await _authRemoteDataSource.login(email, password);

        final authHiveModel = AuthHiveModel(
          id: apiModel!.id ?? '',
          name: apiModel.name,
          email: apiModel.email,
          password: password,
        );
        await _authLocalDataSource.register(authHiveModel);

        return Right(authHiveModel.toEntity());
      } on DioException catch (e) {
        return Left(
          ApiFailure(message: e.response?.data['message'] ?? "Login failed"),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      try {
        final model = await _authLocalDataSource.getUserByEmail(email);
        if (model != null && model.password == password) {
          return Right(model.toEntity());
        }
        return const Left(
          LocalDatabaseFailure(
            message: "Offline login failed. Check credentials.",
          ),
        );
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity?>> getCurrentUser() async {
    try {
      final model = await _authLocalDataSource.getCurrentUser();
      if (model != null) {
        return Right(model.toEntity());
      }
      return const Left(LocalDatabaseFailure(message: "No active session"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await _authLocalDataSource.logout();
      return const Right(true);
    } catch (e) {
      return Left(
        LocalDatabaseFailure(message: "Logout failed: ${e.toString()}"),
      );
    }
  }
}
