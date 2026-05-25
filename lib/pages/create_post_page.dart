import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostPage extends StatefulWidget {
  final String communityId;
  const CreatePostPage({super.key, required this.communityId});
  static Route<void> route(String commId) => MaterialPageRoute(builder: (_) => CreatePostPage(communityId: commId));

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _publishPost() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('posts').insert({
        'community_id': widget.communityId,
        'profile_id': Supabase.instance.client.auth.currentUser!.id,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao publicar.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Post')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Título apelativo...'),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(hintText: 'O que tens em mente? Partilha aqui...'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _publishPost,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
