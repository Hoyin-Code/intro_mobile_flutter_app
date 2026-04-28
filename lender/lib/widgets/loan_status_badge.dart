import 'package:flutter/material.dart';
import '../models/loan_request_model.dart';

class LoanStatusBadge extends StatelessWidget {
  final LoanStatus status;

  const LoanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: _color, fontSize: 12),
      ),
    );
  }

  Color get _color => switch (status) {
        LoanStatus.pending => Colors.orange,
        LoanStatus.accepted => Colors.blue,
        LoanStatus.active => Colors.green,
        LoanStatus.returned => Colors.grey,
        LoanStatus.rejected => Colors.red,
        LoanStatus.cancelled => Colors.grey,
      };
}
