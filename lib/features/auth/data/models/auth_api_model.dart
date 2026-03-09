import 'package:rentora/features/auth/data/models/auth_hive_model.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';

class AuthApiModel {
  final String? id;
  final String name;
  final String email;
  final String? password;
  final String? token;
  final String? profilePicture;
  final String? role;

  AuthApiModel({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.token,
    this.profilePicture,
    this.role,
  });

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      token: json['token'],
      profilePicture: json['profilePicture'] ?? json['image'],
      role: UserSessionService.normalizeRole(
        json['role'] ??
            (json['roles'] is List && json['roles'].isNotEmpty
                ? json['roles'][0]
                : json['roles']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name, 'email': email};

    if (id != null && id!.isNotEmpty) {
      json['id'] = id;
    }
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      json['profilePicture'] = profilePicture;
    }

    return json;
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
