class MealLogItem {
  final String label;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealLogItem({
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    return MealLogItem(
      label: json['label']?.toString() ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }
}

class MealLog {
  final String id;
  final String date;
  final List<MealLogItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String source;
  final String mealType;

  MealLog({
    required this.id,
    required this.date,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.source,
    required this.mealType,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? [])
        .map((item) => MealLogItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return MealLog(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      items: rawItems,
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
      totalProtein: (json['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (json['totalCarbs'] ?? 0).toDouble(),
      totalFat: (json['totalFat'] ?? 0).toDouble(),
      source: json['source']?.toString() ?? 'manual',
      mealType: json['mealType']?.toString() ?? 'Café da manhã',
    );
  }
}
