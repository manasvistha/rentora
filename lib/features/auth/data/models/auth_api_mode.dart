import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String name;
  final String email;
  final String? password;
  final String? token; // APIs usually return a JWT token on login/signup

  AuthApiModel({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.token,
  });

  // Convert JSON from API to this Model
  // Handles both standard 'id' and MongoDB '_id'
  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      token: json['token'],
    );
  }

  // Convert Model to JSON to send to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      // token is usually not sent back to API in the body
    };
  }

  // To Entity: Convert this API model to a Domain Entity
  AuthEntity toEntity() {
    return AuthEntity(
      id: id ?? '',
      name: name,
      email: email,
      password: password ?? '',
    );
  }

  //from entity
  factory AuthApiModel.fromEntity(AuthEntity user) {
    return AuthApiModel(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
    );
  }

  // To Hive Model: Convert this API model to your Persistence Model
  AuthHiveModel toHiveModel() {
    return AuthHiveModel(
      id: id ?? '',
      name: name,
      email: email,
      password: password ?? '',
    );
  }

  //toentitylist
  static List<AuthEntity> toEntityList(List<AuthApiModel> apiModels) {
    return apiModels.map((model) => model.toEntity()).toList();
  }
}
