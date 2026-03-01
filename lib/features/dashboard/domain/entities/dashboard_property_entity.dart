import 'package:equatable/equatable.dart';
import 'package:rentora/core/api/api_endpoints.dart';

class DashboardPropertyEntity extends Equatable {
  final String id;
  final String title;
  final String location;
  final double price;
  final String status;
  final List<String> images;

  const DashboardPropertyEntity({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.status,
    required this.images,
  });

  String get imageUrl {
    if (images.isEmpty) return '';
    return _toAbsoluteImageUrl(images.first);
  }

  static String _toAbsoluteImageUrl(String raw) {
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

  @override
  List<Object?> get props => [id, title, location, price, status, images];
}
