import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../models/gamification_summary.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../services/gamification_service.dart';
import '../widgets/post_card.dart';

class CommunityScreen extends StatefulWidget {
  static const route = '/community';
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _service = CommunityService();
  final _gamificationService = GamificationService();
  final ScrollController _scrollController = ScrollController();
  static const _pageSize = 20;
  List<CommunityPost> _posts = [];
  GamificationSummary? _summary;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _error;
  final Set<String> _liked = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPosts(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _fetchPosts(loadMore: true);
    }
  }

  Future<void> _fetchPosts({bool loadMore = false, bool reset = false}) async {
    if (loadMore) {
      if (!_hasMore || _loadingMore) return;
      setState(() {
        _loadingMore = true;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
        if (reset) {
          _posts = [];
          _nextCursor = null;
          _hasMore = true;
          _liked.clear();
        }
      });
    }

    try {
      final feed = await _service.loadFeed(
        limit: _pageSize,
        startAfter: loadMore ? _nextCursor : null,
      );

      GamificationSummary? summary = _summary;
      if (!loadMore) {
        final user = context.read<AuthProvider>().user;
        if (user != null) {
          try {
            summary = await _gamificationService.getSummary(user.id);
          } catch (e) {
            debugPrint('Erro ao carregar gamificação: $e');
          }
        } else {
          summary = null;
        }
      }

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _posts = [..._posts, ...feed.posts];
        } else {
          _posts = feed.posts;
          _summary = summary;
        }
        _nextCursor = feed.nextCursor;
        _hasMore = feed.posts.length == _pageSize && feed.nextCursor != null;
      });
    } catch (e) {
      if (!mounted) return;
      if (loadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar mais posts: $e')),
        );
      } else {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (!mounted) return;
      if (loadMore) {
        setState(() {
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openCreatePost() {
    Navigator.pushNamed(context, '/community/create')
        .then((_) => _fetchPosts(reset: true));
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre para interagir com a comunidade.')),
      );
      return;
    }

    final liked = _liked.contains(post.id);
    try {
      if (liked) {
        await _service.unlikePost(post.id, user.id);
        _liked.remove(post.id);
      } else {
        await _service.likePost(post.id, user.id);
        _liked.add(post.id);
      }
      setState(() {
        _posts = _posts
            .map((p) {
              if (p.id != post.id) return p;
              final delta = liked ? -1 : 1;
              final updatedLikes = p.likesCount + delta;
              return p.copyWith(likesCount: updatedLikes < 0 ? 0 : updatedLikes);
            })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao curtir: $e')),
      );
    }
  }

  void _openComments(CommunityPost post) {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(
        post: post,
        service: _service,
        userId: user?.id,
      ),
    ).then((refresh) {
      if (refresh == true) {
        _fetchPosts(reset: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('community_title')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPosts(reset: true),
        child: _buildFeed(),
      ),
    );
  }

  Widget _buildFeed() {
    if (_loading && _posts.isEmpty) {
      return ListView(
        controller: _scrollController,
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null && _posts.isEmpty) {
      return ListView(
        controller: _scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro: $_error'),
          ),
          const SizedBox(height: 80),
        ],
      );
    }

    return ListView(
      controller: _scrollController,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro: $_error'),
          ),
        if (_summary != null) _SummaryCard(summary: _summary!),
        if (_posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhum post ainda. Seja o primeiro!'),
          )
        else
          ..._posts.map(
            (post) => PostCard(
              post: post,
              liked: _liked.contains(post.id),
              onLike: () => _toggleLike(post),
              onComment: () => _openComments(post),
            ),
          ),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final GamificationSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seus pontos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${summary.points}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Streak atual: ${summary.streak.current}'),
                  Text('Melhor: ${summary.streak.best}'),
                  Text('Badges: ${summary.achievements.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  final String? userId;

  const _CommentsSheet({
    required this.post,
    required this.service,
    required this.userId,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late Future<List<CommunityComment>> _future;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchComments(widget.post.id);
  }

  Future<void> _send() async {
    final userId = widget.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre para comentar.')),
      );
      return;
    }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await widget.service.addComment(
        postId: widget.post.id,
        userId: userId,
        text: text,
      );
      _commentCtrl.clear();
      setState(() {
        _future = widget.service.fetchComments(widget.post.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao comentar: $e')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<CommunityComment>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro: ${snapshot.error}'),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('Nenhum comentario ainda.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          title: Text(comment.userName),
                          subtitle: Text(comment.text),
                          trailing: Text(
                            comment.createdAt,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Escreva um comentario...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }
}
