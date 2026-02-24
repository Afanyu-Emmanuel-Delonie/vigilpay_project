import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeRiskInsightCard extends StatelessWidget {
  const HomeRiskInsightCard({
    required this.tier,
    required this.creditScore,
    required this.riskProbability,
    super.key,
  });

  final String tier;
  final int creditScore;
  final double? riskProbability;

  @override
  Widget build(BuildContext context) {
    final scoreProgress = ((creditScore - 300) / 550).clamp(0.0, 1.0);
    final riskLabel = _riskLabel(tier);
    final riskColor = _riskColor(riskLabel);
    final probability = riskProbability == null
        ? 'N/A'
        : '${(riskProbability! * 100).toStringAsFixed(1)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VigilColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _ScoreArcPainter(progress: scoreProgress, color: riskColor),
              child: Center(
                child: Text(
                  creditScore.toString(),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit & Retention Insight',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Pill(label: riskLabel.toUpperCase(), color: riskColor),
                    const SizedBox(width: 8),
                    Text(
                      'Tier: $tier',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Risk probability: $probability',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _riskLabel(String tier) {
    final t = tier.toLowerCase();
    if (t.contains('high')) return 'High';
    if (t.contains('medium') || t.contains('mid')) return 'Medium';
    return 'Low';
  }

  static Color _riskColor(String riskLabel) {
    switch (riskLabel) {
      case 'High':
        return VigilColors.red;
      case 'Medium':
        return VigilColors.gold;
      default:
        return const Color(0xFF34D399);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 8.5,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  const _ScoreArcPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const startAngle = -2.4;
    const sweepAngle = 4.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

