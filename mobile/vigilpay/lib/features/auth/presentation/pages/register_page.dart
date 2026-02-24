import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/request_state.dart';
import '../provider/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (auth.registerState == RequestState.success) {
      Navigator.pushReplacementNamed(context, RouteConstants.login);
    }
  }

  String _friendlyRegisterError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Registration failed. Please try again.';
    }
    if (raw.contains('Email already exists')) {
      return 'This email is already in use.';
    }
    if (raw.contains('Username already exists')) {
      return 'This username is already taken.';
    }
    if (raw.contains('This password is too common')) {
      return 'Choose a stronger password.';
    }
    return 'Registration failed. Please check your inputs and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.registerState == RequestState.loading;

    return Scaffold(
      backgroundColor: VigilColors.navyDark,
      // Resize so keyboard shifts content up and scroll works
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Hero gradient background ──
          Positioned.fill(
            child: CustomPaint(painter: _HeroPainter()),
          ),

          // ── Decorative arc rings ──
          Positioned(
            top: -80,
            right: -80,
            child: _ArcRings(),
          ),

          // ── Fully scrollable content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  // physics that feel natural on both platforms
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    // Ensure content is at least full screen height so the
                    // hero area always fills the top even on tall phones
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Compact hero area ──
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo mark
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(28, 28),
                                      painter: _HexLogoPainter(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Vigil'),
                                      TextSpan(
                                        text: 'Pay',
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure Banking Intelligence',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    letterSpacing: 1.8,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Form panel ──
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: VigilColors.stone,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                              ),
                              padding:
                              const EdgeInsets.fromLTRB(28, 36, 28, 48),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Heading ──
                                    const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontFamily: 'PlayfairDisplay',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 26,
                                        letterSpacing: -0.5,
                                        color: VigilColors.navy,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14, // was 12
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF999999),
                                        ),
                                        children: [
                                          const TextSpan(
                                              text: 'Already have an account? '),
                                          WidgetSpan(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  Navigator.pushReplacementNamed(
                                                      context,
                                                      RouteConstants.login),
                                              child: const Text(
                                                'Sign in',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14, // was 12
                                                  fontWeight: FontWeight.w700,
                                                  color: VigilColors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // ── Name row ──
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              const _FieldLabel(
                                                  label: 'First Name'),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller:
                                                _firstNameController,
                                                textCapitalization:
                                                TextCapitalization.words,
                                                style: _inputTextStyle,
                                                decoration: _inputDeco(
                                                  hint: 'John',
                                                  icon: Icons
                                                      .person_outline_rounded,
                                                ),
                                                validator: (v) =>
                                                (v ?? '').trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              const _FieldLabel(
                                                  label: 'Last Name'),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _lastNameController,
                                                textCapitalization:
                                                TextCapitalization.words,
                                                style: _inputTextStyle,
                                                decoration: _inputDeco(
                                                  hint: 'Doe',
                                                  icon: Icons
                                                      .person_outline_rounded,
                                                ),
                                                validator: (v) =>
                                                (v ?? '').trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Username ──
                                    const _FieldLabel(label: 'Username'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _usernameController,
                                      autocorrect: false,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        hint: 'your_username',
                                        icon: Icons.alternate_email_rounded,
                                      ),
                                      validator: (v) =>
                                      (v ?? '').trim().length < 3
                                          ? 'Minimum 3 characters'
                                          : null,
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Email ──
                                    const _FieldLabel(label: 'Email Address'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        hint: 'you@example.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: (v) {
                                        final e = v?.trim() ?? '';
                                        if (e.isEmpty || !e.contains('@')) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Password ──
                                    const _FieldLabel(label: 'Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        hint: 'Min. 8 characters',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: GestureDetector(
                                          onTap: () => setState(() =>
                                          _obscurePassword =
                                          !_obscurePassword),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFFBBBBBB),
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v ?? '').length < 8
                                          ? 'Minimum 8 characters'
                                          : null,
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Confirm password ──
                                    const _FieldLabel(
                                        label: 'Confirm Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _confirmController,
                                      obscureText: _obscureConfirm,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        hint: 'Re-enter your password',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: GestureDetector(
                                          onTap: () => setState(() =>
                                          _obscureConfirm =
                                          !_obscureConfirm),
                                          child: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFFBBBBBB),
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // ── Error banner ──
                                    if (auth.registerState ==
                                        RequestState.error) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: VigilColors.redMuted,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          border: Border.all(
                                            color: VigilColors.red
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: VigilColors.red,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _friendlyRegisterError(
                                                    auth.errorMessage),
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12, // was 11.5
                                                  color: VigilColors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ] else
                                      const SizedBox(height: 16),

                                    // ── Submit button ──
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: VigilColors.red,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                          VigilColors.stoneMid,
                                          elevation: 0,
                                          shadowColor: VigilColors.redGlow,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                            AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                            : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    // ── Sign in row ──
                                    Center(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14, // was 12
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF999999),
                                          ),
                                          children: [
                                            const TextSpan(
                                                text:
                                                'Already have an account? '),
                                            WidgetSpan(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    Navigator.pushReplacementNamed(
                                                        context,
                                                        RouteConstants.login),
                                                child: const Text(
                                                  'Sign in',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14, // was 12
                                                    fontWeight: FontWeight.w700,
                                                    color: VigilColors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 14, // was 13
    color: VigilColors.navy,
  );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14, // was 12.5
        color: Color(0xFFBBBBBB),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: VigilColors.white,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFBBBBBB)),
      suffixIcon: suffix != null
          ? Padding(
        padding: const EdgeInsets.only(right: 12),
        child: suffix,
      )
          : null,
      suffixIconConstraints:
      const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: VigilColors.stoneMid, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: VigilColors.stoneMid, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VigilColors.red, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VigilColors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: VigilColors.redDark, width: 2),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12, // was 10.5
        fontWeight: FontWeight.w600,
        color: VigilColors.red,
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Field label
// ─────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: 10, // was 9.5
        letterSpacing: 1.3,
        color: Color(0xFF1A1917),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Hero background painter
// ─────────────────────────────────────────
class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF8C1515),
          Color(0xFF5A0D0D),
          Color(0xFF2E1010),
          Color(0xFF1A1917),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

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
//  Arc rings
// ─────────────────────────────────────────
class _ArcRings extends StatelessWidget {
  const _ArcRings();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: _ArcRingsPainter()),
    );
  }
}

class _ArcRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radii = [100.0, 160.0, 220.0, 280.0];
    final opacities = [0.5, 0.4, 0.3, 0.2];
    final widths = [0.8, 0.7, 0.6, 0.5];

    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(
        Offset(size.width, 0),
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
//  Hex logo painter
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
