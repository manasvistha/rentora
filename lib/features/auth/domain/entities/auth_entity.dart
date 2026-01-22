import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? password; 

  const AuthEntity({
    required this.id,
    required this.email,
    required this.name,
    this.password,
  });

  @override
  List<Object?> get props => [id, email, name];
}
