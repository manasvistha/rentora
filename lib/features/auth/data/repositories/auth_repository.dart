import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/core/services/connectivity/network_info.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import 'package:rentora/features/auth/data/datasources/auth_datasource.dart';
import 'package:rentora/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:rentora/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:rentora/features/auth/data/models/auth_api_model.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authLocalDataSource = ref.read(authLocalDataSourceProvider);
  final authRemoteDataSource = ref.read(authRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  final sessionService = ref.read(userSessionServiceProvider);

  return AuthRepository(
    authLocalDataSource: authLocalDataSource,
    authRemoteDataSource: authRemoteDataSource,
    networkInfo: networkInfo,
    sessionService: sessionService,
  );
});

class AuthRepository implements IAuthRepository {
  final IAuthLocalDataSource _authLocalDataSource;
  final IAuthRemoteDataSource _authRemoteDataSource;
  final NetworkInfo _networkInfo;
  final UserSessionService _sessionService;

  AuthRepository({
    required IAuthLocalDataSource authLocalDataSource,
    required IAuthRemoteDataSource authRemoteDataSource,
    required NetworkInfo networkInfo,
    required UserSessionService sessionService,
  }) : _authLocalDataSource = authLocalDataSource,
       _authRemoteDataSource = authRemoteDataSource,
       _networkInfo = networkInfo,
       _sessionService = sessionService;

  @override
  Future<Either<Failure, bool>> signup(
    AuthEntity user, {
    File? profileImage,
    String? confirmPassword,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(user);
        await _authRemoteDataSource.register(
          apiModel,
          confirmPassword: confirmPassword,
        );
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
          profilePicture: apiModel.profilePicture, // NEW FIELD
        );
        await _authLocalDataSource.register(authHiveModel);

        // Save token to session service
        if (apiModel.token != null && apiModel.token!.isNotEmpty) {
          await _sessionService.saveUserSession(
            userId: apiModel.id ?? '',
            email: apiModel.email,
            name: apiModel.name,
            token: apiModel.token!,
          );
        }

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
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = await _authRemoteDataSource.getCurrentUser();
        if (apiModel != null) {
          // Store in local database for offline access
          final hiveModel = apiModel.toHiveModel();
          await _authLocalDataSource.register(hiveModel);
          return Right(apiModel.toEntity());
        }
        return const Right(null);
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message:
                e.response?.data['message'] ?? 'Failed to get current user',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
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
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await _authLocalDataSource.logOut();
      return const Right(true);
    } catch (e) {
      return Left(
        LocalDatabaseFailure(message: "Logout failed: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> uploadPhoto(File photo) async {
    if (await _networkInfo.isConnected) {
      try {
        await _authRemoteDataSource.uploadPhoto(photo);
        return const Right(true);
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message: e.response?.data['message'] ?? 'Photo upload failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return const Left(
        LocalDatabaseFailure(message: "No internet connection"),
      );
    }
  }
}
