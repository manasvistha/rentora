import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rentora/core/utils/property_coordinates.dart';

class LocationPickerCard extends StatefulWidget {
  final TextEditingController locationController;
  final PropertyCoordinates? coordinates;
  final ValueChanged<PropertyCoordinates?> onCoordinatesChanged;

  const LocationPickerCard({
    super.key,
    required this.locationController,
    required this.coordinates,
    required this.onCoordinatesChanged,
  });

  @override
  State<LocationPickerCard> createState() => _LocationPickerCardState();
}

class _LocationPickerCardState extends State<LocationPickerCard> {
  static const _defaultCenter = LatLng(27.7172, 85.3240);
  static const _defaultZoom = 13.0;

  final MapController _mapController = MapController();
  final Dio _nominatimClient = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'RentoraMobile/1.0 (app)',
      },
    ),
  );

  bool _searching = false;
  bool _locating = false;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.coordinates;
      if (initial != null) {
        _moveTo(initial, zoom: 15);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LocationPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.coordinates;
    if (current != null && current != oldWidget.coordinates) {
      _moveTo(current, zoom: 15);
    }
  }

  Future<void> _setPin(
    PropertyCoordinates coordinates, {
    bool resolveAddress = true,
  }) async {
    final pin = coordinates.rounded();
    if (!isValidCoordinates(pin)) {
      setState(() => _error = 'Selected coordinates are invalid.');
      return;
    }

    setState(() => _error = null);
    widget.onCoordinatesChanged(pin);
    _moveTo(pin, zoom: 15);

    if (resolveAddress) {
      await _reverseLookup(pin);
    }
  }

  Future<void> _searchAndPin() async {
    final query = widget.locationController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a location first.');
      return;
    }

    setState(() {
      _error = null;
      _searching = true;
    });

    try {
      final response = await _nominatimClient.get(
        '/search',
        queryParameters: {'format': 'jsonv2', 'q': query, 'limit': 1},
      );

      final data = response.data;
      if (data is! List || data.isEmpty) {
        setState(() => _error = 'No matching location found.');
        return;
      }

      final first = data.first;
      final pin = PropertyCoordinates.fromMap({
        'latitude': first['lat'],
        'longitude': first['lon'],
      });
      if (pin == null) {
        setState(
          () => _error = 'Search result does not contain valid coordinates.',
        );
        return;
      }

      final displayName = first['display_name']?.toString();
      if (displayName != null && displayName.trim().isNotEmpty) {
        widget.locationController.text = displayName.trim();
      }

      await _setPin(pin, resolveAddress: false);
    } catch (_) {
      setState(() => _error = 'Unable to search OpenStreetMap right now.');
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _error = null;
      _locating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location service on your device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to use this feature.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      await _setPin(
        PropertyCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to fetch current location.';
      });
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _reverseLookup(PropertyCoordinates pin) async {
    setState(() => _resolving = true);
    try {
      final response = await _nominatimClient.get(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': pin.latitude,
          'lon': pin.longitude,
        },
      );

      final data = response.data;
      final displayName = data is Map ? data['display_name']?.toString() : null;
      if (displayName != null && displayName.trim().isNotEmpty) {
        widget.locationController.text = displayName.trim();
      }
    } catch (_) {
      // Keep manual text if reverse lookup fails.
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  void _moveTo(PropertyCoordinates coordinates, {double? zoom}) {
    _mapController.move(
      LatLng(coordinates.latitude, coordinates.longitude),
      zoom ?? _defaultZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.coordinates;
    final center = pin != null
        ? LatLng(pin.latitude, pin.longitude)
        : _defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pin Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF103033),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location_outlined, size: 18),
                label: Text(_locating ? 'Locating...' : 'Use My Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F9E9A),
                  side: const BorderSide(color: Color(0xFF2F9E9A)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _searching ? null : _searchAndPin,
                icon: const Icon(Icons.search, size: 18),
                label: Text(_searching ? 'Searching...' : 'Search & Pin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F9E9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE5E3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _defaultZoom,
              onTap: (_, point) => _setPin(
                PropertyCoordinates(
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rentora.app',
              ),
              if (pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 40,
                      height: 40,
                      child: const _MapMarker(
                        icon: Icons.home_rounded,
                        color: Color(0xFFE03131),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 16,
              color: Color(0xFF5E7A7E),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pin != null
                    ? 'Pinned: ${formatCoordinates(pin)}'
                    : 'No location pinned yet. Tap the map to drop a pin.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5E7A7E)),
              ),
            ),
            if (pin != null)
              TextButton(
                onPressed: () => widget.onCoordinatesChanged(null),
                child: const Text('Clear'),
              ),
          ],
        ),
        if (_resolving)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Resolving selected address...',
              style: TextStyle(fontSize: 12, color: Color(0xFF5E7A7E)),
            ),
          ),
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD5D5)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B2C2C),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
