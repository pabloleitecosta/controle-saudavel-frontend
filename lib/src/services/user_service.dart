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

  CollectionReference<Map<String, dynamic>> _mealsCollection(String userId) =>
      _usersCollection.doc(userId).collection('meals');

  CollectionReference<Map<String, dynamic>> _weightsCollection(
          String userId) =>
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
    String source = 'manual',
  }) async {
    await _ensureUserDoc(userId);
    await _mealsCollection(userId).add({
      'date': _dateFormatter.format(date),
      'items': items,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MealLog>> fetchMeals(String userId, {DateTime? date}) async {
    await _ensureUserDoc(userId);
    Query<Map<String, dynamic>> query = _mealsCollection(userId);
    if (date != null) {
      query = query.where('date', isEqualTo: _dateFormatter.format(date));
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    final snapshot = await query.get();
    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final log = MealLog.fromJson({
        'id': doc.id,
        'date': data['date'] ??
            _dateFormatter.format(createdAt ?? DateTime.now()),
        'items': (data['items'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        'totalCalories': (data['totalCalories'] ?? 0).toDouble(),
        'totalProtein': (data['totalProtein'] ?? 0).toDouble(),
        'totalCarbs': (data['totalCarbs'] ?? 0).toDouble(),
        'totalFat': (data['totalFat'] ?? 0).toDouble(),
        'source': data['source'] ?? 'manual',
      });
      return MapEntry(
        log,
        createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();

    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => entry.key).toList();
  }

  Future<UserInsights> fetchInsights(String userId) async {
    await _ensureUserDoc(userId);
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _mealsCollection(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) {
      return const UserInsights(
        mealsCount: 0,
        avgCalories: 0,
        avgProtein: 0,
        insights: [],
      );
    }

    double totalCalories = 0;
    double totalProtein = 0;

    for (final doc in docs) {
      final data = doc.data();
      totalCalories += (data['totalCalories'] ?? 0).toDouble();
      totalProtein += (data['totalProtein'] ?? 0).toDouble();
    }

    final avgCalories = totalCalories / docs.length;
    final avgProtein = totalProtein / docs.length;
    final insights = <String>[];

    if (avgCalories < 1400) {
      insights.add('Consuma mais calorias para atingir sua meta semanal.');
    } else if (avgCalories > 2600) {
      insights.add('Reduza um pouco as calorias para equilibrar a dieta.');
    }

    if (avgProtein < 60) {
      insights.add('Inclua fontes de proteina em mais refeicoes.');
    }

    if (docs.length < 10) {
      insights.add('Registre mais refeicoes para obter insights precisos.');
    }

    return UserInsights(
      mealsCount: docs.length,
      avgCalories: avgCalories,
      avgProtein: avgProtein,
      insights: insights,
    );
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
    await _ensureUserDoc(userId);

    double? calculatedTmb;
    double? calculatedTdee;
    double? dailyGoal;

    if (age != null && height != null && weight != null) {
      if (sex == 'feminino') {
        calculatedTmb =
            655 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
      } else {
        calculatedTmb =
            66 + (13.75 * weight) + (5.003 * height) - (6.75 * age);
      }

      calculatedTdee = calculatedTmb * activityLevel;

      switch (goal) {
        case 'perder':
          dailyGoal = calculatedTdee - 350;
          break;
        case 'ganhar':
          dailyGoal = calculatedTdee + 350;
          break;
        default:
          dailyGoal = calculatedTdee;
          break;
      }

      if (dailyGoal != null && dailyGoal < 1200) {
        dailyGoal = 1200;
      }
    }

    await _usersCollection.doc(userId).set({
      'age': age,
      'height': height,
      'weight': weight,
      'sex': sex,
      'goal': goal,
      'activityLevel': activityLevel,
      'tmb': calculatedTmb,
      'tdee': calculatedTdee,
      'dailyCaloriesGoal': dailyGoal,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<List<DailyMacroSummary>> fetchWeeklyMacros(String userId) async {
    await _ensureUserDoc(userId);
    final now = DateTime.now();
    final fromDate = now.subtract(const Duration(days: 6));

    final snapshot = await _mealsCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();

    final Map<String, DailyMacroSummary> aggregates = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date']?.toString();
      if (dateStr == null) continue;
      DateTime? parsed;
      try {
        parsed = DateTime.parse(dateStr);
      } catch (_) {
        parsed = null;
      }
      parsed ??= (data['createdAt'] as Timestamp?)?.toDate();
      if (parsed == null) continue;

      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      if (dateOnly.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        continue;
      }
      final key = _dateFormatter.format(dateOnly);
      final calories = (data['totalCalories'] ?? 0).toDouble();
      final protein = (data['totalProtein'] ?? 0).toDouble();
      final carbs = (data['totalCarbs'] ?? 0).toDouble();
      final fat = (data['totalFat'] ?? 0).toDouble();

      final existing = aggregates[key];
      if (existing == null) {
        aggregates[key] = DailyMacroSummary(
          date: dateOnly,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
      } else {
        aggregates[key] = DailyMacroSummary(
          date: dateOnly,
          calories: existing.calories + calories,
          protein: existing.protein + protein,
          carbs: existing.carbs + carbs,
          fat: existing.fat + fat,
        );
      }
    }

    final list = aggregates.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // garante 7 dias (preenche com zeros caso n�o existam registros)
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
    await _ensureUserDoc(userId);
    final snapshot = await _mealsCollection(userId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
