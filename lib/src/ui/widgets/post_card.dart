import 'package:flutter/material.dart';

import '../../services/community_service.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;
  final bool liked;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onTap,
    this.liked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    post.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    post.createdAt,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.text,
                style: const TextStyle(fontSize: 14),
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              if (_hasMacros(post)) ...[
                const SizedBox(height: 12),
                _MacroRow(post: post),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onLike,
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : null,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: onComment,
                    icon: const Icon(Icons.chat_bubble_outline),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('${post.commentsCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasMacros(CommunityPost post) =>
      post.totalCalories != null ||
      post.totalProtein != null ||
      post.totalCarbs != null ||
      post.totalFat != null;
}

class _MacroRow extends StatelessWidget {
  final CommunityPost post;

  const _MacroRow({required this.post});

  @override
  Widget build(BuildContext context) {
    final entries = <String, String>{};
    if (post.totalCalories != null) {
      entries['Cal'] = '${post.totalCalories!.toStringAsFixed(0)} kcal';
    }
    if (post.totalProtein != null) {
      entries['Prot'] = '${post.totalProtein!.toStringAsFixed(1)} g';
    }
    if (post.totalCarbs != null) {
      entries['Carb'] = '${post.totalCarbs!.toStringAsFixed(1)} g';
    }
    if (post.totalFat != null) {
      entries['Gord'] = '${post.totalFat!.toStringAsFixed(1)} g';
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: entries.entries
          .map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }
}
