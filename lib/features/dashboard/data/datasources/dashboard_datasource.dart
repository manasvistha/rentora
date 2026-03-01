import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';

abstract interface class IDashboardRemoteDataSource {
  Future<List<DashboardPropertyEntity>> getAllProperties();
  Future<List<DashboardPropertyEntity>> getMyProperties();
  Future<List<DashboardBookingEntity>> getMyBookings();
  Future<List<DashboardBookingEntity>> getBookingRequests();
  Future<DashboardSnapshotEntity> getDashboardSnapshot();
}

abstract interface class IDashboardLocalDataSource {
  List<DashboardPropertyEntity> getCachedAllProperties();
  List<DashboardPropertyEntity> getCachedMyProperties();
  List<DashboardBookingEntity> getCachedMyBookings();
  List<DashboardBookingEntity> getCachedBookingRequests();

  void cacheAllProperties(List<DashboardPropertyEntity> properties);
  void cacheMyProperties(List<DashboardPropertyEntity> properties);
  void cacheMyBookings(List<DashboardBookingEntity> bookings);
  void cacheBookingRequests(List<DashboardBookingEntity> bookings);

  DashboardSnapshotEntity getCachedDashboardSnapshot();
  void cacheDashboardSnapshot(DashboardSnapshotEntity snapshot);
}
