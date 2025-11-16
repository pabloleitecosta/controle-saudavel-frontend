import 'food_item.dart';

class MealItem {
  final FoodItem food;
  double quantity; // multiplicador da porção base

  MealItem({required this.food, this.quantity = 1});
}

class Meal {
  final String id;
  final DateTime date;
  final List<MealItem> items;

  Meal({required this.id, required this.date, required this.items});

  double get totalCalories =>
      items.fold(0, (v, i) => v + i.food.calories * i.quantity);
}
