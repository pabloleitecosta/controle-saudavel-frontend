import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/gamification_summary.dart';

class GamificationService {
  final String baseUrl;

  GamificationService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<GamificationSummary> getSummary(String userId) async {
    final uri = Uri.parse('$baseUrl/gamification/$userId/summary');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      return GamificationSummary.fromJson(jsonMap);
    } else {
      throw Exception('Erro ao carregar gamificação: ${resp.statusCode}');
    }
  }
}
