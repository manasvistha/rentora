import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rentora/core/constants/table_constant.dart';
import 'package:rentora/core/services/hive/hive_service.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';

void main() {
  late HiveService hiveService;
  late String testPath;

  setUp(() async {
    testPath = Directory.systemTemp.createTempSync().path;
    Hive.init(testPath);

    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }

    await Hive.openBox<AuthHiveModel>(HiveTableConstant.userTable);
    hiveService = HiveService();
  });

  tearDown(() async {
    await Hive.close();
    Directory(testPath).deleteSync(recursive: true);
  });

  test('should save user to hive and retrieve it by id', () async {
    final user = AuthHiveModel(
      id: '1',
      email: 'test@example.com',
      password: '123456',
      name: 'Test User',
    );

    await hiveService.register(user);
    final result = hiveService.getUserById('1');

    expect(result, isNotNull);
    expect(result!.id, '1');
    expect(result.email, 'test@example.com');
    expect(result.name, 'Test User');
  });

  test('should return true if email is already registered', () async {
    final user = AuthHiveModel(
      id: '2',
      email: 'email@test.com',
      password: '123456',
      name: 'Email User',
    );

    await hiveService.register(user);

    final result = hiveService.isEmailRegistered('email@test.com');

    expect(result, true);
  });

  test('should return null when login credentials are invalid', () async {
    final user = AuthHiveModel(
      id: '1',
      email: 'user@test.com',
      password: 'correct123',
      name: 'Wrong Login',
    );

    await hiveService.register(user);

    final result = hiveService.login('user@test.com', 'wrong123');

    expect(result, isNull);
  });
}
