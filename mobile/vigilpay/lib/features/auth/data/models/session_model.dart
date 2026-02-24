import '../../domain/entities/session_entity.dart';

class SessionModel extends SessionEntity {
  const SessionModel({
    required super.userId,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    super.memberSince,
    super.accountType,
    super.loyaltyScore,
    super.riskProbability,
    super.riskTier,
    super.riskFactors,
    super.activeResolutions,
    super.suggestedProducts,
    super.creditScore,
    super.creditSummary,
    super.creditFactors,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final userInfo = json['user_info'];
    final riskAnalysis = json['risk_analysis'];
    final actionableItems = json['actionable_items'];
    final creditAnalysis = json['credit_analysis'];

    if (userInfo is Map<String, dynamic>) {
      final username = userInfo['username']?.toString() ?? '';
      final factorsRaw = riskAnalysis is Map<String, dynamic> ? riskAnalysis['factors'] : null;
      final activeRaw = actionableItems is Map<String, dynamic>
          ? actionableItems['active_resolutions']
          : null;
      final suggestedRaw = actionableItems is Map<String, dynamic>
          ? actionableItems['suggested_products']
          : null;
      final creditFactorsRaw = creditAnalysis is Map<String, dynamic>
          ? creditAnalysis['factors']
          : null;

      return SessionModel(
        userId: json['id']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? username,
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        memberSince: json['member_since']?.toString() ?? '',
        accountType: userInfo['type']?.toString() ?? 'standard',
        loyaltyScore: (userInfo['loyalty_score'] as num?)?.toDouble() ?? 0,
        riskProbability: riskAnalysis is Map<String, dynamic>
            ? (riskAnalysis['probability'] as num?)?.toDouble()
            : null,
        riskTier: riskAnalysis is Map<String, dynamic>
            ? riskAnalysis['tier']?.toString() ?? 'Low'
            : 'Low',
        riskFactors: factorsRaw is List
            ? factorsRaw.map((e) => e.toString()).toList(growable: false)
            : const <String>[],
        activeResolutions: activeRaw is List
            ? activeRaw.map((e) => e.toString()).toList(growable: false)
            : const <String>[],
        suggestedProducts: suggestedRaw is List
            ? suggestedRaw.map((e) => e.toString()).toList(growable: false)
            : const <String>[],
        creditScore: creditAnalysis is Map<String, dynamic>
            ? (creditAnalysis['score'] as num?)?.round() ?? 0
            : 0,
        creditSummary: creditAnalysis is Map<String, dynamic>
            ? creditAnalysis['summary']?.toString() ?? ''
            : '',
        creditFactors: creditFactorsRaw is List
            ? creditFactorsRaw
                .whereType<Map>()
                .map(
                  (raw) => CreditScoreFactor(
                    name: raw['name']?.toString() ?? '',
                    points: (raw['points'] as num?)?.toDouble() ?? 0.0,
                    maxPoints: (raw['max_points'] as num?)?.toDouble() ?? 0.0,
                    description: raw['description']?.toString() ?? '',
                  ),
                )
                .toList(growable: false)
            : const <CreditScoreFactor>[],
      );
    }

    final username = json['username']?.toString() ?? '';
    return SessionModel(
      userId: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? username,
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      memberSince: json['member_since']?.toString() ?? '',
      accountType: json['type']?.toString() ?? 'standard',
      loyaltyScore: (json['loyalty_score'] as num?)?.toDouble() ?? 0,
    );
  }
}
