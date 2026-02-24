import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/dashboard_models.dart';

class HomeOffersRow extends StatelessWidget {
  const HomeOffersRow({
    required this.offers,
    super.key,
  });

  final List<HomeOfferData> offers;

  static const _offerIcons = [
    Icons.workspace_premium_rounded,
    Icons.savings_rounded,
    Icons.percent_rounded,
    Icons.local_offer_rounded,
  ];

  static const _offerColors = [
    VigilColors.gold,
    Color(0xFF34D399),
    VigilColors.red,
    Color(0xFF60A5FA),
  ];

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      scrollDirection: Axis.horizontal,
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final color = _offerColors[index % _offerColors.length];
        final icon = _offerIcons[index % _offerIcons.length];
        final item = offers[index];
        return Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VigilColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VigilColors.stoneMid, width: 1),
            boxShadow: [
              BoxShadow(
                color: VigilColors.navy.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: VigilColors.navy,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFF777777),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

