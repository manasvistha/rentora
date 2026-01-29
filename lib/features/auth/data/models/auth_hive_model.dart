import 'package:hive_flutter/hive_flutter.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:uuid/uuid.dart';

part 'auth_hive_model.g.dart';

@HiveType(typeId: 0)
class AuthHiveModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String? profilePicture; // NEW FIELD

  AuthHiveModel({
    String? id,
    required this.name,
    required this.email,
    required this.password,
    this.profilePicture, // NEW FIELD
  }) : id = id ?? const Uuid().v4();

  factory AuthHiveModel.fromEntity(AuthEntity entity) {
    return AuthHiveModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      password: entity.password ?? '',
      profilePicture: entity.profilePicture, // NEW FIELD
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(
      id: id,
      name: name,
      email: email,
      password: password,
      profilePicture: profilePicture, // NEW FIELD
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profilePicture': profilePicture, // NEW FIELD
    };
  }

  factory AuthHiveModel.fromJson(Map<String, dynamic> json) {
    return AuthHiveModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      profilePicture: json['profilePicture'], // NEW FIELD
    );
  }
}
