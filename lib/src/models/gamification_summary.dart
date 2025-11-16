class StreakInfo {
  final int current;
  final int best;
  final String? lastDate;

  StreakInfo({
    required this.current,
    required this.best,
    this.lastDate,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      current: (json['current'] ?? 0) as int,
      best: (json['best'] ?? 0) as int,
      lastDate: json['lastDate'] as String?,
    );
  }
}

class GamificationSummary {
  final int points;
  final StreakInfo streak;
  final List<String> achievements;

  GamificationSummary({
    required this.points,
    required this.streak,
    required this.achievements,
  });

  factory GamificationSummary.fromJson(Map<String, dynamic> json) {
    return GamificationSummary(
      points: (json['points'] ?? 0) as int,
      streak: StreakInfo.fromJson(json['streak'] ?? {}),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
