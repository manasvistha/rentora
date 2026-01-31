import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String name;
  final String email;
  final String? password;
  final String? token;
  final String? profilePicture;

  AuthApiModel({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.token,
    this.profilePicture,
  });

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      token: json['token'],
      profilePicture: json['profilePicture'] ?? json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profilePicture': profilePicture,
    };
  }

  AuthEntity toEntity() {
    return AuthEntity(
      id: id ?? '',
      name: name,
      email: email,
      password: password ?? '',
      profilePicture: profilePicture,
    );
  }

  factory AuthApiModel.fromEntity(AuthEntity user) {
    return AuthApiModel(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
      profilePicture: user.profilePicture,
    );
  }

  AuthHiveModel toHiveModel() {
    return AuthHiveModel(
      id: id ?? '',
      name: name,
      email: email,
      password: password ?? '',
      profilePicture: profilePicture,
    );
  }

  static List<AuthEntity> toEntityList(List<AuthApiModel> apiModels) {
    return apiModels.map((model) => model.toEntity()).toList();
  }
}
