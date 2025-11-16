class UserInsights {
  final int mealsCount;
  final double avgCalories;
  final double avgProtein;
  final List<String> insights;

  const UserInsights({
    required this.mealsCount,
    required this.avgCalories,
    required this.avgProtein,
    required this.insights,
  });

  factory UserInsights.fromJson(Map<String, dynamic> json) {
    return UserInsights(
      mealsCount: (json['mealsCount'] ?? 0) as int,
      avgCalories: (json['avgCalories'] ?? 0).toDouble(),
      avgProtein: (json['avgProtein'] ?? 0).toDouble(),
      insights: (json['insights'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
