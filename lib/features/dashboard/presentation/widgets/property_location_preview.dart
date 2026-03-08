import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rentora/core/utils/property_coordinates.dart';

class PropertyLocationPreview extends StatefulWidget {
  final PropertyCoordinates propertyCoordinates;
  final PropertyCoordinates? userCoordinates;
  final bool locatingUser;
  final String? locationError;
  final VoidCallback onLocateUser;

  const PropertyLocationPreview({
    super.key,
    required this.propertyCoordinates,
    required this.userCoordinates,
    required this.locatingUser,
    required this.locationError,
    required this.onLocateUser,
  });

  @override
  State<PropertyLocationPreview> createState() =>
      _PropertyLocationPreviewState();
}

class _PropertyLocationPreviewState extends State<PropertyLocationPreview> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera());
  }

  @override
  void didUpdateWidget(covariant PropertyLocationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyCoordinates != widget.propertyCoordinates ||
        oldWidget.userCoordinates != widget.userCoordinates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera());
    }
  }

  void _syncCamera() {
    final property = widget.propertyCoordinates;
    final user = widget.userCoordinates;

    if (user == null) {
      _mapController.move(LatLng(property.latitude, property.longitude), 15);
      return;
    }

    final latDiff = (property.latitude - user.latitude).abs();
    final lonDiff = (property.longitude - user.longitude).abs();
    final maxDiff = math.max(latDiff, lonDiff);

    final zoom = switch (maxDiff) {
      < 0.002 => 16.0,
      < 0.01 => 14.5,
      < 0.05 => 13.0,
      < 0.2 => 11.5,
      _ => 10.0,
    };

    _mapController.move(
      LatLng(
        (property.latitude + user.latitude) / 2,
        (property.longitude + user.longitude) / 2,
      ),
      zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.propertyCoordinates;
    final user = widget.userCoordinates;
    final distanceKm = user != null
        ? distanceInKilometers(user, property)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Map Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF103033),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.locatingUser ? null : widget.onLocateUser,
              icon: const Icon(Icons.my_location_outlined, size: 16),
              label: Text(
                widget.locatingUser
                    ? 'Locating...'
                    : user == null
                    ? 'Show My Location'
                    : 'Refresh',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2F9E9A),
                side: const BorderSide(color: Color(0xFF2F9E9A)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
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
              initialCenter: LatLng(property.latitude, property.longitude),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rentora.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(property.latitude, property.longitude),
                    width: 40,
                    height: 40,
                    child: const _MapMarker(
                      icon: Icons.home_rounded,
                      color: Color(0xFFE03131),
                    ),
                  ),
                  if (user != null)
                    Marker(
                      point: LatLng(user.latitude, user.longitude),
                      width: 40,
                      height: 40,
                      child: const _MapMarker(
                        icon: Icons.my_location_rounded,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            const _LegendChip(color: Color(0xFFE03131), label: 'Property'),
            if (user != null)
              const _LegendChip(color: Color(0xFF2563EB), label: 'You'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Property: ${formatCoordinates(property)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5E7A7E)),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'You: ${formatCoordinates(user)}'
              '${distanceKm != null ? '  •  ${distanceKm.toStringAsFixed(2)} km away' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5E7A7E)),
            ),
          ),
        if (widget.locationError != null)
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
              widget.locationError!,
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

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF103033),
            ),
          ),
        ],
      ),
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
