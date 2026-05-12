import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    this.size = 16,
  });

  final double averageRating;
  final int totalReviews;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: Colors.amber),
        SizedBox(width: size * 0.25),
        Text(
          '${averageRating.toStringAsFixed(1)} · $totalReviews review${totalReviews == 1 ? '' : 's'}',
          style: TextStyle(fontSize: size * 0.875, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
