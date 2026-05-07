import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/location_model.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final userLocationsProvider = StreamProvider<List<LocationModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return const Stream.empty();
  return ref.watch(locationServiceProvider).getLocations(userId);
});
