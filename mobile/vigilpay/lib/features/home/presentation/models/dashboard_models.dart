class HomeDashboardData {
  const HomeDashboardData({
    required this.userName,
    required this.accountType,
    required this.balanceUsd,
    required this.creditScore,
    required this.riskTier,
    required this.riskProbability,
    required this.offers,
    required this.transactions,
  });

  final String userName;
  final String accountType;
  final double balanceUsd;
  final int creditScore;
  final String riskTier;
  final double? riskProbability;
  final List<HomeOfferData> offers;
  final List<HomeTransactionData> transactions;
}

class HomeOfferData {
  const HomeOfferData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class HomeTransactionData {
  const HomeTransactionData({
    required this.title,
    required this.amountUsd,
    required this.timeLabel,
  });

  final String title;
  final double amountUsd;
  final String timeLabel;
}
