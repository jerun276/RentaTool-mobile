class TrustScoreModel {
  final String userId;
  final int score;
  final String tier;
  final List<TrustLedgerEntry> ledgerHistory;

  const TrustScoreModel({
    required this.userId,
    required this.score,
    required this.tier,
    this.ledgerHistory = const [],
  });

  factory TrustScoreModel.fromJson(Map<String, dynamic> json) {
    return TrustScoreModel(
      userId: json['userId'] ?? '',
      score: json['score'] ?? json['trustScore'] ?? 50,
      tier: json['tier'] ?? 'Tier B',
      ledgerHistory: (json['history'] as List<dynamic>?)
              ?.map((e) => TrustLedgerEntry.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TrustLedgerEntry {
  final String id;
  final int changeAmount;
  final String reason;
  final String reference;
  final int resultingScore;
  final String? createdAtUtc;

  const TrustLedgerEntry({
    required this.id,
    required this.changeAmount,
    required this.reason,
    required this.reference,
    required this.resultingScore,
    this.createdAtUtc,
  });

  factory TrustLedgerEntry.fromJson(Map<String, dynamic> json) {
    return TrustLedgerEntry(
      id: json['id'] ?? '',
      changeAmount: json['changeAmount'] ?? 0,
      reason: json['reason'] ?? '',
      reference: json['reference'] ?? '',
      resultingScore: json['resultingScore'] ?? 50,
      createdAtUtc: json['createdAtUtc'],
    );
  }
}
