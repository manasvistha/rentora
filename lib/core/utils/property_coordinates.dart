import 'dart:math' as math;

class PropertyCoordinates {
  final double latitude;
  final double longitude;

  const PropertyCoordinates({required this.latitude, required this.longitude});

  Map<String, double> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  PropertyCoordinates rounded({int digits = 6}) {
    final factor = math.pow(10, digits).toDouble();
    return PropertyCoordinates(
      latitude: (latitude * factor).roundToDouble() / factor,
      longitude: (longitude * factor).roundToDouble() / factor,
    );
  }

  static PropertyCoordinates? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final latitude = _parseCoordinateValue(map['latitude'] ?? map['lat']);
    final longitude = _parseCoordinateValue(
      map['longitude'] ?? map['lon'] ?? map['lng'],
    );

    if (latitude == null || longitude == null) return null;
    final coordinates = PropertyCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
    return isValidCoordinates(coordinates) ? coordinates : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyCoordinates &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

bool isValidCoordinates(PropertyCoordinates? coordinates) {
  if (coordinates == null) return false;
  return coordinates.latitude >= -90 &&
      coordinates.latitude <= 90 &&
      coordinates.longitude >= -180 &&
      coordinates.longitude <= 180;
}

PropertyCoordinates? parsePropertyCoordinates(Map<String, dynamic>? map) {
  if (map == null) return null;

  final nested = PropertyCoordinates.fromMap(map['coordinates']);
  if (nested != null) return nested;

  return PropertyCoordinates.fromMap({
    'latitude': map['latitude'] ?? map['lat'],
    'longitude': map['longitude'] ?? map['lon'] ?? map['lng'],
  });
}

String formatCoordinates(PropertyCoordinates coordinates, {int digits = 6}) {
  final rounded = coordinates.rounded(digits: digits);
  return '${rounded.latitude.toStringAsFixed(digits)}, ${rounded.longitude.toStringAsFixed(digits)}';
}

double distanceInKilometers(PropertyCoordinates from, PropertyCoordinates to) {
  const earthRadiusKm = 6371.0;
  final deltaLat = _degreesToRadians(to.latitude - from.latitude);
  final deltaLon = _degreesToRadians(to.longitude - from.longitude);

  final fromLat = _degreesToRadians(from.latitude);
  final toLat = _degreesToRadians(to.latitude);

  final a =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(fromLat) *
          math.cos(toLat) *
          math.sin(deltaLon / 2) *
          math.sin(deltaLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c;
}

double? _parseCoordinateValue(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return double.tryParse(raw.toString());
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;
