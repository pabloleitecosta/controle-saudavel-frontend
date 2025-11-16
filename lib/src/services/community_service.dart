import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class CommunityPost {
  final String id;
  final String userName;
  final String text;
  final String? imageUrl;
  final double? totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final int likesCount;
  final int commentsCount;
  final String createdAt;

  CommunityPost({
    required this.id,
    required this.userName,
    required this.text,
    this.imageUrl,
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      userName: json['userName'] ?? 'Usuário',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'],
      totalCalories: (json['totalCalories'] as num?)?.toDouble(),
      totalProtein: (json['totalProtein'] as num?)?.toDouble(),
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble(),
      totalFat: (json['totalFat'] as num?)?.toDouble(),
      likesCount: (json['likesCount'] ?? 0) as int,
      commentsCount: (json['commentsCount'] ?? 0) as int,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class CommunityService {
  final String baseUrl;

  CommunityService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<List<CommunityPost>> loadFeed({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/community/feed?limit=$limit');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final postsJson = data['posts'] as List<dynamic>? ?? [];
      return postsJson
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Erro ao carregar feed: ${resp.statusCode}');
    }
  }

  Future<void> createPost({
    required String userId,
    required String text,
    String? imageUrl,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
  }) async {
    final uri = Uri.parse('$baseUrl/community/$userId/posts');
    final body = {
      'text': text,
      'imageUrl': imageUrl,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar post: ${resp.statusCode}');
    }
  }

  Future<void> likePost(String postId, String userId) async {
    final uri = Uri.parse('$baseUrl/community/$postId/like');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao curtir post: ${resp.statusCode}');
    }
  }
}
