import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const supportHeadingStyle = TextStyle(
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w700,
  fontSize: 13,
  color: VigilColors.navy,
);

const supportMutedStyle = TextStyle(
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w500,
  fontSize: 11,
  color: Color(0xFF777777),
);

class SupportPanel extends StatelessWidget {
  const SupportPanel({
    required this.child,
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VigilColors.stoneMid, width: 1),
      ),
      child: child,
    );
  }
}
