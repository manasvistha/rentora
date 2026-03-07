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

  Future<int> getUsersCount() async {
    final res = await _dio.get(_adminUsers);
    final data = res.data;
    if (data is List) return data.length;
    if (data is Map && data['data'] is List)
      return (data['data'] as List).length;
    if (data is Map && data['total'] is int) return data['total'] as int;
    return 0;
  }

  Future<int> getPropertiesCount() async {
    final res = await _dio.get(_adminProperties);
    final data = res.data;
    if (data is List) return data.length;
    if (data is Map && data['data'] is List)
      return (data['data'] as List).length;
    return 0;
  }

  Future<int> getBookingsCount() async {
    final res = await _dio.get(_adminBookings);
    final data = res.data;
    if (data is List) return data.length;
    if (data is Map && data['data'] is List)
      return (data['data'] as List).length;
    return 0;
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
