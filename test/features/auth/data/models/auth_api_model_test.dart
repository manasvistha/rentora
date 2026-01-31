import 'package:flutter_test/flutter_test.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/data/models/auth_api_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';

void main() {
  group('AuthApiModel', () {
    final json = {
      '_id': '123',
      'name': 'Test User',
      'email': 'test@example.com',
      'password': '123456',
      'token': 'abcd1234',
      'image': 'profile.png',
    };

    test('fromJson should create correct AuthApiModel', () {
      final model = AuthApiModel.fromJson(json);

      expect(model.id, '123');
      expect(model.name, 'Test User');
      expect(model.email, 'test@example.com');
      expect(model.password, '123456');
      expect(model.token, 'abcd1234');
      expect(model.profilePicture, 'profile.png');
    });

    test('toEntity should convert AuthApiModel to AuthEntity', () {
      final model = AuthApiModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity, isA<AuthEntity>());
      expect(entity.id, '123');
      expect(entity.name, 'Test User');
      expect(entity.email, 'test@example.com');
      expect(entity.password, '123456');
      expect(entity.profilePicture, 'profile.png');
    });
  });
}
