import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class DistanceFilter {
  final LatLng center;
  final double radiusKm;
  const DistanceFilter({required this.center, required this.radiusKm});
}

final distanceFilterProvider = StateProvider<DistanceFilter?>((ref) => null);
