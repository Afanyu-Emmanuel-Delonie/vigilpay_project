import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VigilPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VigilPageAppBar({
    required this.title,
    this.subtitle,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.actions,
    super.key,
  });

  final String title;

  /// Optional small label shown above the title (e.g. 'Support Center').
  final String? subtitle;

  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  /// Icon buttons shown on the trailing edge.
  /// Wrap each icon in [VigilAppBarAction] for consistent styling.
  final List<Widget>? actions;

  static const double _barHeight = 80.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = automaticallyImplyLeading && Navigator.canPop(context);

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
      ),
      child: Stack(
        children: [
          // ── Decorative arc rings (top-right corner) ──
          const Positioned(
            top: -30,
            right: -30,
            child: SizedBox(
              width: 180,
              height: 180,
              child: _ArcRings(),
            ),
          ),

          // ── Content ──
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    if (canPop)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ArcButton(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // Title block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.2,
                              ),
                            ),
                          Text(
                            title,
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

                    // Trailing actions
                    if (actions != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                  ],
                ),

                // Optional bottom widget (e.g. TabBar) — forced white styling
                if (bottom != null) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      tabBarTheme: TabBarTheme(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
                        indicatorColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        dividerColor: Colors.transparent,
                      ),
                    ),
                    child: bottom!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  VigilAppBarAction
//  Convenience wrapper — gives any icon the
//  frosted-glass button look used in the hero.
// ─────────────────────────────────────────
class VigilAppBarAction extends StatelessWidget {
  const VigilAppBarAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip ?? '',
        child: _ArcButton(
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Internal: frosted-glass square button
// ─────────────────────────────────────────
class _ArcButton extends StatelessWidget {
  const _ArcButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Arc rings painter (matches hero header)
// ─────────────────────────────────────────
class _ArcRings extends StatelessWidget {
  const _ArcRings();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ArcRingsPainter());
}

class _ArcRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radii = [50.0, 85.0, 120.0, 155.0];
    final opacities = [0.45, 0.3, 0.18, 0.1];
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}