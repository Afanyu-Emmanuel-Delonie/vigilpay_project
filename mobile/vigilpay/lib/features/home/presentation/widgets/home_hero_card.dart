import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.userName,
    required this.accountType,
    required this.balanceUsd,
    required this.creditScore,
    super.key,
  });

  final String userName;
  final String accountType;
  final double balanceUsd;
  final int creditScore;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8C1515),
            Color(0xFF5A0D0D),
            Color(0xFF2E1010),
            Color(0xFF1A1917),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -40,
            child: SizedBox(
              width: 220,
              height: 220,
              child: _ArcRings(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, topPadding + 20, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AvatarInitial(name: userName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 20,
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: VigilColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'TOTAL BALANCE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 2.0,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatUsd(balanceUsd),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroStat(
                      label: 'Credit Score',
                      value: creditScore.toString(),
                      color: VigilColors.gold,
                      icon: Icons.trending_up_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    _HeroStat(
                      label: 'Account',
                      value: accountType,
                      color: const Color(0xFF34D399),
                      icon: Icons.workspace_premium_rounded,
                      valueMaxWidth: 88,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const _HeroStat(
                      label: 'Status',
                      value: 'Active',
                      color: Color(0xFF34D399),
                      icon: Icons.circle,
                      iconSize: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? 'U' : name[0].toUpperCase(),
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.iconSize = 14,
    this.valueMaxWidth,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double iconSize;
  final double? valueMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: valueMaxWidth,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcRings extends StatelessWidget {
  const _ArcRings();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArcRingsPainter());
  }
}

class _ArcRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radii = [60.0, 100.0, 140.0, 180.0];
    final opacities = [0.5, 0.35, 0.2, 0.12];
    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(
        Offset(size.width, 0),
        radii[i],
        Paint()
          ..color = Colors.white.withValues(alpha: opacities[i])
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

