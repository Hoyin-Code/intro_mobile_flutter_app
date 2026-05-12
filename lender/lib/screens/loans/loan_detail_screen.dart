import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/loan_request_model.dart';
import '../../utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/loan_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/add_review_sheet.dart';
import '../../widgets/loan_status_badge.dart';
import '../../widgets/photo_carousel.dart';
import '../../widgets/user_rating_card.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanRequestId;

  const LoanDetailScreen({super.key, required this.loanRequestId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  Future<void> _updateStatus(
    LoanRequestModel request,
    LoanStatus status,
  ) async {
    await ref.read(loanRequestServiceProvider).updateStatus(request.id, status);
    if (status == LoanStatus.active) {
      await ref.read(itemServiceProvider).updateAvailability(
            request.itemId,
            isAvailable: false,
          );
    } else if (status == LoanStatus.returned) {
      await ref.read(itemServiceProvider).updateAvailability(
            request.itemId,
            isAvailable: true,
          );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    String confirmLabel = 'Confirm',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _confirmReturn(
    LoanRequestModel request, {
    required String reviewerName,
    required String borrowerName,
  }) async {
    final confirmed = await _confirm(
      title: 'Confirm return',
      content: 'Has the item been physically returned to you?',
      confirmLabel: 'Yes, returned',
    );
    if (!confirmed || !mounted) return;
    await _updateStatus(request, LoanStatus.returned);
    if (!mounted) return;
    await _showReviewSheet(
      loanRequestId: request.id,
      reviewedUserId: request.borrowerId,
      reviewedUserName: borrowerName,
      reviewerId: request.lenderId,
      reviewerName: reviewerName,
    );
    if (mounted) context.pop();
  }

  Future<void> _showReviewSheet({
    required String loanRequestId,
    required String reviewedUserId,
    required String reviewedUserName,
    required String reviewerId,
    required String reviewerName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddReviewSheet(
        loanRequestId: loanRequestId,
        reviewedUserId: reviewedUserId,
        reviewedUserName: reviewedUserName,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomingAsync = ref.watch(lenderRequestsProvider);
    final outgoingAsync = ref.watch(borrowerRequestsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    final allRequests = [
      ...incomingAsync.value ?? [],
      ...outgoingAsync.value ?? [],
    ];

    final request = allRequests
        .where((r) => r.id == widget.loanRequestId)
        .firstOrNull;

    if (request == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLender = currentUser?.uid == request.lenderId;
    final item = ref
        .watch(itemsProvider)
        .value
        ?.where((i) => i.id == request.itemId)
        .firstOrNull;
    final itemTitle = item?.title ?? '...';
    final photoUrls = item?.photoUrls ?? [];

    final lenderName =
        ref.watch(userDataProvider(request.lenderId)).value?.name ?? '';
    final borrowerName =
        ref.watch(userDataProvider(request.borrowerId)).value?.name ?? '';

    Widget? actionButton;
    if (isLender && request.status == LoanStatus.pending) {
      actionButton = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final router = GoRouter.of(context);
                final ok = await _confirm(
                  title: 'Reject request?',
                  content: 'The borrower will be notified.',
                  confirmLabel: 'Reject',
                );
                if (!ok) return;
                await _updateStatus(request, LoanStatus.rejected);
                if (mounted) router.pop();
              },
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final router = GoRouter.of(context);
                final ok = await _confirm(
                  title: 'Accept request?',
                  content: 'The borrower will be notified.',
                  confirmLabel: 'Accept',
                );
                if (!ok) return;
                await _updateStatus(request, LoanStatus.accepted);
                if (mounted) router.pop();
              },
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    } else if (isLender && request.status == LoanStatus.accepted) {
      actionButton = SizedBox(
        width: double.infinity + 1,
        child: ElevatedButton(
          onPressed: () async {
            final router = GoRouter.of(context);
            final ok = await _confirm(
              title: 'Mark as active?',
              content: 'Confirm the item has been handed to the borrower.',
              confirmLabel: 'Mark Active',
            );
            if (!ok) return;
            await _updateStatus(request, LoanStatus.active);
            if (mounted) router.pop();
          },
          child: const Text('Mark as Active'),
        ),
      );
    } else if (isLender && request.status == LoanStatus.active) {
      actionButton = SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _confirmReturn(
            request,
            reviewerName: lenderName,
            borrowerName: borrowerName,
          ),
          child: const Text('Confirm Returned'),
        ),
      );
    } else if (!isLender && request.status == LoanStatus.returned) {
      actionButton = SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showReviewSheet(
            loanRequestId: request.id,
            reviewedUserId: request.lenderId,
            reviewedUserName: lenderName,
            reviewerId: request.borrowerId,
            reviewerName: borrowerName,
          ),
          child: const Text('Leave a Review'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(itemTitle)),
      bottomNavigationBar: actionButton == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: actionButton,
            ),
      body: ListView(
        children: [
          PhotoCarousel(photoUrls: photoUrls),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    LoanStatusBadge(status: request.status),
                  ],
                ),
                const Divider(height: 24),
                _DetailRow(label: 'Item', value: itemTitle),
                _DetailRow(
                  label: 'Period',
                  value: DateFormatter.formatRange(
                    request.startDate,
                    request.endDate,
                  ),
                ),
                _DetailRow(
                  label: 'Total',
                  value: '€${request.totalPrice.toStringAsFixed(2)}',
                ),
                const Divider(height: 24),
                Text('Borrower', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: UserRatingCard(userId: request.borrowerId)),
                    TextButton(
                      onPressed: () =>
                          context.push('/profile/user/${request.borrowerId}'),
                      child: const Text('View profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
