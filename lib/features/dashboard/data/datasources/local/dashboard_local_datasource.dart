import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';

final dashboardLocalDataSourceProvider = Provider<IDashboardLocalDataSource>((
  ref,
) {
  return DashboardLocalDataSource();
});

class DashboardLocalDataSource implements IDashboardLocalDataSource {
  List<DashboardPropertyEntity> _allProperties = const [];
  List<DashboardPropertyEntity> _myProperties = const [];
  List<DashboardBookingEntity> _myBookings = const [];
  List<DashboardBookingEntity> _bookingRequests = const [];

  @override
  void cacheAllProperties(List<DashboardPropertyEntity> properties) {
    _allProperties = List.unmodifiable(properties);
  }

  @override
  void cacheBookingRequests(List<DashboardBookingEntity> bookings) {
    _bookingRequests = List.unmodifiable(bookings);
  }

  @override
  void cacheDashboardSnapshot(DashboardSnapshotEntity snapshot) {
    cacheAllProperties(snapshot.allProperties);
    cacheMyProperties(snapshot.myProperties);
    cacheMyBookings(snapshot.myBookings);
    cacheBookingRequests(snapshot.bookingRequests);
  }

  @override
  void cacheMyBookings(List<DashboardBookingEntity> bookings) {
    _myBookings = List.unmodifiable(bookings);
  }

  @override
  void cacheMyProperties(List<DashboardPropertyEntity> properties) {
    _myProperties = List.unmodifiable(properties);
  }

  @override
  List<DashboardPropertyEntity> getCachedAllProperties() => _allProperties;

  @override
  List<DashboardBookingEntity> getCachedBookingRequests() => _bookingRequests;

  @override
  DashboardSnapshotEntity getCachedDashboardSnapshot() {
    return DashboardSnapshotEntity(
      allProperties: _allProperties,
      myProperties: _myProperties,
      myBookings: _myBookings,
      bookingRequests: _bookingRequests,
    );
  }

  @override
  List<DashboardBookingEntity> getCachedMyBookings() => _myBookings;

  @override
  List<DashboardPropertyEntity> getCachedMyProperties() => _myProperties;
}
