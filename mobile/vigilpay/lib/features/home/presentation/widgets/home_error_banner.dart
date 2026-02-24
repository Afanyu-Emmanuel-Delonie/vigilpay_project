import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeErrorBanner extends StatelessWidget {
  const HomeErrorBanner({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VigilColors.redMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VigilColors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: VigilColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: VigilColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

