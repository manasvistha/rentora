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
  Future<void> createBookingRequest(String propertyId) async {
    await _dio.post(
      ApiEndpoints.bookingCreate,
      data: {'propertyId': propertyId},
    );
  }

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
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _dio.put(
      ApiEndpoints.bookingUpdateStatus(bookingId),
      data: {'status': status},
    );
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
    final user = map['user'];

    String propertyTitle = 'Property';
    String propertyId = '';
    String propertyLocation = 'Unknown location';
    double propertyPrice = 0;
    String propertyImageUrl = '';

    void addBookingImageIfValid(dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || propertyImageUrl.isNotEmpty) return;
      propertyImageUrl = _toAbsoluteImageUrl(text);
    }

    if (property is Map) {
      propertyTitle = (property['title'] ?? 'Property').toString();
      propertyId = (property['_id'] ?? property['id'] ?? '').toString();
      propertyLocation = (property['location'] ?? 'Unknown location')
          .toString();
      propertyPrice = _asDouble(property['price']);

      final rawImages = property['images'];
      if (rawImages is List) {
        for (final image in rawImages) {
          if (image is Map) {
            addBookingImageIfValid(
              image['url'] ?? image['path'] ?? image['src'],
            );
          } else {
            addBookingImageIfValid(image);
          }
        }
      }

      for (final key in ['image', 'thumbnail', 'cover', 'photo', 'imageUrl']) {
        addBookingImageIfValid(property[key]);
      }
    } else if (property != null) {
      propertyTitle = property.toString();
      propertyId = property.toString();
    }

    String requesterName = '';
    String requesterEmail = '';
    if (user is Map) {
      requesterName = (user['name'] ?? '').toString();
      requesterEmail = (user['email'] ?? '').toString();
    }

    return DashboardBookingEntity(
      id: (map['_id'] ?? '').toString(),
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertyLocation: propertyLocation,
      propertyPrice: propertyPrice,
      propertyImageUrl: propertyImageUrl,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
    );
  }

  String _toAbsoluteImageUrl(String raw) {
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return raw;

      const localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
      if (!localHosts.contains(uri.host)) return raw;

      final apiUri = Uri.parse(ApiEndpoints.baseUrl);
      return uri.replace(host: apiUri.host, port: apiUri.port).toString();
    }

    final apiUri = Uri.parse(ApiEndpoints.baseUrl);
    final basePath = apiUri.path.endsWith('/api/') ? '/api/' : apiUri.path;
    final hostPath = basePath.endsWith('/api/')
        ? basePath.substring(0, basePath.length - 5)
        : basePath;
    final sanitized = raw.startsWith('/') ? raw : '/$raw';

    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: '$hostPath$sanitized',
    ).toString();
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
