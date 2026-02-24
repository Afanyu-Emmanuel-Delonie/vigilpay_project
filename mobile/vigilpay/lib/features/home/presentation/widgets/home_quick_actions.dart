import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'home_section_header.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    required this.onOpenSupport,
    super.key,
  });

  final VoidCallback onOpenSupport;

  static const _actions = [
    _Action(icon: Icons.swap_horiz_rounded, label: 'Transfer'),
    _Action(icon: Icons.phone_android_rounded, label: 'Airtime'),
    _Action(icon: Icons.receipt_long_rounded, label: 'Bills'),
    _Action(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _actions
              .map(
                (action) => Expanded(
                  child: _ActionItem(
                    action: action,
                    onTap: action.label == 'More' ? onOpenSupport : null,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _Action {
  const _Action({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.action, this.onTap});
  final _Action action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: VigilColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VigilColors.stoneMid, width: 1),
              boxShadow: [
                BoxShadow(
                  color: VigilColors.navy.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(action.icon, color: VigilColors.red, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: VigilColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
