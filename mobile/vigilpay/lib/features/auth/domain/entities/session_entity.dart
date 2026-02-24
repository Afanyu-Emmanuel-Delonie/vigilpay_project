class SessionEntity {
  const SessionEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.memberSince = '',
    this.accountType = 'standard',
    this.loyaltyScore = 0,
    this.riskProbability,
    this.riskTier = 'Low',
    this.riskFactors = const <String>[],
    this.activeResolutions = const <String>[],
    this.suggestedProducts = const <String>[],
    this.creditScore = 0,
    this.creditSummary = '',
    this.creditFactors = const <CreditScoreFactor>[],
  });

  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String memberSince;
  final String accountType;
  final double loyaltyScore;
  final double? riskProbability;
  final String riskTier;
  final List<String> riskFactors;
  final List<String> activeResolutions;
  final List<String> suggestedProducts;
  final int creditScore;
  final String creditSummary;
  final List<CreditScoreFactor> creditFactors;
}

class CreditScoreFactor {
  const CreditScoreFactor({
    required this.name,
    required this.points,
    required this.maxPoints,
    required this.description,
  });

  final String name;
  final double points;
  final double maxPoints;
  final String description;
}
