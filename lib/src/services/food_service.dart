import '../core/api_client.dart';
import '../models/food_item.dart';

class FoodService {
  final ApiClient _client = ApiClient();

  Future<List<FoodItem>> search(String query) async {
    final data = await _client.get('/food/search', query: {'q': query});
    return (data as List).map((e) => FoodItem.fromJson(e)).toList();
  }
}
