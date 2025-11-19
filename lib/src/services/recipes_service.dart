import '../core/api_client.dart';
import '../models/nutrition_estimate.dart';

class RecipesService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> listMyRecipes() async {
    final data = await _api.get('/api/recipes', query: {'type': 'mine'});
    return _parseList(data);
  }

  Future<List<Map<String, dynamic>>> exploreRecipes() async {
    final data = await _api.get('/api/recipes', query: {'type': 'explore'});
    return _parseList(data);
  }

  Future<void> createRecipe(Map<String, dynamic> data) async {
    await _api.post('/api/recipes', data);
  }

  Future<Map<String, dynamic>> getRecipe(String id) async {
    final res = await _api.get('/api/recipes/$id');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<NutritionEstimate?> refreshNutrition(String id) async {
    final res = await _api.post('/api/recipes/$id/nutrition/refresh', {});
    if (res == null) return null;
    final map = Map<String, dynamic>.from(res as Map);
    if (map['nutrition'] == null) return null;
    return NutritionEstimate.fromJson(
      Map<String, dynamic>.from(map['nutrition'] as Map),
    );
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return const [];
  }
}
