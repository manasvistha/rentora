import 'package:equatable/equatable.dart';

class DashboardBookingEntity extends Equatable {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyLocation;
  final double propertyPrice;
  final String propertyImageUrl;
  final String requesterName;
  final String requesterEmail;
  final String status;
  final DateTime? createdAt;

  const DashboardBookingEntity({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyLocation,
    required this.propertyPrice,
    required this.propertyImageUrl,
    required this.requesterName,
    required this.requesterEmail,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    propertyId,
    propertyTitle,
    propertyLocation,
    propertyPrice,
    propertyImageUrl,
    requesterName,
    requesterEmail,
    status,
    createdAt,
  ];
}
