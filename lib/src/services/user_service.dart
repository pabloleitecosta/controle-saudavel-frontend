import '../core/api_client.dart';
import '../models/meal_log.dart';
import '../models/user_insights.dart';

class UserService {
  final ApiClient _client = ApiClient();

  Future<List<MealLog>> fetchMeals(String userId, {DateTime? date}) async {
    final query = date != null
        ? {
            'date': date.toIso8601String().substring(0, 10),
          }
        : null;
    final data =
        await _client.get('/user/$userId/meals', query: query);
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
        .toList();
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
  }) {
    return _client.post('/user/$userId/meals', {
      'date': date.toIso8601String().substring(0, 10),
      'items': items,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'source': source,
    });
  }

  Future<UserInsights> fetchInsights(String userId) async {
    final data = await _client.get('/user/$userId/insights');
    return UserInsights.fromJson(data as Map<String, dynamic>);
  }
}
