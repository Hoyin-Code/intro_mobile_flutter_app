import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/item_model.dart';
import '../providers/distance_filter_provider.dart';
import '../providers/items_provider.dart';

class DistanceFilterSheet extends ConsumerStatefulWidget {
  const DistanceFilterSheet({super.key});

  @override
  ConsumerState<DistanceFilterSheet> createState() =>
      _DistanceFilterSheetState();
}

class _DistanceFilterSheetState extends ConsumerState<DistanceFilterSheet> {
  final MapController _mapController = MapController();

  LatLng? _center;
  double _radiusKm = 5.0;
  bool _locating = true;

  // Wilrijk, Belgium as fallback
  static const _fallback = LatLng(51.1535, 4.4305);

  @override
  void initState() {
    super.initState();
    final existing = ref.read(distanceFilterProvider);
    if (existing != null) {
      _center = existing.center;
      _radiusKm = existing.radiusKm;
      _locating = false;
    } else {
      _fetchLocation();
    }
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _center = _fallback;
          _locating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = latLng;
        _locating = false;
      });
      _mapController.move(latLng, _zoomForRadius(_radiusKm));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _center = _fallback;
        _locating = false;
      });
    }
  }

  double _zoomForRadius(double km) {
    return (14 - log(km) / log(2)).clamp(8, 15);
  }

  void _onApply() {
    if (_center == null) return;
    ref.read(distanceFilterProvider.notifier).state = DistanceFilter(
      center: _center!,
      radiusKm: _radiusKm,
    );
    Navigator.pop(context);
  }

  void _onClear() {
    ref.read(distanceFilterProvider.notifier).state = null;
    Navigator.pop(context);
  }

  List<Marker> _buildItemMarkers(List<ItemModel> items) {
    return items
        .where((item) => item.isAvailable)
        .map(
          (item) => Marker(
            point: item.address.latLng,
            width: 28,
            height: 28,
            child: Tooltip(
              message: '${item.title} · \$${item.pricePerDay.toStringAsFixed(0)}/day',
              child: const Icon(Icons.location_pin, color: Colors.red, size: 28),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final center = _center ?? _fallback;
    final itemsAsync = ref.watch(itemsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by distance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(onPressed: _onClear, child: const Text('Clear')),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _zoomForRadius(_radiusKm),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.lender',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: center,
                          radius: _radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: color.withValues(alpha: 0.15),
                          borderColor: color,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: itemsAsync.whenData(_buildItemMarkers).valueOrNull ?? [],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.my_location,
                            color: color,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_locating) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('1 km', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_radiusKm.round()} km',
                    onChanged: (val) {
                      setState(() => _radiusKm = val);
                      _mapController.move(center, _zoomForRadius(val));
                    },
                  ),
                ),
                const Text('50 km', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text(
            'Within ${_radiusKm.round()} km',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _center == null ? null : _onApply,
                child: const Text('Apply filter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
