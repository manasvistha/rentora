import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? password;
  final String? profilePicture;

  const AuthEntity({
    required this.id,
    required this.email,
    required this.name,
    this.password,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [id, email, name, profilePicture];
}
