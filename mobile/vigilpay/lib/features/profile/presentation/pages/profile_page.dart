import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_bottom_nav.dart';
import '../../../../core/widgets/vigil_page_app_bar.dart';
import '../../../auth/domain/entities/session_entity.dart';
import '../../../auth/presentation/provider/auth_controller.dart';

const _kTransactions = 284;
const _kTotalSpent = 'GHS 42,810';
const _kCashbackEarned = 'GHS 1,240';
const _kMonthlyValues = <double>[0.55, 0.72, 0.88, 0.65, 1.0, 0.34];
const _kMonthlyLabels = <String>['5.5k', '7.2k', '8.8k', '6.5k', '9.4k', '3.2k'];
const _kMonthlyMonths = <String>['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().loadSession();
      _ringCtrl.forward();
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthController>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteConstants.login, (route) => false);
  }

  void _showCreditBreakdown(_ProfileData data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreditBreakdownSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _ProfileData.fromSession(context.watch<AuthController>().session);

    return Scaffold(
      backgroundColor: VigilColors.stone,
      appBar: VigilPageAppBar(
        title: 'My Profile',
        subtitle: 'Account',
        actions: [
          VigilAppBarAction(
            icon: Icons.query_stats_rounded,
            onTap: () => _showCreditBreakdown(data),
            tooltip: 'Credit score breakdown',
          ),
          VigilAppBarAction(icon: Icons.edit_outlined, onTap: () {}, tooltip: 'Edit profile'),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentRoute: RouteConstants.profile),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _HeroCard(data: data, ringAnim: _ringAnim),
          const SizedBox(height: 14),
          _StatsRow(data: data),
          const SizedBox(height: 14),
          const _SectionLabel('Account Details'),
          const SizedBox(height: 10),
          _DetailsCard(data: data),
          const SizedBox(height: 14),
          const _SectionLabel('Quick Actions'),
          const SizedBox(height: 10),
          _QuickActions(onSupport: () => Navigator.pushNamed(context, RouteConstants.supportFeedback)),
          const SizedBox(height: 14),
          const _SectionLabel('Activity Summary'),
          const SizedBox(height: 10),
          const _ActivityCard(),
          const SizedBox(height: 24),
          _LogoutButton(onTap: _logout),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
    required this.accountType,
    required this.loyaltyScore,
    required this.riskTier,
    required this.riskProbability,
    required this.creditScore,
    required this.creditSummary,
    required this.creditFactors,
  });

  final String name;
  final String email;
  final String phone;
  final String memberSince;
  final String accountType;
  final double loyaltyScore;
  final String riskTier;
  final double riskProbability;
  final int creditScore;
  final String creditSummary;
  final List<CreditScoreFactor> creditFactors;

  factory _ProfileData.fromSession(SessionEntity? session) {
    final name = (session?.fullName ?? '').trim();
    final email = (session?.email ?? '').trim();
    final phone = (session?.phoneNumber ?? '').trim();
    final memberSince = (session?.memberSince ?? '').trim();
    return _ProfileData(
      name: name.isEmpty ? (email.isEmpty ? 'VigilPay User' : email) : name,
      email: email.isEmpty ? '-' : email,
      phone: phone.isEmpty ? '-' : phone,
      memberSince: memberSince.isEmpty ? '-' : _formatMemberSince(memberSince),
      accountType: _titleCase(session?.accountType ?? 'standard'),
      loyaltyScore: session?.loyaltyScore ?? 0,
      riskTier: _titleCase(session?.riskTier ?? 'low'),
      riskProbability: session?.riskProbability ?? 0,
      creditScore: session?.creditScore ?? 0,
      creditSummary: session?.creditSummary ?? '',
      creditFactors: session?.creditFactors ?? const <CreditScoreFactor>[],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.ringAnim});
  final _ProfileData data;
  final Animation<double> ringAnim;

  @override
  Widget build(BuildContext context) {
    return _Card(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: AnimatedBuilder(
              animation: ringAnim,
              builder: (_, __) => CustomPaint(
                painter: _LoyaltyRingPainter(progress: (data.loyaltyScore / 100) * ringAnim.value),
                child: Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: VigilColors.redMuted,
                    child: Text(
                      _initials(data.name),
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 20, color: VigilColors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: VigilColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 11, color: Color(0xFFAAAAAA)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(data.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF888888))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(text: data.accountType, icon: Icons.workspace_premium_rounded, bg: const [Color(0xFF8C1515), Color(0xFF5A0D0D)], fg: Colors.white, iconColor: VigilColors.gold, gradient: true),
                    const SizedBox(width: 8),
                    _Chip(text: '${data.loyaltyScore.toStringAsFixed(1)} pts', icon: Icons.bolt_rounded, bg: const [Color(0xFFFFFBEB), Color(0xFFFFFBEB)], fg: VigilColors.gold, iconColor: VigilColors.gold),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});
  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _MiniStat(icon: Icons.swap_horiz_rounded, label: 'Transactions', value: '$_kTransactions', bg: Color(0xFFEFF6FF), fg: Color(0xFF60A5FA))),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(icon: Icons.trending_up_rounded, label: 'Total Spent', value: _kTotalSpent, bg: Color(0xFFECFDF5), fg: Color(0xFF34D399))),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(icon: Icons.savings_outlined, label: 'Cashback', value: _kCashbackEarned, bg: Color(0xFFFFFBEB), fg: VigilColors.gold)),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.data});
  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: data.phone),
          _DetailRow(icon: Icons.calendar_today_outlined, label: 'Member since', value: data.memberSince),
          _DetailRow(icon: Icons.shield_outlined, label: 'Risk tier', value: data.riskTier, valueColor: const Color(0xFF059669)),
          _DetailRow(icon: Icons.analytics_outlined, label: 'Risk probability', value: '${data.riskProbability.toStringAsFixed(1)}%', last: true),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSupport});
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        const _ActionTile(icon: Icons.lock_outline_rounded, label: 'Change PIN', bg: Color(0xFFEFF6FF), fg: Color(0xFF60A5FA)),
        const _ActionTile(icon: Icons.notifications_outlined, label: 'Alerts', bg: Color(0xFFFFFBEB), fg: Color(0xFFF59E0B)),
        const _ActionTile(icon: Icons.link_rounded, label: 'Linked Accounts', bg: Color(0xFFECFDF5), fg: Color(0xFF34D399)),
        _ActionTile(icon: Icons.help_outline_rounded, label: 'Support', bg: VigilColors.redMuted, fg: VigilColors.red, onTap: onSupport),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monthly spending', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: VigilColors.navy)),
              const Spacer(),
              Text('Last 6 months', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 14),
          const _Bars(),
          const SizedBox(height: 14),
          Container(height: 1, color: VigilColors.stoneMid),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _FootStat(label: 'Avg / month', value: 'GHS 7,135')),
              _Divider(),
              Expanded(child: _FootStat(label: 'Highest month', value: 'GHS 9,402')),
              _Divider(),
              Expanded(child: _FootStat(label: 'This month', value: 'GHS 3,210')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: VigilColors.redMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VigilColors.red.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 17, color: VigilColors.red),
            SizedBox(width: 8),
            Text('Log Out', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: VigilColors.red)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.iconColor,
    this.gradient = false,
  });
  final String text;
  final IconData icon;
  final List<Color> bg;
  final Color fg;
  final Color iconColor;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: gradient ? null : bg.first,
        gradient: gradient ? LinearGradient(colors: bg) : null,
        borderRadius: BorderRadius.circular(999),
        border: gradient ? null : Border.all(color: VigilColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 10, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return _Card(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: VigilColors.navy)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: VigilColors.stone, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 15, color: const Color(0xFF888888)),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF777777))),
              const Spacer(),
              Text(value, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: valueColor ?? VigilColors.navy)),
            ],
          ),
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(height: 1, color: VigilColors.stoneMid),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: _Card(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: VigilColors.navy))),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_kMonthlyMonths.length, (i) {
          final isMax = _kMonthlyValues[i] == 1.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _kMonthlyLabels[i],
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w600, color: isMax ? VigilColors.red : const Color(0xFFBBBBBB)),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600 + (i * 80)),
                    curve: Curves.easeOutCubic,
                    height: 52 * _kMonthlyValues[i],
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isMax
                            ? const [VigilColors.red, Color(0xFF5A0D0D)]
                            : [VigilColors.red.withValues(alpha: 0.25), VigilColors.red.withValues(alpha: 0.1)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(_kMonthlyMonths[i], style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFFAAAAAA))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FootStat extends StatelessWidget {
  const _FootStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 11.5, color: VigilColors.navy)),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Color(0xFFAAAAAA))),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: VigilColors.stoneMid,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: VigilColors.navy)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: VigilColors.stoneMid)),
      ],
    );
  }
}

