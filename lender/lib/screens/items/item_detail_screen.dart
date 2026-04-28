import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/items_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/review_card.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final reviewsAsync = ref.watch(reviewsProvider(itemId));
    final currentUser = ref.watch(authStateProvider).value;

    return itemsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Item not found.')));
        }

        final isOwner = currentUser?.uid == item.ownerId;

        return Scaffold(
          appBar: AppBar(title: Text(item.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.photoUrls.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: item.photoUrls.length,
                    itemBuilder: (context, i) => Image.network(
                      item.photoUrls[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(item.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('\$${item.pricePerDay.toStringAsFixed(2)} / day',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                      '${item.averageRating.toStringAsFixed(1)} (${item.totalReviews} reviews)'),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.description),
              const SizedBox(height: 8),
              Text('Condition: ${item.condition.name}',
                  style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 32),
              Text('Reviews',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              reviewsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading reviews: $e'),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const Text('No reviews yet.');
                  }
                  return Column(
                    children: reviews
                        .map((r) => ReviewCard(review: r))
                        .toList(),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: isOwner
              ? null
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: item.isAvailable
                        ? () {
                            // TODO: open loan request bottom sheet
                          }
                        : null,
                    child: Text(
                        item.isAvailable ? 'Request to Borrow' : 'Unavailable'),
                  ),
                ),
        );
      },
    );
  }
}
