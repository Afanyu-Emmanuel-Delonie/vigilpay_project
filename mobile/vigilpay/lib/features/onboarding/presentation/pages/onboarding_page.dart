import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _poweredCtrl;
  late final AnimationController _exitCtrl;

  // ── Logo animations ──
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // ── Brand name animations ──
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // ── Tagline animations ──
  late final Animation<double> _taglineFade;

  // ── "Powered by" animations ──
  late final Animation<double> _poweredFade;
  late final Animation<Offset> _poweredSlide;

  // ── Exit fade ──
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Hide status bar for a true full-screen feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── Logo: scale + fade in ──
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    // ── Brand text: fade + slide up ──
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // ── Tagline: fade in ──
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut);

    // ── Powered by: fade + slide up from bottom ──
    _poweredCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _poweredFade = CurvedAnimation(parent: _poweredCtrl, curve: Curves.easeOut);
    _poweredSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _poweredCtrl, curve: Curves.easeOutCubic));

    // ── Exit: full screen fade out ──
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Staggered entrance
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _poweredCtrl.forward();

    // Hold for 5 seconds total (entrance takes ~1.25s, so wait remaining)
    await Future.delayed(const Duration(milliseconds: 3750));
    if (!mounted) return;

    // Fade out then navigate
    await _exitCtrl.forward();
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pushReplacementNamed(context, RouteConstants.authGate);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _poweredCtrl.dispose();
    _exitCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VigilColors.navyDark,
      body: AnimatedBuilder(
        animation: _exitFade,
        builder: (_, child) => Opacity(opacity: _exitFade.value, child: child),
        child: Stack(
          children: [
            // ── Full-screen gradient (identical to login page) ──
            Positioned.fill(
              child: CustomPaint(painter: _HeroPainter()),
            ),

            // ── Arc rings — top right (identical to login page) ──
            Positioned(
              top: -80,
              right: -80,
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(painter: _ArcRingsPainter()),
              ),
            ),

            // ── Arc rings — bottom left (mirror, slightly different radii) ──
            Positioned(
              bottom: -60,
              left: -60,
              child: SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(painter: _ArcRingsPainter(fromTopRight: false)),
              ),
            ),

            // ── Centre content ──
            SafeArea(
              child: Column(
                children: [
                  // Flex spacer — pushes logo to vertical centre
                  const Spacer(flex: 5),

                  // Logo mark
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(38, 38),
                            painter: _HexLogoPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Brand name
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Vigil'),
                            TextSpan(
                              text: 'Pay',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'SECURE BANKING INTELLIGENCE',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        letterSpacing: 2.4,
                        color: Colors.white.withValues(alpha: 0.38),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Subtle loading indicator
                  FadeTransition(
                    opacity: _taglineFade,
                    child: _PulsingDots(),
                  ),

                  const Spacer(flex: 5),

                  // Powered by Equity
                  SlideTransition(
                    position: _poweredSlide,
                    child: FadeTransition(
                      opacity: _poweredFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            Text(
                              'POWERED BY',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 9,
                                letterSpacing: 2.0,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Equity logo mark
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'E',
                                      style: TextStyle(
                                        fontFamily: 'PlayfairDisplay',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Equity',
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.2,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Pulsing dots loading indicator
// ─────────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i / 3.0;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final opacity = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.15, 0.7);
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
//  Hero gradient background painter
//  — exactly matches login page
// ─────────────────────────────────────────
class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8C1515),
          Color(0xFF5A0D0D),
          Color(0xFF2E1010),
          Color(0xFF1A1917),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Radial glow — top-left
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [
          const Color(0xFF8C1515).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Radial glow — bottom-right
    final darkPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 0.9,
        colors: [
          const Color(0xFF1E100F).withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
//  Arc rings painter
// ─────────────────────────────────────────
class _ArcRingsPainter extends CustomPainter {
  const _ArcRingsPainter({this.fromTopRight = true});
  final bool fromTopRight;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = fromTopRight ? size.width : 0.0;
    final cy = fromTopRight ? 0.0 : size.height;

    final radii = [80.0, 130.0, 185.0, 240.0, 300.0];
    final opacities = [0.45, 0.32, 0.22, 0.14, 0.08];
    final widths = [0.9, 0.8, 0.7, 0.6, 0.5];

    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(
        Offset(cx, cy),
        radii[i],
        Paint()
          ..color = Colors.white.withValues(alpha: opacities[i])
          ..style = PaintingStyle.stroke
          ..strokeWidth = widths[i],
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
//  Hex logo painter (shield + dot)
//  — identical to login page
// ─────────────────────────────────────────
class _HexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, h * 0.05)
      ..lineTo(w * 0.92, h * 0.28)
      ..lineTo(w * 0.92, h * 0.72)
      ..lineTo(cx, h * 0.95)
      ..lineTo(w * 0.08, h * 0.72)
      ..lineTo(w * 0.08, h * 0.28)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.14,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}