class _CreditBreakdownSheet extends StatelessWidget {
  const _CreditBreakdownSheet({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D7D7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Credit Score: ${data.creditScore}',
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: VigilColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.creditSummary.isEmpty
                    ? 'Score is calculated from loyalty, activity, balance, and complaint status.'
                    : data.creditSummary,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Color(0xFF777777),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.creditFactors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = data.creditFactors[i];
                    final positive = f.points >= 0;
                    final pointsLabel = positive
                        ? '+${f.points.toStringAsFixed(f.points % 1 == 0 ? 0 : 2)}'
                        : f.points.toStringAsFixed(f.points % 1 == 0 ? 0 : 2);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: VigilColors.navy,
                                  ),
                                ),
                              ),
                              Text(
                                pointsLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: positive ? const Color(0xFF059669) : VigilColors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.description,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.8,
                              color: Color(0xFF6E6E6E),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: VigilColors.redMuted, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.logout_rounded, size: 26, color: VigilColors.red),
            ),
            const SizedBox(height: 18),
            const Text('Log Out', style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w900, fontSize: 20, color: VigilColors.navy)),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to log out of your VigilPay account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF888888), height: 1.55),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(color: VigilColors.stone, borderRadius: BorderRadius.circular(12), border: Border.all(color: VigilColors.stoneMid)),
                      child: const Center(child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: VigilColors.navy))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8C1515), Color(0xFF5A0D0D)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: VigilColors.red.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Log Out', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyRingPainter extends CustomPainter {
  const _LoyaltyRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = VigilColors.red.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8C1515), VigilColors.red]).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LoyaltyRingPainter oldDelegate) => oldDelegate.progress != progress;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'VP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String _formatMemberSince(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[parsed.month - 1]} ${parsed.year}';
}

String _titleCase(String value) {
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return value;
  return v[0].toUpperCase() + v.substring(1);
}
