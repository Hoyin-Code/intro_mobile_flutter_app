import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import 'auth_provider.dart';

final itemServiceProvider = Provider<ItemService>((ref) => ItemService());

// All available items
final itemsProvider = StreamProvider<List<ItemModel>>((ref) {
  return ref.watch(itemServiceProvider).getItems();
});

// Items belonging to the currently logged-in user
final myItemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return const Stream.empty();
  return ref.watch(itemServiceProvider).getItemsByOwner(userId);
});
