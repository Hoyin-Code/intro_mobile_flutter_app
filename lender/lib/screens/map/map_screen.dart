import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../models/item_model.dart';
import '../../providers/items_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _locating = true;
  String? _locationError;

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
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _locating = false;
      });
      _mapController.move(latLng, 13);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get location. Showing default area.';
        _locating = false;
      });
    }
  }

  List<Marker> _buildMarkers(List<ItemModel> items) {
    return items
        .where((item) => item.isAvailable)
        .map(
          (item) => Marker(
            point: item.address.latLng,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => context.push('/items/${item.id}'),
              child: Tooltip(
                message:
                    '${item.title} — €${item.pricePerDay.toStringAsFixed(2)}/day',
                child: const Icon(Icons.location_pin,
                    color: Colors.red, size: 36),
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final centre = _currentPosition ?? _fallback;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Items')),
      body: Stack(
        children: [
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading items: $e')),
            data: (items) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: centre, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.lender',
                ),
                MarkerLayer(markers: _buildMarkers(items)),
              ],
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
