import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviewsForUser(String userId) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .collection(FirestoreConstants.reviews)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addReview(ReviewModel review) async {
    final userRef = _firestore
        .collection(FirestoreConstants.users)
        .doc(review.reviewedUserId);

    final reviewRef = userRef
        .collection(FirestoreConstants.reviews)
        .doc();

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final currentTotal =
          (userSnapshot.data()?['totalReviews'] as int?) ?? 0;
      final currentAvg =
          (userSnapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;

      final newTotal = currentTotal + 1;
      final newAvg =
          ((currentAvg * currentTotal) + review.rating) / newTotal;

      transaction.set(reviewRef, review.toMap());
      transaction.update(userRef, {
        'averageRating': newAvg,
        'totalReviews': newTotal,
      });
    });
  }
}
