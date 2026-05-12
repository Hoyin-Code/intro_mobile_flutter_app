import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMapView extends StatelessWidget {
  const LocationMapView({
    super.key,
    required this.geoPoint,
    required this.mapController,
    this.height = 180,
  });

  final GeoPoint geoPoint;
  final MapController mapController;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final center = LatLng(geoPoint.latitude, geoPoint.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.lender',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 32,
                  height: 32,
                  child: Icon(Icons.location_pin, color: color, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
