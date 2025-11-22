import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/daily_macro_summary.dart';
import '../models/meal_log.dart';
import '../models/nutrition_estimate.dart';
import '../models/user_insights.dart';
import '../models/weight_entry.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final ApiClient _api = ApiClient();

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> _weightsCollection(String userId) =>
      _usersCollection.doc(userId).collection('weights');

  // Criar perfil completo pela primeira vez
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    await _usersCollection.doc(userId).set({
      'name': name,
      'email': email,
      'age': null,
      'height': null,
      'weight': null,
      'sex': null,
      'goal': 'manter',
      'activityLevel': 1.2,
      'tmb': null,
      'tdee': null,
      'dailyCaloriesGoal': null,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Garante que o perfil existe para logins sociais
  Future<void> ensureUserProfile(User firebaseUser) async {
    final doc = await _usersCollection.doc(firebaseUser.uid).get();

    if (!doc.exists) {
      await createUserProfile(
        userId: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Usuario',
        email: firebaseUser.email ?? '',
      );
    }
  }

  // Buscar perfil
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    return doc.data();
  }

    Future<void> saveMeal({
    required String userId,
    required DateTime date,
    required List<Map<String, dynamic>> items,
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    String? mealType,
    String source = 'manual',
  }) async {
    final normalizedMealType = _canonicalMealType(mealType);
    await _api.post('/user/$userId/meals', {
      'date': _dateFormatter.format(date),
      'items': items,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'mealType': normalizedMealType,
      'source': source,
    });
  }

  Future<List<MealLog>> fetchMeals(String userId, {DateTime? date}) async {
    final response = await _api.get(
      '/user/$userId/meals',
      query: date != null ? {'date': _dateFormatter.format(date)} : null,
    );
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(MealLog.fromJson)
          .toList();
    }
    return const [];
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    await _api.delete('/user/$userId/meals/$mealId');
  }

  Future<UserInsights> fetchInsights(String userId) async {
    try {
      final res = await _api.get('/user/$userId/insights');
      if (res is Map<String, dynamic>) {
        return UserInsights(
          mealsCount: (res['mealsCount'] ?? 0).toInt(),
          avgCalories: (res['avgCalories'] ?? 0).toDouble(),
          avgProtein: (res['avgProtein'] ?? 0).toDouble(),
          insights: (res['insights'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
      }
    } catch (_) {
      // Fallback handled abaixo
    }

    return const UserInsights(
      mealsCount: 0,
      avgCalories: 0,
      avgProtein: 0,
      insights: [],
    );
  }

  Future<List<DailyMacroSummary>> fetchWeeklyMacros(String userId) async {
    // Calcula a partir das refeicoes retornadas pela API (sem acesso direto ao Firestore)
    final now = DateTime.now();
    final fromDate = now.subtract(const Duration(days: 6));

    final meals = await fetchMeals(userId);
    final Map<String, DailyMacroSummary> aggregates = {};

    for (final meal in meals) {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(meal.date);
      } catch (_) {
        parsed = null;
      }
      if (parsed == null) continue;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      if (dateOnly
          .isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        continue;
      }
      final key = _dateFormatter.format(dateOnly);
      final existing = aggregates[key];
      if (existing == null) {
        aggregates[key] = DailyMacroSummary(
          date: dateOnly,
          calories: meal.totalCalories,
          protein: meal.totalProtein,
          carbs: meal.totalCarbs,
          fat: meal.totalFat,
        );
      } else {
        aggregates[key] = DailyMacroSummary(
          date: dateOnly,
          calories: existing.calories + meal.totalCalories,
          protein: existing.protein + meal.totalProtein,
          carbs: existing.carbs + meal.totalCarbs,
          fat: existing.fat + meal.totalFat,
        );
      }
    }

    final list = aggregates.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // garante 7 dias (preenche com zeros caso nao existam registros)
    final Map<String, DailyMacroSummary> normalized = {
      for (final entry in list) _dateFormatter.format(entry.date): entry,
    };
    final result = <DailyMacroSummary>[];
    for (int i = 0; i < 7; i++) {
      final day = fromDate.add(Duration(days: i));
      final key = _dateFormatter.format(day);
      result.add(
        normalized[key] ??
            DailyMacroSummary(
              date: DateTime(day.year, day.month, day.day),
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
            ),
      );
    }

    return result;
  }

  Future<bool> hasAnyMeal(String userId) async {
    final meals = await fetchMeals(userId);
    return meals.isNotEmpty;
  }

  Future<void> _ensureUserDoc(String userId) async {
    final docRef = _usersCollection.doc(userId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateUserGoals({
    required String userId,
    int? age,
    double? height,
    double? weight,
    required String sex,
    required String goal,
    required double activityLevel,
  }) async {
    // Redireciona para API do backend (rota PUT /user/:id/profile)
    await _api.put('/user/$userId/profile', {
      'age': age,
      'height': height,
      'weight': weight,
      'sex': sex,
      'goal': goal,
      'activityLevel': activityLevel,
    });
  }

  Future<void> saveMealFromEstimate({
    required String userId,
    required DateTime date,
    required String mealType,
    required NutritionEstimate estimate,
  }) async {
    final items = estimate.items.map((item) {
      return {
        'label': item.label,
        'quantity': item.multiplier,
        'unit': item.servingUnit,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
      };
    }).toList();

    await saveMeal(
      userId: userId,
      date: date,
      items: items,
      totalCalories: estimate.totalCalories,
      totalProtein: estimate.totalProtein,
      totalCarbs: estimate.totalCarbs,
      totalFat: estimate.totalFat,
      mealType: mealType,
      source: 'photo-$mealType',
    );
  }

  Future<void> saveMealFromFood({
    required String userId,
    required DateTime date,
    required String mealType,
    required Map<String, dynamic> food,
  }) async {
    final dateStr = _dateFormatter.format(date);

    await _api.post("/user/$userId/meals", {
      "date": dateStr,
      "mealType": mealType,
      "items": [
        {
          "foodId": food['id'] ?? food['mappedFoodId'],
          "name": food['name'] ?? food['label'],
          "serving": food['serving_size'] ?? 1,
          "servingUnit": food['serving_unit'] ?? 'porcao',
          "calories": food['calories'],
          "protein": food['protein'],
          "carbs": food['carbs'],
          "fat": food['fat'],
        }
      ],
      "source": "food_search",
    });
  }

  Future<void> addWeightEntry({
    required String userId,
    required double weight,
    DateTime? date,
  }) async {
    await _ensureUserDoc(userId);
    final entryDate = date ?? DateTime.now();
    await _weightsCollection(userId).add({
      'weight': weight,
      'date': _dateFormatter.format(entryDate),
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<WeightEntry>> fetchWeightHistory(
    String userId, {
    int limit = 30,
  }) async {
    await _ensureUserDoc(userId);
    Query<Map<String, dynamic>> query =
        _weightsCollection(userId).orderBy('recordedAt', descending: true);
    if (limit > 0) {
      query = query.limit(limit);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(WeightEntry.fromSnapshot).toList();
  }

  String _canonicalMealType(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Personalizar Refeicoes';
    final norm = _normalize(value);
    if (norm.contains('manha')) return 'Cafe da manha';
    if (norm.contains('almo')) return 'Almoco';
    if (norm.contains('jantar')) return 'Jantar';
    if (norm.contains('lanche') || norm.contains('snack')) return 'Lanches/Outros';
    if (norm.contains('agua')) return 'Contador de agua';
    return 'Personalizar Refeicoes';
  }

  String _normalize(String value) {
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

