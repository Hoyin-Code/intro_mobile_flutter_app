import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_model.dart';
import '../models/loan_request_model.dart';
import '../providers/loan_request_provider.dart';

class LoanRequestSheet extends ConsumerStatefulWidget {
  const LoanRequestSheet({
    super.key,
    required this.item,
    required this.borrowerId,
  });

  final ItemModel item;
  final String borrowerId;

  @override
  ConsumerState<LoanRequestSheet> createState() => _LoanRequestSheetState();
}

class _LoanRequestSheetState extends ConsumerState<LoanRequestSheet> {
  int _days = 1;
  bool _isLoading = false;

  static const _minDays = 1;
  static const _maxDays = 30;

  DateTime get _startDate => DateTime.now();
  DateTime get _endDate => _startDate.add(Duration(days: _days));
  double get _totalPrice => _days * widget.item.pricePerDay;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final request = LoanRequestModel(
        id: '',
        itemId: widget.item.id,
        borrowerId: widget.borrowerId,
        lenderId: widget.item.ownerId,
        status: LoanStatus.pending,
        startDate: Timestamp.fromDate(_startDate),
        endDate: Timestamp.fromDate(_endDate),
        totalPrice: _totalPrice,
        createdAt: Timestamp.now(),
      );
      await ref
          .read(loanRequestServiceProvider)
          .createRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Request to Borrow',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.title,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Days stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed: _days > _minDays
                    ? () => setState(() => _days--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      '$_days',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      _days == 1 ? 'day' : 'days',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: _days < _maxDays
                    ? () => setState(() => _days++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Period & price summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Period',
                  value: '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Price per day',
                  value: '€${widget.item.pricePerDay.toStringAsFixed(2)}',
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Total',
                  value: '€${_totalPrice.toStringAsFixed(2)}',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w700)
        : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
