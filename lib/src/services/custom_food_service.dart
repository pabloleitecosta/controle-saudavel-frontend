import '../core/api_client.dart';

class CustomFoodService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> list(String userId) async {
    final res = await _api.get('/food/custom/$userId');
    if (res is List) {
      return res
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (res is Map && res['items'] is List) {
      return (res['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> create(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final res = await _api.post('/food/custom/$userId', payload);
    return Map<String, dynamic>.from(res as Map);
  }
}
