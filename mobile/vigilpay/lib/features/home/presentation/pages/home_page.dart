import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_bottom_nav.dart';
import '../../../auth/presentation/provider/auth_controller.dart';
import '../mappers/home_dashboard_mapper.dart';
import '../widgets/home_error_banner.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_offers_row.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_risk_insight_card.dart';
import '../widgets/home_section_header.dart';
import '../widgets/home_transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().loadSession();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final dashboard = buildHomeDashboardData(
      session: auth.session,
      products: const [],
    );
    final errorMessage = auth.errorMessage;

    return Scaffold(
      backgroundColor: VigilColors.stone,
      bottomNavigationBar: const MainBottomNav(
        currentRoute: RouteConstants.home,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeroCard(
                  userName: dashboard.userName,
                  accountType: dashboard.accountType,
                  balanceUsd: dashboard.balanceUsd,
                  creditScore: dashboard.creditScore,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: HomeQuickActions(
                    onOpenSupport: () {
                      Navigator.pushNamed(context, RouteConstants.supportFeedback);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: HomeRiskInsightCard(
                    tier: dashboard.riskTier,
                    creditScore: dashboard.creditScore,
                    riskProbability: dashboard.riskProbability,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: HomeSectionHeader(title: 'For You', tag: 'Personalized'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 145,
                  child: HomeOffersRow(offers: dashboard.offers),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: HomeSectionHeader(title: 'Recent Transactions', tag: 'USD'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => HomeTransactionTile(
                      item: dashboard.transactions[index],
                    ),
                    childCount: dashboard.transactions.length,
                  ),
                ),
              ),
              if (errorMessage != null && errorMessage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: HomeErrorBanner(message: errorMessage),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}
