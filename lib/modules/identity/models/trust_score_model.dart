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
    final rawScore = json['score'] ?? json['trustScore'] ?? 50;
    final parsedScore = rawScore is int
        ? rawScore
        : (int.tryParse(rawScore.toString()) ?? 50);
    final rawTier = json['tier'] as String?;
    return TrustScoreModel(
      userId: json['userId']?.toString() ?? '',
      score: parsedScore,
      tier: (rawTier != null && rawTier.isNotEmpty)
          ? rawTier
          : computeTier(parsedScore),
      ledgerHistory: (json['history'] as List<dynamic>?)
              ?.map((e) => TrustLedgerEntry.fromJson(e))
              .toList() ??
          (json['ledgerEntries'] is List<dynamic>
              ? (json['ledgerEntries'] as List<dynamic>)
                  .map((e) => TrustLedgerEntry.fromJson(e))
                  .toList()
              : const []),
    );
  }

  static String computeTier(int score) {
    if (score >= 90) return 'Tier A+';
    if (score >= 75) return 'Tier A';
    if (score >= 50) return 'Tier B';
    return 'Tier C';
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
