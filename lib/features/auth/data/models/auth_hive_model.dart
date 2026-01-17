import 'package:hive/hive.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';

part 'auth_hive_model.g.dart';

@HiveType(typeId: 0)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String password;

  AuthHiveModel({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
  });

  factory AuthHiveModel.fromEntity(AuthEntity user) {
    return AuthHiveModel(
      id: user.id,
      email: user.email,
      name: user.name,
      password: user.password ?? '',
    );
  }

  factory AuthHiveModel.fromJson(Map<String, dynamic> json) {
    return AuthHiveModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'password': password};
  }

  AuthEntity toEntity() {
    return AuthEntity(id: id, email: email, name: name, password: password);
  }
}
