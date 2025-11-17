import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/meal_log.dart';
import '../models/user_insights.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> _mealsCollection(String userId) =>
      _usersCollection.doc(userId).collection('meals');

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
}
