import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_bottom_nav.dart';
import '../../../auth/presentation/provider/auth_controller.dart';
import '../provider/products_controller.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

enum ProductType {
  savings,
  creditBuilder,
  loan,
  card,
  insurance,
  investment,
  resolution,
}

enum EligibilityStatus { eligible, nearEligible, notEligible }

class ProductRecommendation {
  const ProductRecommendation({
    required this.id,
    required this.name,
    required this.type,
    required this.benefitText,
    required this.eligibilityStatus,
    required this.displayReasons,
    required this.creditScoreProgress,
    this.balanceProgress,
    this.activityProgress,
    this.unmetRequirements = const [],
  });
  final String id;
  final String name;
  final ProductType type;
  final String benefitText;
  final EligibilityStatus eligibilityStatus;
  final List<String> displayReasons;
  final double creditScoreProgress;
  final double? balanceProgress;
  final double? activityProgress;
  final List<String> unmetRequirements;
}

// ── Mock data ──
const _kCreditScore = 612;
const _kRiskTier = 'Medium';
const _kHasActiveGoal = false;

final _eligibleNow = [
  const ProductRecommendation(
    id: 'p1',
    name: 'Emergency Buffer Savings',
    type: ProductType.savings,
    benefitText: 'Earn 8% p.a. with automatic top-ups',
    eligibilityStatus: EligibilityStatus.eligible,
    displayReasons: ['Strong activity score', 'Consistent deposits'],
    creditScoreProgress: 0.82,
    balanceProgress: 0.91,
  ),
  const ProductRecommendation(
    id: 'p2',
    name: 'Credit Builder Card',
    type: ProductType.creditBuilder,
    benefitText: 'Build your score with every purchase',
    eligibilityStatus: EligibilityStatus.eligible,
    displayReasons: ['Activity rate qualifies', 'Low complaint history'],
    creditScoreProgress: 0.68,
  ),
];

final _almostEligible = [
  const ProductRecommendation(
    id: 'p3',
    name: 'VigilPay Micro Loan',
    type: ProductType.loan,
    benefitText: 'Up to GHS 5,000 at 12% p.a.',
    eligibilityStatus: EligibilityStatus.nearEligible,
    displayReasons: ['Score 38 pts below threshold'],
    creditScoreProgress: 0.55,
    balanceProgress: 0.70,
    unmetRequirements: ['Credit score ≥ 650', 'Balance ≥ GHS 500'],
  ),
  const ProductRecommendation(
    id: 'p4',
    name: 'Gold Loyalty Card',
    type: ProductType.card,
    benefitText: '3× cashback on everyday spending',
    eligibilityStatus: EligibilityStatus.nearEligible,
    displayReasons: ['Loyalty score close to threshold'],
    creditScoreProgress: 0.61,
    unmetRequirements: ['Loyalty score ≥ 80'],
  ),
];

final _growthRecs = [
  const ProductRecommendation(
    id: 'p5',
    name: 'VigilShield Insurance',
    type: ProductType.insurance,
    benefitText: 'Protect your income from GHS 12/month',
    eligibilityStatus: EligibilityStatus.notEligible,
    displayReasons: ['Available after 6 months activity'],
    creditScoreProgress: 0.4,
    activityProgress: 0.3,
    unmetRequirements: ['6-month account history', 'Credit score ≥ 700'],
  ),
  const ProductRecommendation(
    id: 'p6',
    name: 'VigilInvest Starter',
    type: ProductType.investment,
    benefitText: 'Start investing from GHS 50',
    eligibilityStatus: EligibilityStatus.notEligible,
    displayReasons: ['Low risk score required'],
    creditScoreProgress: 0.35,
    unmetRequirements: ['Risk tier: Low', 'Credit score ≥ 720'],
  ),
];

const _goalPresets = [
  'Emergency Buffer',
  'Bill Stability Fund',
  'Credit Improvement Goal',
  'Custom',
];

