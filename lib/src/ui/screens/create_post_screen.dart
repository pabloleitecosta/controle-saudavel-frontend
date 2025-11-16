import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';

class CreatePostScreen extends StatefulWidget {
  static const route = '/community/create';
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;

    if (_textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Digite algo para publicar.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = CommunityService();
      await service.createPost(
        userId: auth.id,
        text: _textCtrl.text.trim(),
      );

      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Compartilhe sua refeição, dica ou progresso',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
