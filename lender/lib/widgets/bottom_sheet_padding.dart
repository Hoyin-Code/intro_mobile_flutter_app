import 'package:flutter/material.dart';

class BottomSheetPadding extends StatelessWidget {
  const BottomSheetPadding({
    super.key,
    required this.child,
    this.horizontal = 24,
    this.bottomExtra = 32,
  });

  final Widget child;
  final double horizontal;
  final double bottomExtra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontal,
        right: horizontal,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + bottomExtra,
      ),
      child: child,
    );
  }
}
