import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_snapshot_entity.dart';

final dashboardRemoteDataSourceProvider = Provider<IDashboardRemoteDataSource>((
  ref,
) {
  final apiClient = ref.read(apiClientProvider);
  return DashboardRemoteDataSource(apiClient.dio);
});

class DashboardRemoteDataSource implements IDashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSource(this._dio);

  @override
  Future<List<DashboardPropertyEntity>> getAllProperties() async {
    final response = await _dio.get(ApiEndpoints.propertyList);
    return _extractList(response.data).map(_mapProperty).toList();
  }

  @override
  Future<List<DashboardBookingEntity>> getBookingRequests() async {
    final response = await _dio.get(ApiEndpoints.bookingOwnerRequests);
    return _extractList(response.data).map(_mapBooking).toList();
  }

  @override
  Future<DashboardSnapshotEntity> getDashboardSnapshot() async {
    final responses = await Future.wait([
      _dio.get(ApiEndpoints.propertyList),
      _dio.get(ApiEndpoints.propertyMy),
      _dio.get(ApiEndpoints.bookingMy),
      _dio.get(ApiEndpoints.bookingOwnerRequests),
    ]);

    final all = _extractList(responses[0].data).map(_mapProperty).toList();
    final mine = _extractList(responses[1].data).map(_mapProperty).toList();
    final myBookings = _extractList(
      responses[2].data,
    ).map(_mapBooking).toList();
    final requests = _extractList(responses[3].data).map(_mapBooking).toList();

    return DashboardSnapshotEntity(
      allProperties: all,
      myProperties: mine,
      myBookings: myBookings,
      bookingRequests: requests,
    );
  }

  @override
  Future<List<DashboardBookingEntity>> getMyBookings() async {
    final response = await _dio.get(ApiEndpoints.bookingMy);
    return _extractList(response.data).map(_mapBooking).toList();
  }

  @override
  Future<List<DashboardPropertyEntity>> getMyProperties() async {
    final response = await _dio.get(ApiEndpoints.propertyMy);
    return _extractList(response.data).map(_mapProperty).toList();
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) return data;
    }
    return const [];
  }

  DashboardBookingEntity _mapBooking(dynamic raw) {
    final map = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
    final property = map['property'];

    String propertyTitle = 'Property';
    if (property is Map) {
      propertyTitle = (property['title'] ?? 'Property').toString();
    } else if (property != null) {
      propertyTitle = property.toString();
    }

    return DashboardBookingEntity(
      id: (map['_id'] ?? '').toString(),
      propertyTitle: propertyTitle,
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
    );
  }

  DashboardPropertyEntity _mapProperty(dynamic raw) {
    final map = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};

    final images = <String>[];

    void addIfValid(dynamic value) {
      if (value == null) return;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) images.add(stringValue);
    }

    final imageRaw = map['images'];
    if (imageRaw is List) {
      for (final item in imageRaw) {
        if (item is Map) {
          addIfValid(item['url'] ?? item['path'] ?? item['src']);
        } else {
          addIfValid(item);
        }
      }
    }

    for (final key in ['image', 'thumbnail', 'cover', 'photo', 'imageUrl']) {
      addIfValid(map[key]);
    }

    final seen = <String>{};
    final deduplicated = images.where((url) => seen.add(url)).toList();

    return DashboardPropertyEntity(
      id: (map['_id'] ?? '').toString(),
      title: (map['title'] ?? 'Untitled Property').toString(),
      location: (map['location'] ?? 'Unknown location').toString(),
      price: _asDouble(map['price']),
      status: (map['status'] ?? 'available').toString(),
      images: deduplicated,
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
