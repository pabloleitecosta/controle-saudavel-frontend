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

  CommunityPost copyWith({
    String? id,
    String? userName,
    String? text,
    String? imageUrl,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    int? likesCount,
    int? commentsCount,
    String? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CommunityComment {
  final String id;
  final String userName;
  final String text;
  final String createdAt;

  CommunityComment({
    required this.id,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Usuario',
      text: json['text']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class CommunityFeedResult {
  final List<CommunityPost> posts;
  final String? nextCursor;

  CommunityFeedResult({required this.posts, this.nextCursor});
}

class CommunityService {
  final String baseUrl;

  CommunityService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<CommunityFeedResult> loadFeed({
    int limit = 20,
    String? startAfter,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (startAfter != null) 'startAfter': startAfter,
    };
    final uri = Uri.parse('$baseUrl/community/feed')
        .replace(queryParameters: query);
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final postsJson = data['posts'] as List<dynamic>? ?? [];
      final posts = postsJson
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextCursor = data['nextCursor'] as String?;
      return CommunityFeedResult(posts: posts, nextCursor: nextCursor);
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

  Future<void> unlikePost(String postId, String userId) async {
    final uri = Uri.parse('$baseUrl/community/$postId/like');
    final request = http.Request('DELETE', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'userId': userId});
    final response = await http.Client().send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao remover like: ${response.statusCode}');
    }
  }

  Future<List<CommunityComment>> fetchComments(String postId) async {
    final uri = Uri.parse('$baseUrl/community/$postId/comments');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (data['comments'] as List<dynamic>? ?? [])
          .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    }
    throw Exception('Erro ao carregar comentarios: ${resp.statusCode}');
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    final uri = Uri.parse('$baseUrl/community/$postId/comments');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'text': text}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao comentar: ${resp.statusCode}');
    }
  }
}
