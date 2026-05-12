import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'bottom_sheet_handle.dart';
import 'bottom_sheet_padding.dart';
import 'loading_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_model.dart';
import '../providers/review_provider.dart';

class AddReviewSheet extends ConsumerStatefulWidget {
  const AddReviewSheet({
    super.key,
    required this.loanRequestId,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.reviewerId,
    required this.reviewerName,
  });

  final String loanRequestId;
  final String reviewedUserId;
  final String reviewedUserName;
  final String reviewerId;
  final String reviewerName;

  @override
  ConsumerState<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<AddReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final review = ReviewModel(
        id: '',
        loanRequestId: widget.loanRequestId,
        reviewedUserId: widget.reviewedUserId,
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: Timestamp.now(),
      );
      await ref.read(reviewServiceProvider).addReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle(),
          Text(
            'Review ${widget.reviewedUserName}',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          LoadingButton(
            label: 'Submit Review',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip', style: TextStyle(color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}
