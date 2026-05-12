import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName
                      : 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.comment,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
