import 'package:hive/hive.dart';
import 'package:rentora/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String password;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      password: user.password ?? '',
    );
  }

  User toEntity() {
    return User(id: id, email: email, name: name, password: password);
  }
}
