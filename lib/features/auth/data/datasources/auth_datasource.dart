import 'dart:io';

import 'package:rentora/features/auth/data/models/auth_api_model.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthLocalDataSource {
  Future<AuthHiveModel> register(AuthHiveModel user);
  Future<AuthHiveModel?> login(String email, String password);
  Future<AuthHiveModel?> getCurrentUser();
  Future<bool> logOut();
  Future<AuthHiveModel?> getUserById(String authId);
  Future<AuthHiveModel?> getUserByEmail(String email);
  Future<bool> updateUser(AuthHiveModel user);
  Future<bool> deleteUser(String authId);
}

abstract interface class IAuthRemoteDataSource {
  Future<AuthApiModel> register(
    AuthApiModel user, {
    String? roleName,
    String? confirmPassword,
  });
  Future<AuthApiModel?> login(String email, String password);
  Future<AuthApiModel?> getCurrentUser();
  Future<bool> logOut();
  Future<String> uploadPhoto(File photo);
  Future<AuthApiModel?> getUserById(String authId);
  Future<AuthApiModel?> getUserByEmail(String email);
  Future<bool> updateUser(AuthApiModel user);
  Future<bool> deleteUser(String authId);
}
