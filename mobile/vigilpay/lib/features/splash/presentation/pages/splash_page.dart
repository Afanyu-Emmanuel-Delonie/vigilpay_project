import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/route_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(const Duration(seconds: 10));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteConstants.authGate);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              // ── Centre content ──
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoMark(),
                    SizedBox(height: 18),
                    Text(
                      'VigilPay',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Secure Banking Intelligence',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                    SizedBox(height: 26),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Inspired by Equity Bank ──
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding + 28),
                child: Column(
                  children: [
                    Text(
                      'INSPIRED BY',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                        letterSpacing: 2.2,
                        color: Color(0x55FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Equity logo mark
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Color(0x2AFFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'E',
                              style: TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Equity Bank',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Logo mark widget
// ─────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.shield_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}