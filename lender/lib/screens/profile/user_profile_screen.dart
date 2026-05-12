import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/items_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/item_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/review_card.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider(userId));
    final itemsAsync = ref.watch(itemsProvider);
    final reviewsAsync = ref.watch(reviewsProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header ──────────────────────────────────────────────
              Center(
                child: UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 40,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: RatingStars(
                  averageRating: user.averageRating,
                  totalReviews: user.totalReviews,
                ),
              ),
              const Divider(height: 32),

              // ── Listings ────────────────────────────────────────────
              Text('Listings',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              itemsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (items) {
                  final userItems = items
                      .where((i) => i.ownerId == userId && i.isAvailable)
                      .toList();
                  if (userItems.isEmpty) {
                    return const Text('No active listings.');
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: userItems.length,
                    itemBuilder: (_, i) => ItemCard(
                      item: userItems[i],
                      onTap: () => context.push('/items/${userItems[i].id}'),
                    ),
                  );
                },
              ),
              const Divider(height: 32),

              // ── Reviews ─────────────────────────────────────────────
              Text('Reviews',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              reviewsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
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
          );
        },
      ),
    );
  }
}
