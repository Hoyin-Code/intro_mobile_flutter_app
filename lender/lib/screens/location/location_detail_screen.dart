import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../models/location_model.dart';
import '../../providers/items_provider.dart';
import '../../widgets/item_card.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  const LocationDetailScreen({super.key, required this.location});

  final LocationModel location;

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final MapController _mapController = MapController();
  LatLng? _center;

  static const _fallback = LatLng(51.1535, 4.4305);

  @override
  void initState() {
    super.initState();
    _geocode();
  }

  Future<void> _geocode() async {
    try {
      final loc = widget.location;
      final results = await locationFromAddress(
        '${loc.street}, ${loc.postalCode} ${loc.city}, ${loc.country}',
      );
      if (!mounted || results.isEmpty) return;
      final center = LatLng(results.first.latitude, results.first.longitude);
      setState(() => _center = center);
      _mapController.move(center, 15);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final center = _center ?? _fallback;
    final myItemsAsync = ref.watch(myItemsProvider);
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(loc.label)),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
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
                if (_center != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _center!,
                        width: 32,
                        height: 32,
                        child: Icon(Icons.location_pin, color: color, size: 32),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${loc.street}, ${loc.postalCode} ${loc.city}, ${loc.country}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items at this location',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: myItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final locationItems = items
                    .where((i) => i.locationLabel == loc.label)
                    .toList();

                if (locationItems.isEmpty) {
                  return const Center(
                    child: Text('No items listed at this location.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: locationItems.length,
                  itemBuilder: (context, index) => ItemCard(
                    item: locationItems[index],
                    onTap: () =>
                        context.push('/items/${locationItems[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
