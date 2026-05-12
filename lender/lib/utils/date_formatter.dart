import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  const DateFormatter._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "12 May" or "12 May 2026" when includeYear is true
  static String format(DateTime d, {bool includeYear = false}) {
    final base = '${d.day} ${_months[d.month - 1]}';
    return includeYear ? '$base ${d.year}' : base;
  }

  /// "12 May 2026 → 15 May 2026"
  static String formatRange(Timestamp start, Timestamp end) {
    final s = start.toDate().toLocal();
    final e = end.toDate().toLocal();
    return '${format(s, includeYear: true)} → ${format(e, includeYear: true)}';
  }
}
