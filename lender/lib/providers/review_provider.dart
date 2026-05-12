import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());

// Keyed by userId — streams all reviews written about that person
final reviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.watch(reviewServiceProvider).getReviewsForUser(userId);
});
