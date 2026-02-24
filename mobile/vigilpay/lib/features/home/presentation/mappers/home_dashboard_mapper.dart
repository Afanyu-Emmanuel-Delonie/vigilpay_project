import '../../../auth/domain/entities/session_entity.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../models/dashboard_models.dart';

HomeDashboardData buildHomeDashboardData({
  required SessionEntity? session,
  required List<ProductEntity> products,
}) {
  final userName = (session?.fullName.trim().isNotEmpty ?? false)
      ? session!.fullName.trim()
      : 'Customer';

  final accountTypeRaw = session?.accountType.trim().isNotEmpty == true
      ? session!.accountType.trim()
      : 'standard';
  final accountType = _titleCase(accountTypeRaw);

  final riskTierRaw = session?.riskTier.trim().isNotEmpty == true
      ? session!.riskTier.trim()
      : 'Low';
  final riskTier = _titleCase(riskTierRaw);

  final loyalty = session?.loyaltyScore ?? 0;
  final seedSource = '${session?.userId ?? ''}|${session?.email ?? ''}|$userName';
  final seed = seedSource.codeUnits.fold<int>(0, (a, b) => a + b);

  final baseBalance = 1800 + (seed % 9200) + (loyalty * 130).round();
  final tierBoost = switch (accountTypeRaw.toLowerCase()) {
    'pro' => 1.75,
    'premium' => 1.45,
    _ => 1.0,
  };
  final balanceUsd = baseBalance * tierBoost;

  final riskProbability = session?.riskProbability;
  final creditScore = _resolveCreditScore(
    fromBackend: session?.creditScore ?? 0,
    riskProbability: riskProbability,
    loyalty: loyalty,
    seed: seed,
  );

  final offers = _resolveOffers(
    session: session,
    products: products,
    accountType: accountType,
  );

  return HomeDashboardData(
    userName: userName,
    accountType: accountType,
    balanceUsd: balanceUsd,
    creditScore: creditScore,
    riskTier: riskTier,
    riskProbability: riskProbability,
    offers: offers,
    transactions: _dummyTransactions(accountType),
  );
}

int _resolveCreditScore({
  required int fromBackend,
  required double? riskProbability,
  required double loyalty,
  required int seed,
}) {
  if (fromBackend > 0) {
    return fromBackend.clamp(300, 850);
  }

  if (riskProbability != null) {
    final score = (850 - (riskProbability.clamp(0.0, 1.0) * 320)).round();
    return score.clamp(300, 850);
  }

  final base = 620 + ((loyalty * 12).round()) + (seed % 55);
  return base.clamp(300, 850);
}

List<HomeOfferData> _resolveOffers({
  required SessionEntity? session,
  required List<ProductEntity> products,
  required String accountType,
}) {
  final offers = <HomeOfferData>[];

  for (final item in session?.suggestedProducts ?? const <String>[]) {
    offers.add(HomeOfferData(title: item, subtitle: 'Recommended for your profile'));
  }

  for (final item in session?.activeResolutions ?? const <String>[]) {
    offers.add(HomeOfferData(title: item, subtitle: 'Active support benefit'));
  }

  for (final product in products.take(2)) {
    offers.add(
      HomeOfferData(
        title: product.name,
        subtitle: 'From \$${product.price.toStringAsFixed(2)} USD',
      ),
    );
  }

  if (offers.isNotEmpty) {
    return offers;
  }

  final fallback = switch (accountType.toLowerCase()) {
    'pro' => const <HomeOfferData>[
        HomeOfferData(
          title: 'Premium Credit Line',
          subtitle: 'Pre-qualified based on your account history',
        ),
        HomeOfferData(
          title: 'International Transfer Discount',
          subtitle: 'Reduced fees on selected transfer corridors',
        ),
      ],
    'premium' => const <HomeOfferData>[
        HomeOfferData(
          title: 'Card Upgrade Offer',
          subtitle: 'Upgrade to a higher cashback tier',
        ),
        HomeOfferData(
          title: 'Savings Booster',
          subtitle: 'Earn bonus interest for the first 90 days',
        ),
      ],
    _ => const <HomeOfferData>[
        HomeOfferData(
          title: 'Build Credit Starter',
          subtitle: 'Improve your score with guided payments',
        ),
        HomeOfferData(
          title: 'Essential Protection Plan',
          subtitle: 'Stay covered with low-cost account protection',
        ),
      ],
  };

  return fallback;
}

List<HomeTransactionData> _dummyTransactions(String accountType) {
  final salary = accountType.toLowerCase() == 'pro' ? 4200.00 : 2800.00;
  return <HomeTransactionData>[
    HomeTransactionData(
      title: 'Payroll Deposit',
      amountUsd: salary,
      timeLabel: 'Today, 08:20',
    ),
    const HomeTransactionData(
      title: 'Groceries',
      amountUsd: -84.65,
      timeLabel: 'Today, 12:15',
    ),
    const HomeTransactionData(
      title: 'Utility Bill',
      amountUsd: -129.40,
      timeLabel: 'Yesterday, 19:03',
    ),
    const HomeTransactionData(
      title: 'Coffee Shop',
      amountUsd: -6.90,
      timeLabel: 'Yesterday, 09:30',
    ),
    const HomeTransactionData(
      title: 'Transfer Received',
      amountUsd: 240.00,
      timeLabel: 'Mon, 13:11',
    ),
  ];
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
