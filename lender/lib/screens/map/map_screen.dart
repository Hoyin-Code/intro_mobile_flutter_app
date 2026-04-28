import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/item_model.dart';
import '../../providers/items_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _locating = true;
  String? _locationError;

  // Fallback centre while GPS loads
  static const _fallback = LatLng(45.4215, -75.6972);

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission denied. Showing default area.';
          _locating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _locating = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get location. Showing default area.';
        _locating = false;
      });
    }
  }

  Set<Marker> _buildMarkers(List<ItemModel> items) {
    return items
        .where((item) => item.isAvailable)
        .map(
          (item) => Marker(
            markerId: MarkerId(item.id),
            position: item.address.latLng,
            infoWindow: InfoWindow(
              title: item.title,
              snippet: '\$${item.pricePerDay.toStringAsFixed(2)}/day — tap for details',
              onTap: () => context.push('/items/${item.id}'),
            ),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);

    final centre = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _fallback;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Items')),
      body: Stack(
        children: [
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading items: $e')),
            data: (items) => GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: centre, zoom: 13),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _buildMarkers(items),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(centre),
                  );
                }
              },
            ),
          ),
          if (_locating)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _LocationBanner(message: 'Finding your location…'),
              ),
            ),
          if (_locationError != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _LocationBanner(message: _locationError!),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
