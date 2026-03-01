import 'package:equatable/equatable.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';

class DashboardSnapshotEntity extends Equatable {
  final List<DashboardPropertyEntity> allProperties;
  final List<DashboardPropertyEntity> myProperties;
  final List<DashboardBookingEntity> myBookings;
  final List<DashboardBookingEntity> bookingRequests;

  const DashboardSnapshotEntity({
    required this.allProperties,
    required this.myProperties,
    required this.myBookings,
    required this.bookingRequests,
  });

  @override
  List<Object?> get props => [
    allProperties,
    myProperties,
    myBookings,
    bookingRequests,
  ];
}
