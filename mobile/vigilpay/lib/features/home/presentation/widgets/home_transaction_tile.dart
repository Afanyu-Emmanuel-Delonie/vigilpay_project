import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/dashboard_models.dart';
import '../utils/currency_formatter.dart';

class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    required this.item,
    super.key,
  });

  final HomeTransactionData item;

  @override
  Widget build(BuildContext context) {
    final isDebit = item.amountUsd < 0;
    final amountColor = isDebit ? VigilColors.red : const Color(0xFF059669);
    final iconBg = isDebit ? VigilColors.redMuted : const Color(0xFFECFDF5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: VigilColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VigilColors.stoneMid, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isDebit ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 18,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: VigilColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.timeLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatUsd(item.amountUsd, includeSign: true),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
