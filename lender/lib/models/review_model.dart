import 'package:cloud_firestore/cloud_firestore.dart';

// Stored as a subcollection: items/{itemId}/reviews/{reviewId}
class ReviewModel {
  final String id;
  final String loanRequestId;
  final String reviewerId; // the borrower who wrote the review
  final int rating; // 1–5
  final String comment;
  final Timestamp createdAt;

  ReviewModel({
    required this.id,
    required this.loanRequestId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) =>
      ReviewModel(
        id: id,
        loanRequestId: map['loanRequestId'],
        reviewerId: map['reviewerId'],
        rating: map['rating'] as int,
        comment: map['comment'],
        createdAt: map['createdAt'] as Timestamp,
      );

  Map<String, dynamic> toMap() => {
        'loanRequestId': loanRequestId,
        'reviewerId': reviewerId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };
}