// ═════════════════════════════════════════════════════════════════════════════
//  PRODUCTS PAGE
// ═════════════════════════════════════════════════════════════════════════════

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _goalCompleted = _kHasActiveGoal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMandatoryGoal();
      context.read<ProductsController>().loadProducts();
    });
  }

  int _creditScore() {
    final session = context.read<AuthController>().session;
    final score = session?.creditScore ?? 0;
    return score > 0 ? score : _kCreditScore;
  }

  String _riskTier() {
    final session = context.read<AuthController>().session;
    final tier = (session?.riskTier ?? '').trim();
    return tier.isEmpty ? _kRiskTier : tier;
  }

  void _checkMandatoryGoal() {
    if (_creditScore() < 650 && !_goalCompleted) {
      _showGoalSheet(mandatory: true);
    }
  }

  void _showGoalSheet({bool mandatory = false}) {
    showModalBottomSheet(
      context: context,
      isDismissible: !mandatory,
      enableDrag: !mandatory,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalSheet(
        mandatory: mandatory,
        onGoalCreated: () {
          setState(() => _goalCompleted = true);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _checkMandatoryGoal();
      context.read<ProductsController>().loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsCtrl = context.watch<ProductsController>();
    final score = _creditScore();
    final riskTier = _riskTier();
    final backendEligible = productsCtrl.products
        .map(
          (p) => ProductRecommendation(
            id: p.id,
            name: p.name,
            type: ProductType.savings,
            benefitText: 'From ${p.currency} ${p.price.toStringAsFixed(2)}',
            eligibilityStatus: EligibilityStatus.eligible,
            displayReasons: const ['Recommended from live catalog'],
            creditScoreProgress: (score / 850).clamp(0.2, 1.0),
          ),
        )
        .toList(growable: false);
    final eligibleNow = backendEligible.isNotEmpty ? backendEligible : _eligibleNow;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: VigilColors.stone,
      bottomNavigationBar: const MainBottomNav(
        currentRoute: RouteConstants.products,
      ),
      // ── FAB: Add Savings Goal ──
      floatingActionButton: _GoalFAB(
        goalActive: _goalCompleted,
        onTap: () => _showGoalSheet(mandatory: false),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: VigilColors.red,
        child: CustomScrollView(
          slivers: [
            // ── Hero Header ──
            SliverToBoxAdapter(
              child: _ProductsHeroHeader(
                topPadding: topPadding,
                goalCompleted: _goalCompleted,
                creditScore: score,
                riskTier: riskTier,
                eligibleCount: eligibleNow.length,
              ),
            ),

            // ── Body content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Goal linked banner
                  if (_goalCompleted) ...[
                    const _GoalLinkedBanner(),
                    const SizedBox(height: 16),
                  ],

                  // Eligible Now
                  _SectionLabel(
                    title: 'Eligible Now',
                    count: eligibleNow.length,
                    accentColor: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 10),
                  ...eligibleNow.map((p) => _ProductCard(
                    product: p,
                    goalCompleted: _goalCompleted,
                    creditScore: score,
                    onRequestGoal: () => _showGoalSheet(mandatory: false),
                  )),

                  const SizedBox(height: 20),

                  // Almost Eligible
                  _SectionLabel(
                    title: 'Almost Eligible',
                    count: _almostEligible.length,
                    accentColor: VigilColors.gold,
                  ),
                  const SizedBox(height: 10),
                  ..._almostEligible.map((p) => _ProductCard(
                    product: p,
                    goalCompleted: _goalCompleted,
                    creditScore: score,
                    onRequestGoal: () => _showGoalSheet(mandatory: false),
                  )),

                  const SizedBox(height: 20),

                  // Growth Recommendations
                  _SectionLabel(
                    title: 'Growth Opportunities',
                    count: _growthRecs.length,
                    accentColor: const Color(0xFF60A5FA),
                  ),
                  const SizedBox(height: 10),
                  ..._growthRecs.map((p) => _ProductCard(
                    product: p,
                    goalCompleted: _goalCompleted,
                    creditScore: score,
                    onRequestGoal: () => _showGoalSheet(mandatory: false),
                  )),

                  const SizedBox(height: 20),

                  // Tip card
                  const _BoostTipCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HERO HEADER — matches brand design system
// ═════════════════════════════════════════════════════════════════════════════

class _ProductsHeroHeader extends StatelessWidget {
  const _ProductsHeroHeader({
    required this.topPadding,
    required this.goalCompleted,
    required this.creditScore,
    required this.riskTier,
    required this.eligibleCount,
  });
  final double topPadding;
  final bool goalCompleted;
  final int creditScore;
  final String riskTier;
  final int eligibleCount;

  @override
  Widget build(BuildContext context) {
    final scoreColor = creditScore >= 700
        ? const Color(0xFF34D399)
        : creditScore >= 600
        ? VigilColors.gold
        : VigilColors.red;

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
          // Arc rings decoration
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
            padding: EdgeInsets.fromLTRB(22, topPadding + 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized for you',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const Text(
                          'Products',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Filter button
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                    height: 1, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _HeroStat(
                      label: 'Credit Score',
                      value: '$creditScore',
                      color: scoreColor,
                      icon: Icons.trending_up_rounded,
                    ),
                    _Divider(),
                    _HeroStat(
                      label: 'Risk Tier',
                      value: riskTier,
                      color: VigilColors.gold,
                      icon: Icons.shield_outlined,
                    ),
                    _Divider(),
                    _HeroStat(
                      label: 'Can Apply',
                      value: '$eligibleCount products',
                      color: const Color(0xFF34D399),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),

                // Goal gate notice
                if (creditScore < 650) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: goalCompleted
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: goalCompleted
                            ? const Color(0xFF34D399).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          goalCompleted
                              ? Icons.check_circle_rounded
                              : Icons.lock_outline_rounded,
                          size: 13,
                          color: goalCompleted
                              ? const Color(0xFF34D399)
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goalCompleted
                                ? 'Savings goal active — products unlocked'
                                : 'Set a savings goal to unlock product applications',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: goalCompleted
                                  ? const Color(0xFF34D399)
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FLOATING ACTION BUTTON
// ═════════════════════════════════════════════════════════════════════════════

class _GoalFAB extends StatelessWidget {
  const _GoalFAB({required this.goalActive, required this.onTap});
  final bool goalActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8C1515), Color(0xFF5A0D0D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VigilColors.red.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              goalActive ? 'Add Another Goal' : 'Add Savings Goal',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  GOAL LINKED BANNER
// ═════════════════════════════════════════════════════════════════════════════

class _GoalLinkedBanner extends StatelessWidget {
  const _GoalLinkedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_rounded,
                size: 16, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal linked to your growth plan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF059669),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Keep depositing to improve your score and unlock more products',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF4B7A5A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Color(0xFF059669)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.count,
    required this.accentColor,
  });
  final String title;
  final int count;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: VigilColors.navy,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: VigilColors.stoneMid),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PRODUCT CARD
// ═════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.goalCompleted,
    required this.creditScore,
    required this.onRequestGoal,
  });
  final ProductRecommendation product;
  final bool goalCompleted;
  final int creditScore;
  final VoidCallback onRequestGoal;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;

  Color _progressColor(double v) {
    if (v >= 0.75) return const Color(0xFF059669);
    if (v >= 0.5) return VigilColors.gold;
    return VigilColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final locked = widget.creditScore < 650 && !widget.goalCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductTypeIcon(type: p.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: VigilColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _EligibilityBadge(status: p.eligibilityStatus),
                        ],
                      ),
                      const SizedBox(height: 3),
                      _TypeLabel(type: p.type),
                      const SizedBox(height: 5),
                      Text(
                        p.benefitText,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: Color(0xFF777777),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Reason chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              children: p.displayReasons
                  .map((r) => _ReasonChip(
                label: r,
                isPositive: !r.toLowerCase().contains('below') &&
                    !r.toLowerCase().contains('pts'),
              ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Progress meters ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ProgressBar(
                  label: 'Credit Score',
                  progress: p.creditScoreProgress,
                  color: _progressColor(p.creditScoreProgress),
                ),
                if (p.balanceProgress != null) ...[
                  const SizedBox(height: 7),
                  _ProgressBar(
                    label: 'Balance',
                    progress: p.balanceProgress!,
                    color: _progressColor(p.balanceProgress!),
                  ),
                ],
                if (p.activityProgress != null) ...[
                  const SizedBox(height: 7),
                  _ProgressBar(
                    label: 'Activity',
                    progress: p.activityProgress!,
                    color: _progressColor(p.activityProgress!),
                  ),
                ],
              ],
            ),
          ),

          // ── Expandable requirements ──
          if (p.unmetRequirements.isNotEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded
                          ? 'Hide requirements'
                          : 'What to improve to qualify',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VigilColors.stone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: p.unmetRequirements
                        .map(
                          (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: VigilColors.red.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              req,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 14),
          Container(height: 1, color: VigilColors.stoneMid),

          // ── CTAs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _CardCTAs(
              status: p.eligibilityStatus,
              locked: locked,
              onApply: widget.onRequestGoal,
              onSetGoal: widget.onRequestGoal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Product card sub-widgets
// ─────────────────────────────────────────

class _ProductTypeIcon extends StatelessWidget {
  const _ProductTypeIcon({required this.type});
  final ProductType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (type) {
      ProductType.savings => (
      Icons.savings_outlined,
      const Color(0xFF059669),
      const Color(0xFFECFDF5)
      ),
      ProductType.creditBuilder => (
      Icons.trending_up_rounded,
      VigilColors.red,
      VigilColors.redMuted
      ),
      ProductType.loan => (
      Icons.account_balance_outlined,
      const Color(0xFF60A5FA),
      const Color(0xFFEFF6FF)
      ),
      ProductType.card => (
      Icons.credit_card_rounded,
      VigilColors.gold,
      const Color(0xFFFFFBEB)
      ),
      ProductType.insurance => (
      Icons.shield_outlined,
      const Color(0xFF8B5CF6),
      const Color(0xFFF5F3FF)
      ),
      ProductType.investment => (
      Icons.show_chart_rounded,
      const Color(0xFF34D399),
      const Color(0xFFECFDF5)
      ),
      ProductType.resolution => (
      Icons.handshake_outlined,
      VigilColors.gold,
      const Color(0xFFFFFBEB)
      ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});
  final ProductType type;

  static const _labels = {
    ProductType.savings: 'Savings',
    ProductType.creditBuilder: 'Credit Builder',
    ProductType.loan: 'Loan',
    ProductType.card: 'Card',
    ProductType.insurance: 'Insurance',
    ProductType.investment: 'Investment',
    ProductType.resolution: 'Resolution',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: VigilColors.stone,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VigilColors.stoneMid),
      ),
      child: Text(
        _labels[type] ?? '',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 9,
          color: Color(0xFF888888),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  const _EligibilityBadge({required this.status});
  final EligibilityStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      EligibilityStatus.eligible => (
      'Eligible',
      const Color(0xFF059669),
      const Color(0xFFECFDF5)
      ),
      EligibilityStatus.nearEligible => (
      'Near Eligible',
      VigilColors.gold,
      const Color(0xFFFFFBEB)
      ),
      EligibilityStatus.notEligible => (
      'Not Eligible',
      const Color(0xFF888888),
      VigilColors.stone
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
          color: color,
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.isPositive});
  final String label;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? const Color(0xFF059669) : VigilColors.red;
    final bg = isPositive ? const Color(0xFFECFDF5) : VigilColors.redMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_rounded : Icons.info_outline_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.progress,
    required this.color,
  });
  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: VigilColors.stoneMid,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CardCTAs extends StatelessWidget {
  const _CardCTAs({
    required this.status,
    required this.locked,
    required this.onApply,
    required this.onSetGoal,
  });
  final EligibilityStatus status;
  final bool locked;
  final VoidCallback onApply;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      EligibilityStatus.eligible => Row(
        children: [
          Expanded(
            child: _CTAButton(
              label: locked ? 'Set goal first' : 'Apply Now',
              isPrimary: true,
              isDisabled: locked,
              icon: locked
                  ? Icons.lock_outline_rounded
                  : Icons.arrow_forward_rounded,
              onTap: locked ? onSetGoal : onApply,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CTAButton(
              label: 'Learn More',
              isPrimary: false,
              icon: Icons.info_outline_rounded,
              onTap: () {},
            ),
          ),
        ],
      ),
      EligibilityStatus.nearEligible => Row(
        children: [
          Expanded(
            child: _CTAButton(
              label: 'Set Goal',
              isPrimary: true,
              icon: Icons.flag_outlined,
              onTap: onSetGoal,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CTAButton(
              label: 'Improve Eligibility',
              isPrimary: false,
              icon: Icons.trending_up_rounded,
              onTap: () {},
            ),
          ),
        ],
      ),
      EligibilityStatus.notEligible => _CTAButton(
        label: 'How to Qualify',
        isPrimary: false,
        icon: Icons.help_outline_rounded,
        onTap: () {},
        fullWidth: true,
      ),
    };
  }
}

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.label,
    required this.isPrimary,
    required this.icon,
    this.onTap,
    this.isDisabled = false,
    this.fullWidth = false,
  });
  final String label;
  final bool isPrimary;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isPrimary && !isDisabled
              ? const LinearGradient(
            colors: [Color(0xFF8C1515), Color(0xFF5A0D0D)],
          )
              : null,
          color: isPrimary
              ? (isDisabled ? VigilColors.stoneMid : null)
              : VigilColors.stone,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: VigilColors.stoneMid),
          boxShadow: isPrimary && !isDisabled
              ? [
            BoxShadow(
              color: VigilColors.red.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isPrimary
                  ? (isDisabled ? const Color(0xFFAAAAAA) : Colors.white)
                  : VigilColors.navy,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: isPrimary
                      ? (isDisabled ? const Color(0xFFAAAAAA) : Colors.white)
                      : VigilColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return btn;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  BOOST TIP CARD
// ═════════════════════════════════════════════════════════════════════════════

class _BoostTipCard extends StatelessWidget {
  const _BoostTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C1515), Color(0xFF2E1010)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: VigilColors.red.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded,
                size: 22, color: VigilColors.gold),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boost your score by 38 pts',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Deposit consistently for 4 weeks to unlock the Micro Loan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  GOAL SHEET (mandatory + voluntary)
// ═════════════════════════════════════════════════════════════════════════════

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.onGoalCreated, required this.mandatory});
  final VoidCallback onGoalCreated;
  final bool mandatory;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _goalNameCtrl = TextEditingController();
  final _targetAmountCtrl = TextEditingController();
  String _selectedPreset = _goalPresets[0];
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _isSubmitting = false;

  double get _targetAmount =>
      double.tryParse(_targetAmountCtrl.text.replaceAll(',', '')) ?? 0;
  int get _weeksRemaining =>
      _targetDate.difference(DateTime.now()).inDays ~/ 7;
  double get _weeklyContribution =>
      _weeksRemaining > 0 ? _targetAmount / _weeksRemaining : 0;
  double get _monthlyContribution => _weeklyContribution * 4;

  @override
  void initState() {
    super.initState();
    _goalNameCtrl.text = _goalPresets[0];
    _targetAmountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _goalNameCtrl.dispose();
    _targetAmountCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != 'Custom') _goalNameCtrl.text = preset;
    });
  }

  Future<void> _submit() async {
    if (_goalNameCtrl.text.trim().isEmpty ||
        _targetAmountCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      widget.onGoalCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VigilColors.stoneMid,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // Hero block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8C1515), Color(0xFF2E1010)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.savings_outlined,
                        size: 22, color: VigilColors.gold),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a Savings Goal',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Consistent saving improves your credit score and unlocks better products',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mandatory score callout
            if (widget.mandatory) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: VigilColors.redMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: VigilColors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 13, color: VigilColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your credit score is $_kCreditScore. A savings goal is required to access products.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: VigilColors.red,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Goal presets
            const _SheetLabel('Goal type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalPresets
                  .map((preset) => _PresetChip(
                label: preset,
                selected: _selectedPreset == preset,
                onTap: () => _selectPreset(preset),
              ))
                  .toList(),
            ),

            const SizedBox(height: 18),

            // Goal name
            const _SheetLabel('Goal name'),
            const SizedBox(height: 8),
            _SheetField(
              controller: _goalNameCtrl,
              hint: 'e.g. Emergency Buffer',
              enabled: _selectedPreset == 'Custom',
            ),

            const SizedBox(height: 14),

            // Target amount
            const _SheetLabel('Target amount (GHS)'),
            const SizedBox(height: 8),
            _SheetField(
              controller: _targetAmountCtrl,
              hint: '0.00',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 14),

            // Target date
            const _SheetLabel('Target date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now().add(const Duration(days: 14)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: VigilColors.stone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VigilColors.stoneMid),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFFAAAAAA)),
                    const SizedBox(width: 10),
                    Text(
                      '${_targetDate.day} ${_monthName(_targetDate.month)} ${_targetDate.year}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: VigilColors.navy,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: Color(0xFFCCCCCC)),
                  ],
                ),
              ),
            ),

            // Auto-calc contribution
            if (_targetAmount > 0 && _weeksRemaining > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 12, color: Color(0xFF059669)),
                        SizedBox(width: 6),
                        Text(
                          'Suggested contributions',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ContribTile(
                            label: 'Weekly',
                            amount:
                            'GHS ${_weeklyContribution.toStringAsFixed(2)}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContribTile(
                            label: 'Monthly',
                            amount:
                            'GHS ${_monthlyContribution.toStringAsFixed(2)}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContribTile(
                            label: 'Weeks left',
                            amount: '$_weeksRemaining wks',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_goalNameCtrl.text.trim().isNotEmpty &&
                    _targetAmountCtrl.text.trim().isNotEmpty &&
                    !_isSubmitting)
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VigilColors.red,
                  disabledBackgroundColor: VigilColors.stoneMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Create Savings Goal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            if (!widget.mandatory) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text(
                    'Go back',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Goal sheet sub-widgets
// ─────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? VigilColors.redMuted : VigilColors.stone,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? VigilColors.red.withValues(alpha: 0.4)
                : VigilColors.stoneMid,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
            color: selected ? VigilColors.red : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _ContribTile extends StatelessWidget {
  const _ContribTile({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF059669).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: VigilColors.navy,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? VigilColors.stone : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VigilColors.stoneMid),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: VigilColors.navy,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ARC RINGS
// ═════════════════════════════════════════════════════════════════════════════

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

// ═════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═════════════════════════════════════════════════════════════════════════════

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
}
