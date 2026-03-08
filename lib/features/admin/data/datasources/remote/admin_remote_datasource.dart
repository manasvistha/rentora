import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/core/api/api_client.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminRemoteDataSource(dio);
});

class AdminRemoteDataSource {
  final Dio _dio;
  AdminRemoteDataSource(this._dio);

  static const String _adminUsers = 'admin/users';
  static const String _adminProperties = 'admin/properties';
  static const String _adminBookings = 'admin/bookings';

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  int _extractCount(dynamic data) {
    if (data is List) return data.length;
    if (data is! Map) return 0;

    final map = data.cast<String, dynamic>();

    // Prefer explicit totals from paginated/admin responses.
    final totalCandidates = [
      map['total'],
      map['count'],
      map['totalCount'],
      map['totalUsers'],
      map['totalProperties'],
      map['totalBookings'],
      (map['meta'] is Map) ? (map['meta'] as Map)['total'] : null,
      (map['pagination'] is Map) ? (map['pagination'] as Map)['total'] : null,
    ];

    for (final candidate in totalCandidates) {
      final parsed = _asInt(candidate);
      if (parsed >= 0) return parsed;
    }

    if (map['data'] is List) return (map['data'] as List).length;
    if (map['items'] is List) return (map['items'] as List).length;
    return 0;
  }

  Future<int> getUsersCount() async {
    final res = await _dio.get(_adminUsers);
    return _extractCount(res.data);
  }

  Future<int> getPropertiesCount() async {
    final res = await _dio.get(_adminProperties);
    return _extractCount(res.data);
  }

  Future<int> getBookingsCount() async {
    final res = await _dio.get(_adminBookings);
    return _extractCount(res.data);
  }

  Future<List<dynamic>> getBookings() async {
    final res = await _dio.get(_adminBookings);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['bookings'] is List) {
      return data['bookings'] as List;
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10}) async {
    final res = await _dio.get(
      _adminUsers,
      queryParameters: {'page': page, 'limit': limit},
    );
    return (res.data is Map<String, dynamic>)
        ? (res.data as Map<String, dynamic>)
        : <String, dynamic>{'data': <dynamic>[]};
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('$_adminUsers/$id');
  }

  Future<void> promoteUser(String id) async {
    await _dio.post('$_adminUsers/$id/promote');
  }

  Future<List<dynamic>> getProperties() async {
    final res = await _dio.get(_adminProperties);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return <dynamic>[];
  }

  Future<void> updatePropertyStatus(String id, String status) async {
    await _dio.put('$_adminProperties/$id/status', data: {'status': status});
  }

  Future<void> deleteProperty(String id) async {
    await _dio.delete('$_adminProperties/$id');
  }
}
