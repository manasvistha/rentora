import 'package:rentora/core/services/hive/hive_service.dart';
import 'package:rentora/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getUser(String email);
  Future<void> saveUser(UserModel user);
  Future<void> deleteUser(String email);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveService hiveService;

  AuthLocalDataSourceImpl(this.hiveService);

  @override
  Future<UserModel?> getUser(String email) async {
    return hiveService.users.get(email);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await hiveService.users.put(user.email, user);
  }

  @override
  Future<void> deleteUser(String email) async {
    await hiveService.users.delete(email);
  }
}
