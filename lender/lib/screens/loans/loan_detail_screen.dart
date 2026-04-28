import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/loan_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_request_provider.dart';
import '../../widgets/loan_status_badge.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String loanRequestId;

  const LoanDetailScreen({super.key, required this.loanRequestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(lenderRequestsProvider);
    final outgoingAsync = ref.watch(borrowerRequestsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    final allRequests = [
      ...incomingAsync.value ?? [],
      ...outgoingAsync.value ?? [],
    ];

    final request =
        allRequests.where((r) => r.id == loanRequestId).firstOrNull;

    if (request == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final isLender = currentUser?.uid == request.lenderId;

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status',
                    style: Theme.of(context).textTheme.titleSmall),
                LoanStatusBadge(status: request.status),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(
                label: 'Item', value: request.itemId),
            _DetailRow(
                label: 'From',
                value: request.startDate.toDate().toLocal().toString()),
            _DetailRow(
                label: 'To',
                value: request.endDate.toDate().toLocal().toString()),
            _DetailRow(
                label: 'Total',
                value: '\$${request.totalPrice.toStringAsFixed(2)}'),
            const Spacer(),
            if (isLender && request.status == LoanStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(loanRequestServiceProvider)
                          .updateStatus(request.id, LoanStatus.rejected),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(loanRequestServiceProvider)
                          .updateStatus(request.id, LoanStatus.accepted),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            if (isLender && request.status == LoanStatus.accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(loanRequestServiceProvider)
                      .updateStatus(request.id, LoanStatus.returned),
                  child: const Text('Mark as Returned'),
                ),
              ),
          ],
        ),
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
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
