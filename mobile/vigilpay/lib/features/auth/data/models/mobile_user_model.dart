import '../../domain/entities/session_entity.dart';

class MobileUserModel extends SessionEntity {
  const MobileUserModel({
    required super.userId,
    required super.fullName,
    required super.email,
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

  factory MobileUserModel.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';
    final creditAnalysis = json['credit_analysis'];
    final creditFactorsRaw = creditAnalysis is Map<String, dynamic>
        ? creditAnalysis['factors']
        : null;
    return MobileUserModel(
      userId: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? username,
      email: json['email']?.toString() ?? '',
      accountType: json['type']?.toString() ?? 'standard',
      loyaltyScore: (json['loyalty_score'] as num?)?.toDouble() ?? 0,
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
}
