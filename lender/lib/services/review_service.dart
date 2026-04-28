import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviewsForItem(String itemId) {
    return _firestore
        .collection(FirestoreConstants.items)
        .doc(itemId)
        .collection(FirestoreConstants.reviews)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addReview(String itemId, ReviewModel review) async {
    final reviewRef = _firestore
        .collection(FirestoreConstants.items)
        .doc(itemId)
        .collection(FirestoreConstants.reviews)
        .doc();

    final itemRef =
        _firestore.collection(FirestoreConstants.items).doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemRef);
      final currentTotal =
          (itemSnapshot.data()?['totalReviews'] as int?) ?? 0;
      final currentAvg =
          (itemSnapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;

      // Running average formula — avoids reading all reviews
      final newTotal = currentTotal + 1;
      final newAvg =
          ((currentAvg * currentTotal) + review.rating) / newTotal;

      transaction.set(reviewRef, review.toMap());
      transaction.update(itemRef, {
        'averageRating': newAvg,
        'totalReviews': newTotal,
      });
    });
  }
}
