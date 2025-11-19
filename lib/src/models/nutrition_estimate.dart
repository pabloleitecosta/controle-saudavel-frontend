class NutritionEstimateItem {
  /// Rótulo do alimento detectado (ex.: "Frango grelhado")
  final String label;

  /// Confiança do modelo (0.0 a 1.0)
  final double confidence;

  /// ID do alimento mapeado na base (opcional)
  final String? mappedFoodId;

  /// Porção estimada pela IA (ex.: 150)
  final double estimatedServing;

  /// Unidade da porção (ex.: "g", "xíc.", "fatias")
  final String servingUnit;

  /// Valores nutricionais referentes à porção estimada original
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  /// Fator de multiplicação da porção (1.0 = porção original)
  ///
  /// Quando o usuário mexe no slider, alteramos esse multiplier,
  /// e recalculamos os totais com base nele.
  double multiplier;

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
    this.multiplier = 1.0,
  });

  factory NutritionEstimateItem.fromJson(Map<String, dynamic> json) {
    return NutritionEstimateItem(
      label: json['label'] as String,
      confidence: (json['confidence'] ?? 0).toDouble(),
      mappedFoodId: json['mapped_food_id'] as String?,
      estimatedServing: (json['estimated_serving'] ?? 0).toDouble(),
      servingUnit: (json['serving_unit'] ?? '') as String,
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      multiplier: 1.0,
    );
  }

  /// Totais considerando o multiplier aplicado
  double get totalCalories => calories * multiplier;
  double get totalProtein => protein * multiplier;
  double get totalCarbs => carbs * multiplier;
  double get totalFat => fat * multiplier;

  /// Porção exibida após ajuste (ex.: 1.5 x 100g = 150g)
  double get adjustedServing => estimatedServing * multiplier;
}

class NutritionEstimate {
  final List<NutritionEstimateItem> items;

  /// Totais atuais (considerando multiplier dos itens)
  double totalCalories;
  double totalProtein;
  double totalCarbs;
  double totalFat;

  NutritionEstimate({
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory NutritionEstimate.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    final items =
        itemsJson.map((e) => NutritionEstimateItem.fromJson(e)).toList();

    final estimate = NutritionEstimate(
      items: items,
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
    );

    // Garante que os totais estejam coerentes com o multiplier (1.0 inicialmente)
    estimate.recalculateTotals();
    return estimate;
  }

  /// Recalcula os totais com base nos itens (usado quando o usuário mexe no slider)
  void recalculateTotals() {
    double cals = 0;
    double prot = 0;
    double carb = 0;
    double fatTotal = 0;

    for (final item in items) {
      cals += item.totalCalories;
      prot += item.totalProtein;
      carb += item.totalCarbs;
      fatTotal += item.totalFat;
    }

    totalCalories = cals;
    totalProtein = prot;
    totalCarbs = carb;
    totalFat = fatTotal;
  }
}
