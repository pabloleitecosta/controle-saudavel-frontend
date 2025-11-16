import 'package:flutter/material.dart';
import '../../services/community_service.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                post.text,
                style: const TextStyle(fontSize: 14),
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (post.totalCalories != null) ...[
                const SizedBox(height: 8),
                Text(
                  '≈ ${post.totalCalories!.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite_border),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, size: 20),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
