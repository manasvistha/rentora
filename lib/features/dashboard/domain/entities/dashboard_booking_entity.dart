import 'package:equatable/equatable.dart';

class DashboardBookingEntity extends Equatable {
  final String id;
  final String propertyTitle;
  final String status;
  final DateTime? createdAt;

  const DashboardBookingEntity({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, propertyTitle, status, createdAt];
}
