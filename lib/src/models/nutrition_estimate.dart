class NutritionEstimateItem {
  final String label;
  final double confidence;
  final String? mappedFoodId;
  double estimatedServing;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionEstimateItem({
    required this.label,
    required this.confidence,
    this.mappedFoodId,
    required this.estimatedServing,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionEstimateItem.fromJson(Map<String, dynamic> json) {
    return NutritionEstimateItem(
      label: json['label'],
      confidence: (json['confidence'] ?? 0).toDouble(),
      mappedFoodId: json['mapped_food_id'],
      estimatedServing: (json['estimated_serving'] ?? 0).toDouble(),
      servingUnit: json['serving_unit'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }
}

class NutritionEstimate {
  final List<NutritionEstimateItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  NutritionEstimate({
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory NutritionEstimate.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return NutritionEstimate(
      items:
          itemsJson.map((e) => NutritionEstimateItem.fromJson(e)).toList(),
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
    );
  }
}
