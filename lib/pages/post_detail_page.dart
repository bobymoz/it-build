import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  Map<String, dynamic>? _postAuthorProfile;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchAuthor();
    _loadComments();
  }

  void _loadComments() {
    setState(() {
      // Puxa os comentários E os perfis de quem comentou de uma só vez
      _commentsFuture = Supabase.instance.client
          .from('comments')
          .select('*, profiles(*)')
          .eq('post_id', widget.post['id'])
          .order('created_at', ascending: true);
    });
  }

  Future<void> _fetchAuthor() async {
    final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.post['profile_id']).single();
    if (mounted) setState(() => _postAuthorProfile = data);
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('comments').insert({
        'post_id': widget.post['id'],
        'profile_id': _currentUserId,
        'content': _commentCtrl.text.trim(),
      });
      
      // Gera Notificação para o dono do post (se não fores tu mesmo a comentar no teu post)
      if (widget.post['profile_id'] != _currentUserId) {
        await Supabase.instance.client.from('notifications').insert({
          'profile_id': widget.post['profile_id'],
          'content': 'Alguém comentou no teu post: "${widget.post['title']}"',
        });
      }

      _commentCtrl.clear();
      FocusScope.of(context).unfocus();
      _loadComments(); // Atualiza a lista de comentários
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar comentário.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          // O Post em Si
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Autor do Post (Clicável)
                  if (_postAuthorProfile != null)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(ProfilePage.route(_postAuthorProfile!['id'])),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(int.parse(_postAuthorProfile!['avatar_color'])).withOpacity(0.3),
                            child: Padding(padding: const EdgeInsets.all(3.0), child: Image.asset('assets/${_postAuthorProfile!['avatar_icon']}.png', fit: BoxFit.contain)),
                          ),
                          const SizedBox(width: 8),
                          Text(_postAuthorProfile!['username'] ?? 'Utilizador', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(widget.post['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(widget.post['content'], style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 40, color: Colors.white24),
                  const Text('Comentários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Lista de Comentários
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Sê o primeiro a comentar!', style: TextStyle(color: Colors.white54));
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final comment = snapshot.data![index];
                          final profile = comment['profiles'] ?? {'username': 'Anónimo', 'avatar_icon': 1, 'avatar_color': '0xFFB388FF'};
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(ProfilePage.route(profile['id'])),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(int.parse(profile['avatar_color'].toString())).withOpacity(0.3),
                                    child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${profile['avatar_icon']}.png', fit: BoxFit.contain)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(15)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(profile['username'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                                        const SizedBox(height: 4),
                                        Text(comment['content']),
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
          
          // Barra de Escrever Comentário
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF23232F),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Adicionar comentário...',
                        filled: true,
                        fillColor: const Color(0xFF181820),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                    onPressed: _sendComment,
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
