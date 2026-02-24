import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.tag,
    super.key,
  });

  final String title;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 2,
          margin: const EdgeInsets.only(right: 7),
          color: VigilColors.red,
        ),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
            letterSpacing: 2.2,
            color: VigilColors.red,
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: VigilColors.redMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 8.5,
                color: VigilColors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
