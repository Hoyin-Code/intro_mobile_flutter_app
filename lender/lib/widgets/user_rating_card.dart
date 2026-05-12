import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import 'rating_stars.dart';
import 'user_avatar.dart';

class UserRatingCard extends ConsumerWidget {
  const UserRatingCard({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider(userId));

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Could not load user info.'),
      data: (user) {
        if (user == null) return const Text('Unknown user.');
        return Row(
          children: [
            UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                RatingStars(
                  averageRating: user.averageRating,
                  totalReviews: user.totalReviews,
                  size: 13,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
