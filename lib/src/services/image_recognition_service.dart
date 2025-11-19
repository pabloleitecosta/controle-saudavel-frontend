import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/nutrition_estimate.dart';

class ImageRecognitionService {
  /// Envia a imagem para o backend que encapsula a IA.
  /// Para trocar o provedor (Hugging Face, Google Vision etc),
  /// atualize `AppConstants.apiBaseUrl` e as credenciais no backend (.env).
  Future<NutritionEstimate> recognize(File image) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/image/recognize');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body) as Map<String, dynamic>;
      return NutritionEstimate.fromJson(jsonData);
    } else {
      throw Exception('Erro ao reconhecer imagem: ${response.statusCode}');
    }
  }
}
