import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:my_chat_app/pages/profile_page.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailPage({super.key, required this.post});
  static Route<void> route(Map<String, dynamic> postMap) => MaterialPageRoute(builder: (_) => PostDetailPage(post: postMap));

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentCtrl = TextEditingController();
  final _gifCtrl = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _commentsStream;
  Map<String, dynamic>? _postAuthorProfile;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  bool _isLiked = false;
  int _likesCount = 0;
  String? _replyingToId;
  String? _replyingToName;
  VideoPlayerController? _videoCtrl;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post['likes'] ?? 0;
    _fetchAuthor();
    _checkLike();
    
    // Inicia o vídeo se existir
    if (widget.post['video_url'] != null) {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.post['video_url']))
        ..initialize().then((_) {
          setState(() {});
          _videoCtrl!.play();
          _videoCtrl!.setLooping(true);
        });
    }

    _commentsStream = Supabase.instance.client.from('comments').stream(primaryKey: ['id']).eq('post_id', widget.post['id']).order('created_at', ascending: true);
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchAuthor() async {
    final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.post['profile_id']).single();
    if (mounted) setState(() => _postAuthorProfile = data);
  }

  Future<void> _checkLike() async {
    final res = await Supabase.instance.client.from('post_likes').select().eq('post_id', widget.post['id']).eq('profile_id', _currentUserId);
    if (res.isNotEmpty && mounted) setState(() => _isLiked = true);
  }

  Future<void> _toggleLike() async {
    if (_isLiked) {
      await Supabase.instance.client.from('post_likes').delete().eq('post_id', widget.post['id']).eq('profile_id', _currentUserId);
      await Supabase.instance.client.from('posts').update({'likes': _likesCount - 1}).eq('id', widget.post['id']);
      setState(() { _isLiked = false; _likesCount--; });
    } else {
      await Supabase.instance.client.from('post_likes').insert({'post_id': widget.post['id'], 'profile_id': _currentUserId});
      await Supabase.instance.client.from('posts').update({'likes': _likesCount + 1}).eq('id', widget.post['id']);
      setState(() { _isLiked = true; _likesCount++; });
      
      // Notificação de Like
      if (widget.post['profile_id'] != _currentUserId) {
        await Supabase.instance.client.from('notifications').insert({
          'profile_id': widget.post['profile_id'],
          'content': 'Alguém gostou do teu post: "${widget.post['title']}"',
          'post_id': widget.post['id']
        });
      }
    }
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty && _gifCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('comments').insert({
        'post_id': widget.post['id'],
        'profile_id': _currentUserId,
        'content': _commentCtrl.text.trim(),
        'gif_url': _gifCtrl.text.trim().isEmpty ? null : _gifCtrl.text.trim(),
        'parent_id': _replyingToId,
      });
      
      // Notificação de Comentário
      if (widget.post['profile_id'] != _currentUserId) {
        await Supabase.instance.client.from('notifications').insert({
          'profile_id': widget.post['profile_id'],
          'content': 'Novo comentário no teu post: "${widget.post['title']}"',
          'post_id': widget.post['id']
        });
      }

      setState(() { _commentCtrl.clear(); _gifCtrl.clear(); _replyingToId = null; _replyingToName = null; });
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao comentar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_postAuthorProfile != null)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(ProfilePage.route(_postAuthorProfile!['id'])),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 16, backgroundColor: Color(int.parse(_postAuthorProfile!['avatar_color'])).withOpacity(0.3), child: Padding(padding: const EdgeInsets.all(3.0), child: Image.asset('assets/${_postAuthorProfile!['avatar_icon']}.png'))),
                          const SizedBox(width: 8),
                          Text(_postAuthorProfile!['username'], style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(widget.post['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // IMAGEM OU VÍDEO DO POST
                  if (widget.post['image_url'] != null)
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(widget.post['image_url'], width: double.infinity, fit: BoxFit.cover))),
                  
                  if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: AspectRatio(
                          aspectRatio: _videoCtrl!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              VideoPlayer(_videoCtrl!),
                              VideoProgressIndicator(_videoCtrl!, allowScrubbing: true, colors: VideoProgressColors(playedColor: Theme.of(context).primaryColor)),
                              Center(child: IconButton(icon: Icon(_videoCtrl!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 50), onPressed: () { setState(() { _videoCtrl!.value.isPlaying ? _videoCtrl!.pause() : _videoCtrl!.play(); }); })),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  Linkify(text: widget.post['content'], style: const TextStyle(fontSize: 16, height: 1.5), onOpen: (link) => launchUrl(Uri.parse(link.url))),
                  const SizedBox(height: 20),
                  
                  // LIKES DO POST
                  Row(
                    children: [
                      IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white54, size: 30), onPressed: _toggleLike),
                      Text('$_likesCount Gostos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const Divider(height: 40, color: Colors.white24),
                  const Text('Comentários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _commentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) return const Text('Sê o primeiro a comentar!');
                      
                      return ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          // INDENTAÇÃO PARA RESPOSTAS A COMENTÁRIOS
                          final isReply = c['parent_id'] != null;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.0, left: isReply ? 40.0 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(15)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Linkify(text: c['content'], onOpen: (link) => launchUrl(Uri.parse(link.url))),
                                        if (c['gif_url'] != null)
                                          Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(c['gif_url'], height: 100, fit: BoxFit.cover))),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => setState(() { _replyingToId = c['id']; _replyingToName = 'Comentário'; }),
                                          child: Text('Responder', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // BARRA DE COMENTÁRIO COM GIF E RESPOSTA
          Container(
            padding: const EdgeInsets.all(16), color: const Color(0xFF23232F),
            child: SafeArea(
              child: Column(
                children: [
                  if (_replyingToId != null)
                    Row(
                      children: [
                        Text('A responder a $_replyingToName...', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _replyingToId = null))
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _commentCtrl, decoration: InputDecoration(hintText: 'Comentar...', filled: true, fillColor: const Color(0xFF181820), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
                      IconButton(icon: const Icon(Icons.gif_box, color: Colors.white54), onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Inserir GIF (Link)'), content: TextField(controller: _gifCtrl), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))]))),
                      IconButton(icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor), onPressed: _sendComment),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
