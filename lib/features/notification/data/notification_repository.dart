import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return NotificationRepository(dio);
});

class NotificationItem {
  final String id;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? message,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      relatedId: json['relatedId']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: _parseDate(createdAtRaw),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notificationList,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = response.data;
    final entries = _extractList(raw);
    return entries.map(NotificationItem.fromJson).toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.put(ApiEndpoints.notificationMarkRead(id));
  }

  Future<void> markAllRead() async {
    await _dio.put(ApiEndpoints.notificationMarkAllRead);
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    final Map<String, dynamic>? dataMap = _asMap(payload);
    final segments = <dynamic>[
      payload,
      dataMap?['data'],
      dataMap?['notifications'],
      dataMap?['items'],
      _asMap(dataMap?['data'])?['data'],
      _asMap(dataMap?['data'])?['notifications'],
    ];
    for (final segment in segments) {
      if (segment is List) {
        final parsed = segment
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }
}
