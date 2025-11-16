import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../widgets/post_card.dart';

class CommunityScreen extends StatefulWidget {
  static const route = '/community';
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _service = CommunityService();
  List<CommunityPost> _posts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final posts = await _service.loadFeed();
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openCreatePost() {
    Navigator.pushNamed(context, '/community/create').then((_) => _loadFeed());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('community_title')),
        actions: [
          IconButton(
            onPressed: _openCreatePost,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Erro: $_error'),
                      ),
                    ],
                  )
                : _posts.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhum post ainda. Seja o primeiro!'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return PostCard(
                            post: post,
                            onLike: () async {
                              final auth =
                                  context.read<AuthProvider>().user;
                              if (auth == null) return;
                              await _service.likePost(post.id, auth.id);
                              _loadFeed();
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
