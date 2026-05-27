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
  final _imageCtrl = TextEditingController();
  final _videoCtrl = TextEditingController(); // CAMPO PARA VÍDEO
  bool _isLoading = false;
  String _previewImageUrl = '';

  @override
  void initState() {
    super.initState();
    _imageCtrl.addListener(() => setState(() => _previewImageUrl = _imageCtrl.text.trim()));
  }

  Future<void> _publishPost() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('posts').insert({
        'community_id': widget.communityId,
        'profile_id': Supabase.instance.client.auth.currentUser!.id,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'image_url': _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        'video_url': _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Título apelativo...'), maxLength: 100),
            const SizedBox(height: 16),
            
            TextField(controller: _imageCtrl, decoration: const InputDecoration(hintText: 'Link da Imagem (Opcional)')),
            if (_previewImageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(_previewImageUrl, height: 150, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Text('Imagem Inválida', style: TextStyle(color: Colors.red)))),
            ],
            const SizedBox(height: 16),
            
            TextField(controller: _videoCtrl, decoration: const InputDecoration(hintText: 'Link do Vídeo MP4 (Opcional)')),
            const SizedBox(height: 16),
            
            TextField(controller: _contentCtrl, maxLines: 6, decoration: const InputDecoration(hintText: 'O que tens em mente?')),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _publishPost,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
