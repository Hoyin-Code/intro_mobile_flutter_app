import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());

// Family provider — keyed by itemId so each item gets its own stream
final reviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, itemId) {
  return ref.watch(reviewServiceProvider).getReviewsForItem(itemId);
});
