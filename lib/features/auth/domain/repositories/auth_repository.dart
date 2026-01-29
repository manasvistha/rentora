import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, bool>> signup(
    AuthEntity user, {
    File? profileImage,
    String? confirmPassword,
  }); // UPDATED

  Future<Either<Failure, AuthEntity>> login(String email, String password);

  Future<Either<Failure, AuthEntity?>> getCurrentUser();
  Future<Either<Failure, bool>> uploadPhoto(File photo);

  Future<Either<Failure, bool>> logout();
}
