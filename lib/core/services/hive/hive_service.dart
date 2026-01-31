import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rentora/core/constants/table_constant.dart'; // Ensure filename matches
import 'package:rentora/features/auth/data/models/auth_hive_model.dart'; // Strict 4-field model

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);

    _registerAdapter();
    await _openBoxes();
  }

  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.userTable);
  }

  Box<AuthHiveModel> get _userBox =>
      Hive.box<AuthHiveModel>(HiveTableConstant.userTable);

  Future<void> register(AuthHiveModel user) async {
    await _userBox.put(user.id, user);
  }

  AuthHiveModel? login(String email, String password) {
    try {
      return _userBox.values.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  AuthHiveModel? getUserById(String id) {
    return _userBox.get(id);
  }

  bool isEmailRegistered(String email) {
    return _userBox.values.any((user) => user.email == email);
  }

  Future<AuthHiveModel?> getUserByEmail(String email) async {
    try {
      return _userBox.values.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(AuthHiveModel user) async {
    if (_userBox.containsKey(user.id)) {
      await _userBox.put(user.id, user);
      return true;
    }
    return false;
  }

  Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }

  Future<void> clearAll() async {
    await _userBox.clear();
  }
}
