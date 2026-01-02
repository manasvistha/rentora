import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rentora/features/auth/data/models/user_model.dart';

@singleton
class HiveService {
  static const String userBox = 'userBox';
  static const String sessionBox = 'sessionBox';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());

    // ✅ OPEN BOXES ONCE
    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<String>(sessionBox);
  }

  Box<UserModel> get users => Hive.box<UserModel>(userBox);
  Box<String> get session => Hive.box<String>(sessionBox);
}
