import 'package:cloud_firestore/cloud_firestore.dart';

// Stored as a subcollection: users/{reviewedUserId}/reviews/{reviewId}
class ReviewModel {
  final String id;
  final String loanRequestId;
  final String reviewedUserId;
  final String reviewerId;
  final String reviewerName;
  final int rating; // 1–5
  final String comment;
  final Timestamp createdAt;

  ReviewModel({
    required this.id,
    required this.loanRequestId,
    required this.reviewedUserId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) =>
      ReviewModel(
        id: id,
        loanRequestId: map['loanRequestId'],
        reviewedUserId: map['reviewedUserId'],
        reviewerId: map['reviewerId'],
        reviewerName: map['reviewerName'] ?? '',
        rating: map['rating'] as int,
        comment: map['comment'],
        createdAt: map['createdAt'] as Timestamp,
      );

  Map<String, dynamic> toMap() => {
        'loanRequestId': loanRequestId,
        'reviewedUserId': reviewedUserId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };
}
