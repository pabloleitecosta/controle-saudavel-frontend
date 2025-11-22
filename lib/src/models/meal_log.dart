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
      mealType: _canonicalMealType(json['mealType']?.toString()),
    );
  }

  static String _canonicalMealType(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Personalizar Refeicoes';
    final norm = _normalize(value);
    if (norm.contains('manha')) return 'Cafe da manha';
    if (norm.contains('almo')) return 'Almoco';
    if (norm.contains('jantar')) return 'Jantar';
    if (norm.contains('lanche') || norm.contains('snack')) {
      return 'Lanches/Outros';
    }
    if (norm.contains('agua')) return 'Contador de agua';
    return 'Personalizar Refeicoes';
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase();
    return lower
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00ec', 'i')
        .replaceAll('\u00ee', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00f2', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00f9', 'u')
        .replaceAll('\u00fb', 'u')
        .replaceAll('\u00e7', 'c');
  }
}
